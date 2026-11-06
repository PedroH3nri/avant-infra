#!/bin/sh
# Checagens do avant-web, as mesmas do CI do GitHub. O Node 25 em diante não traz o corepack:
# o pnpm entra pelo npm, na versão do packageManager, dentro da pasta temporária do job.
set -eu

export HOME="$WORKSPACE_TMP/home"
export NPM_CONFIG_PREFIX="$WORKSPACE_TMP/npm"
export npm_config_store_dir="$WORKSPACE_TMP/pnpm-store"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
mkdir -p "$HOME"

pnpm_version=$(node -p "require('./package.json').packageManager.split('@')[1]")
npm install -g "pnpm@$pnpm_version"

pnpm install --frozen-lockfile
pnpm lint
pnpm clean-code
pnpm typecheck
pnpm test
pnpm build
