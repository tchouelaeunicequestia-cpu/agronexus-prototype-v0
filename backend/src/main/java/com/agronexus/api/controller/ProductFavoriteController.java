package com.agronexus.api.controller;

import com.agronexus.api.entity.Product;
import com.agronexus.api.entity.ProductFavorite;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.ProductFavoriteRepository;
import com.agronexus.api.repository.ProductRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/products/favorites")
@PreAuthorize("hasRole('BUYER')")
public class ProductFavoriteController {

    private final ProductFavoriteRepository favoriteRepository;
    private final ProductRepository productRepository;

    public ProductFavoriteController(
            ProductFavoriteRepository favoriteRepository,
            ProductRepository productRepository
    ) {
        this.favoriteRepository = favoriteRepository;
        this.productRepository = productRepository;
    }

    @GetMapping
    public ResponseEntity<List<Long>> getFavoriteProductIds(
            @AuthenticationPrincipal User buyer
    ) {
        return ResponseEntity.ok(
                favoriteRepository.findByUserIdOrderByCreatedAtDesc(buyer.getId())
                        .stream()
                        .map(favorite -> favorite.getProduct().getId())
                        .toList()
        );
    }

    @PostMapping("/{productId}")
    public ResponseEntity<?> addFavorite(
            @AuthenticationPrincipal User buyer,
            @PathVariable Long productId
    ) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Produce listing not found."));
        if (!Boolean.TRUE.equals(product.getIsActive())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "This produce listing is no longer active."));
        }
        if (!favoriteRepository.existsByUserIdAndProductId(buyer.getId(), productId)) {
            favoriteRepository.save(ProductFavorite.builder()
                    .user(buyer)
                    .product(product)
                    .build());
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("productId", productId, "favorite", true));
    }

    @DeleteMapping("/{productId}")
    public ResponseEntity<Map<String, Object>> removeFavorite(
            @AuthenticationPrincipal User buyer,
            @PathVariable Long productId
    ) {
        favoriteRepository.deleteByUserIdAndProductId(buyer.getId(), productId);
        return ResponseEntity.ok(Map.of("productId", productId, "favorite", false));
    }
}
