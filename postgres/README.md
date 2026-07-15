# ShopAssist PostgreSQL (production-grade)

A Dockerized PostgreSQL 17 setup for integration, staging, and production
environments, with persistent storage, health checks, and modular SQL scripts.

## Layout

```
postgres/
├── schema/
│   ├── schema.sql       # enum types + tables: columns, PKs, defaults
│   ├── constraints.sql  # FKs, UNIQUE, CHECK constraints (idempotent)
│   └── indexes.sql      # performance indexes (idempotent)
├── seeds/
│   ├── seed_customers.sql  # 10 customers (Indian names/addresses)
│   ├── seed_items.sql      # 25 IISc merchandise items, priced in INR
│   ├── seed_sessions.sql   # 10 sessions
│   └── seed_orders.sql     # 15 orders + 22 order items
├── migrations/          # versioned migrations for existing databases
└── scripts/
    ├── create_db.py      # create the database (if needed) + apply schema + load seeds
    ├── reset_db.py        # drop all tables, recreate schema, reload seed data
    ├── db_common.py        # shared connection/config helpers (not run directly)
    └── requirements.txt    # one dependency: psycopg2-binary
```

The SQL files run in this order (schema → constraints → indexes → seeds,
with seeds themselves ordered customers → items → sessions → orders to
satisfy foreign keys), whether that's Docker's automatic init or
`create_db.py`/`reset_db.py`.

`create_db.py`/`reset_db.py` are plain Python (via `psycopg2`) — no `psql`
CLI, no shell scripts, so they run identically on Windows, macOS, and Linux.

## Running with Docker Compose (recommended)

See the [top-level README](../README.md) for the full walkthrough. In short:

```bash
docker volume create shopassist-postgres-data   # one-time, persists data
docker compose up -d
```

On first startup (empty volume), the official `postgres:17` image
automatically executes `schema.sql`, `constraints.sql`, `indexes.sql`, and
the four seed files, in that order, via files mounted into
`/docker-entrypoint-initdb.d/`. Subsequent restarts skip initialization and
just start Postgres against the existing data.

If you're using this, you don't need `create_db.py` at all — it's for
everything Docker Compose doesn't cover (see below).

## Running against an existing Postgres server (no Docker)

Useful for staging/production hosts, or any Postgres instance not managed
by this repo's `docker-compose.yml`.

```bash
pip install -r postgres/scripts/requirements.txt   # first time only
python3 postgres/scripts/create_db.py
```

By default this targets the same `localhost:5432` instance
`docker-compose.yml` starts. To point it elsewhere, either edit `.env` in
the repo root (works the same on every OS) or set environment variables
before running the script:

```bash
# macOS/Linux
export POSTGRES_HOST=your-db-host POSTGRES_PORT=5432 POSTGRES_USER=shopassist POSTGRES_PASSWORD=your-password POSTGRES_DB=shopassist
python3 postgres/scripts/create_db.py
```

```powershell
# Windows (PowerShell)
$env:POSTGRES_HOST="your-db-host"; $env:POSTGRES_PASSWORD="your-password"
python postgres/scripts/create_db.py
```

`create_db.py` creates the database if it doesn't exist, then applies
schema, constraints, indexes, and seed data in order. It's safe to run
more than once — every statement is idempotent, so re-running it just
confirms the database already matches.

(On Windows, use `python` instead of `python3` if that's what your install
responds to — the commands are otherwise identical.)

If `psycopg2` fails to connect, the script prints what's likely wrong
(server not running, wrong host/port, dependency not installed) instead of
a raw traceback — read that message first.

## Resetting

```bash
python3 postgres/scripts/reset_db.py          # interactive confirmation
python3 postgres/scripts/reset_db.py --yes    # non-interactive (CI/CD)
```

This drops the `public` schema (all tables, data, and objects in it) and
rebuilds everything from `schema/` and `seeds/`. It targets whatever
`POSTGRES_HOST`/`POSTGRES_PORT` resolve to (defaults match the Docker Compose
service on `localhost:5432`), so it works equally against the Docker
container or a remote server.

To wipe persisted data instead of just the schema (i.e. destroy the volume
too), see the "Resetting PostgreSQL" section in the [top-level README](../README.md).

## Schema overview

Five tables: `customers`, `items`, `sessions`, `orders`, `order_items`.
`customer_id`/`item_id`/`order_id` are human-readable business keys
(`cust-1001`, `item-1001`, `ord-1001`) rather than auto-incrementing
integers — supplied explicitly in the seed data, same idea `session_id`
already used. Full entity design, relationships, and rationale for the
schema/constraints/indexes split are documented in
[../docs/database-design.md](../docs/database-design.md).
