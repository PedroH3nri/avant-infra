#!/bin/sh
# Checagens de um repositório Python do Avant, as mesmas do CI do GitHub.
# O token do avant-core (privado) só vale durante o uv sync e não é gravado em arquivo.
set -eu

export HOME="$WORKSPACE_TMP/home"
export UV_CACHE_DIR="$WORKSPACE_TMP/uv-cache"
export UV_PYTHON_DOWNLOADS=never
mkdir -p "$HOME"

GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0="url.https://x-access-token:${AVANT_CORE_ACCESS}@github.com/PedroH3nri/avant-core.insteadOf" \
GIT_CONFIG_VALUE_0="https://github.com/PedroH3nri/avant-core" \
  uv sync --frozen
unset AVANT_CORE_ACCESS

# Vulnerabilidades conhecidas nas dependências travadas no uv.lock (o avant-core é nosso e fica de fora).
# Em dois passos: o sh não tem pipefail, e uma falha do uv export sumiria no pipe.
uv export --frozen --no-hashes --no-emit-project > "$WORKSPACE_TMP/requirements-lock.txt"
grep -v '^avant-core @' "$WORKSPACE_TMP/requirements-lock.txt" > "$WORKSPACE_TMP/requirements-audit.txt"
uvx pip-audit@2.9.0 --no-deps --disable-pip -r "$WORKSPACE_TMP/requirements-audit.txt"

uv run ruff format --check .
uv run ruff check .
uv run mypy
uv run python scripts/clean_code.py
uv run pytest -q
