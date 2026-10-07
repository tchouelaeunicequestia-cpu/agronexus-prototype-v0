// src/main/java/com/agronexus/api/controller/TransporterController.java
package com.agronexus.api.controller;

import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.entity.EscrowStatus;
import com.agronexus.api.entity.Order;
import com.agronexus.api.entity.User;
import com.agronexus.api.service.EscrowEngineService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.Map;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/transporter")
public class TransporterController {

    private final OrderRepository orderRepository;
    private final EscrowEngineService escrowEngineService;

    public TransporterController(OrderRepository orderRepository, EscrowEngineService escrowEngineService) {
        this.orderRepository = orderRepository;
        this.escrowEngineService = escrowEngineService;
    }

    @GetMapping("/metrics")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<?> getTransporterMetrics() {
        return ResponseEntity.ok(Map.of(
            "lockedEscrow", "100,000 XAF",
            "temp", "8.2°C",
            "odometer", "142 km",
            "jobs", 2
        ));
    }

    @GetMapping("/quote-requests")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<List<Map<String, Object>>> getQuoteRequests() {
        return ResponseEntity.ok(orderRepository.findAll().stream()
                .filter(order -> order.getEscrowStatus() == EscrowStatus.TRANSPORT_QUOTE_PENDING)
                .map(this::orderSummary)
                .collect(Collectors.toList()));
    }

    @PostMapping("/orders/{orderCode}/quote")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<Map<String, Object>> submitQuote(
            @PathVariable String orderCode,
            @RequestBody Map<String, Object> payload,
            @AuthenticationPrincipal User transporter) {
        BigDecimal fee = new BigDecimal(payload.get("transportFee").toString());
        Order order = escrowEngineService.submitTransportQuote(orderCode, transporter, fee);
        return ResponseEntity.ok(orderSummary(order));
    }

    @GetMapping("/active-trip")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<Map<String, Object>> getActiveTrip(@AuthenticationPrincipal User transporter) {
        // Fetch the first order assigned to this transporter that is in transit or dispatched
        Order activeOrder = orderRepository.findAll().stream()
                .filter(order -> order.getTransporter() != null && 
                                 order.getTransporter().getId().equals(transporter.getId()) &&
                                 (order.getEscrowStatus() == EscrowStatus.DISPATCHED || order.getEscrowStatus() == EscrowStatus.IN_TRANSIT))
                .findFirst()
                .orElse(null);

        if (activeOrder == null) {
            return ResponseEntity.ok(Map.of("hasActiveTrip", false));
        }
        
        Map<String, Object> tripData = orderSummary(activeOrder);
        tripData.put("hasActiveTrip", true);
        return ResponseEntity.ok(tripData);
    }

    @GetMapping("/waybill/{orderCode}")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<Map<String, Object>> getWaybill(@PathVariable String orderCode, @AuthenticationPrincipal User transporter) {
        Order order = orderRepository.findAll().stream()
                .filter(o -> o.getOrderCode().equals(orderCode))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));
                
        return ResponseEntity.ok(orderSummary(order));
    }

    private Map<String, Object> orderSummary(Order order) {
        String sellerName = order.getProduct().getFarmer() != null ? order.getProduct().getFarmer().getFullName() : "Unknown Farmer";
        String origin = order.getProduct().getLocation() != null ? order.getProduct().getLocation() : "Farm Gate";
        
        return Map.of(
                "id", order.getOrderCode(),
                "type", "Dry/Cold Cargo",
                "priority", "Standard",
                "price", order.getTransportFee() != null ? order.getTransportFee().toString() : "0",
                "title", order.getQuantity() + " kg " + order.getProduct().getTitle(),
                "seller", sellerName,
                "pickup", "Ready for pickup",
                "distance", "Distance est. by routing",
                "origin", origin,
                "destination", order.getDeliveryAddress() != null ? order.getDeliveryAddress() : "Buyer Location",
                "image", "assets/images/abstract_background_1.jpg",
                "status", order.getEscrowStatus().name());
    }
}