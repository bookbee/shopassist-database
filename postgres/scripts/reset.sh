#!/usr/bin/env bash
# ShopAssist :: drop all tables, recreate the schema, and reload seed data
# against a reachable PostgreSQL server (e.g. the docker-compose service
# exposed on localhost:${POSTGRES_PORT}).
#
# Destructive: this drops the entire `public` schema. A confirmation prompt
# is required unless run non-interactively with --yes (for CI/CD).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$POSTGRES_DIR/.." && pwd)"

FORCE=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) FORCE=1 ;;
    esac
done

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

if [ "$FORCE" -ne 1 ]; then
    read -r -p "This will DROP ALL TABLES in '$POSTGRES_DB' on $POSTGRES_HOST:$POSTGRES_PORT and reload seed data. Continue? [y/N] " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

psql_exec() {
    psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f "$1"
}

echo "==> Dropping and recreating the public schema ..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 \
    -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "==> Recreating schema ..."
psql_exec "$POSTGRES_DIR/schema/schema.sql"

echo "==> Recreating constraints ..."
psql_exec "$POSTGRES_DIR/schema/constraints.sql"

echo "==> Recreating indexes ..."
psql_exec "$POSTGRES_DIR/schema/indexes.sql"

echo "==> Reloading seed data: users ..."
psql_exec "$POSTGRES_DIR/seeds/seed_users.sql"

echo "==> Reloading seed data: products ..."
psql_exec "$POSTGRES_DIR/seeds/seed_products.sql"

echo "==> Reloading seed data: orders ..."
psql_exec "$POSTGRES_DIR/seeds/seed_orders.sql"

echo "ShopAssist :: PostgreSQL reset completed successfully."
