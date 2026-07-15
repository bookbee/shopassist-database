# ShopAssist SQLite (local development)

A zero-infrastructure SQLite database for developers who want to run and test
the ShopAssist application locally without Docker or a Postgres server.

## Requirements

- Python 3.9+ only — the management scripts use Python's built-in
  [`sqlite3`](https://docs.python.org/3/library/sqlite3.html) module, so no
  `sqlite3` CLI or extra pip packages are needed.

## Layout

```
sqlite/
├── database/        # generated .db file lives here (git-ignored)
├── schema/schema.sql # table definitions, indexes, CHECK constraints
├── seeds/seed.sql    # 6 customers, 10 IISc merch items, 6 sessions, 7 orders
└── scripts/
    ├── db_common.py  # shared paths + schema/seed loading logic
    ├── create_db.py  # create the database if it doesn't already exist
    └── reset_db.py   # drop, recreate, and reseed the database
```

## Usage

Create the database (first time):

```bash
python3 sqlite/scripts/create_db.py
```

This produces `sqlite/database/shopassist.db`, built from `schema/schema.sql`
and populated from `seeds/seed.sql`.

Reset the database at any time (drops the file and rebuilds it):

```bash
python3 sqlite/scripts/reset_db.py
```

Both scripts resolve their paths relative to their own location, so they can
be run from any working directory. On Windows, use `python` instead of
`python3` if that's what your install responds to — everything else is
identical (these are plain Python, no shell scripts involved).

## Connecting from Python

```python
import sqlite3

conn = sqlite3.connect("sqlite/database/shopassist.db")
conn.execute("PRAGMA foreign_keys = ON")

cur = conn.execute("SELECT item_id, name, price FROM items LIMIT 5")
for row in cur.fetchall():
    print(row)
```

## Schema

Five tables: `customers`, `items`, `sessions`, `orders`, `order_items`. See
[../docs/database-design.md](../docs/database-design.md) for the full entity
design and rationale. The SQLite schema mirrors the PostgreSQL schema
exactly in table/column names (so application SQL is portable between the
two), but uses SQLite-native types (`TEXT`, `NUMERIC`, `INTEGER`) and
`CHECK` constraints in place of PostgreSQL-specific types (`ENUM`, `UUID`,
`INET`, `TIMESTAMPTZ`).

`customer_id`/`item_id`/`order_id` are human-readable IDs (`cust-1001`,
`item-1001`, `ord-1001`) rather than autoincrementing integers, so they're
easy to spot and reference by hand while testing. The sample data is an
IISc alumni-shop catalog priced in INR, with Indian customer names and
addresses.
