#!/usr/bin/env bash
# Builds the theme picker into vicinae's extension folder. Vicinae only loads a new
# extension after `vicinae server --replace`; rebuilds of a known one are picked up live.
#
# @setup name: vicinae-theme-picker
# @setup inputs: package.json package-lock.json tsconfig.json src/* assets/*
# @setup check: test -f "${XDG_DATA_HOME:-$HOME/.local/share}/vicinae/extensions/theme-picker/pick-theme.js"
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
npm ci --no-fund --no-audit
npm run build
