# Migrations

This directory holds versioned, forward-only schema migrations that are
applied **after** the baseline in `../schema/` on databases that already
have data (i.e. everywhere except a brand-new environment, which just gets
the current `schema.sql` + `constraints.sql` + `indexes.sql` directly).

No migrations exist yet — `schema/schema.sql`, `schema/constraints.sql`, and
`schema/indexes.sql` in this repository represent the current baseline
schema. Start numbering from `0001` the first time a change needs to be
applied to a database that's already running.

## Naming convention

```
NNNN_short_description.sql
```

- `NNNN` — zero-padded, monotonically increasing sequence number (`0001`, `0002`, ...)
- `short_description` — snake_case summary of the change

Example: `0001_add_customers_marketing_opt_in.sql`

## Authoring a migration

- One logical change per file (add a column, add a table, backfill data, etc.)
- Write it to be safe to run against a database with live data:
  use `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, guard `ADD CONSTRAINT` with a
  `pg_constraint` check (see the pattern in `../schema/constraints.sql`), and
  wrap multi-statement changes in a transaction.
- Never edit a migration file that has already been applied to any shared
  environment — add a new migration instead.
- After adding a migration, also update `../schema/schema.sql` (and
  `constraints.sql`/`indexes.sql` as needed) so that a fresh database created
  from the baseline scripts ends up in the same state as one that went
  through every migration.

## Applying migrations

Until a migration runner is introduced, apply new files in order with `psql`:

```bash
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    -v ON_ERROR_STOP=1 -f postgres/migrations/0001_add_customers_marketing_opt_in.sql
```

For a growing set of migrations, adopt a dedicated tool (e.g.
[`sqlx-cli`](https://github.com/launchbadge/sqlx), [`golang-migrate`](https://github.com/golang-migrate/migrate),
or [`Flyway`](https://flywaydb.org/)) rather than hand-rolling one — see
[../../docs/database-design.md](../../docs/database-design.md#future-migration-strategy)
for the recommended path.
