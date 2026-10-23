#!/usr/bin/env python3
"""Проверка анимаций в бою: прогоняет демо-сценарий (tests/_anim_probe.gd) и по каждому тику считает, где у
бойца ступни относительно земли и не дёргается ли фигура.

Запуск (из bitva-legend/): python3 tools/anim_audit.py <сценарий> <a,b> <тиков> [meter] [hp] [wins]
Печатает подозрительные отрезки: «висит» (на земле по игре, а рисунок выше земли), «вкопан» (ниже),
«рывок» (центр фигуры прыгнул по экрану, а боец почти не сдвинулся).
"""
import json, subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GODOT = str(Path.home() / "godot/Godot_v4.4.1-stable_linux.x86_64")
SCALE = 0.5
GROUND_STATES = {"STAND", "WALK_F", "WALK_B", "CROUCH", "ATTACK", "BLOCK", "BLOCKSTUN", "HITSTUN", "THROWING",
                 "RUN", "RUN_STOP", "LAND", "DOWN", "KNOCKDOWN", "PREJUMP", "BACKDASH"}
_cache = {}
_res = {}


def shape(path, px):
    """Фигура бойца в кадре (в парной сцене — та, что ближе к опорной точке): её низ и середина ступней."""
    key = (path, round(px))
    if key not in _cache:
        a = np.asarray(Image.open(ROOT / "game" / path.replace("res://", "")).convert("RGBA"))[..., 3] > 128
        cols = np.nonzero(a.sum(0) > 2)[0]
        if len(cols) == 0:
            _cache[key] = (0, px)
            return _cache[key]
        runs, s0, pv = [], cols[0], cols[0]
        for c in cols[1:]:
            if c > pv + 24:
                runs.append((s0, pv)); s0 = c
            pv = c
        runs.append((s0, pv))
        x0, x1 = min(runs, key=lambda r: 0 if r[0] <= px <= r[1] else min(abs(r[0] - px), abs(r[1] - px)))
        band = a[:, x0:x1 + 1]
        ys = np.nonzero(band.any(1))[0]
        bottom = ys.max()
        low = band[max(bottom - max((bottom - ys.min()) // 10, 6), 0):bottom + 1]
        fx = np.nonzero(low.any(0))[0]
        _cache[key] = (bottom, x0 + (fx.min() + fx.max()) / 2)
    return _cache[key]


def res(who):
    if who not in _res:
        j = json.loads((ROOT / f"game/art/fighters/{who}/idle.json").read_text())
        _res[who] = float(j.get("res", 1))
    return _res[who]


def main():
    args = sys.argv[1:]
    out = subprocess.run([GODOT, "--headless", "--path", str(ROOT / "game"), "--script", "res://tests/_anim_probe.gd",
                          "--"] + args, capture_output=True, text=True).stdout
    rows = [l.split("|")[1:] for l in out.splitlines() if l.startswith("P|")]
    prev = {}
    issues = []
    for r in rows:
        tick, p, state, x, y, facing, dface, path, px, py, hidden, phase, lift = r
        tick, p, x, y, dface, px, py, hidden, lift = int(tick), int(p), int(x), int(y), int(dface), float(px), float(py), int(hidden), int(lift)
        if hidden or not path:
            prev.pop(p, None)
            continue
        who = path.split("/")[-2]
        k = SCALE / res(who)
        bottom, feet = shape(path, px)
        anim = path.split("/")[-1].rsplit("_", 1)[0]
        gap = y + lift + (py - bottom) * k            # px игры: + выше земли, − ниже
        cx = x + dface * (feet - px) * k                # середина ступней на экране
        pair = anim.startswith(("pair_", "finisher_"))
        if state in GROUND_STATES and y == 0 and abs(gap) > 10 and lift == 0:
            issues.append((tick, p, "висит" if gap > 0 else "вкопан", state, anim, round(gap)))
        if p in prev:
            pt, pcx, px_, panim = prev[p]
            if tick == pt + 1 and abs(cx - pcx) > 40 and abs(x - px_) < 20:
                issues.append((tick, p, "рывок", state, f"{panim}→{anim}", round(cx - pcx)))
        prev[p] = (tick, cx, x, anim)
    # Склеить подряд идущие одинаковые замечания в отрезки.
    merged = []
    for it in issues:
        if merged and tuple(merged[-1][1:5]) == tuple(it[1:5]) and it[0] - merged[-1][-1] <= 2:
            merged[-1][-1] = it[0]
            merged[-1][5] = max(merged[-1][5], it[5], key=abs)
        else:
            merged.append(list(it) + [it[0]])
    for m in merged:
        print(f"тик {m[0]}–{m[6]} боец {m[1]}: {m[2]:6} {m[3]:10} {m[4]:28} {m[5]:+d} px")
    print(f"всего тиков {len(rows)//2}, замечаний {len(merged)}")


if __name__ == "__main__":
    main()
