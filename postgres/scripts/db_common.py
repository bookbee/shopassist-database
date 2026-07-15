"""Shared helpers for ShopAssist PostgreSQL management scripts.

Needs psycopg2 (pip install -r postgres/scripts/requirements.txt) - the one
non-stdlib dependency on this side of the repo, unavoidable since Python has
no built-in PostgreSQL client. See ../../sqlite/scripts/db_common.py for the
zero-dependency SQLite equivalent.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

try:
    import psycopg2
    from psycopg2 import sql as psql_sql
except ImportError:
    print(
        "Missing dependency: psycopg2\n\n"
        "Install it with:\n"
        "    pip install -r postgres/scripts/requirements.txt\n",
        file=sys.stderr,
    )
    sys.exit(1)

POSTGRES_DIR = Path(__file__).resolve().parent.parent
ROOT_DIR = POSTGRES_DIR.parent
ENV_FILE = ROOT_DIR / ".env"

SCHEMA_FILE = POSTGRES_DIR / "schema" / "schema.sql"
CONSTRAINTS_FILE = POSTGRES_DIR / "schema" / "constraints.sql"
INDEXES_FILE = POSTGRES_DIR / "schema" / "indexes.sql"
SEED_FILES = [
    POSTGRES_DIR / "seeds" / "seed_customers.sql",
    POSTGRES_DIR / "seeds" / "seed_items.sql",
    POSTGRES_DIR / "seeds" / "seed_sessions.sql",
    POSTGRES_DIR / "seeds" / "seed_orders.sql",
]

# psql-only meta-commands (\echo, \c, ...) that appear in the .sql files for
# Docker's automatic init (which runs them through psql). psycopg2 speaks
# plain SQL only, so these lines are dropped before a file is sent over.
_META_COMMAND_RE = re.compile(r"^\s*\\")

DEFAULTS = {
    "POSTGRES_HOST": "localhost",
    "POSTGRES_PORT": "5432",
    "POSTGRES_DB": "shopassist",
    "POSTGRES_USER": "shopassist",
    "POSTGRES_PASSWORD": "shopassist123",
}


def _load_env_file(env_path: Path) -> None:
    """Minimal KEY=VALUE .env parser (stdlib only - mirrors what `source
    .env` did for the old shell scripts, including that .env values win
    over anything already set in the shell environment)."""
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ[key.strip()] = value.strip()


def get_config() -> dict:
    """Connection settings: .env file, falling back to the same defaults
    docker-compose.yml uses so this works out of the box against the local
    `docker compose up -d` instance with no configuration at all."""
    _load_env_file(ENV_FILE)
    return {
        "host": os.environ.get("POSTGRES_HOST", DEFAULTS["POSTGRES_HOST"]),
        "port": int(os.environ.get("POSTGRES_PORT", DEFAULTS["POSTGRES_PORT"])),
        "dbname": os.environ.get("POSTGRES_DB", DEFAULTS["POSTGRES_DB"]),
        "user": os.environ.get("POSTGRES_USER", DEFAULTS["POSTGRES_USER"]),
        "password": os.environ.get("POSTGRES_PASSWORD", DEFAULTS["POSTGRES_PASSWORD"]),
    }


def describe_target(config: dict) -> str:
    return f"{config['user']}@{config['host']}:{config['port']}/{config['dbname']}"


def connect(config: dict, dbname: str | None = None):
    """Open an autocommit connection. Raises psycopg2.OperationalError with
    a friendly hint (rather than a raw traceback) if the server is
    unreachable - the #1 first-run failure mode for a new developer."""
    conn_kwargs = dict(config)
    if dbname is not None:
        conn_kwargs["dbname"] = dbname
    try:
        conn = psycopg2.connect(**conn_kwargs)
    except psycopg2.OperationalError as exc:
        print(
            f"\nCould not connect to PostgreSQL at "
            f"{config['host']}:{config['port']} as '{config['user']}'.\n"
            f"  - Is it running? Try: docker compose up -d\n"
            f"  - Check postgres/scripts/requirements.txt is installed.\n"
            f"  - Check .env (or POSTGRES_* env vars) match docker-compose.yml.\n\n"
            f"Original error: {exc}",
            file=sys.stderr,
        )
        sys.exit(1)
    conn.autocommit = True
    return conn


def ensure_database_exists(config: dict) -> None:
    """CREATE DATABASE if it doesn't exist yet. Connects to the server's
    default `postgres` database to do the check/create, since you can't
    connect to a database that doesn't exist yet."""
    target_db = config["dbname"]
    conn = connect(config, dbname="postgres")
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (target_db,))
            if cur.fetchone() is None:
                print(f"==> Creating database '{target_db}' ...")
                cur.execute(psql_sql.SQL("CREATE DATABASE {}").format(psql_sql.Identifier(target_db)))
    finally:
        conn.close()


def run_sql_file(conn, path: Path) -> None:
    print(f"==> Applying {path.name} ...")
    sql_text = "\n".join(
        line for line in path.read_text().splitlines() if not _META_COMMAND_RE.match(line)
    )
    with conn.cursor() as cur:
        cur.execute(sql_text)


def apply_schema(conn) -> None:
    run_sql_file(conn, SCHEMA_FILE)
    run_sql_file(conn, CONSTRAINTS_FILE)
    run_sql_file(conn, INDEXES_FILE)


def load_seeds(conn) -> None:
    for seed_file in SEED_FILES:
        run_sql_file(conn, seed_file)
