package com.agronexus.api.controller;

import com.agronexus.api.entity.TelemetryLog;
import com.agronexus.api.entity.ActuatorCommand;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.ActuatorCommandRepository;
import com.agronexus.api.repository.TelemetryLogRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * ==============================================================================
 * AgroNexus Cyber-Physical IoT Telemetry Ingestion Controller
 *
 * WHY: Ingests real-time environmental data from ESP32 storage sensor nodes
 *      and serves telemetry logs to monitoring dashboards.
 * HOW: Evaluates safety thresholds (temperature, humidity, gas levels) upon
 *      ingestion to flag environmental alerts for crop preservation.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/telemetry")
public class TelemetryController {

    private final TelemetryLogRepository telemetryLogRepository;
    private final ActuatorCommandRepository actuatorCommandRepository;
    private final CopyOnWriteArrayList<SseEmitter> alertSubscribers =
            new CopyOnWriteArrayList<>();

    public TelemetryController(
            TelemetryLogRepository telemetryLogRepository,
            ActuatorCommandRepository actuatorCommandRepository) {
        this.telemetryLogRepository = telemetryLogRepository;
        this.actuatorCommandRepository = actuatorCommandRepository;
    }

    // POST /api/v1/telemetry — ESP32 Sensor Hardware Payload Ingestion
    @PostMapping
    public ResponseEntity<?> ingestTelemetry(@RequestBody Map<String, Object> payload) {
        String nodeId = (String) payload.get("nodeId");
        Float temp = ((Number) payload.get("temp")).floatValue();
        Float humidity = ((Number) payload.get("humidity")).floatValue();
        Integer gas = ((Number) payload.get("gas")).intValue();

        // Safety Threshold Evaluation (FAO Crop Storage Standards)
        boolean alert = temp > 30.0f || humidity > 85.0f || gas > 400;
        String alertMsg = alert ? "CRITICAL: Storage environmental parameters exceed FAO safe threshold!" : null;

        TelemetryLog log = TelemetryLog.builder()
                .nodeId(nodeId)
                .temperature(temp)
                .humidity(humidity)
                .gasLevel(gas)
                .isAlertTriggered(alert)
                .alertMessage(alertMsg)
                .build();

        TelemetryLog saved = telemetryLogRepository.save(log);
        if (alert) {
            publishAlert(saved);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping(value = "/alerts/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @PreAuthorize("hasRole('AGRONOMIST')")
    public SseEmitter streamAlerts() {
        SseEmitter emitter = new SseEmitter(0L);
        alertSubscribers.add(emitter);
        emitter.onCompletion(() -> alertSubscribers.remove(emitter));
        emitter.onTimeout(() -> alertSubscribers.remove(emitter));
        emitter.onError(error -> alertSubscribers.remove(emitter));
        try {
            emitter.send(SseEmitter.event()
                    .name("connected")
                    .data(Map.of("status", "connected")));
        } catch (IOException error) {
            alertSubscribers.remove(emitter);
            emitter.completeWithError(error);
        }
        return emitter;
    }

    // GET /api/v1/telemetry/node/{nodeId} — Latest 50 sensor logs for a storage unit
    @GetMapping("/node/{nodeId}")
    public ResponseEntity<List<TelemetryLog>> getNodeLogs(@PathVariable String nodeId) {
        return ResponseEntity.ok(telemetryLogRepository.findTop50ByNodeIdOrderByRecordedAtDesc(nodeId));
    }

    @GetMapping("/nodes")
    @PreAuthorize("hasRole('AGRONOMIST')")
    public ResponseEntity<List<TelemetryLog>> getNodes() {
        List<TelemetryLog> nodes = telemetryLogRepository.findDistinctNodeIds().stream()
                .map(telemetryLogRepository::findTopByNodeIdOrderByRecordedAtDesc)
                .filter(log -> log != null)
                .toList();
        return ResponseEntity.ok(nodes);
    }

    @GetMapping("/actuator-commands")
    @PreAuthorize("hasRole('AGRONOMIST')")
    public ResponseEntity<List<Map<String, Object>>> getActuatorCommands() {
        return ResponseEntity.ok(actuatorCommandRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(TelemetryController::commandResponse)
                .toList());
    }

    @PostMapping("/nodes/{nodeId}/commands")
    @PreAuthorize("hasRole('AGRONOMIST')")
    public ResponseEntity<?> createActuatorCommand(
            @PathVariable String nodeId,
            @RequestBody Map<String, String> request,
            @AuthenticationPrincipal User user) {
        String action = request.get("action");
        if (!"AERATION_START".equals(action) && !"UV_DECONTAMINATION".equals(action)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Action must be AERATION_START or UV_DECONTAMINATION."));
        }
        if (!telemetryLogRepository.existsByNodeId(nodeId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "error", "No telemetry node was found with ID " + nodeId + "."));
        }

        ActuatorCommand command = ActuatorCommand.builder()
                .nodeId(nodeId)
                .action(action)
                .status("PENDING_DEVICE")
                .requestedBy(user.getEmail())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(commandResponse(actuatorCommandRepository.save(command)));
    }

    private static Map<String, Object> commandResponse(ActuatorCommand command) {
        return Map.of(
                "id", command.getId(),
                "nodeId", command.getNodeId(),
                "action", command.getAction(),
                "status", command.getStatus(),
                "createdAt", command.getCreatedAt());
    }

    private void publishAlert(TelemetryLog alert) {
        alertSubscribers.removeIf(emitter -> {
            try {
                emitter.send(SseEmitter.event()
                        .name("telemetry-alert")
                        .data(alert));
                return false;
            } catch (IOException error) {
                emitter.completeWithError(error);
                return true;
            }
        });
    }
}