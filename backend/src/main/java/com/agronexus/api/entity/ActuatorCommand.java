package com.agronexus.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.ZonedDateTime;

@Entity
@Table(name = "actuator_commands")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActuatorCommand {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "node_id", nullable = false, length = 50)
    private String nodeId;

    @Column(name = "action", nullable = false, length = 40)
    private String action;

    @Column(name = "status", nullable = false, length = 30)
    private String status;

    @Column(name = "requested_by", nullable = false, length = 100)
    private String requestedBy;

    @Column(name = "created_at", nullable = false)
    private ZonedDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
    }
}
