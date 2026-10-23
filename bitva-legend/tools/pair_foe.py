#!/usr/bin/env python3
"""Лежащий соперник из последнего кадра парной сцены — отдельной картинкой.

Когда ролик парной сцены кончается, игра снова рисует соперника его спрайтом, а поза спрайта (плащ раскинут,
руки в стороны) не та, что в ролике. Чтобы не было подмены, игра несколько тиков плавно перетекает из лежащего
в ролике в спрайт (`arena_view._draw_pair_foe`). Скрипт вырезает лежащего из последнего кадра листа:
все связные области, кроме той, где опорная точка (это бросивший), → `<лист>_foe.png`, в json листа —
`"foe": {"file", "pivot"}` (опорная точка в координатах вырезки, та же, что у кадра).

Запуск (из bitva-legend/): python3 tools/pair_foe.py <боец> <лист> [<лист> …]
Запускать ПОСЛЕ process_fighter_art.py / foe_ground.py / add_feet.py (они перезаписывают кадры и json).
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from foe_ground import components  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    who = sys.argv[1]
    folder = ROOT / "game/art/fighters" / who
    for name in sys.argv[2:]:
        meta = json.loads((folder / f"{name}.json").read_text())
        fr = meta["frames"][-1]
        im = np.array(Image.open(folder / fr["file"]).convert("RGBA"))
        px, py = fr["pivot"]
        masks = components(im[:, :, 3])
        # Бросивший — область, ближайшая по горизонтали к опорной точке.
        def dist(m):
            xs = np.where(m.any(0))[0]
            return 0 if xs.min() <= px <= xs.max() else min(abs(xs.min() - px), abs(xs.max() - px))
        thrower = min(masks, key=dist)
        foe = np.zeros(im.shape[:2], bool)
        for m in masks:
            if m is not thrower:
                foe |= m
        if not foe.any():
            print(f"  {name}: соперника в последнем кадре нет")
            continue
        out = np.where(foe[:, :, None], im, 0).astype(np.uint8)
        ys, xs = np.where(foe)
        box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
        Image.fromarray(out).crop(box).save(folder / f"{name}_foe.png", optimize=True)
        meta["foe"] = {"file": f"{name}_foe.png", "pivot": [px - box[0], py - box[1]]}
        (folder / f"{name}.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
        print(f"  {name}: соперник {box[2] - box[0]}×{box[3] - box[1]} → {name}_foe.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
