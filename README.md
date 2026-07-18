# shopassist-database

Dockerized PostgreSQL 17 + [pgvector](https://github.com/pgvector/pgvector)
for ShopAssist — order/customer/catalog data plus vector storage for RAG
semantic search. Table and column names match `shopassist`'s own local
SQLite dev database (`db/schema_sqlite.sql` in the `shopassist` repo) 1:1,
so `shopassist`'s `clients/ecommerce_api_client.py` works unchanged against
either, just by setting `DATABASE_URL`.

## Layout

```text
shopassist-database/
├── docker-compose.yml         # postgres service (default) + rag-init (opt-in, --profile rag)
├── .env                       # local config, git-ignored (see "Configuration")
├── requirements.txt           # one file, every Python script in postgres/scripts/
└── postgres/
    ├── schema/
    │   ├── schema.sql         # tables + enum types (single source of truth)
    │   ├── constraints.sql    # FKs, UNIQUE, CHECK
    │   └── indexes.sql        # performance indexes
    ├── seeds/                 # relational sample data: customers → items → sessions → orders
    ├── rag_sources/           # sample PDFs/sheets/text for RAG - see "RAG semantic search"
    └── scripts/
        ├── create_db.py         # create db (if needed), apply schema, load seeds
        ├── reset_db.py          # drop all tables, recreate, reseed
        ├── init_vector_store.py # chunk + embed rag_sources/ into document_chunks
        └── db_common.py         # shared connection/config helpers
```

Schema files apply in order — `schema.sql` → `constraints.sql` →
`indexes.sql` → seeds (`customers` → `items` → `sessions` → `orders`) —
whether via Docker's auto-init or `create_db.py`/`reset_db.py`. Every file
is idempotent: `CREATE TABLE`/`INDEX IF NOT EXISTS`, a `pg_constraint`
guard before each `ALTER TABLE ADD CONSTRAINT`, and `ON CONFLICT DO NOTHING` on every seed `INSERT` — safe to rerun any of them against an
already-initialized database as a no-op.

## Quick start (Docker Compose — recommended)

Prereq: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
(Linux: [Engine](https://docs.docker.com/engine/install/) + [Compose
plugin](https://docs.docker.com/compose/install/linux/)). Check with
`docker compose version`.

```bash
docker volume create shopassist-postgres-data   # one-time, persists data
docker compose up -d
docker compose ps                               # STATUS should read "healthy"
```

First run against an empty volume auto-applies schema → constraints →
indexes → seeds via `/docker-entrypoint-initdb.d/`. Reruns skip init and
reuse existing data. Progress: `docker compose logs postgres`.

The image is `pgvector/pgvector:pg17`, not the bare `postgres:17` —
pgvector must actually be installed for the `document_chunks` table (see
**Schema** below); this is the official image the pgvector project
maintains for exactly this, not a custom Dockerfile.

Want sample data in `document_chunks` too, not just the relational
tables? `docker compose --profile rag up rag-init` — optional, needs
Ollama; see **RAG semantic search** below.

### Configuration

`.env` already exists for local dev, with a working default for every
variable. Elsewhere, copy the template and adjust:

```bash
cp .env.example .env
```

`.env.example` documents each variable — Postgres connection settings plus
the Ollama settings `init_vector_store.py` uses for RAG (see **RAG
semantic search** below). `.env` itself is git-ignored — never commit real
staging/production credentials.

## Against an existing Postgres server (no Docker)

For staging/production hosts, or any instance not managed by this repo's
`docker-compose.yml`.

```bash
pip install -r requirements.txt   # first time only
python3 postgres/scripts/create_db.py
```

Targets `localhost:5432` by default. Point elsewhere via `.env` or env vars:

```bash
# macOS/Linux
export POSTGRES_HOST=your-db-host POSTGRES_PASSWORD=your-password
python3 postgres/scripts/create_db.py
```

```powershell
# Windows (PowerShell)
$env:POSTGRES_HOST="your-db-host"; $env:POSTGRES_PASSWORD="your-password"
python postgres/scripts/create_db.py
```

Idempotent — safe to rerun; it just confirms the database already matches.
If `psycopg2` can't connect, the script prints the likely cause (server
down, wrong host/port, missing dependency) instead of a raw traceback. The
target server needs the pgvector extension available (`CREATE EXTENSION vector` must succeed) — install the `pgvector` package for your Postgres
version if it isn't already there.

## Schema

Six tables:

| Table               | Purpose                        | Key relationship                                          |
| ------------------- | ------------------------------ | --------------------------------------------------------- |
| `customers`       | People who place orders        | referenced by`sessions.user_id`, `orders.user_id`     |
| `items`           | Product catalog (INR)          | referenced by`order_items.item_id`                      |
| `sessions`        | Browsing/chat sessions         | belongs to a customer; referenced by`orders.session_id` |
| `orders`          | Order headers                  | belongs to a customer + optional session, has many items  |
| `order_items`     | Order line items               | belongs to an order and an item                           |
| `document_chunks` | RAG semantic search (pgvector) | loosely referenced via JSONB`metadata`, no FK           |

```mermaid
erDiagram
    CUSTOMERS ||--o{ SESSIONS : starts
    CUSTOMERS ||--o{ ORDERS : places
    SESSIONS |o--o{ ORDERS : "placed during"
    ORDERS ||--o{ ORDER_ITEMS : contains
    ITEMS ||--o{ ORDER_ITEMS : "ordered as"

    CUSTOMERS {
        varchar user_id PK
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
        varchar session_id PK
        varchar user_id FK
        varchar device_type
        enum status
        timestamptz started_at
        timestamptz ended_at
    }
    ORDERS {
        varchar order_id PK
        varchar user_id FK
        varchar session_id FK
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

`document_chunks` sits outside this diagram — no FKs to the other five
tables, populated by `postgres/scripts/init_vector_store.py` and by
`PgVectorRAGService` (see **RAG semantic search** below), not by this
repo's relational seed data:

```text
document_chunks {
    varchar     doc_id PK       -- matches shopassist's ChunkedDocument.doc_id 1:1
    text        content
    vector(768) embedding       -- nomic-embed-text output dimension
    varchar     source_type
    jsonb       metadata        -- e.g. {"product_id": "item-1001"}, no enforced FK
    timestamptz created_at
    timestamptz updated_at
}
```

- **`VECTOR(768)`** — `nomic-embed-text`'s output dimension (see
  `shopassist-model/config/generative.yaml`). pgvector enforces this at the
  type level; a mismatched embedding fails on `INSERT`, not silently.
- **`idx_document_chunks_embedding`** is an HNSW index with cosine ops
  (`vector_cosine_ops`) — no list-count "training" step needed, matches how
  `nomic-embed-text` embeddings are meant to be compared.

See **RAG semantic search** below for how this table gets populated and
queried, and what `shopassist` needs on its side to use it.

### Naming conventions

- Tables: plural, `snake_case` (`order_items`, not `OrderItem`).
- Primary keys: `<table_singular>_id` (`item_id`, `session_id`,
  `order_id`), not a generic `id` — matches `shopassist`'s own
  `db/schema_sqlite.sql` exactly. The one exception is `customers`, whose
  key is `user_id` rather than `customer_id` — that's `shopassist`'s own
  naming choice (the identifier `shopassist-client` sends at login, used
  end to end), carried through unchanged here.
- `user_id`, `item_id`, `session_id`, `order_id` are human-readable
  business keys (`alum-1001`, `item-1001`, `sess-1001`, `ord-1001`), not
  auto-increment integers or UUIDs — `VARCHAR(20)`, supplied explicitly on
  `INSERT` (see `postgres/seeds/`).
- Foreign keys: same name as the primary key they reference
  (`sessions.user_id` / `orders.user_id` reference `customers.user_id`).
- Constraint names: `<type>_<table>_<column(s)>` (`fk_orders_user`,
  `uq_customers_email`, `chk_orders_subtotal_nonneg`) — `fk_*`/`chk_*`/`uq_*`
  prefixes make constraints easy to find in `pg_constraint`.
- Indexes: `idx_<table>_<column(s)>` (`idx_orders_user_id`).
- Timestamps: `created_at`/`updated_at` (or `placed_at`/`started_at`/
  `ended_at` for domain-specific events), always `TIMESTAMPTZ` — displayed
  and interpreted in IST (`Asia/Kolkata`) by default, per `TZ`/`PGTZ` in
  `docker-compose.yml`/`.env` (`TIMESTAMPTZ` always stores an absolute
  instant regardless of session timezone; only input/display go through
  IST).

### Foreign key delete behavior

| Relationship                                 | On delete    | Why                                                                                                             |
| -------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------- |
| `sessions.user_id → customers.user_id`    | `SET NULL` | A session survives independently of the customer, for analytics                                                 |
| `orders.user_id → customers.user_id`      | `RESTRICT` | A customer with existing orders can't be deleted outright                                                       |
| `orders.session_id → sessions.session_id` | `SET NULL` | Session is provenance, not a hard dependency                                                                    |
| `order_items.order_id → orders.order_id`  | `CASCADE`  | Line items have no lifecycle independent of their order                                                         |
| `order_items.item_id → items.item_id`     | `RESTRICT` | Historical order items can't reference a hard-deleted item — deactivate via`items.is_active = false` instead |

`order_items.line_total` is `GENERATED ALWAYS AS (quantity * unit_price) STORED` — never part of an `INSERT` column list, and never join back to
`items.price` to compute historical order totals (price can change after
an order is placed; `unit_price` snapshots what was actually paid).

## RAG semantic search

### What RAG is, in three moving parts

RAG (Retrieval-Augmented Generation) lets a chatbot ground its answer in
actual text — a product description, a support policy, a past
conversation — instead of relying only on what the LLM memorized during
training or on plain keyword search. Three steps, always in this order:

1. **Embed** — an embedding model turns a chunk of text into a vector (a
   fixed-length list of floats) such that texts with similar *meaning*
   produce vectors that are numerically close together, even if they don't
   share any of the same words.
2. **Store & index** — persist each chunk's text alongside its vector, in
   an index built for fast "nearest vector" search. This is what pgvector
   adds to Postgres: a `VECTOR` column type plus nearest-neighbor indexes
   (HNSW here), so a dedicated vector database isn't needed.
3. **Retrieve & inject** — when a user asks a question, embed the question
   itself with the *same* embedding model, fetch the `top_k` nearest stored
   vectors (semantically closest chunks), and hand that text to the LLM
   alongside the question. The reply is now grounded in real, specific
   content instead of the model's own general knowledge.

`document_chunks` (see **Schema** above) is where step 2 lives. `embedding`
is always a finished, 768-length vector — never raw text — and every read
against this table is a nearest-neighbor query (`ORDER BY embedding <=> ...`), never a full scan.

### `PgVectorRAGService`

`PgVectorRAGService` is `shopassist`'s RAG service, backed by this table.
It exposes two operations:

- **`ingest_document(doc)`** — embed step: given a `ChunkedDocument`
  (`doc_id`, `content`, `source_type`, `metadata`), call the embedding
  model and upsert the result:

  ```sql
  INSERT INTO document_chunks (doc_id, content, embedding, source_type, metadata)
  VALUES (%(doc_id)s, %(content)s, %(embedding)s::vector, %(source_type)s, %(metadata)s)
  ON CONFLICT (doc_id) DO UPDATE SET
      content = EXCLUDED.content, embedding = EXCLUDED.embedding,
      metadata = EXCLUDED.metadata, updated_at = now()
  ```
- **`query_knowledge_base(query_embedding, query_text, top_k)`** —
  retrieve step: embed the query the same way, then find the nearest
  stored chunks:

  ```sql
  SELECT * FROM document_chunks ORDER BY embedding <=> %(query_embedding)s::vector LIMIT %(top_k)s
  ```

  `<=>` is pgvector's cosine-distance operator, matching
  `idx_document_chunks_embedding`'s `vector_cosine_ops` — this is what
  makes the query actually use that index instead of scanning every row.

Both operations need real embeddings — a fixed 768-length vector per call,
from the same model every time (`nomic-embed-text`, already configured via
`OLLAMA_EMBEDDING_MODEL` and pulled by `shopassist-model`'s bootstrap).
pgvector enforces the column's dimension exactly: an `INSERT` with any
other vector length fails outright, so `PgVectorRAGService`'s embedding
call must be wired up correctly before this table sees any real traffic.

`postgres/scripts/init_vector_store.py` (below) implements this exact
`embed → upsert` pattern already, end-to-end and tested against a real
Postgres + Ollama — read it alongside implementing `PgVectorRAGService`
in `shopassist` itself.

### Populating `document_chunks`: `init_vector_store.py`

`postgres/rag_sources/` ships with six starter files — one IISc alumni
store example and one generic e-commerce example in each of
`product_catalog/`, `customer_support_policy/`, and
`customer_support_conversation/`, across all five supported file types
(`.txt`, `.md`, `.csv`, `.xlsx`, `.pdf`) — so there's real content to load
and query immediately, before writing a line of your own. See that
folder's README for the full file list.

Run it directly:

```bash
pip install -r requirements.txt   # once - adds openai/pypdf/openpyxl to psycopg2-binary
ollama pull nomic-embed-text      # once, if not already pulled
python3 postgres/scripts/init_vector_store.py
```

Or via Docker Compose, with no local Python setup at all:

```bash
docker compose --profile rag up rag-init
```

`rag-init` is **not** part of the default `docker compose up -d` — it's
gated behind the `rag` [profile](https://docs.docker.com/compose/how-tos/profiles/)
specifically so hosting just the relational database (the common case)
never depends on Ollama being reachable. It installs `requirements.txt`
into an official `python:3.12-slim` image at container start (no custom
image to maintain) and runs the same script above against the `postgres`
service by its container name. Needs Ollama reachable from inside the
container: the default (`OLLAMA_API_BASE_URL=http://host.docker.internal:11434`)
targets a host-installed Ollama and works out of the box on Docker
Desktop (Mac/Windows) and on Linux via the `extra_hosts` entry already in
`docker-compose.yml`; override that env var if Ollama runs somewhere else
(e.g. `http://ollama:11434` if this repo runs as part of
`shopassist-devops`'s platform-wide compose alongside `shopassist-model`).

Either way, it walks `postgres/rag_sources/<source_type>/`, chunks each
file, embeds every chunk via Ollama's OpenAI-compatible `/v1/embeddings`
endpoint, and upserts into `document_chunks`, keyed by a `doc_id` derived
from the filename plus chunk index (`prod_chunk_<file_stem>_<i>`,
`policy_chunk_<file_stem>_<i>`, `conv_chunk_<file_stem>_<i>`). Idempotent:
rerunning after editing a file updates its rows instead of duplicating
them (`ON CONFLICT (doc_id) DO UPDATE`) — but it's additive only, so a
file removed or renamed since the last run leaves its old rows behind.
Pass `--truncate` (or `RAG_INIT_TRUNCATE=true` for the Compose form) to
wipe `document_chunks` first instead, so the result matches
`rag_sources/` exactly:

```bash
python3 postgres/scripts/init_vector_store.py --truncate
RAG_INIT_TRUNCATE=true docker compose --profile rag up rag-init
```

It also applies `schema.sql`/`constraints.sql`/`indexes.sql` first (a
no-op if already applied), so it works standalone against a bare
database.

Use it directly to load policy documents, product spec sheets, or any
other static source into semantic search — no application code required.

### Operational notes

- **The embedding dimension is locked to the column.** Swapping
  `nomic-embed-text` for a different embedding model with a different
  output size means `VECTOR(768)` has to change with it — add an `ALTER TABLE document_chunks ALTER COLUMN embedding TYPE VECTOR(<new_dim>)`,
  then drop and recreate `idx_document_chunks_embedding` (an HNSW index is
  built for one fixed dimension, it doesn't adapt), and update
  `schema.sql`/`indexes.sql` to match. `init_vector_store.py` checks every
  embedding is exactly 768 numbers before each `INSERT`, so a mismatch
  here fails with a clear message instead of a raw pgvector error.
- **No seed data is provided for `document_chunks`** — `postgres/seeds/`
  covers the relational tables only. This table is populated by
  `init_vector_store.py` or by `PgVectorRAGService` at request time.
- **`source_type`** identifies where a chunk came from —
  `product_catalog`, `customer_support_policy`, or
  `customer_support_conversation` — and doubles as the subfolder name
  under `postgres/rag_sources/`. Add a new value only alongside a real
  producer of that kind of content.
- **`metadata.product_id` should match `items.item_id`** (`item-1001`
  style) for any chunk about a real catalog item, so a chunk can be
  cross-referenced back to its row in `items`. The `JSONB metadata` column
  has no enforced FK on purpose — chunks come from several different kinds
  of sources, not all of which reference the same table.

## Resetting

Drops + reloads tables, keeps the Docker volume (or a non-Docker server's
data directory):

```bash
pip install -r requirements.txt   # once
python3 postgres/scripts/reset_db.py --yes         # omit --yes for a confirmation prompt
```

This drops the `public` schema and rebuilds from `schema/` + `seeds/`.
Works against the local container or any reachable server via `POSTGRES_*`.

`DROP SCHEMA public CASCADE` removes **every** table, `document_chunks`
included — any RAG data loaded via `init_vector_store.py` is gone after a
reset too, and isn't reloaded automatically. Rerun `init_vector_store.py`
(or `docker compose --profile rag up rag-init`) afterward if you need it
back.

Nuke the Docker volume itself and start from empty (rarely needed —
destroys persisted data):

```bash
docker compose down
docker volume rm shopassist-postgres-data && docker volume create shopassist-postgres-data
docker compose up -d
```

## Schema changes over time

`postgres/schema/schema.sql` + `constraints.sql` + `indexes.sql` are the
**single source of truth** for this schema — edit them directly for any
change, and either `reset_db.py` or a fresh `docker compose up -d` against
an empty volume picks it up.

This holds as long as every environment running this schema is one that
can be safely dropped and rebuilt (a local Docker volume, a `reset_db.py`
target). The moment that's no longer true — a shared staging environment,
production, anywhere holding data a rebuild would destroy — stop editing
`schema.sql` directly and introduce versioned migrations instead —
a `postgres/migrations/` folder of numbered, idempotent SQL files
(`0001_description.sql`, `0002_...`), each safe against live data (`ADD COLUMN IF NOT EXISTS`, guarded `ADD CONSTRAINT`, batched backfills),
applied in order and never edited after the fact, with `schema.sql`
updated afterward so a fresh install and a migrated database end up
identical. Once there are more than a handful, move off hand-rolled
`psql` runs onto a dedicated tool —
[golang-migrate](https://github.com/golang-migrate/migrate) or
[Flyway](https://flywaydb.org/) for a language-agnostic, CI/CD-driven
setup, [Alembic](https://alembic.sqlalchemy.org/) if the app layer is
already Python/SQLAlchemy.

## Connecting from applications

```text
postgresql://shopassist:shopassist123@localhost:5432/shopassist
```

```python
from sqlalchemy import create_engine
engine = create_engine(f"postgresql+psycopg://{user}:{password}@{host}:{port}/{db}")
```

`shopassist` picks this up as `DATABASE_URL` (see its own
`clients/ecommerce_api_client.py` and `.env.example`). Leave `DATABASE_URL`
unset there to keep using its local SQLite dev database instead.
