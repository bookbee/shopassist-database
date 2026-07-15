# shopassist-database

The centralized database project for the ShopAssist platform. It serves two
purposes:

1. **SQLite** — a zero-infrastructure database for local development and
   testing, no Docker required.
2. **PostgreSQL** — a production-grade, Dockerized database for integration,
   staging, and production, with persistent storage and a repeatable
   initialization process.

Both share the same e-commerce domain (`customers`, `items`, `sessions`,
`orders`, `order_items`) and the same table/column names as
[shopassist](../shopassist)'s application-level schema, so
`services/ecommerce_client.py` there can point at either one, unchanged —
see [docs/database-design.md](docs/database-design.md) for the full design.

The sample data models an **IISc alumni-shop capstone demo**: Indian
customer names/addresses, an IISc merchandise catalog (t-shirts, mugs,
bags, ...) priced in INR, and human-readable IDs throughout
(`cust-1001`, `item-1001`, `ord-1001`, ...) instead of opaque
auto-incrementing integers — easy to recognize in logs, a demo transcript,
or a support conversation.

Both `sqlite/scripts/` and `postgres/scripts/` follow the same two-command
pattern — `create_db.py` for first-time setup, `reset_db.py` to wipe and
reseed — and are plain Python, so they run the same way on Windows, macOS,
and Linux with no shell scripts, no `psql` CLI, and (for SQLite) no extra
packages to install.

## Repository structure

```
shopassist-database/
├── docker-compose.yml       # PostgreSQL service, volume, network, health check
├── .env                     # local dev config (git-ignored; see .env.example)
├── .env.example             # template for .env
│
├── sqlite/                  # local development database
│   ├── database/            # generated shopassist.db lives here (git-ignored)
│   ├── schema/schema.sql
│   ├── seeds/seed.sql
│   ├── scripts/{create_db.py, reset_db.py, db_common.py}
│   └── README.md
│
├── postgres/                # production-grade database
│   ├── schema/{schema.sql, constraints.sql, indexes.sql}
│   ├── seeds/{seed_customers.sql, seed_items.sql, seed_sessions.sql, seed_orders.sql}
│   ├── migrations/          # versioned migrations (empty today, see README)
│   ├── scripts/{create_db.py, reset_db.py, db_common.py, requirements.txt}
│   └── README.md
│
└── docs/
    └── database-design.md   # ERD, naming conventions, migration strategy
```

## Database schema overview

| Table         | Purpose                                    | Key relationships                        |
|---------------|---------------------------------------------|--------------------------------------------|
| `customers`   | People who place orders                     | referenced by `sessions`/`orders.customer_id` |
| `items`       | Product catalog (IISc merchandise, INR)     | referenced by `order_items.item_id`        |
| `sessions`    | Customer browsing/chat sessions              | belongs to a customer, referenced by `orders.session_id` |
| `orders`      | Order headers (status, totals, addresses)    | belongs to a customer and (optionally) a session, has many items |
| `order_items` | Line items within an order                   | belongs to an order and an item            |

Full ERD and design rationale: [docs/database-design.md](docs/database-design.md).

---

## Using SQLite for local development

No Docker, no server — just a file.

```bash
python3 sqlite/scripts/create_db.py   # first-time setup
python3 sqlite/scripts/reset_db.py    # drop, recreate, and reseed at any time
```

Both scripts use only Python's built-in `sqlite3` module — no external
dependencies, no `sqlite3` CLI required. This produces
`sqlite/database/shopassist.db`, built from `sqlite/schema/schema.sql` and
populated with sample data from `sqlite/seeds/seed.sql` (6 customers, 10
IISc merchandise items, 6 sessions, 7 orders):

```python
import sqlite3
conn = sqlite3.connect("sqlite/database/shopassist.db")
```

(Windows: use `python` instead of `python3` if that's what your install
responds to.)

Details: [sqlite/README.md](sqlite/README.md).

---

## Running PostgreSQL with Docker Compose

### 1. Create the external persistent volume (one-time)

The Postgres data volume is declared `external` in `docker-compose.yml` so
that `docker compose down` (even without `-v`) — and any container
recreation — never touches it. Create it once per host:

```bash
docker volume create shopassist-postgres-data
```

### 2. Configure environment variables

A working `.env` already exists for local development (see below for its
contents). For any other environment, copy the template and adjust:

```bash
cp .env.example .env
```

```env
POSTGRES_DB=shopassist
POSTGRES_USER=shopassist
POSTGRES_PASSWORD=shopassist123
POSTGRES_PORT=5432
POSTGRES_HOST=localhost
TZ=UTC
```

