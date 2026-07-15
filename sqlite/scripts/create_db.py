#!/usr/bin/env python3
"""ShopAssist :: create the local SQLite database from schema + seed data.

Safe to run multiple times: it will not overwrite an existing database.
"""

from __future__ import annotations

import sys

from db_common import DB_FILE, build_db


def main() -> int:
    if DB_FILE.exists():
        print(f"Database already exists at {DB_FILE}")
        print("Use reset_db.py to recreate it from scratch.")
        return 0

    print(f"==> Creating SQLite database at {DB_FILE}")
    build_db()
    print(f"ShopAssist SQLite database ready: {DB_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
