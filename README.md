# shopassist-database

Database layer for ShopAssist. SQLite for local dev, PostgreSQL (Docker) for
everything else — same schema, same table/column names, so
`shopassist`'s `services/ecommerce_client.py` points at either unchanged.
PostgreSQL also runs pgvector, backing `shopassist`'s RAG semantic search
(`document_chunks` — Postgres-only, see below).
Full design/ERD: [docs/database-design.md](docs/database-design.md).

Sample data: IISc alumni-shop demo — Indian names/addresses, INR pricing,
human-readable IDs (`cust-1001`, `item-1001`, `ord-1001`, ...) instead of
auto-increment integers.

## Structure

```
shopassist-database/
├── docker-compose.yml       # Postgres service, volume, healthcheck
├── .env                     # local config, git-ignored (vars in "PostgreSQL" below)
│
├── sqlite/
│   ├── database/             # generated shopassist.db (git-ignored)
│   ├── schema/schema.sql
│   ├── seeds/seed.sql
│   ├── scripts/{create_db.py, reset_db.py, db_common.py}
│   └── README.md
│
├── postgres/
│   ├── schema/{schema.sql, constraints.sql, indexes.sql}
│   ├── seeds/{seed_customers, seed_items, seed_sessions, seed_orders}.sql
│   ├── migrations/            # versioned migrations for live databases
│   ├── scripts/{create_db.py, reset_db.py, db_common.py, requirements.txt}
│   └── README.md
│
└── docs/database-design.md   # ERD, naming conventions, migration strategy
```

Both `sqlite/scripts/` and `postgres/scripts/` follow the same pattern —
`create_db.py` (first-time setup), `reset_db.py` (wipe + reseed). Pure
Python, no shell scripts: identical commands on macOS/Linux/Windows.

## Schema

| Table             | Purpose                             | Key relationship                                         |
|-------------------|-------------------------------------|----------------------------------------------------------|
| `customers`       | People who place orders             | referenced by `sessions`, `orders.customer_id`           |
| `items`           | Product catalog (INR)               | referenced by `order_items.item_id`                      |
| `sessions`        | Browsing/chat sessions              | belongs to a customer; referenced by `orders.session_id` |
| `orders`          | Order headers                       | belongs to a customer + optional session, has many items |
| `order_items`     | Order line items                    | belongs to an order and an item                          |
| `document_chunks` | RAG semantic search (Postgres-only) | loosely referenced via JSONB `metadata`, no FK           |

## SQLite — local dev

```bash
python3 sqlite/scripts/create_db.py   # first time
python3 sqlite/scripts/reset_db.py    # wipe + reseed, any time
```

No Docker, no server, no dependencies — built-in `sqlite3` only. Produces
`sqlite/database/shopassist.db`. Windows: use `python` in place of `python3`.
Details: [sqlite/README.md](sqlite/README.md).

## PostgreSQL — Docker Compose

Prereq: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
(Linux: [Engine](https://docs.docker.com/engine/install/) +
[Compose plugin](https://docs.docker.com/compose/install/linux/)). Check
with `docker compose version`.

`.env` already exists for local dev. Elsewhere, create one in the repo root:

```env
POSTGRES_DB=shopassist
POSTGRES_USER=shopassist
POSTGRES_PASSWORD=shopassist123
POSTGRES_PORT=5432
POSTGRES_HOST=localhost
TZ=UTC
```

```bash
docker volume create shopassist-postgres-data   # one-time, persists data
docker compose up -d
docker compose ps                               # STATUS should read "healthy"
```

First run against an empty volume applies, in order: `schema.sql` →
`constraints.sql` → `indexes.sql` → seeds (`customers` → `items` →
`sessions` → `orders`). Reruns skip init and reuse existing data. Progress:
`docker compose logs postgres`.

Runs `pgvector/pgvector:pg17`, not the bare `postgres:17` image — needed
for `document_chunks`' semantic search (`shopassist`'s RAG service). See
[docs/database-design.md](docs/database-design.md#rag-semantic-search-document_chunks-postgresql-only).

Running against a non-Docker Postgres server (staging/production): details:
[postgres/README.md](postgres/README.md).

## Resetting

SQLite:

```bash
python3 sqlite/scripts/reset_db.py
```

PostgreSQL — drops + reloads tables, keeps the Docker volume:

```bash
pip install -r postgres/scripts/requirements.txt   # once
python3 postgres/scripts/reset_db.py --yes         # omit --yes for a prompt
```

Nuke the volume and start from empty (rarely needed — destroys persisted data):

```bash
docker compose down
docker volume rm shopassist-postgres-data && docker volume create shopassist-postgres-data
docker compose up -d
```

## Connecting from applications

```
postgresql://shopassist:shopassist123@localhost:5432/shopassist
```

```python
from sqlalchemy import create_engine
engine = create_engine(
    f"postgresql+psycopg://{user}:{password}@{host}:{port}/{db}"
)
```

SQLite: point at `sqlite/database/shopassist.db` directly.

## Migrations

Schema changes against a database that already holds data go in
`postgres/migrations/` as numbered, idempotent SQL — not as edits to
`postgres/schema/*.sql`, which is the fresh-install baseline.
`0001_add_document_chunks_for_rag.sql` is the first one. See
[postgres/migrations/README.md](postgres/migrations/README.md).

## Notes

- All Postgres SQL is idempotent — safe to rerun `create_db.py` or the
  files directly.
- `.env` is git-ignored. Never commit real staging/production credentials.
- Everything here is plain Python/SQL/Docker — no OS-specific scripts.
