-- ShopAssist :: PostgreSQL schema
-- Target: PostgreSQL 17
--
-- This file defines enum types and tables only (columns, primary keys,
-- defaults). Foreign keys and CHECK/UNIQUE constraints live in
-- constraints.sql; performance indexes live in indexes.sql. Keeping these
-- concerns separate lets each be re-run, reviewed, or migrated
-- independently.
--
-- Table and column names deliberately match shopassist's application-level
-- schema (customer_id / item_id / session_id / order_id, not a generic
-- "id") so services/ecommerce_client.py's SQL runs unchanged against this
-- database - see docs/database-design.md.
--
-- customer_id / item_id / order_id are human-readable business keys
-- (cust-1001, item-1001, ord-1001 - see seeds/) rather than
-- database-generated integers, for the same reason session_id already
-- looked like an identifiable token: they're easy to recognize, log, and
-- read back in a demo. That means they're supplied explicitly on INSERT,
-- same as session_id already was - there's no IDENTITY/SERIAL here to
-- override.
--
-- Idempotent: safe to re-run. CREATE TABLE uses IF NOT EXISTS; enum types
-- are guarded by a DO block since PostgreSQL has no CREATE TYPE IF NOT
-- EXISTS.

\echo 'ShopAssist :: applying schema.sql ...'

SET client_encoding = 'UTF8';
SET timezone = 'UTC';

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
    customer_id     VARCHAR(20)   PRIMARY KEY,
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
    session_id      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     VARCHAR(20),
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
    customer_id     VARCHAR(20)   NOT NULL,
    session_id      UUID,
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

\echo 'ShopAssist :: schema.sql applied.'
