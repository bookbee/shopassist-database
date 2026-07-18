#!/usr/bin/env python3
"""ShopAssist :: chunk + embed postgres/rag_sources/ into document_chunks.

Provisions the vector-search side of this database the same way
create_db.py provisions the relational side: point it at a target
database and it gets you to a known, populated state.

What it does, in order:
  1. Ensure schema.sql/constraints.sql/indexes.sql have been applied (so
     the `vector` extension + document_chunks exist even against a bare
     database) - safe to skip if already applied, everything is
     idempotent.
  2. Walk postgres/rag_sources/<source_type>/ for supported files
     (.txt, .md, .csv, .xlsx, .pdf), extracting plain text from each.
  3. Chunk each file's text (see chunk_text() below - simple paragraph
     packing, not a sophisticated splitter).
  4. Embed every chunk via Ollama's OpenAI-compatible /v1/embeddings
     endpoint (nomic-embed-text by default - see OLLAMA_EMBEDDING_MODEL).
  5. Upsert each chunk into document_chunks, keyed by a doc_id derived
     from the source filename + chunk index - rerunning after editing a
     file updates its rows instead of duplicating them. This is additive
     only: a file removed or renamed since the last run leaves its old
     rows behind untouched - pass --truncate to clear document_chunks
     first instead, so the result matches rag_sources/ exactly.

Requires Ollama running locally with the embedding model already pulled:
    ollama pull nomic-embed-text

Usage:
    python postgres/scripts/init_vector_store.py
    python postgres/scripts/init_vector_store.py --max-chars 1000 --overlap 150
    python postgres/scripts/init_vector_store.py --truncate
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path
from typing import Iterator

from db_common import apply_schema, connect, describe_target, get_config, get_ollama_config

try:
    from openai import OpenAI
except ImportError:
    print(
        "Missing dependency: openai\n\n"
        "Install it with (from the repo root):\n"
        "    pip install -r requirements.txt\n",
        file=sys.stderr,
    )
    sys.exit(1)

from psycopg2.extras import Json

RAG_SOURCES_DIR = Path(__file__).resolve().parent.parent / "rag_sources"

# Subfolder name (== document_chunks.source_type) -> doc_id prefix. Mirrors
# the conv_chunk_ / prod_chunk_ convention shopassist's own
# services/data_pipeline.py already uses for its in-memory ingestion, so a
# doc_id looks the same regardless of which pipeline produced it.
SOURCE_TYPE_PREFIXES = {
    "product_catalog": "prod",
    "customer_support_policy": "policy",
    "customer_support_conversation": "conv",
}

SUPPORTED_SUFFIXES = {".txt", ".md", ".csv", ".xlsx", ".pdf"}

# nomic-embed-text's actual output size (see schema.sql's VECTOR(768) and
# README's RAG section). Checked explicitly so a wrong/misconfigured
# embedding model fails here with a clear message, not as a cryptic
# pgvector dimension error three layers down.
EXPECTED_EMBEDDING_DIM = 768


def extract_text(path: Path) -> str:
    """Return plain text for one source file. Raises for anything under
    SUPPORTED_SUFFIXES that fails to parse - caller decides how to react."""
    suffix = path.suffix.lower()

    if suffix in (".txt", ".md"):
        return path.read_text(encoding="utf-8")

    if suffix == ".csv":
        with path.open(newline="", encoding="utf-8") as f:
            rows = list(csv.reader(f))
        if not rows:
            return ""
        header, *data_rows = rows
        lines = [
            "; ".join(f"{col}={val}" for col, val in zip(header, row))
            for row in data_rows
        ]
        return "\n".join(lines)

    if suffix == ".xlsx":
        import openpyxl

        wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
        parts = []
        for sheet in wb.worksheets:
            rows = list(sheet.iter_rows(values_only=True))
            if not rows:
                continue
            header, *data_rows = rows
            header = [str(c) if c is not None else "" for c in header]
            prefix = f"[Sheet: {sheet.title}] " if len(wb.worksheets) > 1 else ""
            for row in data_rows:
                cells = "; ".join(
                    f"{col}={val}" for col, val in zip(header, row) if val is not None
                )
                if cells:
                    parts.append(prefix + cells)
        return "\n".join(parts)

    if suffix == ".pdf":
        from pypdf import PdfReader

        reader = PdfReader(str(path))
        return "\n\n".join(page.extract_text() or "" for page in reader.pages)

    raise ValueError(f"Unsupported file type: {suffix}")


def chunk_text(text: str, max_chars: int = 1500, overlap: int = 200) -> list[str]:
    """Pack paragraphs (blank-line-separated) into chunks up to max_chars,
    each chunk repeating the last `overlap` characters of the previous one
    so a fact split across a chunk boundary doesn't lose context. A single
    paragraph longer than max_chars is hard-split instead of left whole.

    Deliberately simple - swap for a proper splitter (e.g. one of
    LangChain's) once real, larger documents show this isn't good enough.
    """
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    chunks: list[str] = []
    current = ""

    def flush():
        if current.strip():
            chunks.append(current.strip())

    for para in paragraphs:
        candidate = f"{current}\n\n{para}" if current else para
        if len(candidate) <= max_chars:
            current = candidate
            continue

        flush()
        if len(para) <= max_chars:
            current = para
        else:
            # One paragraph alone exceeds max_chars - hard-split it.
            start = 0
            while start < len(para):
                end = start + max_chars
                chunks.append(para[start:end])
                start = end - overlap
            current = ""

    flush()

    # Apply overlap between whole chunks (paragraph-packed chunks above
    # don't carry it yet - hard-split ones already do).
    overlapped = []
    for i, chunk in enumerate(chunks):
        if i == 0 or overlap <= 0:
            overlapped.append(chunk)
        else:
            tail = chunks[i - 1][-overlap:]
            overlapped.append(f"{tail}\n\n{chunk}")
    return overlapped


def iter_source_files() -> Iterator[tuple[str, Path]]:
    for source_type in SOURCE_TYPE_PREFIXES:
        folder = RAG_SOURCES_DIR / source_type
        if not folder.is_dir():
            continue
        for path in sorted(folder.iterdir()):
            if path.suffix.lower() in SUPPORTED_SUFFIXES:
                yield source_type, path


def embed(client: OpenAI, model: str, text: str) -> list[float]:
    response = client.embeddings.create(model=model, input=text)
    vector = response.data[0].embedding
    if len(vector) != EXPECTED_EMBEDDING_DIM:
        raise ValueError(
            f"Embedding model '{model}' returned {len(vector)} dimensions, "
            f"expected {EXPECTED_EMBEDDING_DIM} (document_chunks.embedding is "
            f"VECTOR({EXPECTED_EMBEDDING_DIM}) - see schema.sql). Either the "
            f"wrong model is configured, or the schema's column needs a "
            f"migration to match this model's real output size."
        )
    return vector


def truncate_document_chunks(conn) -> None:
    """Wipe document_chunks entirely before reloading. Without this,
    upsert_chunk() only ever adds/updates rows for files that still exist
    under rag_sources/ - a file that was renamed or removed leaves its old
    rows behind forever (see rag_sources/README.md). Use when you want
    document_chunks to end up matching rag_sources/ exactly, not just
    reflect it additively."""
    print("==> Truncating document_chunks (--truncate) ...")
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE document_chunks")


def upsert_chunk(conn, doc_id: str, content: str, embedding: list[float], source_type: str, metadata: dict) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO document_chunks (doc_id, content, embedding, source_type, metadata)
            VALUES (%(doc_id)s, %(content)s, %(embedding)s::vector, %(source_type)s, %(metadata)s)
            ON CONFLICT (doc_id) DO UPDATE SET
                content = EXCLUDED.content,
                embedding = EXCLUDED.embedding,
                metadata = EXCLUDED.metadata,
                updated_at = now()
            """,
            {
                "doc_id": doc_id,
                "content": content,
                "embedding": str(embedding),
                "source_type": source_type,
                "metadata": Json(metadata),
            },
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--max-chars", type=int, default=1500, help="Max characters per chunk (default: 1500)")
    parser.add_argument("--overlap", type=int, default=200, help="Characters of overlap between chunks (default: 200)")
    parser.add_argument(
        "--truncate",
        action="store_true",
        default=os.environ.get("RAG_INIT_TRUNCATE", "").lower() in ("1", "true", "yes"),
        help="Wipe document_chunks before reloading, so the result matches rag_sources/ "
        "exactly instead of just adding to what's already there (also settable via "
        "RAG_INIT_TRUNCATE=true, e.g. for the docker-compose rag-init service)",
    )
    args = parser.parse_args()

    config = get_config()
    ollama_config = get_ollama_config()
    print(f"==> Target database: {describe_target(config)}")
    print(f"==> Embedding model: {ollama_config['embedding_model']} @ {ollama_config['base_url']}")

    conn = connect(config)
    client = OpenAI(base_url=f"{ollama_config['base_url']}/v1", api_key="ollama")

    try:
        print("==> Ensuring schema is applied ...")
        apply_schema(conn)

        if args.truncate:
            truncate_document_chunks(conn)

        files = list(iter_source_files())
        if not files:
            print(f"No source files found under {RAG_SOURCES_DIR} - nothing to do.")
            print("Add files under postgres/rag_sources/<source_type>/ first (see that folder's README).")
            return 0

        total_chunks = 0
        for source_type, path in files:
            relative_path = path.relative_to(RAG_SOURCES_DIR)
            print(f"==> {relative_path}")
            try:
                text = extract_text(path)
            except Exception as exc:
                print(f"    skipped: could not extract text ({exc})", file=sys.stderr)
                continue

            chunks = chunk_text(text, max_chars=args.max_chars, overlap=args.overlap)
            prefix = SOURCE_TYPE_PREFIXES[source_type]
            stem = path.stem.lower().replace(" ", "_")

            for i, chunk_content in enumerate(chunks):
                doc_id = f"{prefix}_chunk_{stem}_{i}"
                embedding = embed(client, ollama_config["embedding_model"], chunk_content)
                upsert_chunk(
                    conn,
                    doc_id=doc_id,
                    content=chunk_content,
                    embedding=embedding,
                    source_type=source_type,
                    metadata={"source_file": str(relative_path), "chunk_idx": i},
                )
            print(f"    {len(chunks)} chunk(s) upserted")
            total_chunks += len(chunks)

        print(f"ShopAssist :: init_vector_store.py complete - {total_chunks} chunk(s) across {len(files)} file(s).")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
