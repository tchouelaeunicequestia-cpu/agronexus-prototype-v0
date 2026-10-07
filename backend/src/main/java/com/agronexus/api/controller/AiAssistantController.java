package com.agronexus.api.controller;

import com.agronexus.api.entity.KnowledgeEmbedding;
import com.agronexus.api.repository.KnowledgeEmbeddingRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * ==============================================================================
 * AgroNexus Domain-Guarded RAG AI Assistant Controller
 *
 * WHY: Evaluates prompt domain constraints and returns grounded FAO/USDA advice
 *      to eliminate AI hallucinations for rural agricultural producers.
 * HOW: Filters queries against domain keyword guardrails and retrieves published
 *      Agronomist guides using lexical keyword matching.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/ai")
public class AiAssistantController {

    private static final Set<String> STOP_WORDS = Set.of(
            "about", "after", "are", "can", "does", "for", "from", "how", "into",
            "the", "this", "what", "when", "where", "which", "with", "would");

    private static final List<String> ALLOWED_KEYWORDS = List.of(
        "crop", "maize", "fao", "post-harvest", "storage", "temperature", 
        "humidity", "cocoa", "grain", "mold", "pest", "aflatoxin", "harvest"
    );

    private final KnowledgeEmbeddingRepository guideRepository;

    public AiAssistantController(KnowledgeEmbeddingRepository guideRepository) {
        this.guideRepository = guideRepository;
    }

    @PostMapping("/query")
    public ResponseEntity<Map<String, Object>> queryAssistant(@RequestBody Map<String, String> request) {
        String query = request.get("query");
        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", "REJECTED",
                    "answer", "Enter an agricultural question to search published guides."));
        }
        String normalizedQuery = query.toLowerCase(Locale.ROOT);

        // 1. Domain Guardrail Validation
        boolean isAllowed = ALLOWED_KEYWORDS.stream().anyMatch(normalizedQuery::contains);

        if (!isAllowed) {
            return ResponseEntity.badRequest().body(Map.of(
                "status", "REJECTED",
                "answer", "Query outside approved agricultural domain. AgroNexus AI is strictly restricted to agronomy, post-harvest crop preservation, storage telemetry, and CEMAC/FAO trade standards."
            ));
        }

        Set<String> queryTerms = terms(normalizedQuery);
        List<RankedGuide> matches = guideRepository
                .findAllByStatusOrderByCreatedAtDesc("PUBLISHED")
                .stream()
                .map(guide -> new RankedGuide(
                        guide,
                        (int) terms(guide.getTitle() + " " + guide.getCategory() + " "
                                + guide.getContentChunk()).stream()
                                .filter(queryTerms::contains)
                                .count()))
                .filter(match -> match.score() > 0)
                .sorted(Comparator.comparingInt(RankedGuide::score).reversed())
                .limit(3)
                .toList();

        if (matches.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                    "status", "NO_SOURCE",
                    "answer", "No published Agronomist guide matched this question. Try different terms or publish a relevant guide.",
                    "groundingMode", "PUBLISHED_GUIDE_KEYWORD_MATCH"));
        }

        String answer = matches.stream()
                .map(match -> match.guide().getContentChunk())
                .collect(Collectors.joining("\n\n"));
        String citations = matches.stream()
                .map(match -> match.guide().getTitle() + " — " + match.guide().getSourceAgency())
                .collect(Collectors.joining("; "));
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "APPROVED");
        response.put("answer", answer);
        response.put("citation", citations);
        response.put("groundingMode", "PUBLISHED_GUIDE_KEYWORD_MATCH");
        return ResponseEntity.ok(response);
    }

    private static Set<String> terms(String text) {
        return java.util.Arrays.stream(text.toLowerCase(Locale.ROOT)
                        .split("[^\\p{L}\\p{N}]+"))
                .filter(term -> term.length() > 2)
                .filter(term -> !STOP_WORDS.contains(term))
                .collect(Collectors.toSet());
    }

    private record RankedGuide(KnowledgeEmbedding guide, int score) {}
}