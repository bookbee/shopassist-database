"""Shared helpers for ShopAssist SQLite management scripts.

Uses only the Python standard library (sqlite3, pathlib) - no external
dependencies, and no sqlite3 CLI required.
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

SQLITE_DIR = Path(__file__).resolve().parent.parent
DB_FILE = SQLITE_DIR / "database" / "shopassist.db"
SCHEMA_FILE = SQLITE_DIR / "schema" / "schema.sql"
SEED_FILE = SQLITE_DIR / "seeds" / "seed.sql"


def remove_db_file(db_file: Path = DB_FILE) -> None:
    """Delete the database file and any journal/WAL/SHM sidecar files."""
    for suffix in ("", "-journal", "-wal", "-shm"):
        sidecar = db_file.with_name(db_file.name + suffix)
        sidecar.unlink(missing_ok=True)


def build_db(db_file: Path = DB_FILE) -> None:
    """Create db_file (if missing) and apply schema.sql then seed.sql."""
    db_file.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(db_file)
    try:
        print(f"==> Applying {SCHEMA_FILE.name} ...")
        conn.executescript(SCHEMA_FILE.read_text())

        print(f"==> Applying {SEED_FILE.name} ...")
        conn.executescript(SEED_FILE.read_text())
    finally:
        conn.close()
