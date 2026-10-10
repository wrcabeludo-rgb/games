#!/usr/bin/env bash
# Готовит чистую облачную среду к работе над игрой: Godot 4.4.1, шаблоны экспорта Windows,
# Python-пакеты для обработки арта и нейросетевого апскейлера. Повторный запуск ничего не ломает.
set -euo pipefail
GV=4.4.1-stable
if [ ! -x "$HOME/godot/Godot_v${GV}_linux.x86_64" ]; then
	mkdir -p "$HOME/godot" && cd "$HOME/godot"
	curl -sSL -o g.zip "https://github.com/godotengine/godot/releases/download/${GV}/Godot_v${GV}_linux.x86_64.zip"
	unzip -qo g.zip && rm g.zip
fi
T="$HOME/.local/share/godot/export_templates/4.4.1.stable"
if [ ! -f "$T/windows_release_x86_64.exe" ]; then
	mkdir -p "$T" && cd "$(mktemp -d)"
	curl -sSL -o t.tpz "https://github.com/godotengine/godot/releases/download/${GV}/Godot_v${GV}_export_templates.tpz"
	unzip -qo t.tpz "templates/windows_*_x86_64.exe" "templates/version.txt"
	mv templates/* "$T/"
fi
pip install -q pillow numpy torch spandrel pe_tools 2>&1 | grep -v "WARNING: Running pip" || true
echo "Среда готова: Godot $GV, шаблоны Windows, Python-пакеты."
