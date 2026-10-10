#!/usr/bin/env bash
# Публикует последнюю сборку в GitHub Releases репозитория games (лимит 2 ГБ на файл).
# Токен подставляет сетевой посредник среды (секрет GH_RELEASE_TOKEN для api/uploads.github.com).
# Постоянная ссылка: https://github.com/wrcabeludo-rgb/games/releases/latest/download/BitvaLegend-windows.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$ROOT/game/project.godot")"
ZIP="$ROOT/build/BitvaLegend-$VERSION-full.zip"
API="https://api.github.com/repos/wrcabeludo-rgb/games"
UP="https://uploads.github.com/repos/wrcabeludo-rgb/games"
[ -d "$ROOT/build/BitvaLegend" ] || { echo "Нет сборки — сначала запусти tools/build.sh"; exit 1; }

# Один архив со всем: запускатель, данные игры и пакеты бойцов.
rm -f "$ZIP"
(cd "$ROOT/build" && zip -qr "$ZIP" BitvaLegend)

TAG="v$VERSION"
BODY="Битва легенд $VERSION. Скачать BitvaLegend-windows.zip, распаковать и запустить BitvaLegend.exe. Если Windows покажет «Windows защитила ваш компьютер»: «Подробнее» → «Выполнить в любом случае»."
# Релиз этой версии уже есть (пересборка) — удаляем, чтобы выложить заново.
OLD="$(curl -sS "$API/releases/tags/$TAG" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))')"
if [ -n "$OLD" ]; then
	curl -sS -X DELETE "$API/releases/$OLD" >/dev/null
	curl -sS -X DELETE "$API/git/refs/tags/$TAG" >/dev/null || true
fi
ID="$(python3 -c 'import json,sys; print(json.dumps({"tag_name": sys.argv[1], "target_commitish": "main", "name": "Битва легенд " + sys.argv[2], "body": sys.argv[3], "make_latest": "true"}))' "$TAG" "$VERSION" "$BODY" \
	| curl -sS -X POST "$API/releases" -H "Content-Type: application/json" -d @- \
	| python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("id") or sys.exit("Не удалось создать релиз: " + str(d)))')"
curl -sS -X POST "$UP/releases/$ID/assets?name=BitvaLegend-windows.zip" -H "Content-Type: application/zip" \
	--data-binary @"$ZIP" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("Загружено:", d.get("name"), d.get("size")) if d.get("state")=="uploaded" else sys.exit("Ошибка загрузки: " + str(d))'
echo "Опубликовано: версия $VERSION"
echo "https://github.com/wrcabeludo-rgb/games/releases/latest/download/BitvaLegend-windows.zip"
