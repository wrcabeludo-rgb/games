#!/usr/bin/env python3
"""Лежащий соперник в парной сцене / добивании — на полу.

Veo укладывает брошенного «ближе к зрителю»: его низ на 15–25 px ниже ступней бросившего, и когда ролик кончается,
обычный спрайт лежащего подскакивает. Скрипт находит в кадре лежащую фигуру (связная область ниже 400 px, низ ниже
опорной точки) и поднимает её пиксели на пол (низ = опорная точка). Остальные фигуры не трогает.
Если лежащий слился с бросившим в одну область (тот склонился над ним), с ключом --merged поднимается весь кадр (опорная точка).

Запуск (из bitva-legend/): python3 tools/foe_ground.py <боец> <лист> [с кадра] [по кадр] [--merged]
Запускать ПОСЛЕ process_fighter_art.py (он перезаписывает кадры) и перед add_feet.py.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LYING = 400       # выше — не лежит
MIN_PX = 2000     # мелочь (крошки, искры) не трогаем


def components(alpha: np.ndarray):
    """Связные области фигур: маски (заливка от каждой ещё не размеченной точки)."""
    left = alpha > 40
    out = []
    while left.any():
        ys, xs = np.where(left)
        im = Image.fromarray(np.where(left, 255, 0).astype(np.uint8), "L").copy()
        ImageDraw.floodfill(im, (int(xs[0]), int(ys[0])), 128, thresh=0)
        mask = np.asarray(im) == 128
        left &= ~mask
        if mask.sum() >= MIN_PX:
            # Полупрозрачная кайма (alpha ≤ 40) — тоже фигура, иначе останется призраком на старом месте.
            for _ in range(3):
                grow = mask.copy()
                grow[1:] |= mask[:-1]
                grow[:-1] |= mask[1:]
                grow[:, 1:] |= mask[:, :-1]
                grow[:, :-1] |= mask[:, 1:]
                mask = grow & (alpha > 0)
            out.append(mask)
    return out


def shift_up(im: np.ndarray, mask: np.ndarray, lift: int) -> None:
    part = np.where(mask[:, :, None], im, 0)
    im[mask] = 0
    moved = np.zeros_like(im)
    moved[:-lift] = part[lift:]
    keep = moved[:, :, 3] > 0
    im[keep] = moved[keep]


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    merged = "--merged" in sys.argv
    who, name = args[0], args[1]
    first = int(args[2]) if len(args) > 2 else 1
    last = int(args[3]) if len(args) > 3 else 10 ** 6
    folder = ROOT / "game/art/fighters" / who
    meta = json.loads((folder / f"{name}.json").read_text())
    for i, fr in enumerate(meta["frames"], 1):
        if i < first or i > last:
            continue
        path = folder / fr["file"]
        im = np.array(Image.open(path).convert("RGBA"))
        py = fr["pivot"][1]
        moved = []
        for mask in components(im[:, :, 3]):
            ys = np.where(mask.any(1))[0]
            top, bot = int(ys.min()), int(ys.max()) + 1
            lift = bot - py
            if lift <= 0:
                continue
            if bot - top <= LYING and lift <= top:
                shift_up(im, mask, lift)
                moved.append(lift)
            elif merged and bot - top > LYING:
                fr["pivot"][1] += lift  # весь кадр вверх — это сдвиг опорной точки
                moved.append(f"весь кадр {lift}")
                break
        if moved:
            Image.fromarray(im).save(path, optimize=True)
            print(f"  {name} {i}: поднят на {moved}")
    (folder / f"{name}.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
