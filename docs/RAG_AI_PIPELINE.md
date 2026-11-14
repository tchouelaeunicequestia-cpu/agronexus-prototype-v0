# AgroNexus RAG AI Pipeline

## Current behavior

`POST /api/v1/ai/query` applies an agricultural-domain keyword guard and searches the database for published Agronomist guides. Retrieval is currently lexical keyword matching over guide title, category, and content. Matching guide text is returned verbatim with its title and source agency; no language model generates or expands the answer.

The response reports `groundingMode: "PUBLISHED_GUIDE_KEYWORD_MATCH"`. Out-of-domain questions are rejected. In-domain questions with no matching published guide return `status: "NO_SOURCE"` rather than fabricated advice.

Agronomists create guides as drafts and explicitly publish them. Only published guide content is eligible for the current AgroAI retrieval. Source-agency metadata is displayed with guide citations; publication does not independently verify that a guide is authoritative.

This is a retrieval-only MVP, not yet a complete generative RAG system. Embeddings, semantic search, and LLM answer generation are planned but are not part of the current implementation.

## Current limitations

- There is no configured embedding model or LLM inference integration in the current query path. The database schema and deployment setup contain pgvector preparation, but that does not mean semantic retrieval is active.
- Keyword matching can miss relevant guidance when a query and guide use different vocabulary, and may return text that shares terms without answering the question.
- The returned text is source-attributed guide content, not an independently verified or generated recommendation. Users should consult the cited source and qualified experts for safety-critical decisions.
- Agronomist guides are not the only appropriate information source. A guide may be incomplete, outdated, region-specific, or inconsistent with official guidance.
- No precision, latency, or hallucination benchmark has been collected for this implementation.

## Recommended target architecture

The target system should use a **multi-source hybrid RAG architecture**:

```text
Official sources, reviewed agronomist guides, research, live data, and farmer observations
  -> ingestion, validation, metadata, and review
  -> document storage and chunking
  -> Hugging Face multilingual embeddings
  -> PostgreSQL full-text search + pgvector HNSW search
  -> hybrid ranking, source authority, freshness, and conflict handling
  -> optional Hugging Face instruction model
  -> cited answer with safety warnings
```

Agronomist guides should remain an important local source, but not the sole source. The source hierarchy should be:

1. Official agricultural and regulatory sources, including FAO, Cameroon agricultural authorities, USDA, UNECE, and research institutions.
2. Reviewed agronomist guides containing local and practical recommendations.
3. Peer-reviewed research and agricultural extension publications.
4. Structured live data such as weather, soil, crop, pest, and market data.
5. Farmer observations, clearly labelled as observations rather than verified advice.

Every source should carry provenance and filtering metadata such as `sourceType`, `sourceUrl`, `language`, `country`, `region`, `cropName`, `publicationDate`, `reviewStatus`, and `authorityLevel`. Conflicting sources should be surfaced or resolved using authority and freshness rules rather than silently mixed.

## Hugging Face recommendation

Do not train a large language model from scratch for the MVP. Hugging Face is a model and dataset ecosystem, not a single training source. Use it in two separate roles:

- **Embedding model:** start with `intfloat/multilingual-e5-base` for English/French semantic retrieval. It produces 768-dimensional vectors.
- **Instruction model:** add a multilingual instruction-tuned model only after retrieval quality is measured. It may summarize retrieved passages, but it must not be treated as the source of agricultural facts.

Fine-tuning is not an initial requirement. Facts that change over time, such as weather, pesticide rules, and disease alerts, should remain in the retrieved knowledge and live-data layers rather than being stored permanently in model weights.

## Database recommendation

Keep the existing **PostgreSQL 16 + PostGIS + pgvector** design:

- PostgreSQL stores users, products, orders, escrow, guides, and knowledge metadata.
- PostGIS supports spatial marketplace and regional filtering.
- PostgreSQL full-text search provides lexical matching.
- pgvector provides semantic similarity search.
- PostgreSQL transactions remain appropriate for escrow and order state changes.

A separate vector database is unnecessary for the MVP because it would add deployment and synchronization complexity. Use hybrid retrieval: combine PostgreSQL full-text results with pgvector cosine similarity, then rerank using source authority, geographic/crop scope, review status, and freshness.

The recommended embedding column is:

```sql
embedding vector(768)
```

Each vector must record its model and version. Do not mix vectors from different embedding models in one index; changing models requires re-embedding existing documents.

## Future implementation and evaluation

Before enabling semantic retrieval, pin the embedding model, change the vector dimension to match it, add a managed migration and HNSW index, and establish ingestion, re-embedding, provenance, review, and failure-handling procedures.

Before enabling generated answers, measure retrieval precision/recall, answer groundedness, citation correctness, latency, and refusal behavior on a representative English/French agricultural evaluation set. Keep returning `NO_SOURCE` when evidence is insufficient. For pesticide, disease-treatment, livestock-health, or other safety-critical questions, require authoritative current sources, display source dates, and recommend consultation with a qualified local professional.
