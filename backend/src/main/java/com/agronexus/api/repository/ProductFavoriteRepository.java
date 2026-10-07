package com.agronexus.api.repository;

import com.agronexus.api.entity.ProductFavorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductFavoriteRepository extends JpaRepository<ProductFavorite, Long> {

    List<ProductFavorite> findByUserIdOrderByCreatedAtDesc(Long userId);

    boolean existsByUserIdAndProductId(Long userId, Long productId);

    void deleteByUserIdAndProductId(Long userId, Long productId);
}
