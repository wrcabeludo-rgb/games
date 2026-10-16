#!/usr/bin/env python3
"""Пятна тени для листов, где в кадре два бойца (парные сцены, добивания): по каждому кадру — отдельные фигуры
(столбцы, разделённые пустотой) и их низ. Пишет в json анимации "feet": [[[x0, x1, низ], …], …] — px листа
от опорной точки. Игра рисует тень под фигурой, если её низ у земли.

Запуск (из bitva-legend/): python3 tools/add_feet.py <боец> <лист> […]
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "game/art/fighters"


def runs(cols, gap=24):
    xs = np.nonzero(cols)[0]
    if len(xs) == 0:
        return []
    out, s, p = [], xs[0], xs[0]
    for c in xs[1:]:
        if c > p + gap:
            out.append((s, p))
            s = c
        p = c
    out.append((s, p))
    return out


def main():
    who = sys.argv[1]
    for name in sys.argv[2:]:
        path = ROOT / who / f"{name}.json"
        meta = json.loads(path.read_text())
        feet = []
        for f in meta["frames"]:
            a = np.asarray(Image.open(ROOT / who / f["file"]))[..., 3] > 128
            px, py = f["pivot"]
            row = []
            for x0, x1 in runs(a.sum(0) > 3):
                if x1 - x0 < 40:
                    continue
                band = a[:, x0:x1 + 1]
                ys = np.nonzero(band.any(1))[0]
                bottom = int(ys.max())
                # Ширина тени — по нижней четверти фигуры (ступни, лежащее тело), не по раскинутым рукам.
                low = band[max(bottom - (bottom - ys.min()) // 4, 0):bottom + 1]
                lx = np.nonzero(low.any(0))[0]
                row.append([int(x0 + lx.min() - px), int(x0 + lx.max() - px), bottom - py])
            feet.append(row)
        meta["feet"] = feet
        path.write_text(json.dumps(meta, ensure_ascii=False, indent=1))
        print(who, name, len(feet), "кадров")


if __name__ == "__main__":
    main()
