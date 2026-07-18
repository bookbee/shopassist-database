-- ShopAssist :: PostgreSQL schema
-- Target: PostgreSQL 17
--
-- This file defines enum types and tables only (columns, primary keys,
-- defaults). Foreign keys and CHECK/UNIQUE constraints live in
-- constraints.sql; performance indexes live in indexes.sql. Keeping these
-- concerns separate lets each be re-run, reviewed, or migrated
-- independently.
--
-- Table and column names match shopassist's own db/schema_sqlite.sql
-- exactly (user_id / item_id / session_id / order_id, not a generic "id"),
-- so clients/ecommerce_api_client.py's SQL runs unchanged once DATABASE_URL
-- points here instead of shopassist's local SQLite file - see
-- README.md.
--
-- user_id is shopassist's own naming choice - the identifier sent by
-- shopassist-client at login, used end to end (see shopassist's
-- db/README.md). user_id / item_id / session_id / order_id are all
-- human-readable business keys (alum-1001, item-1001, sess-1001, ord-1001 -
-- see seeds/) rather than database-generated integers or UUIDs: easy to
-- recognize, log, and read back in a demo. That means they're supplied
-- explicitly on INSERT - there's no IDENTITY/SERIAL/gen_random_uuid() here
-- to override.
--
-- Idempotent: safe to re-run. CREATE TABLE uses IF NOT EXISTS; enum types
-- are guarded by a DO block since PostgreSQL has no CREATE TYPE IF NOT
-- EXISTS.

\echo 'ShopAssist :: applying schema.sql ...'

SET client_encoding = 'UTF8';
-- IST (UTC+5:30) - matches TZ/PGTZ in docker-compose.yml/.env. Only scopes
-- this init session; the container's PGTZ env var is what sets Postgres's
-- actual default `timezone` GUC for every other session.
SET timezone = 'Asia/Kolkata';

-- Needed for document_chunks' embedding column below. Requires the
-- pgvector/pgvector Docker image (see docker-compose.yml) - the bare
-- postgres image doesn't bundle this extension.
CREATE EXTENSION IF NOT EXISTS vector;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status_enum') THEN
        CREATE TYPE order_status_enum AS ENUM (
            'pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'returned'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_status_enum') THEN
        CREATE TYPE session_status_enum AS ENUM ('active', 'expired', 'terminated');
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    user_id         VARCHAR(20)   PRIMARY KEY,
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(255)  NOT NULL,
    phone           VARCHAR(20),
    address_line1   VARCHAR(255),
    address_line2   VARCHAR(255),
    city            VARCHAR(100),
    state           VARCHAR(100),
    postal_code     VARCHAR(20),
    country         VARCHAR(100)  DEFAULT 'India',
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE customers IS 'ShopAssist end users who place orders.';

-- ---------------------------------------------------------------------------
-- items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS items (
    item_id         VARCHAR(20)   PRIMARY KEY,
    name            VARCHAR(255)  NOT NULL,
    description     TEXT,
    category        VARCHAR(100),
    price           NUMERIC(10,2) NOT NULL,
    mrp             NUMERIC(10,2),
    stock_quantity  INTEGER       NOT NULL DEFAULT 0,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE items IS 'Product catalog available for purchase.';

-- ---------------------------------------------------------------------------
-- sessions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sessions (
    session_id      VARCHAR(20)   PRIMARY KEY,
    user_id         VARCHAR(20),
    ip_address      INET,
    user_agent      TEXT,
    device_type     VARCHAR(50),
    status          session_status_enum NOT NULL DEFAULT 'active',
    started_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    ended_at        TIMESTAMPTZ
);

COMMENT ON TABLE sessions IS 'Customer browsing/chat sessions (web, app, or support-chat).';

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id        VARCHAR(20)   PRIMARY KEY,
    user_id         VARCHAR(20)   NOT NULL,
    session_id      VARCHAR(20),
    status          order_status_enum NOT NULL DEFAULT 'pending',
    subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount        NUMERIC(12,2) NOT NULL DEFAULT 0,
    shipping_fee    NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
    shipping_address TEXT,
    placed_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE orders IS 'Customer orders. One row per order header.';

-- ---------------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    order_id        VARCHAR(20)   NOT NULL,
    item_id         VARCHAR(20)   NOT NULL,
    quantity        INTEGER       NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL,
    line_total      NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    PRIMARY KEY (order_id, item_id)
);

COMMENT ON TABLE order_items IS 'Line items belonging to an order (order-to-item join with quantity/price).';

-- ---------------------------------------------------------------------------
-- document_chunks
-- ---------------------------------------------------------------------------
-- Backing store for PgVectorRAGService, shopassist's RAG semantic search
-- service - chunked product/policy/conversation text plus its embedding,
-- so a chat query can retrieve the most relevant chunks by meaning
-- instead of keyword match. Postgres-only: there's no SQLite equivalent,
-- see README.md.
--
-- Before inserting into this table, read the README's RAG section - the
-- embedding column below requires a real, fixed-dimension vector on every
-- INSERT (pgvector rejects anything else outright), so the embedding
-- model must be wired up correctly first.
--
-- doc_id is VARCHAR rather than this schema's usual human-readable
-- business-key style (alum-1001 etc.) - it matches shopassist's
-- ChunkedDocument.doc_id field 1:1 (app-generated slugs like
-- "prod_chunk_<product_id>" / "conv_chunk_<conv_id>_<chunk_idx>", see
-- services/data_pipeline.py), a deliberate exception so the app layer
-- needs no ID translation at the RAG boundary.
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

\echo 'ShopAssist :: schema.sql applied.'
