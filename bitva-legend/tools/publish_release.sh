#!/usr/bin/env bash
# Публикует последнюю сборку в GitHub Releases репозитория games (лимит 2 ГБ на файл).
# Токен: GH_TOKEN из окружения (GitHub Actions), иначе его подставляет сетевой посредник среды.
# Постоянная ссылка: https://github.com/wrcabeludo-rgb/games/releases/latest/download/BitvaLegend-windows.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$ROOT/game/project.godot")"
ZIP="$ROOT/build/BitvaLegend-$VERSION-windows.zip"
API="https://api.github.com/repos/wrcabeludo-rgb/games"
UP="https://uploads.github.com/repos/wrcabeludo-rgb/games"
AUTH=()
[ -n "${GH_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GH_TOKEN")
[ -f "$ZIP" ] || { echo "Нет $ZIP — сначала запусти tools/build.sh"; exit 1; }

TAG="v$VERSION"
BODY="Битва легенд $VERSION. Скачать BitvaLegend-windows.zip, распаковать и запустить BitvaLegend.exe. Если Windows покажет «Windows защитила ваш компьютер»: «Подробнее» → «Выполнить в любом случае»."
# Релиз этой версии уже есть (пересборка) — удаляем, чтобы выложить заново.
OLD="$(curl -sS "${AUTH[@]}" "$API/releases/tags/$TAG" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))')"
if [ -n "$OLD" ]; then
	curl -sS "${AUTH[@]}" -X DELETE "$API/releases/$OLD" >/dev/null
	curl -sS "${AUTH[@]}" -X DELETE "$API/git/refs/tags/$TAG" >/dev/null || true
fi
ID="$(python3 -c 'import json,sys; print(json.dumps({"tag_name": sys.argv[1], "target_commitish": sys.argv[4], "name": "Битва легенд " + sys.argv[2], "body": sys.argv[3], "make_latest": "true"}))' "$TAG" "$VERSION" "$BODY" "${GITHUB_SHA:-main}" \
	| curl -sS "${AUTH[@]}" -X POST "$API/releases" -H "Content-Type: application/json" -d @- \
	| python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("id") or sys.exit("Не удалось создать релиз: " + str(d)))')"
curl -sS "${AUTH[@]}" -X POST "$UP/releases/$ID/assets?name=BitvaLegend-windows.zip" -H "Content-Type: application/zip" \
	--data-binary @"$ZIP" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("Загружено:", d.get("name"), d.get("size")) if d.get("state")=="uploaded" else sys.exit("Ошибка загрузки: " + str(d))'
echo "Опубликовано: версия $VERSION"
echo "https://github.com/wrcabeludo-rgb/games/releases/latest/download/BitvaLegend-windows.zip"
