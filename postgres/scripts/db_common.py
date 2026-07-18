"""Shared helpers for ShopAssist PostgreSQL management scripts.

Needs psycopg2 (pip install -r requirements.txt, from the repo root) - the
one dependency every script here needs, unavoidable since Python has no
built-in PostgreSQL client.
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
        "Install it with (from the repo root):\n"
        "    pip install -r requirements.txt\n",
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
    # Same variable names as shopassist's own .env.example, so a developer
    # running both repos locally only sets these once mentally - not read
    # from shopassist's .env directly (separate repo, separate process).
    "OLLAMA_API_BASE_URL": "http://localhost:11434",
    "OLLAMA_EMBEDDING_MODEL": "nomic-embed-text",
}


def _load_env_file(env_path: Path) -> None:
    """Minimal KEY=VALUE .env parser (stdlib only). A real environment
    variable - one already set before this process started, e.g. by
    `docker compose`'s `environment:` block, or an explicit `export` -
    always wins over the .env file; this only fills in what isn't already
    set. That's what lets rag-init's compose service point POSTGRES_HOST
    at the `postgres` service by name while this same .env file (baked in
    for bare local runs, where POSTGRES_HOST=localhost is correct) sits
    right next to it unmodified."""
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


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


def get_ollama_config() -> dict:
    """Ollama connection settings for init_vector_store.py, resolved the
    same way get_config() resolves Postgres settings: .env file, falling
    back to defaults that match a local `ollama serve` with
    nomic-embed-text already pulled (`ollama pull nomic-embed-text`)."""
    _load_env_file(ENV_FILE)
    return {
        "base_url": os.environ.get("OLLAMA_API_BASE_URL", DEFAULTS["OLLAMA_API_BASE_URL"]),
        "embedding_model": os.environ.get("OLLAMA_EMBEDDING_MODEL", DEFAULTS["OLLAMA_EMBEDDING_MODEL"]),
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
            f"  - Check the repo root's requirements.txt is installed.\n"
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
