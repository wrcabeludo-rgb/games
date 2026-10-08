#!/usr/bin/env python3
"""Арт меню (см. docs/ART_FIGHTERS.md, «Партия: меню»): art_src/menu/title.(png|jpg|webp) →
game/art/menu/title.png (1920×1080, обрезка по центру до 16:9).
Портреты бойцов (select, select_win_p1/p2) обрабатывает tools/process_fighter_art.py.
Запуск: python3 tools/process_menu_art.py"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art_src" / "menu"
OUT = ROOT / "game" / "art" / "menu"
SIZE = (1920, 1080)


def main() -> int:
    src = next((p for ext in ("png", "jpg", "jpeg", "webp") for p in SRC.glob(f"title.{ext}")), None)
    if src is None:
        print(f"Нет {SRC}/title.*")
        return 1
    img = Image.open(src).convert("RGB")
    k = max(SIZE[0] / img.width, SIZE[1] / img.height)
    img = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
    left, top = (img.width - SIZE[0]) // 2, (img.height - SIZE[1]) // 2
    OUT.mkdir(parents=True, exist_ok=True)
    img.crop((left, top, left + SIZE[0], top + SIZE[1])).save(OUT / "title.png")
    print(f"Готово: {OUT / 'title.png'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
