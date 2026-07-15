-- ShopAssist :: PostgreSQL schema
-- Target: PostgreSQL 17
--
-- This file defines tables only (columns, primary keys, defaults).
-- Foreign keys and CHECK/UNIQUE constraints live in constraints.sql;
-- performance indexes live in indexes.sql. Keeping these concerns separate
-- lets each be re-run, reviewed, or migrated independently.
--
-- Idempotent: safe to re-run via CREATE TABLE IF NOT EXISTS.

\echo 'ShopAssist :: applying schema.sql ...'

SET client_encoding = 'UTF8';
SET timezone = 'UTC';

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    id              BIGSERIAL PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    phone           VARCHAR(30),
    address_line1   VARCHAR(255),
    city            VARCHAR(100),
    state           VARCHAR(100),
    postal_code     VARCHAR(20),
    country         VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE customers IS 'ShopAssist end users who place orders.';

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id              BIGSERIAL PRIMARY KEY,
    sku             VARCHAR(64) NOT NULL,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    category        VARCHAR(100) NOT NULL,
    price           NUMERIC(10, 2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    stock_quantity  INTEGER NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE products IS 'Product catalog available for purchase.';

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id                  BIGSERIAL PRIMARY KEY,
    order_number        VARCHAR(32) NOT NULL,
    customer_id         BIGINT NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_amount        NUMERIC(12, 2) NOT NULL DEFAULT 0,
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    shipping_address    VARCHAR(255),
    billing_address     VARCHAR(255),
    placed_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE orders IS 'Customer orders. One row per order header.';

-- ---------------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INTEGER NOT NULL,
    unit_price      NUMERIC(10, 2) NOT NULL,
    subtotal        NUMERIC(12, 2) NOT NULL
);

COMMENT ON TABLE order_items IS 'Line items belonging to an order (order-to-product join with quantity/price).';

\echo 'ShopAssist :: schema.sql applied.'