### 3. Start PostgreSQL

```bash
docker compose up -d
```

On the **first** startup against an empty volume, the official `postgres:17`
image automatically runs, in order:

1. `postgres/schema/schema.sql` — creates enum types and `customers`, `items`, `sessions`, `orders`, `order_items`
2. `postgres/schema/constraints.sql` — adds foreign keys, `UNIQUE`, and `CHECK` constraints
3. `postgres/schema/indexes.sql` — adds performance indexes
4. `postgres/seeds/seed_customers.sql` — 10 sample customers (Indian names/addresses, `cust-1001` ...)
5. `postgres/seeds/seed_items.sql` — 25 sample IISc merchandise items, priced in INR (`item-1001` ...)
6. `postgres/seeds/seed_sessions.sql` — 10 sample sessions
7. `postgres/seeds/seed_orders.sql` — 15 sample orders with 22 order items (`ord-1001` ...)

Each script logs its own progress (`\echo`) to `docker compose logs postgres`,
ending with `ShopAssist :: PostgreSQL initialization completed successfully.`

Subsequent `docker compose up -d` runs against the same volume skip
initialization entirely (Postgres only runs
`/docker-entrypoint-initdb.d/*` scripts once, against an empty data
directory) and just start the server against the existing data.

### 4. Verify it's healthy

```bash
docker compose ps            # STATUS should show "healthy"
docker compose logs postgres
```

The health check runs `pg_isready` every 10 seconds.

---

## Resetting databases

### SQLite

```bash
python3 sqlite/scripts/reset_db.py
```

Deletes the local `.db` file and rebuilds it from schema + seed data.

### PostgreSQL

First time only, install the one dependency talking to Postgres from Python
needs (see [postgres/scripts/requirements.txt](postgres/scripts/requirements.txt)):

```bash
pip install -r postgres/scripts/requirements.txt
```

Then, drop all tables and reload seed data, without touching the Docker
volume itself:

```bash
python3 postgres/scripts/reset_db.py          # prompts for confirmation
python3 postgres/scripts/reset_db.py --yes    # non-interactive, e.g. CI/CD
```

This works against the local `docker compose up -d` instance out of the box
(same defaults as `docker-compose.yml`), or any other reachable Postgres
server via `.env` / `POSTGRES_*` env vars.

To wipe the data volume completely and start over from an empty database
(rarely necessary — this deletes persisted data outright):

```bash
docker compose down
docker volume rm shopassist-postgres-data
docker volume create shopassist-postgres-data
docker compose up -d
```

---

## Connecting from external applications

The Postgres container publishes its port to the host, so any application —
including [shopassist](../shopassist) and
[shopassist-streamlit](../shopassist-streamlit) — can connect using the
same `.env` values:

```
postgresql://shopassist:shopassist123@localhost:5432/shopassist
```

```python
# psycopg / SQLAlchemy example
import os
from sqlalchemy import create_engine

engine = create_engine(
    f"postgresql+psycopg://{os.environ['POSTGRES_USER']}:{os.environ['POSTGRES_PASSWORD']}"
    f"@{os.environ['POSTGRES_HOST']}:{os.environ['POSTGRES_PORT']}/{os.environ['POSTGRES_DB']}"
)
```

For local development against SQLite instead, point the application at
`sqlite/database/shopassist.db` (see [sqlite/README.md](sqlite/README.md)).

---

## Future migration strategy

New schema changes on databases that already hold data belong in
`postgres/migrations/` as numbered, idempotent SQL files — not as edits to
`postgres/schema/*.sql`, which represents the current baseline for a
brand-new database. See
[postgres/migrations/README.md](postgres/migrations/README.md) and
[docs/database-design.md](docs/database-design.md#future-migration-strategy)
for the full convention and a recommended migration tool once the number of
migrations grows.

---

## Non-functional notes

- All PostgreSQL SQL scripts are idempotent (`IF NOT EXISTS` / guarded
  `ALTER TABLE` / `ON CONFLICT DO NOTHING`), so `create_db.py` and the SQL
  files themselves can be safely re-run.
- Schema, constraints, and indexes are deliberately separated — see
  [docs/database-design.md](docs/database-design.md) for why.
- `.env` is git-ignored; `.env.example` documents the required variables.
  Never commit real staging/production credentials.
- Every script in this repo (`sqlite/scripts/*.py`, `postgres/scripts/*.py`)
  is plain Python — no shell scripts, no OS-specific commands — so Windows
  developers run the exact same commands as macOS/Linux. Docker Compose
  itself is identical across platforms via Docker Desktop.
