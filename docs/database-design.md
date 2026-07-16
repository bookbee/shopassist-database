# ShopAssist Database Design

## Entities and relationships

Five entities model the ShopAssist e-commerce domain, shared by either the
SQLite or the PostgreSQL database here. A sixth, `document_chunks`, exists
**Postgres-only** for RAG semantic search — see **RAG semantic search:
document_chunks** below.

```
customers (1) ─┬─< (N) sessions
                └─< (N) orders (1) ───< (N) order_items (N) >─── (1) items
sessions  (0..1) ─< (N) orders
```

- **customers** — people who place orders.
- **items** — the catalog of products available for purchase (currently
  IISc alumni-shop merchandise, priced in INR). 
- **sessions** — a customer's browsing/chat session; an order optionally
  records which session it was placed in.
- **orders** — one row per order header (status, totals, addresses).
- **order_items** — line items belonging to an order; the join between
  `orders` and `items`, carrying quantity and price at time of purchase.

```mermaid
erDiagram
    CUSTOMERS ||--o{ SESSIONS : starts
    CUSTOMERS ||--o{ ORDERS : places
    SESSIONS |o--o{ ORDERS : "placed during"
    ORDERS ||--o{ ORDER_ITEMS : contains
    ITEMS ||--o{ ORDER_ITEMS : "ordered as"

    CUSTOMERS {
        varchar customer_id PK
        varchar first_name
        varchar last_name
        varchar email UK
        varchar phone
        varchar city
        varchar country
        boolean is_active
    }
    ITEMS {
        varchar item_id PK
        varchar name
        varchar category
        numeric price
        numeric mrp
        int stock_quantity
        boolean is_active
    }
    SESSIONS {
        uuid session_id PK
        varchar customer_id FK
        varchar device_type
        enum status
        timestamptz started_at
        timestamptz ended_at
    }
    ORDERS {
        varchar order_id PK
        varchar customer_id FK
        uuid session_id FK
        enum status
        numeric subtotal
        numeric discount
        numeric shipping_fee
        numeric total_amount
    }
    ORDER_ITEMS {
        varchar order_id FK
        varchar item_id FK
        int quantity
        numeric unit_price
        numeric line_total
    }
```

### Why `unit_price`/`line_total` are stored on `order_items`

Denormalized on purpose: an item's `price` can change after an order is
placed, so each order item snapshots the price paid at purchase time. This
is standard practice for order history integrity — never join back to
`items.price` to compute historical order totals. In PostgreSQL,
`line_total` is a `GENERATED ALWAYS AS (quantity * unit_price) STORED`
column, so it's derived automatically and never appears in an `INSERT`
column list; SQLite stores it as a plain column computed at insert time
(see [../sqlite/schema/schema.sql](../sqlite/schema/schema.sql) for why).

### Foreign key delete behavior

- `sessions.customer_id → customers.customer_id` — `ON DELETE SET NULL`. A
  session outlives (or survives independently of) the customer record for
  analytics purposes.
- `orders.customer_id → customers.customer_id` — `ON DELETE RESTRICT`. A
  customer with existing orders cannot be deleted outright, preserving
  order history.
- `orders.session_id → sessions.session_id` — `ON DELETE SET NULL`. An
  order's session is provenance, not a hard dependency; the order stands on
  its own once placed.
- `order_items.order_id → orders.order_id` — `ON DELETE CASCADE`. Deleting
  an order removes its line items; there's no independent lifecycle for an
  order item without its parent order.
- `order_items.item_id → items.item_id` — `ON DELETE RESTRICT`. An item
  referenced by historical order items cannot be hard-deleted; deactivate it
  via `items.is_active = false` instead.

## RAG semantic search: `document_chunks` (PostgreSQL-only)

```text
document_chunks {
    varchar     doc_id PK
    text        content
    vector(768) embedding
    varchar     source_type
    jsonb       metadata
    timestamptz created_at
    timestamptz updated_at
}
```

Deliberately outside the entity diagram above — it has no foreign keys to
`customers`/`items`/`orders`, and isn't meant to. A chunk about a product
carries `{"product_id": "item-1001"}` in `metadata` as a loose, JSON-level
reference, not an enforced `item_id` FK, because chunks (support-policy
text, past conversation excerpts) don't all originate from a row in
another table — forcing a real FK would mean nullable references to three
different tables, which is worse than an untyped one.

- **`doc_id VARCHAR(255)` instead of this schema's usual human-readable
  business key** (`cust-1001` style) — it matches `shopassist`'s
  `ChunkedDocument.doc_id` field 1:1 (app-generated slugs like
  `prod_chunk_item-1001`), a deliberate exception so the RAG boundary
  needs no ID translation between the app and this table.
- **`VECTOR(768)`** — `nomic-embed-text`'s actual output dimension (see
  `shopassist-model/config/generative.yaml`'s `embedding` role). pgvector
  enforces this at the type level; a mismatched embedding fails on
  `INSERT`, not silently.
- **HNSW index, cosine ops** (`idx_document_chunks_embedding` in
  `indexes.sql`) rather than IVFFlat — HNSW needs no list-count "training"
  step to perform well, a better default at this project's scale. Cosine
  distance (`<=>`) matches how `nomic-embed-text` is designed to be
  compared.
