package com.agronexus.api.repository;

import com.agronexus.api.entity.TelemetryLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * ==============================================================================
 * AgroNexus Cyber-Physical IoT Telemetry Repository
 *
 * WHY: Provides database access for continuous environmental telemetry metrics
 *      (temperature, relative humidity, gas levels) captured by ESP32 hardware nodes.
 * HOW: Maps to the 'telemetry_logs' table to return recent storage facility logs
 *      and filter active environmental safety alert triggers.
 * ==============================================================================
 */
@Repository
public interface TelemetryLogRepository extends JpaRepository<TelemetryLog, Long> {

    // Fetch the 50 most recent environmental readings recorded by a specific IoT storage node
    List<TelemetryLog> findTop50ByNodeIdOrderByRecordedAtDesc(String nodeId);

    // Fetch all logs where environmental safety thresholds (temperature/humidity/gas) were exceeded
    List<TelemetryLog> findByIsAlertTriggeredTrue();

    TelemetryLog findTopByOrderByRecordedAtDesc();

    TelemetryLog findTopByNodeIdOrderByRecordedAtDesc(String nodeId);

    boolean existsByNodeId(String nodeId);

    long countByIsAlertTriggeredTrue();

    @Query("select count(distinct t.nodeId) from TelemetryLog t")
    long countDistinctNodeIds();

    @Query("select distinct t.nodeId from TelemetryLog t order by t.nodeId")
    List<String> findDistinctNodeIds();
}