# ShopAssist SQLite (local development)

Zero-infrastructure database for local dev/testing — no Docker, no server.

## Requirements

Python 3.9+. Uses the built-in [`sqlite3`](https://docs.python.org/3/library/sqlite3.html)
module only — no CLI, no pip packages.

## Layout

```
sqlite/
├── database/          # generated .db file (git-ignored)
├── schema/schema.sql   # tables, indexes, CHECK constraints
├── seeds/seed.sql       # 6 customers, 10 items, 6 sessions, 7 orders
└── scripts/
    ├── db_common.py    # shared paths + load logic
    ├── create_db.py    # create if missing
    └── reset_db.py     # drop, recreate, reseed
```

## Usage

```bash
python3 sqlite/scripts/create_db.py   # first time
python3 sqlite/scripts/reset_db.py    # wipe + rebuild, any time
```

Produces `sqlite/database/shopassist.db`. Windows: use `python` in place of
`python3`. Scripts resolve paths relative to their own location — run from
anywhere.

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

Same five tables and column names as PostgreSQL (`customers`, `items`,
`sessions`, `orders`, `order_items`) — SQLite types (`TEXT`, `NUMERIC`,
`INTEGER`) and inline `CHECK` constraints in place of Postgres-specific
types. Full design: [../docs/database-design.md](../docs/database-design.md).
