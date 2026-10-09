#!/usr/bin/env bash
# Публикует последнюю сборку в ветку builds репозитория games.
# Ветка содержит только последнюю сборку (каждый раз перезаписывается),
# чтобы репозиторий не раздувался бинарными файлами.
# Постоянная ссылка: https://github.com/wrcabeludo-rgb/games/raw/builds/BitvaLegend-windows.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$ROOT/game/project.godot")"
ZIP="$ROOT/build/BitvaLegend-$VERSION-windows.zip"
REMOTE="$(git -C "$ROOT" remote get-url origin)"
[ -f "$ZIP" ] || { echo "Нет $ZIP — сначала запусти tools/build.sh"; exit 1; }

EXE_SHA="$(sha256sum "$ROOT/build/BitvaLegend/BitvaLegend.exe" | cut -d' ' -f1)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$ZIP" "$TMP/BitvaLegend-windows.zip"
# Дополнительные пакеты бойцов (см. EXTRA_PACKS в build.sh) — отдельными архивами.
EXTRA=""
for z in "$ROOT"/build/BitvaLegend-"$VERSION"-*.zip; do
	id="${z##*-}"; id="${id%.zip}"
	[ "$id" = "windows" ] && continue
	cp "$z" "$TMP/BitvaLegend-$id.zip"
	EXTRA="$EXTRA
- [BitvaLegend-$id.zip](BitvaLegend-$id.zip?raw=1)"
done
cat > "$TMP/README.md" <<EOF
# Битва легенд — последняя сборка

**Версия:** $VERSION · **Собрано:** $(date -u '+%Y-%m-%d %H:%M UTC')

1. [Скачать BitvaLegend-windows.zip](BitvaLegend-windows.zip?raw=1) — сама игра.
2. Дополнительные бойцы в высоком разрешении (распаковать в ту же папку, что и игру):$EXTRA

Запускать \`BitvaLegend.exe\`. Без дополнительных архивов игра работает, но эти бойцы будут заглушками.

Если Windows покажет «Windows защитила ваш компьютер»: «Подробнее» → «Выполнить в любом случае».

\`BitvaLegend.exe\` — официальный запускатель Godot 4.4.1 (изменена только иконка), \`*.pck\` — данные игры.
Держи все файлы в одной папке.

SHA-256 \`BitvaLegend.exe\`: \`$EXE_SHA\`
EOF

cd "$TMP"
git init -q -b builds
git add -A
git -c user.name="$(git -C "$ROOT" config user.name)" -c user.email="$(git -C "$ROOT" config user.email)" \
	commit -q -m "Сборка $VERSION"
git push -q -f "$REMOTE" builds
echo "Опубликовано: версия $VERSION"
for f in "$TMP"/*.zip; do echo "https://github.com/wrcabeludo-rgb/games/raw/builds/$(basename "$f")"; done
