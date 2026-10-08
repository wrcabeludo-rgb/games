#!/usr/bin/env bash
# Сборка «Битвы легенд» для Windows: импорт ресурсов, автотесты, экспорт .exe, архив.
# Использование: tools/build.sh [версия]   (по умолчанию берётся из project.godot)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/godot/Godot_v4.4.1-stable_linux.x86_64}"
GAME="$ROOT/game"
VERSION="${1:-$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$GAME/project.godot")}"
OUT="$ROOT/build/BitvaLegend"

echo "== Импорт ресурсов"
"$GODOT" --headless --path "$GAME" --import >/dev/null 2>&1 || true

echo "== Автотесты"
"$GODOT" --headless --path "$GAME" --script res://tests/test_determinism.gd

echo "== Прогон игры без экрана (поиск ошибок скриптов)"
LOG="$(mktemp)"
"$GODOT" --headless --path "$GAME" --quit-after 300 >"$LOG" 2>&1 || true
if grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$LOG"; then
	echo "Найдены ошибки скриптов, сборка остановлена"
	exit 1
fi
rm -f "$LOG"

echo "== Экспорт Windows"
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path "$GAME" --export-release "Windows Desktop" "$OUT/BitvaLegend.exe"

ZIP="$ROOT/build/BitvaLegend-$VERSION-windows.zip"
rm -f "$ZIP"
(cd "$ROOT/build" && zip -qr "$ZIP" BitvaLegend)
ls -lh "$OUT/BitvaLegend.exe" "$ZIP"
