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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$ZIP" "$TMP/BitvaLegend-windows.zip"
cat > "$TMP/README.md" <<EOF
# Битва легенд — последняя сборка

**Версия:** $VERSION · **Собрано:** $(date -u '+%Y-%m-%d %H:%M UTC')

[Скачать BitvaLegend-windows.zip](BitvaLegend-windows.zip?raw=1) — распаковать и запустить \`BitvaLegend.exe\`.

Если Windows покажет «Windows защитила ваш компьютер»: «Подробнее» → «Выполнить в любом случае».
EOF

cd "$TMP"
git init -q -b builds
git add -A
git -c user.name="$(git -C "$ROOT" config user.name)" -c user.email="$(git -C "$ROOT" config user.email)" \
	commit -q -m "Сборка $VERSION"
git push -q -f "$REMOTE" builds
echo "Опубликовано: версия $VERSION"
echo "https://github.com/wrcabeludo-rgb/games/raw/builds/BitvaLegend-windows.zip"
