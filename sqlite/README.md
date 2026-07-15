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
├── seeds/seed.sql    # ~28 rows of realistic sample data
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
be run from any working directory.

## Connecting from Python

```python
import sqlite3

conn = sqlite3.connect("sqlite/database/shopassist.db")
conn.execute("PRAGMA foreign_keys = ON")

cur = conn.execute("SELECT id, name, price FROM products LIMIT 5")
for row in cur.fetchall():
    print(row)
```

## Schema

Four tables: `customers`, `products`, `orders`, `order_items`. See
[../docs/database-design.md](../docs/database-design.md) for the full entity
design and rationale. The SQLite schema mirrors the PostgreSQL schema
conceptually, but uses SQLite-native types (`TEXT`, `NUMERIC`, `INTEGER`) and
`CHECK` constraints in place of PostgreSQL-specific types.
