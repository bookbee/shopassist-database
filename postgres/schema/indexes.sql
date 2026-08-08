-- ShopAssist :: PostgreSQL indexes
-- Performance indexes beyond those implicitly created by PRIMARY KEY / UNIQUE
-- constraints in constraints.sql. Kept in their own file so they can be
-- tuned, added, or dropped without touching table or constraint definitions.
--
-- Idempotent: CREATE INDEX IF NOT EXISTS is supported natively since
-- PostgreSQL 9.5.

\echo 'ShopAssist :: applying indexes.sql ...'

CREATE INDEX IF NOT EXISTS idx_items_category        ON items(category);
CREATE INDEX IF NOT EXISTS idx_items_is_active        ON items(is_active);

-- item_reviews is read two ways: "all reviews for this product" (the RAG
-- ingestion pipeline's items-to-reviews join) and "is this review mine?"
-- (EcommerceClient.remove_review's author check).
CREATE INDEX IF NOT EXISTS idx_item_reviews_item_id   ON item_reviews(item_id);
CREATE INDEX IF NOT EXISTS idx_item_reviews_user_id   ON item_reviews(user_id);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id       ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status        ON sessions(status);

CREATE INDEX IF NOT EXISTS idx_orders_user_id         ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_session_id      ON orders(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_status          ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_placed_at       ON orders(placed_at);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_item_id    ON order_items(item_id);

CREATE INDEX IF NOT EXISTS idx_document_chunks_source_type ON document_chunks(source_type);

-- HNSW over IVFFlat: no list-count "training" step needed, good recall/
-- latency out of the box at this project's scale. Cosine ops since
-- nomic-embed-text is designed to be compared by cosine similarity.
CREATE INDEX IF NOT EXISTS idx_document_chunks_embedding
    ON document_chunks USING hnsw (embedding vector_cosine_ops);

\echo 'ShopAssist :: indexes.sql applied.'
