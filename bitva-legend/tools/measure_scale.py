#!/usr/bin/env python3
"""Проверка единого масштаба бойца: голова из стойки ищется на каждом кадре в разных масштабах
(нормированная корреляция). Масштаб, при котором голова совпала лучше всего, — во сколько раз
боец на этом кадре крупнее стойки. У всех анимаций медиана должна быть ≈ 1.00.
Запуск: python3 tools/measure_scale.py <боец> [анимации…]"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "game" / "art" / "fighters"
DOWN = 3  # считаем на уменьшенных в 3 раза картинках
THRESH = float(__import__("os").environ.get("THRESH", "0.55"))  # порог совпадения


def gray(img: Image.Image) -> np.ndarray:
    bg = Image.new("RGBA", img.size, (128, 128, 128, 255))
    bg.alpha_composite(img.convert("RGBA"))
    return np.asarray(bg.convert("L")).astype(np.float32)


WHO = "ilya"


def head_box(img: Image.Image):
    """Опорная точка головы: у Ильи — верх бороды, у Дракулы — верх бледного лица."""
    a = np.asarray(img.convert("RGBA")).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    if WHO == "dracula":
        beard = (r > 190) & (g > 170) & (b > 140) & (r - b < 60) & (r - b > 5) & (al > 200)
    else:
        beard = (r > 140) & (g > 70) & (g < 140) & (b < 70) & (r - g > 50) & (al > 200)
    ys, xs = np.where(beard)
    if len(ys) < 50:
        return None
    top = int(np.percentile(ys, 1))
    cx = int(xs[ys < top + 25].mean())
    return cx, top


def ncc_best(region: np.ndarray, tpl: np.ndarray) -> float:
    th, tw = tpl.shape
    rh, rw = region.shape
    if th >= rh or tw >= rw:
        return -1.0
    t = tpl - tpl.mean()
    tn = np.sqrt((t * t).sum()) + 1e-6
    win = np.lib.stride_tricks.sliding_window_view(region, (th, tw))
    wm = win.mean(axis=(2, 3), keepdims=True)
    w = win - wm
    num = (w * t).sum(axis=(2, 3))
    den = np.sqrt((w * w).sum(axis=(2, 3))) * tn + 1e-6
    return float((num / den).max())


def template(who: str):
    m = json.loads((ROOT / who / "idle.json").read_text())
    im = Image.open(ROOT / who / m["frames"][0]["file"])
    cx, top = head_box(im)
    if WHO == "dracula":
        return gray(im.crop((cx - 70, top - 40, cx + 60, top + 90)))
    return gray(im.crop((cx - 100, top - 100, cx + 60, top + 30)))


def scale_of(path: Path, tpl: np.ndarray):
    im = Image.open(path)
    hb = head_box(im)
    if hb is None:
        return None
    cx, top = hb
    region = gray(im.crop((cx - 240, top - 230, cx + 200, top + 160)))
    reg = np.asarray(Image.fromarray(region).resize((region.shape[1] // DOWN, region.shape[0] // DOWN)))
    best = (-1.0, None)
    for s in np.arange(0.70, 1.45, 0.025):
        t = Image.fromarray(tpl)
        t = t.resize((max(4, round(t.width * s / DOWN)), max(4, round(t.height * s / DOWN))))
        sc = ncc_best(reg, np.asarray(t))
        if sc > best[0]:
            best = (sc, s)
    return best[1] if best[0] > THRESH else None


if __name__ == "__main__":
    who = sys.argv[1] if len(sys.argv) > 1 else "ilya"
    WHO = who
    tpl = template(who)
    names = sys.argv[2:] or sorted(p.stem for p in (ROOT / who).glob("*.json"))
    for a in names:
        m = json.loads((ROOT / who / f"{a}.json").read_text())
        v = [scale_of(ROOT / who / f["file"], tpl) for f in m["frames"]]
        vals = [x for x in v if x]
        med = float(np.median(vals)) if vals else 0
        print(f"{a:10s} медиана {med:4.2f}   " + " ".join(f"{x:.2f}" if x else " -  " for x in v))
