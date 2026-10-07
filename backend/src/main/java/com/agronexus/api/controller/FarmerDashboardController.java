package com.agronexus.api.controller;

import com.agronexus.api.entity.Product;
import com.agronexus.api.entity.TelemetryLog;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.repository.ProductRepository;
import com.agronexus.api.repository.TelemetryLogRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farmers")
public class FarmerDashboardController {

    private final ProductRepository productRepository;
    private final TelemetryLogRepository telemetryLogRepository;
    private final OrderRepository orderRepository;
    public FarmerDashboardController(ProductRepository productRepository, 
                                     TelemetryLogRepository telemetryLogRepository,
                                     OrderRepository orderRepository) {
        this.productRepository = productRepository;
        this.telemetryLogRepository = telemetryLogRepository;
        this.orderRepository = orderRepository;
    }

    // GET /api/v1/farmers/{farmerId}/dashboard
    @GetMapping("/{farmerId}/dashboard")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    public ResponseEntity<?> getFarmerDashboard(@PathVariable Long farmerId,
                                                @AuthenticationPrincipal User authenticatedUser) {
        if (!authenticatedUser.getId().equals(farmerId)
                && authenticatedUser.getRole().name().equals("FARMER")) {
            return ResponseEntity.status(403).body(Map.of("error", "You can only view your own dashboard."));
        }
        return buildDashboard(farmerId);
    }

    @GetMapping("/me/dashboard")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<?> getMyDashboard(@AuthenticationPrincipal User authenticatedUser) {
        return buildDashboard(authenticatedUser.getId());
    }

    private ResponseEntity<?> buildDashboard(Long farmerId) {
        List<Product> products = productRepository.findByFarmerId(farmerId);
        double totalYield = products.stream()
                .mapToDouble(Product::getAvailableQuantity)
                .sum();
        TelemetryLog telemetry = telemetryLogRepository.findTopByOrderByRecordedAtDesc();
        double escrowBalance = orderRepository.findByProductFarmerId(farmerId).stream()
                .filter(order -> order.getEscrowStatus() != null
                        && order.getEscrowStatus().name().equals("HELD_IN_ESCROW"))
                .map(order -> order.getTotalEscrowAmount().doubleValue())
                .reduce(0.0, Double::sum);

        Map<String, Object> dashboard = new HashMap<>();
        dashboard.put("escrowBalance", escrowBalance);
        dashboard.put("activeLotsCount", products.size());
        dashboard.put("totalYieldKg", totalYield);
        dashboard.put("siloTemp", telemetry == null ? null : telemetry.getTemperature());
        dashboard.put("siloHumidity", telemetry == null ? null : telemetry.getHumidity());
        dashboard.put("siloGas", telemetry == null ? null : telemetry.getGasLevel());
        dashboard.put("telemetryAvailable", telemetry != null);
        dashboard.put("telemetryNodeId", telemetry == null ? null : telemetry.getNodeId());
        dashboard.put("storageFacilityName", telemetry == null ? null : telemetry.getStorageFacilityName());
        dashboard.put("telemetryAlert", telemetry != null && Boolean.TRUE.equals(telemetry.getIsAlertTriggered()));
        dashboard.put("telemetryAlertMessage", telemetry == null ? null : telemetry.getAlertMessage());
        dashboard.put("telemetryRecordedAt", telemetry == null ? null : telemetry.getRecordedAt());
        return ResponseEntity.ok(dashboard);
    }
}