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
import java.util.HashMap;
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
        
        Map<String, Object> tripData = new java.util.HashMap<>(orderSummary(activeOrder));
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
                
        Map<String, Object> summary = new java.util.HashMap<>(orderSummary(order));
        summary.put("consignorName", order.getProduct() != null && order.getProduct().getFarmer() != null ? order.getProduct().getFarmer().getFullName() : "Verified Farmer");
        summary.put("consignorPhone", order.getProduct() != null && order.getProduct().getFarmer() != null && order.getProduct().getFarmer().getPhoneNumber() != null ? order.getProduct().getFarmer().getPhoneNumber() : "+237 670 000 000");
        summary.put("consignorLocation", order.getProduct() != null && order.getProduct().getLocation() != null ? order.getProduct().getLocation() : "Farm Gate");
        
        summary.put("consigneeName", order.getBuyer() != null ? order.getBuyer().getFullName() : "Verified Buyer");
        summary.put("consigneePhone", order.getBuyer() != null && order.getBuyer().getPhoneNumber() != null ? order.getBuyer().getPhoneNumber() : "+237 690 000 000");
        summary.put("consigneeAddress", order.getDeliveryAddress() != null ? order.getDeliveryAddress() : "Destination Warehouse");
        
        summary.put("transporterName", transporter != null ? transporter.getFullName() : (order.getTransporter() != null ? order.getTransporter().getFullName() : "Active Transporter"));
        summary.put("transporterPhone", transporter != null && transporter.getPhoneNumber() != null ? transporter.getPhoneNumber() : "+237 680 000 000");
        
        summary.put("productTitle", order.getProduct() != null ? order.getProduct().getTitle() : "Produce");
        summary.put("productQuantity", order.getQuantity() != null ? order.getQuantity().toString() + " kg" : "0 kg");
        summary.put("escrowAmount", order.getTotalEscrowAmount() != null ? order.getTotalEscrowAmount().toString() : "0.00");
        summary.put("transportFee", order.getTransportFee() != null ? order.getTransportFee().toString() : "0.00");
        summary.put("createdAt", order.getCreatedAt() != null ? order.getCreatedAt().toString() : java.time.ZonedDateTime.now().toString());

        return ResponseEntity.ok(summary);
    }

    @PostMapping("/handover/{orderCode}/confirm")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<Map<String, Object>> confirmHandover(
            @PathVariable String orderCode,
            @AuthenticationPrincipal User transporter) {
        Map<String, Object> result = escrowEngineService.disburseEscrowFunds(orderCode);
        return ResponseEntity.ok(result);
    }

    private Map<String, Object> orderSummary(Order order) {
        String sellerName = order.getProduct() != null && order.getProduct().getFarmer() != null
                ? order.getProduct().getFarmer().getFullName() : "Unknown Farmer";
        String origin = "Farm Gate";
        if (order.getProduct() != null && order.getProduct().getLocation() != null) {
            origin = String.format("%.4f, %.4f", order.getProduct().getLocation().getY(), order.getProduct().getLocation().getX());
        }
        
        Map<String, Object> map = new HashMap<>();
        map.put("id", order.getOrderCode());
        map.put("type", "Dry/Cold Cargo");
        map.put("priority", "Standard");
        map.put("price", order.getTransportFee() != null ? order.getTransportFee().toString() : "0");
        map.put("title", (order.getQuantity() != null ? order.getQuantity() : "0") + " kg " + (order.getProduct() != null ? order.getProduct().getTitle() : "Harvest Cargo"));
        map.put("seller", sellerName);
        map.put("pickup", "Ready for pickup");
        map.put("distance", "Distance est. by routing");
        map.put("origin", origin);
        map.put("destination", order.getDeliveryAddress() != null ? order.getDeliveryAddress() : "Buyer Location");
        map.put("image", "assets/images/abstract_background_1.jpg");
        map.put("status", order.getEscrowStatus() != null ? order.getEscrowStatus().name() : "PENDING");
        return map;
    }
}