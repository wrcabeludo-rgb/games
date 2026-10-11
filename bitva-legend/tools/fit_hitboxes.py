#!/usr/bin/env python3
"""Подбор хитбоксов ударов по кадрам анимации: для активных кадров (hit…hit_end) ищет конечность, вынесенную
вперёд дальше тела, и печатает предлагаемый box [вперёд, низ, ширина, высота] (px игры, 720p) рядом с текущим.

Запуск (из bitva-legend/): python3 tools/fit_hitboxes.py <боец> [удары…]
"""
import json, re, sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SCALE = 0.5


def boxes_from_data(who):
    src = (ROOT / "game/scripts/core/fighter_data.gd").read_text()
    block = src[src.index(f'"{who}": {{'):]
    m = re.search(r'\n\t"[a-z_]+": \{', block[10:])
    block = block[:m.start() + 10] if m else block
    out = {}
    for name, box in re.findall(r'"([a-z_]+)": \{[^\n]*?"box": \[([-\d, ]+)\]', block):
        out[name] = [int(v) for v in box.split(",")]
    body = int(re.search(r'"push_half": (\d+)', block).group(1))
    return out, body


def suggest(who, name, body_half):
    meta = json.loads((ROOT / f"game/art/fighters/{who}/{name}.json").read_text())
    res = float(meta.get("res", 1))
    k = SCALE / res
    fr = meta["frames"]
    h0, h1 = meta.get("hit", 0), meta.get("hit_end", 0) or meta.get("hit", 0)
    if not h0:
        return None
    pts = []
    for f in fr[h0 - 1:h1]:
        a = np.asarray(Image.open(ROOT / f"game/art/fighters/{who}/{f['file']}").getchannel("A")) > 64
        ys, xs = np.nonzero(a)
        gx = (xs - f["pivot"][0]) * k          # вперёд от центра бойца
        gy = (f["pivot"][1] - ys) * k          # вверх от земли
        reach = gx.max()
        if reach <= body_half:
            continue
        # Конечность: всё, что дальше 55 % вылета за тело.
        cut = body_half + (reach - body_half) * 0.45
        sel = gx >= cut
        pts.append((cut, reach, gy[sel].min(), gy[sel].max()))
    if not pts:
        return None
    fwd = int(min(p[0] for p in pts))
    reach = int(max(p[1] for p in pts))
    lo = int(max(0, min(p[2] for p in pts) - 6))
    hi = int(max(p[3] for p in pts) + 6)
    return [fwd, lo, reach - fwd + 6, hi - lo]


def main():
    who = sys.argv[1]
    only = set(sys.argv[2:])
    boxes, body = boxes_from_data(who)
    for name, box in sorted(boxes.items()):
        if only and name not in only:
            continue
        p = ROOT / f"game/art/fighters/{who}/{name}.json"
        if not p.exists():
            continue
        s = suggest(who, name, body)
        print(f"{name:10s} сейчас {box}  по кадрам {s}")


if __name__ == "__main__":
    main()
