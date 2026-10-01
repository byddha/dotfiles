#!/usr/bin/env bash
# Installs the region selector's OCR: a venv with RapidOCR and the PP-OCRv6 small and medium models under
# ~/.local/share/bidshell/ocr. Run by scripts/setup, which runs it again when a Python upgrade breaks
# the venv.
#
# @setup name: ocr
# @setup inputs: ocr.py
# @setup version: python3 -c 'import sys; print(sys.version_info[:2])'
# @setup check: d="${XDG_DATA_HOME:-$HOME/.local/share}/bidshell/ocr" && "$d/venv/bin/python" -c 'import rapidocr' && for m in det_small rec_small det_medium rec_medium; do test -s "$d/models/PP-OCRv6_$m.onnx" || exit 1; done
# @setup note: downloads a ~550 MB venv and ~163 MB of models
set -euo pipefail

dir="${XDG_DATA_HOME:-$HOME/.local/share}/bidshell/ocr"
log="$dir/setup.log"
mkdir -p "$dir"
exec > >(tee "$log") 2>&1

# The venv and the models are built next to the old ones and swapped in only at the end, so a
# failed run (no network, pip error, a download cut halfway) leaves a working install in place.
# Moving a venv breaks the shebangs of its pip scripts, but nothing calls those after setup;
# the shell only runs venv/bin/python.
rm -rf "$dir/venv.new" "$dir/staging"
python3 -m venv "$dir/venv.new"
# Pinned: RapidOCR fetches the models from URLs tied to its version
"$dir/venv.new/bin/pip" install --quiet rapidocr==3.9.2 onnxruntime==1.30.0
# ocr.py puts the models under $XDG_DATA_HOME/bidshell/ocr/models, so this points it at staging/
XDG_DATA_HOME="$dir/staging" "$dir/venv.new/bin/python" "$(dirname "$(readlink -f "$0")")/ocr.py" --download

rm -rf "$dir/venv" "$dir/models"
mv "$dir/venv.new" "$dir/venv"
mv "$dir/staging/bidshell/ocr/models" "$dir/models"
rm -rf "$dir/staging"
echo "OCR is ready. Log: $log"
