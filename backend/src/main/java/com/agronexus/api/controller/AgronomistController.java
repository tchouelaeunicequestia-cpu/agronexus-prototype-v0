package com.agronexus.api.controller;

import com.agronexus.api.entity.KnowledgeEmbedding;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.KnowledgeEmbeddingRepository;
import com.agronexus.api.repository.TelemetryLogRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/agronomist")
@PreAuthorize("hasRole('AGRONOMIST')")
public class AgronomistController {

    private final TelemetryLogRepository telemetryLogRepository;
    private final KnowledgeEmbeddingRepository guideRepository;

    public AgronomistController(
            TelemetryLogRepository telemetryLogRepository,
            KnowledgeEmbeddingRepository guideRepository) {
        this.telemetryLogRepository = telemetryLogRepository;
        this.guideRepository = guideRepository;
    }

    @GetMapping("/metrics")
    public ResponseEntity<Map<String, Object>> getAgronomistMetrics() {
        long alertCount = telemetryLogRepository.countByIsAlertTriggeredTrue();
        long storageNodes = telemetryLogRepository.countDistinctNodeIds();
        return ResponseEntity.ok(Map.of(
                "openAlerts", alertCount,
                "triggeredAlerts", alertCount,
                "storageNodes", storageNodes,
                "monitoredNodes", storageNodes));
    }

    @GetMapping("/guides")
    public ResponseEntity<List<Map<String, Object>>> getGuides() {
        return ResponseEntity.ok(guideRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(AgronomistController::guideResponse)
                .toList());
    }

    @PostMapping("/guides")
    public ResponseEntity<?> createGuide(
            @RequestBody GuideRequest request,
            @AuthenticationPrincipal User author) {
        if (request.title() == null || request.title().isBlank()
                || request.sourceAgency() == null || request.sourceAgency().isBlank()
                || request.category() == null || request.category().isBlank()
                || request.content() == null || request.content().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Title, source agency, category, and content are required."));
        }

        KnowledgeEmbedding guide = KnowledgeEmbedding.builder()
                .title(request.title().trim())
                .sourceAgency(request.sourceAgency().trim())
                .category(request.category().trim())
                .contentChunk(request.content().trim())
                .status("DRAFT")
                .createdBy(author.getEmail())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(guideResponse(guideRepository.save(guide)));
    }

    @PostMapping("/guides/{guideId}/publish")
    @Transactional
    public ResponseEntity<?> publishGuide(@PathVariable Long guideId) {
        return guideRepository.findById(guideId)
                .map(guide -> {
                    guide.setStatus("PUBLISHED");
                    return ResponseEntity.ok(guideResponse(guideRepository.save(guide)));
                })
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "Guide not found.")));
    }

    private static Map<String, Object> guideResponse(KnowledgeEmbedding guide) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("id", guide.getId());
        response.put("title", guide.getTitle());
        response.put("sourceAgency", guide.getSourceAgency());
        response.put("category", guide.getCategory());
        response.put("content", guide.getContentChunk());
        response.put("status", guide.getStatus());
        response.put("createdAt", guide.getCreatedAt());
        return response;
    }

    public record GuideRequest(String title, String sourceAgency, String category, String content) {
    }
}
