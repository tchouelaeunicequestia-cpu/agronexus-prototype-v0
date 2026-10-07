package com.agronexus.api.repository;

import com.agronexus.api.entity.KnowledgeEmbedding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface KnowledgeEmbeddingRepository extends JpaRepository<KnowledgeEmbedding, Long> {

    List<KnowledgeEmbedding> findAllByOrderByCreatedAtDesc();

    List<KnowledgeEmbedding> findAllByStatusOrderByCreatedAtDesc(String status);
}
