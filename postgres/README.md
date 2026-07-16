# ShopAssist PostgreSQL (production-grade)

Dockerized PostgreSQL 17 (with pgvector) for integration, staging, and
production — persistent storage, health checks, modular SQL, and semantic
search for `shopassist`'s RAG service.

## Layout

```
postgres/
├── schema/{schema.sql, constraints.sql, indexes.sql}   # tables / FKs+checks / indexes
├── seeds/{seed_customers, seed_items, seed_sessions, seed_orders}.sql
├── migrations/          # versioned migrations for live databases
└── scripts/
    ├── create_db.py     # create db (if needed), apply schema, load seeds
    ├── reset_db.py       # drop all tables, recreate, reseed
    ├── db_common.py       # shared connection/config helpers
    └── requirements.txt   # one dependency: psycopg2-binary
```

Files run in order — schema → constraints → indexes → seeds (customers →
items → sessions → orders) — whether via Docker's auto-init or
`create_db.py`/`reset_db.py`. Both scripts are plain Python (`psycopg2`), no
`psql` CLI: identical on Windows/macOS/Linux.

## Docker Compose (recommended)

Full walkthrough: [top-level README](../README.md). In short:

```bash
docker volume create shopassist-postgres-data   # one-time
docker compose up -d
```

First startup against an empty volume auto-runs schema, constraints,
indexes, and seeds via `/docker-entrypoint-initdb.d/`. Reruns skip init and
reuse existing data. `create_db.py` isn't needed here — it's for everything
Compose doesn't cover, below.

`docker-compose.yml`'s image is `pgvector/pgvector:pg17`, not the bare
`postgres:17` — the pgvector extension needs to actually be installed for
`document_chunks` (see **Schema** below); this is the official image the
pgvector project maintains for exactly this, not a custom Dockerfile.

## Against an existing Postgres server (no Docker)

For staging/production hosts, or any instance not managed by this repo's
`docker-compose.yml`.

```bash
pip install -r postgres/scripts/requirements.txt   # first time only
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
down, wrong host/port, missing dependency) instead of a raw traceback.

## Resetting

```bash
python3 postgres/scripts/reset_db.py          # prompts for confirmation
python3 postgres/scripts/reset_db.py --yes    # non-interactive (CI/CD)
```

Drops the `public` schema and rebuilds from `schema/` + `seeds/`, without
touching the Docker volume. Works against the local container or any
reachable server via `POSTGRES_*`. To destroy the volume too, see the
top-level README's reset section.

## Schema

Five e-commerce tables: `customers`, `items`, `sessions`, `orders`,
`order_items`. IDs are human-readable business keys (`cust-1001`,
`item-1001`, `ord-1001`), supplied explicitly in seed data. Plus a sixth,
`document_chunks` — pgvector-backed semantic search storage for
`shopassist`'s RAG service, Postgres-only, no seed data (populated by
`shopassist`'s own ingestion pipeline, not this repo). Full design:
[../docs/database-design.md](../docs/database-design.md).
