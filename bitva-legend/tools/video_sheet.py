#!/usr/bin/env python3
"""Лист кадров из видео (Veo, Kling…): цикл или движение бойца на пурпурном фоне → сетка кадров для
process_fighter_art.py.

Использование: python3 tools/video_sheet.py <видео> <первый кадр> <последний кадр> <выход.png> [шаг] [столбцов] [опорный]
  кадры — с 1, как у ffmpeg; последний не включается (для цикла: первый кадр следующего витка);
  шаг — брать каждый N-й кадр (по умолчанию 1); столбцов — ширина сетки (по умолчанию 8);
  опорный — кадр со стойкой, ставится первым (для выравнивания по стойке, если движение начинается
  не из неё; в sheets.json тогда "drop_ref": true — после выравнивания он выбрасывается).
Рядом пишется <выход>.cells.json — раскладка клеток (для "fixed_pivot" в sheets.json).
Кадры обрезаются по общей рамке бойца (с запасом), фон приводится к чистому #FF00FF, водяной знак
в правом нижнем углу (Kling) отрезается рамкой. Печатает число кадров и сетку для sheets.json.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

MARGIN = 24   # запас вокруг бойца в кадре, px
GAP = 40      # пустое поле между кадрами в листе, px


def is_bg(a: np.ndarray) -> np.ndarray:
    r, g, b = (a[..., i].astype(int) for i in range(3))
    return (np.minimum(r, b) - g) > 90


def main() -> int:
    if len(sys.argv) < 5:
        print(__doc__)
        return 1
    video, first, last, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), Path(sys.argv[4])
    step = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    cols = int(sys.argv[6]) if len(sys.argv) > 6 else 8
    tmp = Path(tempfile.mkdtemp())
    subprocess.run(["ffmpeg", "-v", "error", "-i", video, str(tmp / "%04d.png")], check=True)
    ref = int(sys.argv[7]) if len(sys.argv) > 7 else 0
    idx = ([ref] if ref else []) + list(range(first, last, step))
    frames = [np.asarray(Image.open(tmp / f"{i:04d}.png").convert("RGB")) for i in idx]
    h, w = frames[0].shape[:2]
    # Общая рамка бойца по всем кадрам (без правого нижнего угла с водяным знаком).
    y0, y1, x0, x1 = h, 0, w, 0
    for a in frames:
        m = ~is_bg(a)
        m[int(h * 0.9):, int(w * 0.8):] = False
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = min(y0, ys.min()), max(y1, ys.max()), min(x0, xs.min()), max(x1, xs.max())
    y0, x0 = max(0, y0 - MARGIN), max(0, x0 - MARGIN)
    y1, x1 = min(h, y1 + MARGIN + 1), min(w, x1 + MARGIN + 1)
    cw, ch = x1 - x0, y1 - y0
    rows = (len(frames) + cols - 1) // cols
    sheet = np.zeros((rows * (ch + GAP) + GAP, cols * (cw + GAP) + GAP, 3), np.uint8)
    sheet[:] = (255, 0, 255)
    for k, a in enumerate(frames):
        c = a[y0:y1, x0:x1].copy()
        c[is_bg(c)] = (255, 0, 255)
        r, q = divmod(k, cols)
        sheet[GAP + r * (ch + GAP):GAP + r * (ch + GAP) + ch, GAP + q * (cw + GAP):GAP + q * (cw + GAP) + cw] = c
    out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(sheet).save(out)
    # Раскладка листа — для process_fighter_art.py ("fixed_pivot": true): кадры режутся по клеткам,
    # опорная точка у всех одна (камера неподвижна, сдвиг бойца в ролике — его настоящее движение).
    out.with_suffix(".cells.json").write_text(json.dumps(
        {"cols": cols, "rows": rows, "cell": [int(cw), int(ch)], "gap": GAP, "width": int(sheet.shape[1]), "frames": len(frames)}))
    print(f"{out}: {len(frames)} кадров, сетка [{cols}, {rows}], кадр {cw}×{ch}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
