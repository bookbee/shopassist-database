-- ShopAssist :: PostgreSQL constraints
-- Foreign keys, UNIQUE constraints, and CHECK constraints for the tables
-- defined in schema.sql. Kept separate so schema evolution (e.g. adding a
-- column) doesn't require touching FK/CHECK definitions, and so constraints
-- can be dropped/reapplied independently during a migration.
--
-- The two status CHECK sets below (chk_orders_status, chk_sessions_status)
-- replace the order_status_enum / session_status_enum types an earlier
-- revision of schema.sql declared - see that file's header for why. Their
-- allowed values are exactly what shopassist-service's
-- clients/ecommerce_api_client.py reads and writes: 'pending', 'confirmed',
-- 'shipped' are its cancellable set, 'pending'/'cancelled' its deletable
-- set, and 'delivered'/'returned' are terminal. Adding a value here without
-- teaching that client about it leaves rows the app can't act on.
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

    -- items.price / mrp must be sane
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_items_price_nonneg') THEN
        ALTER TABLE items ADD CONSTRAINT chk_items_price_nonneg CHECK (price >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_items_mrp_gte_price') THEN
        ALTER TABLE items ADD CONSTRAINT chk_items_mrp_gte_price CHECK (mrp IS NULL OR mrp >= price);
    END IF;

    -- items.discount_percentage is a percentage (64.00), not a fraction
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_items_discount_percentage_range') THEN
        ALTER TABLE items ADD CONSTRAINT chk_items_discount_percentage_range
            CHECK (discount_percentage IS NULL OR (discount_percentage >= 0 AND discount_percentage <= 100));
    END IF;

    -- items.rating is the source CSV's 0-5 star aggregate
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_items_rating_range') THEN
        ALTER TABLE items ADD CONSTRAINT chk_items_rating_range
            CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_items_rating_count_nonneg') THEN
        ALTER TABLE items ADD CONSTRAINT chk_items_rating_count_nonneg
            CHECK (rating_count IS NULL OR rating_count >= 0);
    END IF;

    -- item_reviews.item_id -> items.item_id
    -- CASCADE: a review has no meaning once its product row is gone.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_item_reviews_item') THEN
        ALTER TABLE item_reviews
            ADD CONSTRAINT fk_item_reviews_item
            FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE;
    END IF;

    -- item_reviews.user_id -> customers.user_id
    -- CASCADE: reviews are personal data, they go with the customer.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_item_reviews_user') THEN
        ALTER TABLE item_reviews
            ADD CONSTRAINT fk_item_reviews_user
            FOREIGN KEY (user_id) REFERENCES customers(user_id) ON DELETE CASCADE;
    END IF;

    -- sessions.user_id -> customers.user_id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sessions_user') THEN
        ALTER TABLE sessions
            ADD CONSTRAINT fk_sessions_user
            FOREIGN KEY (user_id) REFERENCES customers(user_id) ON DELETE SET NULL;
    END IF;

    -- sessions.status - replaces session_status_enum, see file header
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_sessions_status') THEN
        ALTER TABLE sessions ADD CONSTRAINT chk_sessions_status
            CHECK (status IN ('active', 'expired', 'terminated'));
    END IF;

    -- sessions.ended_at cannot precede sessions.started_at
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_sessions_ended_after_started') THEN
        ALTER TABLE sessions ADD CONSTRAINT chk_sessions_ended_after_started
            CHECK (ended_at IS NULL OR ended_at >= started_at);
    END IF;

    -- orders.user_id -> customers.user_id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_orders_user') THEN
        ALTER TABLE orders
            ADD CONSTRAINT fk_orders_user
            FOREIGN KEY (user_id) REFERENCES customers(user_id) ON DELETE RESTRICT;
    END IF;

    -- orders.session_id -> sessions.session_id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_orders_session') THEN
        ALTER TABLE orders
            ADD CONSTRAINT fk_orders_session
            FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE SET NULL;
    END IF;

    -- orders.status - replaces order_status_enum, see file header
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_status') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_status
            CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'returned'));
    END IF;

    -- orders.subtotal / discount / shipping_fee / total_amount must be non-negative
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_subtotal_nonneg') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_subtotal_nonneg CHECK (subtotal >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_discount_nonneg') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_discount_nonneg CHECK (discount >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_shipping_fee_nonneg') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_shipping_fee_nonneg CHECK (shipping_fee >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_orders_total_nonneg') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_orders_total_nonneg CHECK (total_amount >= 0);
    END IF;

    -- order_items.order_id -> orders.order_id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_order_items_order') THEN
        ALTER TABLE order_items
            ADD CONSTRAINT fk_order_items_order
            FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE;
    END IF;

    -- order_items.item_id -> items.item_id
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_order_items_item') THEN
        ALTER TABLE order_items
            ADD CONSTRAINT fk_order_items_item
            FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE RESTRICT;
    END IF;

    -- order_items.quantity must be positive
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_quantity_positive') THEN
        ALTER TABLE order_items ADD CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0);
    END IF;

    -- order_items.unit_price must be non-negative
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_unit_price_nonneg') THEN
        ALTER TABLE order_items ADD CONSTRAINT chk_order_items_unit_price_nonneg CHECK (unit_price >= 0);
    END IF;

    -- order_items.line_total must be non-negative. It's a plain stored
    -- column now rather than GENERATED (see schema.sql), so this is the
    -- only guard left on it - the app is trusted to keep it equal to
    -- quantity * unit_price.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_line_total_nonneg') THEN
        ALTER TABLE order_items ADD CONSTRAINT chk_order_items_line_total_nonneg CHECK (line_total >= 0);
    END IF;
END
$$;

\echo 'ShopAssist :: constraints.sql applied.'
