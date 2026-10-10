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
for test in "$GAME"/tests/test_*.gd; do
	echo "-- $(basename "$test")"
	"$GODOT" --headless --path "$GAME" --script "res://tests/$(basename "$test")" 2>&1 | grep -E "OK|FAIL|ИТОГ|ERROR"
	"$GODOT" --headless --path "$GAME" --script "res://tests/$(basename "$test")" >/dev/null 2>&1 \
		|| { echo "Тесты не пройдены, сборка остановлена"; exit 1; }
done

echo "== Прогон игры без экрана (поиск ошибок скриптов)"
LOG="$(mktemp)"
"$GODOT" --headless --path "$GAME" --quit-after 300 >"$LOG" 2>&1 || true
if grep -E "SCRIPT ERROR|Parse Error|Compile Error|^ERROR" "$LOG"; then
	echo "Найдены ошибки скриптов, сборка остановлена"
	exit 1
fi
rm -f "$LOG"

echo "== Экспорт Windows"
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path "$GAME" --export-release "Windows Desktop" "$OUT/BitvaLegend.exe"

# Иконка игры вместо иконки Godot (rcedit не нужен, см. tools/set_exe_icon.py).
python3 "$ROOT/tools/set_exe_icon.py" "$OUT/BitvaLegend.exe" "$GAME/icon.ico"

# Бойцы в высоком разрешении — отдельными пакетами рядом с игрой (подключаются scripts/core/packs.gd).
# Список должен совпадать с exclude_filter в game/export_presets.cfg.
EXTRA_PACKS="koschei"
cp "$ROOT/tools/pack_fighter.gd" "$GAME/tools_pack_fighter.gd"
for id in $EXTRA_PACKS; do
	"$GODOT" --headless --path "$GAME" --script res://tools_pack_fighter.gd -- "$id" "$OUT/$id.pck" 2>&1 | grep "Пакет"
done
rm -f "$GAME/tools_pack_fighter.gd"

# Один архив со всем: запускатель, данные игры и пакеты бойцов (GitHub Releases принимает файлы до 2 ГБ).
ZIP="$ROOT/build/BitvaLegend-$VERSION-windows.zip"
rm -f "$ROOT"/build/BitvaLegend-$VERSION-*.zip
(cd "$ROOT/build" && zip -qr "$ZIP" BitvaLegend)
ls -lh "$OUT"/* "$ROOT"/build/BitvaLegend-$VERSION-*.zip
