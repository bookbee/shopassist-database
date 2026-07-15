#!/usr/bin/env python3
"""ShopAssist :: drop all tables, recreate the schema, and reload seed data
against a reachable PostgreSQL server (e.g. the docker-compose service
exposed on localhost:${POSTGRES_PORT}).

Destructive: this drops the entire `public` schema (all tables, data, and
objects in it). Prompts for confirmation unless run with --yes/-y (for
CI/CD or other non-interactive use).

Usage:
    python3 postgres/scripts/reset_db.py
    python3 postgres/scripts/reset_db.py --yes
"""

from __future__ import annotations

import sys

from db_common import apply_schema, connect, describe_target, get_config, load_seeds


def main() -> int:
    force = any(arg in ("--yes", "-y") for arg in sys.argv[1:])

    config = get_config()
    target = describe_target(config)

    if not force:
        confirm = input(
            f"This will DROP ALL TABLES in '{target}' and reload seed data. Continue? [y/N] "
        )
        if confirm.strip().lower() != "y":
            print("Aborted.")
            return 1

    conn = connect(config)
    try:
        print("==> Dropping and recreating the public schema ...")
        with conn.cursor() as cur:
            cur.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")

        apply_schema(conn)
        load_seeds(conn)
    finally:
        conn.close()

    print("ShopAssist :: PostgreSQL reset completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
