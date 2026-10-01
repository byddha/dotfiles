#!/usr/bin/env bash
# Builds the Bidshell.Plasma QML module, which hosts KDE's Plasma applets in the bar (KWin backend only),
# into ~/.local/share/bidshell/qml. The shell finds it through QML_IMPORT_PATH (see PORT.md).
#
# @setup name: plasma
# @setup inputs: CMakeLists.txt *.h *.cpp
# @setup version: plasmashell --version; qtpaths6 --qt-version
# @setup check: test -f "${XDG_DATA_HOME:-$HOME/.local/share}/bidshell/qml/Bidshell/Plasma/libbidshell_plasma.so"
# @setup note: needs cmake, ninja and extra-cmake-modules; builds against the installed Plasma
set -euo pipefail

dir="${XDG_DATA_HOME:-$HOME/.local/share}/bidshell"
build="$dir/plasma-build"
mkdir -p "$dir"
cmake -S "$(dirname "$(readlink -f "$0")")" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$build"
rm -rf "$dir/qml/Bidshell/Plasma"
mkdir -p "$dir/qml/Bidshell"
cp -r "$build/qml/Bidshell/Plasma" "$dir/qml/Bidshell/Plasma"
echo "Plasma applet host built into $dir/qml"
