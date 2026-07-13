#!/usr/bin/env bash
# ShopAssist :: manually initialize a PostgreSQL database (schema + constraints
# + indexes + seed data) against a reachable Postgres server.
#
# This is for environments where you are NOT using docker-compose's automatic
# docker-entrypoint-initdb.d bootstrap (e.g. an existing staging/production
# Postgres instance). If you're using `docker compose up -d`, initialization
# already happens automatically on first startup - you don't need this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$POSTGRES_DIR/.." && pwd)"

if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
    set +a
fi

POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-shopassist}"
POSTGRES_USER="${POSTGRES_USER:-shopassist}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-shopassist123}"

export PGPASSWORD="$POSTGRES_PASSWORD"

if ! command -v psql >/dev/null 2>&1; then
    echo "Error: psql CLI not found. Install the PostgreSQL client tools." >&2
    exit 1
fi

psql_exec() {
    psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f "$1"
}

echo "==> Ensuring database '$POSTGRES_DB' exists on $POSTGRES_HOST:$POSTGRES_PORT ..."
DB_EXISTS=$(psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'")
if [ "$DB_EXISTS" != "1" ]; then
    psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 \
        -c "CREATE DATABASE \"$POSTGRES_DB\""
fi

echo "==> Applying schema ..."
psql_exec "$POSTGRES_DIR/schema/schema.sql"

echo "==> Applying constraints ..."
psql_exec "$POSTGRES_DIR/schema/constraints.sql"

echo "==> Applying indexes ..."
psql_exec "$POSTGRES_DIR/schema/indexes.sql"

echo "==> Loading seed data: users ..."
psql_exec "$POSTGRES_DIR/seeds/seed_users.sql"

echo "==> Loading seed data: products ..."
psql_exec "$POSTGRES_DIR/seeds/seed_products.sql"

echo "==> Loading seed data: orders ..."
psql_exec "$POSTGRES_DIR/seeds/seed_orders.sql"

echo "ShopAssist :: PostgreSQL initialization completed successfully."
