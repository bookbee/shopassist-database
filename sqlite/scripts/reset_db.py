#!/usr/bin/env python3
"""ShopAssist :: drop, recreate, and reseed the local SQLite database."""

from __future__ import annotations

import sys

from db_common import DB_FILE, build_db, remove_db_file


def main() -> int:
    if DB_FILE.exists():
        print(f"==> Removing existing database at {DB_FILE}")
    remove_db_file()

    print(f"==> Recreating schema and reloading seed data at {DB_FILE}")
    build_db()
    print(f"ShopAssist SQLite database reset complete: {DB_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
