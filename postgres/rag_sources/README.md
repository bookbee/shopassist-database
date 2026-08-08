# RAG source documents

Static source material for RAG — PDFs, spreadsheets, plain text, Markdown
— that `postgres/scripts/init_vector_store.py` chunks, embeds, and loads
into `document_chunks`. Separate from `postgres/seeds/`, which is
relational data loaded as literal `INSERT`s with no processing step.

## Layout

Subfolder name = `document_chunks.source_type` for every file placed in
it — `init_vector_store.py` doesn't infer this from content, only from
which folder a file is dropped into. Each ships with two starter files: one
for the IISc alumni store demo dataset (matching `postgres/seeds/`), one
for a generic e-commerce site, so the pattern is obvious regardless of
which one your own content resembles.

```text
rag_sources/
├── product_catalog/                          # product descriptions, spec sheets
│   ├── iisc-alumni-merchandise-catalog.csv    # 6 IISc store items, one row each
│   └── ecommerce-product-spec-sheet.xlsx      # 4 generic electronics SKUs
├── customer_support_policy/                   # returns/shipping/warranty policy text
│   ├── iisc-alumni-returns-and-shipping-policy.md
│   └── ecommerce-warranty-and-refund-policy.pdf
└── customer_support_conversation/              # anonymized past support transcripts
    ├── iisc-alumni-order-status-conversation.txt
    └── ecommerce-return-request-conversation.txt
```

## Supported file types

`.txt`, `.md`, `.csv`, `.xlsx`, `.pdf` — the six starter files above cover
all five. Each file becomes one or more rows in `document_chunks` (see
`init_vector_store.py` for the exact chunking and `doc_id` scheme).

## Running it

```bash
pip install -r requirements.txt   # from the repo root, once
ollama pull nomic-embed-text      # once, if not already pulled
python3 postgres/scripts/init_vector_store.py
```

Loads all six starter files above into `document_chunks` — 6 rows, one
per file (each is short enough to be a single chunk). Confirm it worked:

```bash
docker exec -it shopassist-postgres psql -U shopassist -d shopassist \
    -c "SELECT doc_id, source_type FROM document_chunks ORDER BY doc_id;"
```

Or, without installing anything locally, via Docker Compose (see the root
README's RAG section for the full explanation of this service):

```bash
docker compose --profile rag up rag-init
```

## Adding your own document

1. Drop the file into the subfolder matching its `source_type` — replace
   the starter files outright once you have real content, or add
   alongside them.
2. Run `python3 postgres/scripts/init_vector_store.py` (or the
   `docker compose --profile rag up rag-init` form above) again.

Rerunning is always safe: `doc_id` is derived from the filename and a
chunk index, so editing a file and rerunning updates its existing rows
instead of duplicating them.

## Resetting to match this folder exactly

Rerunning is additive by default — it never deletes. Deleting a source
file, or replacing it with one that chunks differently, leaves the old
rows behind in `document_chunks` untouched. To wipe the table first and
reload only what's currently in this folder:

```bash
python3 postgres/scripts/init_vector_store.py --truncate
```

Or via Docker Compose:

```bash
RAG_INIT_TRUNCATE=true docker compose --profile rag up rag-init
```

Use this whenever `document_chunks` needs to match this folder's current
contents exactly rather than reflect the accumulated history of every run
against it.

## PII

Mask PII before it lands here, the same way `shopassist-service`'s own ingestion
(`services/pii_masker.py`) does before anything reaches an embedding call.
Don't drop real, unmasked customer conversations or any file containing
real names/emails/phone numbers into `customer_support_conversation/` —
anonymize first.
