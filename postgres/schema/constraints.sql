-- ShopAssist :: PostgreSQL constraints
-- Foreign keys, UNIQUE constraints, and CHECK constraints for the tables
-- defined in schema.sql. Kept separate so schema evolution (e.g. adding a
-- column) doesn't require touching FK/CHECK definitions, and so constraints
-- can be dropped/reapplied independently during a migration.
--
-- Idempotent: each ALTER TABLE is guarded by a check against pg_constraint,
-- so this file can be re-run safely.

\echo 'ShopAssist :: applying constraints.sql ...'

DO $$
BEGIN
    -- customers.email must be unique
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_customers_email') THEN
        ALTER TABLE customers ADD CONSTRAINT uq_customers_email UNIQUE (email);
    END IF;

    -- products.sku must be unique
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_products_sku') THEN
        ALTER TABLE products ADD CONSTRAINT uq_products_sku UNIQUE (sku);
    END IF;

    -- orders.order_number must be unique
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_orders_order_number') THEN
        ALTER TABLE orders ADD CONSTRAINT uq_orders_order_number UNIQUE (order_number);
    END IF;

    -- orders.customer_id -> customers.id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_orders_customer') THEN
        ALTER TABLE orders
            ADD CONSTRAINT fk_orders_customer
            FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT;
    END IF;

    -- order_items.order_id -> orders.id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_order_items_order') THEN
        ALTER TABLE order_items
            ADD CONSTRAINT fk_order_items_order
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
    END IF;

    -- order_items.product_id -> products.id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_order_items_product') THEN
        ALTER TABLE order_items
            ADD CONSTRAINT fk_order_items_product
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT;
    END IF;

    -- products.price / stock_quantity must be non-negative
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_products_price_nonneg') THEN
        ALTER TABLE products ADD CONSTRAINT chk_products_price_nonneg CHECK (price >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_products_stock_nonneg') THEN
        ALTER TABLE products ADD CONSTRAINT chk_products_stock_nonneg CHECK (stock_quantity >= 0);
    END IF;

    -- orders.status must be one of a fixed set of lifecycle states
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_status') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_status
            CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'));
    END IF;

    -- orders.total_amount must be non-negative
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_total_nonneg') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_total_nonneg CHECK (total_amount >= 0);
    END IF;

    -- order_items.quantity must be positive
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_quantity_positive') THEN
        ALTER TABLE order_items ADD CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0);
    END IF;

    -- order_items.unit_price / subtotal must be non-negative
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_unit_price_nonneg') THEN
        ALTER TABLE order_items ADD CONSTRAINT chk_order_items_unit_price_nonneg CHECK (unit_price >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_subtotal_nonneg') THEN
        ALTER TABLE order_items ADD CONSTRAINT chk_order_items_subtotal_nonneg CHECK (subtotal >= 0);
    END IF;
END
$$;

\echo 'ShopAssist :: constraints.sql applied.'
