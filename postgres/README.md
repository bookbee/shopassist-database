# ShopAssist PostgreSQL (production-grade)

A Dockerized PostgreSQL 17 setup for integration, staging, and production
environments, with persistent storage, health checks, and modular SQL scripts.

## Layout

```
postgres/
├── schema/
│   ├── schema.sql       # tables only: columns, PKs, defaults
│   ├── constraints.sql  # FKs, UNIQUE, CHECK constraints (idempotent)
│   └── indexes.sql      # performance indexes (idempotent)
├── seeds/
│   ├── seed_users.sql      # 10 customers
│   ├── seed_products.sql   # 25 products
│   └── seed_orders.sql     # 15 orders + 22 order items
├── migrations/          # versioned migrations for existing databases
└── scripts/
    ├── init.sh   # manual bootstrap against any reachable Postgres server
    └── reset.sh  # drop all tables, recreate schema, reload seed data
```

Scripts run in this order (schema → constraints → indexes → seeds), both via
Docker's automatic init and via `init.sh`/`reset.sh`.

## Running with Docker Compose (recommended)

See the [top-level README](../README.md) for the full walkthrough. In short:

```bash
docker volume create shopassist-postgres-data   # one-time, persists data
docker compose up -d
```

On first startup (empty volume), the official `postgres:17` image
automatically executes `schema.sql`, `constraints.sql`, `indexes.sql`, and
the three seed files, in that order, via files mounted into
`/docker-entrypoint-initdb.d/`. Subsequent restarts skip initialization and
just start Postgres against the existing data.

## Running against an existing Postgres server (no Docker)

Useful for staging/production hosts where Postgres already runs outside
this repo's Docker Compose file.

```bash
export POSTGRES_HOST=your-db-host
export POSTGRES_PORT=5432
export POSTGRES_USER=shopassist
export POSTGRES_PASSWORD=your-password
export POSTGRES_DB=shopassist

./postgres/scripts/init.sh
```

`init.sh` creates the database if it doesn't exist, then applies schema,
constraints, indexes, and seed data in order.

## Resetting

```bash
./postgres/scripts/reset.sh          # interactive confirmation
./postgres/scripts/reset.sh --yes    # non-interactive (CI/CD)
```

This drops the `public` schema (all tables, data, and objects in it) and
rebuilds everything from `schema/` and `seeds/`. It targets whatever
`POSTGRES_HOST`/`POSTGRES_PORT` resolve to (defaults match the Docker Compose
service on `localhost:5432`), so it works equally against the Docker
container or a remote server.

To wipe persisted data instead of just the schema (i.e. destroy the volume
too), see the "Resetting PostgreSQL" section in the [top-level README](../README.md).

## Schema overview

Four tables: `customers`, `products`, `orders`, `order_items`. Full entity
design, relationships, and rationale for the schema/constraints/indexes split
are documented in [../docs/database-design.md](../docs/database-design.md).
