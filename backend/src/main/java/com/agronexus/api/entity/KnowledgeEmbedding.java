package com.agronexus.api.entity;

import jakarta.persistence.*; // JPA ORM annotations
import lombok.*; // Lombok getters, setters, builders
import java.time.ZonedDateTime;

/**
 * ==============================================================================
 * AgroNexus Knowledge Embedding Entity (FAO / USDA RAG Vectors)
 * 
 * WHY: Stores authoritative agricultural reference text chunks for RAG AI retrieval.
 * HOW: Maps to PostgreSQL 'knowledge_embeddings' table with unlimited TEXT capacity
 *      to ensure zero truncation of FAO/USDA reference documents.
 * ==============================================================================
 */
@Entity
@Table(name = "knowledge_embeddings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KnowledgeEmbedding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "title", nullable = false, length = 500) // Expanded for long document titles
    private String title;

    @Column(name = "source_agency", nullable = false, length = 50) // e.g. FAO, USDA, UNECE
    private String sourceAgency;

    @Column(name = "category", nullable = false, length = 100) // e.g. CROP_STORAGE, DISEASE_CONTROL
    private String category;

    @Column(name = "content_chunk", nullable = false, columnDefinition = "TEXT") // Full text capacity
    private String contentChunk;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
        if (status == null) {
            status = "DRAFT";
        }
    }
}