- **`JSONB` metadata** rather than a fixed set of nullable FK columns —
  chunks come from genuinely different source shapes (`product_catalog`,
  `customer_support_policy`, `customer_support_conversation`, per
  `source_type`), each carrying different identifying fields.
- **Postgres-only, no SQLite equivalent.** SQLite has no vector extension,
  and this project's own convention already treats SQLite as disposable
  local-dev data (see "Why schema, constraints, and indexes are separate
  files" below and `sqlite/README.md`) — `shopassist`'s RAG service falls
  back to an in-memory mock when `DATABASE_URL` isn't Postgres, rather
  than reimplementing similarity search in SQLite.

## Why schema, constraints, and indexes are separate files (PostgreSQL)

- **`schema.sql`** — table shape: columns, types, defaults, primary keys.
  This is what changes when you add a column.
- **`constraints.sql`** — foreign keys, `UNIQUE`, and `CHECK` constraints.
  Separating these means referential/business rules can be reviewed,
  migrated, or temporarily dropped (e.g. for a bulk load) independently of
  table shape.
- **`indexes.sql`** — indexes that exist purely for query performance.
  These are the first thing you tune under load, and tuning them shouldn't
  touch table or constraint definitions.

Each file is idempotent (`CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT
EXISTS`, and a `pg_constraint` existence check before each `ALTER TABLE ADD
CONSTRAINT`), so re-running any of them against an already-initialized
database is a no-op rather than an error.

The SQLite schema (`sqlite/schema/schema.sql`) intentionally inlines
constraints and indexes into one file — SQLite is the lightweight local-dev
path, and there's no independent lifecycle to protect there.

## Naming conventions

- Tables: plural, `snake_case` (`order_items`, not `OrderItem`).
- Primary keys: `<table_singular>_id` (`customer_id`, `item_id`,
  `session_id`, `order_id`) rather than a generic `id` — this matches
  shopassist's application-level schema exactly, which is the whole point
  of this repo being the shared source of truth (see the top of this doc).
- `customer_id`, `item_id`, and `order_id` are human-readable business keys
  (`cust-1001`, `item-1001`, `ord-1001`), not database-generated integers —
  `VARCHAR(20)` in Postgres, `TEXT` in SQLite, supplied explicitly on
  `INSERT` (see seeds/). This is the same idea `session_id` already used
  (a recognizable token instead of an opaque number), applied consistently
  across every entity so any ID is identifiable at a glance in logs, demo
  transcripts, or a support conversation.
- Foreign keys: same name as the primary key they reference
  (`orders.customer_id` references `customers.customer_id`).
- Constraint names: `<type>_<table>_<column(s)>` — e.g. `fk_orders_customer`,
  `uq_customers_email`, `chk_orders_subtotal_nonneg`. Consistent prefixes
  make it easy to find "all foreign keys" (`fk_*`) or "all checks" (`chk_*`)
  in `pg_constraint`.
- Indexes: `idx_<table>_<column(s)>` — e.g. `idx_orders_customer_id`.
- Timestamps: `created_at` / `updated_at` (or `placed_at` / `started_at` /
  `ended_at` for a domain-specific event time), always `TIMESTAMPTZ` in
  Postgres, UTC.

## Future migration strategy

Today, `postgres/schema/*.sql` is the single source of truth for a
brand-new database. `postgres/migrations/` holds its first entry,
`0001_add_document_chunks_for_rag.sql` (see
[postgres/migrations/README.md](../postgres/migrations/README.md)) — the
baseline `schema.sql`/`indexes.sql` files already reflect that same
change, so a fresh install and a migrated one end up identical, per the
convention below.

As the schema evolves on databases that already hold data, add numbered
migration files (`0001_description.sql`, `0002_description.sql`, ...) to
`postgres/migrations/` rather than editing `schema.sql` retroactively:

1. Write the migration to be idempotent and safe against live data
   (`ADD COLUMN IF NOT EXISTS`, backfill in batches, guard constraint
   additions the same way `constraints.sql` does).
2. Apply it to each environment in order.
3. Update `schema.sql`/`constraints.sql`/`indexes.sql` to reflect the new
   baseline, so a fresh database created from scratch matches one that went
   through every migration.

Once there are more than a handful of migrations, adopt a dedicated tool
instead of hand-rolling the runner:

- **[golang-migrate](https://github.com/golang-migrate/migrate)** or
  **[Flyway](https://flywaydb.org/)** if migrations should be
  language-agnostic and driven by CI/CD.
- **[Alembic](https://alembic.sqlalchemy.org/)** if the application layer
  is Python and already uses SQLAlchemy.

Any of these track applied migrations in a version table, run outstanding
migrations in order, and support rollback — capabilities worth adopting
before the hand-rolled numbered-file convention gets unwieldy.

SQLite has no migration story by design: it's disposable local-dev data.
When the schema changes, developers run `sqlite/scripts/reset_db.py` to
rebuild from the current `schema.sql`/`seed.sql`.
