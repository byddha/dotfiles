#!/usr/bin/env bash
# Installs the region selector's OCR: a venv with RapidOCR and the PP-OCRv6 medium models under
# ~/.local/share/bidshell/ocr. Started by `qs ipc call setup ocr`; run it again when a Python
# upgrade breaks the venv.
set -euo pipefail

dir="${XDG_DATA_HOME:-$HOME/.local/share}/bidshell/ocr"
log="$dir/setup.log"
mkdir -p "$dir"
exec >"$log" 2>&1

notify() { notify-send -a "OCR setup" "$@"; }
trap 'notify -u critical "OCR setup failed" "Details in $log"' ERR

notify "OCR setup" "Installing RapidOCR and the PP-OCRv6 medium models…"
rm -rf "$dir/venv"
python3 -m venv "$dir/venv"
# Pinned: RapidOCR fetches the models from URLs tied to its version
"$dir/venv/bin/pip" install --quiet rapidocr==3.9.2 onnxruntime==1.30.0
"$dir/venv/bin/python" "$(dirname "$(readlink -f "$0")")/ocr.py" --download
notify "OCR setup" "Done: the region selector's text tools are ready."
