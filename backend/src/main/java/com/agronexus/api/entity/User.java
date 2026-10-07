package com.agronexus.api.entity;

import jakarta.persistence.*;//jpa
import lombok.*;//lombok
import org.locationtech.jts.geom.Point;//postgis
import java.time.ZonedDateTime;//time api

/**
 * ==============================================================================
 * AgroNexus User Entity
 * 
 * WHY: Represents user accounts, credentials, RBAC role flags, and base GPS location.
 * HOW: Maps to PostgreSQL 'users' table and utilizes PostGIS Point spatial geometry.
 * ==============================================================================
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;

    @Column(name = "email", nullable = false, unique = true, length = 100)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 20)
    private Role role;

    @Column(name = "phone_number", length = 20)
    private String phoneNumber;

    @Column(name = "national_id_hash", length = 128)
    private String nationalIdHash;

    @Column(name = "email_verified", nullable = false)
    private Boolean emailVerified;

    @Column(name = "phone_verified", nullable = false)
    private Boolean phoneVerified;

    @Column(name = "identity_verified", nullable = false)
    private Boolean identityVerified;

    @Column(name = "biometric_verified", nullable = false)
    private Boolean biometricVerified;

    @Column(name = "cni_verified")
    private Boolean cniVerified;

    @Column(name = "cni_image_path", length = 500)
    private String cniImagePath;

    @Column(name = "face_image_path", length = 500)
    private String faceImagePath;

    @Column(name = "is_verified")
    private Boolean isVerified;

    @Column(name = "location", columnDefinition = "geometry(Point, 4326)")
    private Point location;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = ZonedDateTime.now();
        updatedAt = ZonedDateTime.now();
        if (isVerified == null) {
            isVerified = false;
        }
        if (emailVerified == null) emailVerified = false;
        if (phoneVerified == null) phoneVerified = false;
        if (identityVerified == null) identityVerified = false;
        if (biometricVerified == null) biometricVerified = false;
        if (cniVerified == null) cniVerified = false;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = ZonedDateTime.now();
    }
}
