#!/usr/bin/env python3
"""ShopAssist :: initialize PostgreSQL (schema + constraints + indexes + seed data).

Works cross-platform (Windows/macOS/Linux) against any reachable PostgreSQL
server - the local `docker compose up -d` instance, or a remote
staging/production host via .env / POSTGRES_* env vars.

If you're using `docker compose up -d` for local dev, you likely don't need
this: Postgres already runs these same SQL files automatically on first
startup against an empty volume (see ../../README.md). This script is for
everything else - an existing server, a fresh clone where you'd rather not
touch Docker, or CI.

Safe to run more than once: every statement in schema/constraints/indexes is
guarded (CREATE ... IF NOT EXISTS / pg_constraint checks) and every seed
INSERT uses ON CONFLICT DO NOTHING, so re-running this just confirms the
database already matches the current schema + seed data.

Usage:
    python3 postgres/scripts/create_db.py
"""

from __future__ import annotations

import sys

from db_common import apply_schema, connect, describe_target, ensure_database_exists, get_config, load_seeds


def main() -> int:
    config = get_config()
    print(f"==> Target: {describe_target(config)}")

    ensure_database_exists(config)

    conn = connect(config)
    try:
        apply_schema(conn)
        load_seeds(conn)
    finally:
        conn.close()

    print("ShopAssist :: PostgreSQL initialization completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
