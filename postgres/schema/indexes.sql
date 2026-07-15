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

CREATE INDEX IF NOT EXISTS idx_sessions_customer_id   ON sessions(customer_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status        ON sessions(status);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id     ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_session_id      ON orders(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_status          ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_placed_at       ON orders(placed_at);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_item_id    ON order_items(item_id);

\echo 'ShopAssist :: indexes.sql applied.'
