#!/bin/sh
# Checagens do avant-web, as mesmas do CI do GitHub. O pnpm vem do packageManager do
# package.json, pelo corepack, sem instalar nada global no container.
set -eu

export HOME="$WORKSPACE_TMP/home"
export COREPACK_HOME="$WORKSPACE_TMP/corepack"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export npm_config_store_dir="$WORKSPACE_TMP/pnpm-store"
mkdir -p "$HOME"

corepack pnpm install --frozen-lockfile
corepack pnpm lint
corepack pnpm clean-code
corepack pnpm typecheck
corepack pnpm test
corepack pnpm build
