-- Adds pgvector-backed semantic search storage for shopassist's RAG
-- service (services/rag.py::PgVectorRAGService) - see
-- docs/database-design.md for the full design rationale.
--
-- Requires the postgres service to actually have pgvector installed:
-- docker-compose.yml's image must be pgvector/pgvector:pg17 (or
-- equivalent), not the bare postgres:17 image, which doesn't bundle it.
--
-- Idempotent: CREATE EXTENSION/TABLE/INDEX all guard with IF NOT EXISTS,
-- safe to re-run against a database that already has the other 5 tables
-- and data.
--
-- After applying this to a live database, ../schema/schema.sql and
-- ../schema/indexes.sql have already been updated to match (a fresh
-- install gets this table directly, it doesn't need this migration) -
-- see postgres/migrations/README.md's convention.

\echo 'ShopAssist :: applying migration 0001_add_document_chunks_for_rag ...'

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS document_chunks (
    doc_id          VARCHAR(255)  PRIMARY KEY,
    content         TEXT          NOT NULL,
    embedding       VECTOR(768)   NOT NULL,
    source_type     VARCHAR(50)   NOT NULL,
    metadata        JSONB         NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE document_chunks IS 'Chunked text + embeddings for RAG semantic search (product catalog, support policy, conversation history).';
COMMENT ON COLUMN document_chunks.embedding IS 'nomic-embed-text output dimension (768) via Ollama - see shopassist-model/config/generative.yaml.';

CREATE INDEX IF NOT EXISTS idx_document_chunks_source_type ON document_chunks(source_type);

CREATE INDEX IF NOT EXISTS idx_document_chunks_embedding
    ON document_chunks USING hnsw (embedding vector_cosine_ops);

\echo 'ShopAssist :: migration 0001_add_document_chunks_for_rag applied.'
