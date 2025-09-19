#!/usr/bin/env bash
# Start FastAPI using uvicorn, cross-platform friendly (Linux/macOS).

set -euo pipefail

# Load environment variables from .env if present
if [ -f "backend/.env" ]; then
  # Normalize line endings (CRLF -> LF) in a portable way
  # macOS/BSD sed needs an empty string after -i
  if sed --version >/dev/null 2>&1; then
    # GNU sed (Linux)
    sed -i 's/\r$//' backend/.env
  else
    # BSD sed (macOS)
    sed -i '' -e 's/\r$//' backend/.env
  fi

  set -o allexport
  # shellcheck disable=SC1091
  source backend/.env
  set +o allexport
fi

# Defaults
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"

# Compute reload flag in a way that works on Bash 3.2+
UV_RELOAD_LOWER="$(printf '%s' "${UVICORN_RELOAD:-}" | tr '[:upper:]' '[:lower:]')"
RELOAD_FLAG=""
if [[ "$UV_RELOAD_LOWER" == "true" || "$UV_RELOAD_LOWER" == "1" ]]; then
  RELOAD_FLAG="--reload"
fi

echo "Attempting to start server on ${HOST}:${PORT} with reload flag: '${RELOAD_FLAG}'"

# Prefer 'uv' if available; otherwise fall back to python -m uvicorn
if command -v uv >/dev/null 2>&1; then
  uv run python -m uvicorn backend.app.main:app --host "$HOST" --port "$PORT" $RELOAD_FLAG
elif command -v python >/dev/null 2>&1; then
  python -m uvicorn backend.app.main:app --host "$HOST" --port "$PORT" $RELOAD_FLAG
else
  echo "Error: neither 'uv' nor 'python' found in PATH." >&2
  exit 1
fi