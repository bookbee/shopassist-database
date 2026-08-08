-- ShopAssist :: PostgreSQL schema
-- Target: PostgreSQL 17 (docker-compose.yml runs pgvector/pgvector:pg17 -
-- Postgres 17 with the pgvector extension pre-built, needed for
-- document_chunks' embedding column below; the bare postgres image doesn't
-- bundle it). Every table but document_chunks would still run fine on
-- plain PostgreSQL 13+.
--
-- This file defines tables only (columns, primary keys, defaults). Foreign
-- keys and CHECK/UNIQUE constraints live in constraints.sql; performance
-- indexes live in indexes.sql. Keeping these concerns separate lets each be
-- re-run, reviewed, or migrated independently.
--
-- SOURCE OF TRUTH: this schema is what shopassist-service's
-- clients/ecommerce_api_client.py issues SQL against - it is the only
-- database that project has (its former local SQLite dev DB and its own
-- bundled postgres service were both removed when the database moved here).
-- Table and column names are exactly what that client's SQL expects; a
-- rename here breaks it at runtime, not at startup.
--
-- user_id is shopassist's own naming choice - the identifier sent by
-- shopassist-client at login, used end to end. user_id / item_id /
-- session_id / order_id / review_id are all human-readable business keys
-- (alum-1001, item-1001, sess-1001, ord-1001, rev-1001 - see ../seeds/)
-- rather than database-generated integers or UUIDs: easy to recognize, log,
-- and read back in a demo. That means they're supplied explicitly on INSERT
-- - there's no IDENTITY/SERIAL/gen_random_uuid() here to override.
--
-- Key columns are TEXT rather than VARCHAR(n): item_id also carries product
-- IDs from the Amazon-style source CSV the RAG ingestion pipeline loads
-- (see items' own comment below), which routinely exceed any short bound.
--
-- Status columns are TEXT with a CHECK constraint (in constraints.sql)
-- rather than an enum type. shopassist-service writes them as plain string
-- literals through SQLAlchemy `text()`, and a CHECK set is far cheaper to
-- extend than an enum (ALTER TYPE ... ADD VALUE can't run in a transaction
-- and can't remove a label).
--
-- Idempotent: safe to re-run. CREATE TABLE uses IF NOT EXISTS.

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

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    user_id         TEXT          PRIMARY KEY,
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
-- Column shape mirrors the Amazon-style product CSV that
-- shopassist-service's RAG ingestion pipeline (services/data_pipeline.py)
-- is built against - product_id/product_name/category/discounted_price/
-- actual_price/discount_percentage/rating/rating_count/about_product/
-- img_link/product_link map onto item_id/name/category/price/mrp/
-- discount_percentage/rating/rating_count/description/img_link/
-- product_link here. That pipeline re-joins items with item_reviews (and
-- customers, for the reviewer name) to reconstruct the CSV shape before
-- handing it to the vector store.
CREATE TABLE IF NOT EXISTS items (
    item_id             TEXT          PRIMARY KEY,
    name                VARCHAR(255)  NOT NULL,
    description         TEXT,
    -- Full pipe-delimited category path as the source CSV ships it, e.g.
    -- 'Computers&Accessories|Accessories&Peripherals|Cables&Accessories|
    -- Cables|USBCables' - TEXT rather than VARCHAR(100) because that path
    -- routinely exceeds 100 chars. The seed data's plain single-word
    -- categories ('Apparel', 'Drinkware', ...) fit the same column fine.
    category            TEXT,
    price               NUMERIC(10,2) NOT NULL,
    mrp                 NUMERIC(10,2),
    -- CSV's "64%" stored as the numeric percentage (64.00), not a fraction.
    discount_percentage NUMERIC(5,2),
    -- Product-level rating aggregates from the CSV - nullable, since the
    -- seeded catalog predates that dataset and doesn't carry them.
    rating              NUMERIC(2,1),
    rating_count        INTEGER,
    img_link            TEXT,
    product_link        TEXT,
    stock_quantity      INTEGER       NOT NULL DEFAULT 0,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE items IS 'Product catalog available for purchase (INR pricing).';

-- ---------------------------------------------------------------------------
-- item_reviews
-- ---------------------------------------------------------------------------
-- One row per review - the source CSV's pipe-separated user_id/user_name/
-- review_id/review_title/review_content columns (parallel arrays, one
-- product row fanning out to several reviews) normalized into their own
-- rows here.
--
-- user_id is a real FK to customers (unlike the source CSV's anonymous
-- reviewer IDs), so every table sits in one FK/PK-connected graph. The
-- reviewer's display name is NOT stored here - join customers for
-- first_name/last_name instead, so it can't drift from the customer's
-- actual profile name.
--
-- Read/written by shopassist-service's EcommerceClient.add_review() /
-- remove_review(), which enforce that a reviewer has actually purchased the
-- item and that only a review's own author can delete it.
CREATE TABLE IF NOT EXISTS item_reviews (
    review_id       TEXT          PRIMARY KEY,
    item_id         TEXT          NOT NULL,
    user_id         TEXT          NOT NULL,
    review_title    VARCHAR(255),
    review_content  TEXT,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE item_reviews IS 'Customer product reviews. Author name is derived by joining customers, never stored here.';

-- ---------------------------------------------------------------------------
-- sessions
-- ---------------------------------------------------------------------------
-- ip_address is TEXT rather than INET: shopassist-service records whatever
-- the request context carries (including proxy-forwarded values that aren't
-- always a bare address), and INET would reject those outright.
CREATE TABLE IF NOT EXISTS sessions (
    session_id      TEXT          PRIMARY KEY,
    user_id         TEXT,
    ip_address      TEXT,
    user_agent      TEXT,
    device_type     VARCHAR(50),
    status          TEXT          NOT NULL DEFAULT 'active',
    started_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    ended_at        TIMESTAMPTZ
);

COMMENT ON TABLE sessions IS 'Customer browsing/chat sessions (web, app, or support-chat).';

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id        TEXT          PRIMARY KEY,
    user_id         TEXT          NOT NULL,
    session_id      TEXT,
    status          TEXT          NOT NULL DEFAULT 'pending',
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
-- line_total is a plain stored column, NOT `GENERATED ALWAYS AS (quantity *
-- unit_price) STORED`. It was generated in an earlier revision of this
-- schema, but shopassist-service's EcommerceClient.create_order() writes it
-- explicitly in its INSERT column list, and Postgres rejects any INSERT that
-- supplies a value for a generated column - order creation failed outright
-- against that shape. The non-negative/consistency guarantee lives in
-- constraints.sql instead.
--
-- Still never join back to items.price to compute historical order totals:
-- price can change after an order is placed, and unit_price snapshots what
-- was actually paid.
CREATE TABLE IF NOT EXISTS order_items (
    order_id        TEXT          NOT NULL,
    item_id         TEXT          NOT NULL,
    quantity        INTEGER       NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL,
    line_total      NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (order_id, item_id)
);

COMMENT ON TABLE order_items IS 'Line items belonging to an order (order-to-item join with quantity/price).';

-- ---------------------------------------------------------------------------
-- document_chunks
-- ---------------------------------------------------------------------------
-- Backing store for PgVectorRAGService, shopassist-service's RAG semantic
-- search service - chunked product/policy/conversation text plus its
-- embedding, so a chat query can retrieve the most relevant chunks by
-- meaning instead of keyword match.
--
-- Before inserting into this table, read the README's RAG section - the
-- embedding column below requires a real, fixed-dimension vector on every
-- INSERT (pgvector rejects anything else outright), so the embedding
-- model must be wired up correctly first.
--
-- doc_id is VARCHAR rather than this schema's usual human-readable
-- business-key style (alum-1001 etc.) - it matches shopassist-service's
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
