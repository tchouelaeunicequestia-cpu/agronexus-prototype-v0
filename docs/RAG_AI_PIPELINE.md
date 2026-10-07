# AgroNexus Agronomist Guide Retrieval

## Current behavior

`POST /api/v1/ai/query` applies an agricultural-domain keyword guard and searches the database for published Agronomist guides. Retrieval is lexical keyword matching over guide title, category, and content. Matching guide text is returned verbatim with its title and source agency; no language model generates or expands the answer.

The response reports `groundingMode: "PUBLISHED_GUIDE_KEYWORD_MATCH"`. Out-of-domain questions are rejected. In-domain questions with no matching published guide return `status: "NO_SOURCE"` rather than fabricated advice.

Agronomists create guides as drafts and explicitly publish them. Only published guide content is eligible for AgroAI retrieval. Source-agency metadata is displayed with guide citations; publication does not independently verify that a guide is authoritative.

## Current limitations

- There is no configured embedding model, vector column/index, pgvector dependency, semantic search, or LLM inference integration.
- Keyword matching can miss relevant guidance when a query and guide use different vocabulary, and may return text that shares terms without answering the question.
- The returned text is source-attributed guide content, not an independently verified or generated recommendation. Users should consult the cited source and qualified experts for safety-critical decisions.
- No precision, latency, or hallucination benchmark has been collected for this implementation.

## Future vector-search work

Before introducing semantic retrieval, select and configure an embedding provider, define model/version and vector dimensions, add a managed schema migration and vector index, and establish ingestion, re-embedding, provenance, evaluation, and failure-handling procedures. Keep lexical retrieval clearly identified until those components are deployed and measured.
