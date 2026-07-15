-- ShopAssist :: PostgreSQL indexes
-- Performance indexes beyond those implicitly created by PRIMARY KEY / UNIQUE
-- constraints in constraints.sql. Kept in their own file so they can be
-- tuned, added, or dropped without touching table or constraint definitions.
--
-- Idempotent: CREATE INDEX IF NOT EXISTS is supported natively since
-- PostgreSQL 9.5.

\echo 'ShopAssist :: applying indexes.sql ...'

CREATE INDEX IF NOT EXISTS idx_orders_customer_id      ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status            ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_placed_at         ON orders(placed_at);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id     ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id   ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_products_category        ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_is_active       ON products(is_active);

\echo 'ShopAssist :: indexes.sql applied.'
