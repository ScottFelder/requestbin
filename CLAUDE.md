# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

RequestBin is an HTTP request collector/inspector service. Users create temporary "bins" (HTTP endpoints) to capture and inspect incoming requests — useful for debugging webhooks and API integrations.

## Running the Project

**Development (in-memory storage, no Redis needed):**
```bash
pip install -r requirements.txt
python web.py
# Runs at http://localhost:4000
```

**Production-like (with Redis):**
```bash
docker-compose up --build
# Runs at http://localhost:8000
```

Key environment variables:
- `REALM=prod` — switches to Redis storage and disables debug mode
- `REDIS_URL` — Redis connection string (e.g. `redis://localhost:6379#0`)
- `PORT` — override default port (4000 dev, 8000 via Docker)
- `MAX_RAW_SIZE` — max request body size in bytes (default: 10240)

## Architecture

The app is a Flask application with a storage abstraction layer that swaps between in-memory (dev) and Redis (prod) backends based on `REALM`.

**Request flow:**
1. HTTP request hits a bin URL → `views.py` captures it via `db.py` → stored as a `Request` model
2. Inspection UI fetches via `api.py` → deserializes from storage → renders via Jinja2 templates
3. `WSGIRawBody` middleware captures the raw body before Flask parses it (needed for body display)

**Storage backends** (`requestbin/storage/`):
- `memory.py` — dict-based, ephemeral, used when `REALM != 'prod'`
- `redis.py` — msgpack-serialized Redis keys with TTL expiration (48h default), used in production

**Inspection UI (`requestbin/templates/bin.html`):**
- Each captured request's body has a Raw/JSON/XML format selector. Reformatting happens entirely client-side (JSON.parse/DOMParser) against a cached copy of the raw body — no server round-trip.
- JSON output is syntax-highlighted by wrapping tokens in `<span>`s using the classes from the already-vendored `prettify.css` (`.str`, `.atn`, `.lit`, `.kwd`), so no new CSS/JS dependency is introduced.

**Key modules:**
- `requestbin/__init__.py` — app factory, route definitions, middleware setup
- `requestbin/models.py` — `Bin` and `Request` dataclasses with msgpack serialization and curl generation
- `requestbin/db.py` — storage backend loader; all data access goes through here
- `requestbin/api.py` — JSON REST API (`/api/v1/...`)
- `requestbin/views.py` — HTML page handlers
- `requestbin/config.py` — environment-based configuration

## API Endpoints

| Route | Method | Purpose |
|-------|--------|---------|
| `/api/v1/bins` | POST | Create bin |
| `/api/v1/bins/<name>` | GET/DELETE | Fetch or delete bin |
| `/api/v1/bins/<bin>/requests` | GET | List captured requests |
| `/api/v1/bins/<bin>/requests/<id>` | GET | Single request detail |
| `/<bin_name>` | ANY | Capture incoming request |
| `/<bin_name>?inspect` | GET | Inspection UI |

## No Test Suite

There are no tests in this repository. The `nose` package in `requirements.txt` is vestigial.
