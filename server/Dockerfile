# Cloud Run image for the Qalam tutor server (14-AI-SPEC §3 "Cloud Run deploy notes").
# python:3.12-slim avoids the <3.11 async context-var footgun (AI-SPEC pitfall 3).
# Entrypoint is a PLAIN uvicorn — NOT `langgraph dev` / LangGraph Platform; we own the transport.
FROM python:3.12-slim

# uv for fast, reproducible installs (matches the local dev workflow).
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /srv

# Install runtime deps first (better layer caching). Only the prod group — no dev deps.
COPY pyproject.toml ./
RUN uv pip install --system --no-cache \
    "langgraph>=1.2,<2" \
    "langchain>=1.0,<2" \
    "langchain-anthropic>=1.0,<2" \
    "langchain-google-genai>=3.0,<5" \
    "langchain-google-vertexai>=3.0,<4" \
    "fastapi>=0.115" \
    "uvicorn[standard]>=0.32" \
    "pydantic>=2.9,<3" \
    "sse-starlette>=2.1" \
    "firebase-admin>=7.0,<8"

# Copy only the application package (tests/.env excluded via .dockerignore).
COPY app ./app

# Cloud Run injects $PORT; bind 0.0.0.0. No reload, no langgraph-cli.
# Use shell form so $PORT expands at container start.
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
