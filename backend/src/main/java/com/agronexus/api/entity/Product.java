package com.agronexus.api.entity;

import jakarta.persistence.*;//jpa
import lombok.*;//lombok
import org.locationtech.jts.geom.Point;//postgis
import java.math.BigDecimal;//bigdecimal
import java.time.ZonedDateTime;

/**
 * ==============================================================================
 * AgroNexus Product Produce Entity
 * 
 * WHY: Represents agricultural produce listings created by Farmers.
 * HOW: Maps to PostgreSQL 'products' table and contains PostGIS GPS coordinates.
 * ==============================================================================
 */
@Entity
@Table(name = "products")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)//auto increment id
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)//many to one mapping
    @com.fasterxml.jackson.annotation.JsonIgnore
    private User farmer;

    @Column(name = "title", nullable = false, length = 150)
    private String title;

    @Column(name = "category", nullable = false, length = 50)
    private String category;

    @Column(name = "description", columnDefinition = "TEXT", length = 10000)
    private String description;

    @Column(name = "price_per_unit", nullable = false, precision = 10, scale = 2)
    private BigDecimal pricePerUnit;

    @Column(name = "unit_type", length = 20)
    private String unitType;

    @Column(name = "available_quantity", nullable = false)
    private Double availableQuantity;

    @Column(name = "location", nullable = false, columnDefinition = "geometry(Point, 4326)")
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Point location;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = ZonedDateTime.now();
        updatedAt = ZonedDateTime.now();
        if (isActive == null) {
            isActive = true;
        }
        if (unitType == null) {
            unitType = "kg";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = ZonedDateTime.now();
    }
}
