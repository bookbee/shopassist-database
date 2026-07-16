# Migrations

Versioned, forward-only schema changes applied **after** the baseline in
`../schema/` — for databases that already hold data. A brand-new
environment just gets `schema.sql` + `constraints.sql` + `indexes.sql`
directly.

`0001_add_document_chunks_for_rag.sql` is the first one — adds the
pgvector extension + `document_chunks` table for RAG semantic search to a
database that already has the other 5 tables and data. Start at `0002` for
the next one.

## Naming

```
NNNN_short_description.sql
```

`NNNN` — zero-padded, monotonic (`0001`, `0002`, ...). `short_description`
— snake_case summary.

Example: `0002_add_customers_marketing_opt_in.sql`

## Authoring

- One logical change per file (add a column, add a table, backfill data, etc.)
- Safe against live data: `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, guard
  `ADD CONSTRAINT` with a `pg_constraint` check (pattern in
  `../schema/constraints.sql`), wrap multi-statement changes in a transaction.
- Never edit a migration already applied to a shared environment — add a
  new one instead.
- After adding a migration, update `../schema/schema.sql` (and
  `constraints.sql`/`indexes.sql` as needed) so a fresh database matches one
  built through every migration.

## Applying

No runner yet — apply new files in order with `psql`:

```bash
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    -v ON_ERROR_STOP=1 -f postgres/migrations/0001_add_document_chunks_for_rag.sql
```

For a growing set of migrations, adopt a dedicated tool (e.g.
[`sqlx-cli`](https://github.com/launchbadge/sqlx), [`golang-migrate`](https://github.com/golang-migrate/migrate),
or [`Flyway`](https://flywaydb.org/)) rather than hand-rolling one — see
[../../docs/database-design.md](../../docs/database-design.md#future-migration-strategy)
for the recommended path.
