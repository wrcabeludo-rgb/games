#!/usr/bin/env python3
"""Обработка спрайтов бойцов (см. docs/ART_FIGHTERS.md).

Берёт листы кадров (как их выдала нейросеть) из art_src/fighters/<боец>/ и кладёт в game/art/fighters/<боец>/:
  <анимация>_<N>.png — кадры без фона, все в одном масштабе;
  <анимация>.json    — опорные точки кадров (ступни на земле) для игры.

Запуск: python3 tools/process_fighter_art.py <боец>        (ilya, dracula)

Лист — кадры одной анимации в ряд (слева направо) на пурпурном фоне. Имя файла = имя анимации
(idle.png, st_lp.png …). Необязательный art_src/fighters/<боец>/sheets.json уточняет обработку:
  {"idle": {"frames": 4, "fit": "stand"}, "st_lp": {"frames": 3, "fit": "inherit:idle"}}
  fit: "stand"        — масштаб по высоте кадров (боец стоит во весь рост): высота = росту бойца;
       "inherit:<лист>" — тот же масштаб, что у другого листа (холсты одной высоты, боец того же размера);
       число           — масштаб вручную.
  pivot_y: "feet" (по умолчанию — низ ступней) или "center" (кадры в воздухе).
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from process_arena_art import chroma_key, split_objects, sharpen  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
# Рост бойца стоя в пикселях 1440p (= рост в игре × 2, см. FighterData "height").
HEIGHT = {"ilya": 600, "dracula": 540}
FEET_BAND = 0.06   # опорная точка по x — центр непрозрачных пикселей в нижних 6% кадра


def frames_of(sheet: Image.Image, expected: int):
    """Кадры листа: по пустому месту между ними; если нейросеть слепила кадры — равными долями."""
    frames = list(split_objects(sheet, min_gap=10))
    if expected and len(frames) != expected:
        print(f"    нашлось кадров {len(frames)}, ждали {expected} — режу на равные доли")
        w = sheet.width / expected
        frames = []
        for i in range(expected):
            cell = sheet.crop((round(i * w), 0, round((i + 1) * w), sheet.height))
            box = cell.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
            frames.append(cell.crop(box) if box else cell)
    return frames


def pivot(frame: Image.Image, mode: str):
    """Опорная точка: x — центр ступней (или всего кадра), y — низ ступней (или центр)."""
    a = np.asarray(frame.getchannel("A")) > 24
    ys, xs = np.where(a)
    if len(xs) == 0:
        return frame.width / 2, frame.height
    if mode == "center":
        return float(xs.mean()), float(ys.mean())
    bottom = ys.max()
    band = ys >= bottom - max(2, int(frame.height * FEET_BAND))
    return float(xs[band].mean()), float(bottom)


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in HEIGHT:
        print(__doc__)
        return 1
    who = sys.argv[1]
    src = ROOT / "art_src" / "fighters" / who
    out = ROOT / "game" / "art" / "fighters" / who
    out.mkdir(parents=True, exist_ok=True)
    cfg_path = src / "sheets.json"
    cfg = json.loads(cfg_path.read_text()) if cfg_path.exists() else {}
    sheets = sorted(p for p in src.iterdir() if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp")
                    and not p.stem.startswith("model"))
    # Сначала листы с собственным масштабом, потом наследующие.
    sheets.sort(key=lambda p: str(cfg.get(p.stem, {}).get("fit", "stand")).startswith("inherit"))
    scales = {}       # масштаб листа
    heights = {}      # высота исходного листа — для наследования масштаба
    for p in sheets:
        name = p.stem
        opt = cfg.get(name, {})
        raw = Image.open(p)
        heights[name] = raw.height
        frames = frames_of(chroma_key(raw), opt.get("frames", 0))
        fit = opt.get("fit", "stand")
        if isinstance(fit, (int, float)):
            scale = float(fit)
        elif str(fit).startswith("inherit:"):
            base = fit.split(":", 1)[1]
            if base not in scales:
                print(f"  {name}: нет листа {base} для масштаба — пропускаю")
                continue
            scale = scales[base] * heights[base] / raw.height
        else:
            scale = HEIGHT[who] / float(np.median([f.height for f in frames]))
        scales[name] = scale
        meta = {"frames": []}
        for i, f in enumerate(frames, 1):
            f = f.resize((max(1, round(f.width * scale)), max(1, round(f.height * scale))), Image.LANCZOS)
            f = sharpen(f)
            px, py = pivot(f, opt.get("pivot_y", "feet"))
            f.save(out / f"{name}_{i}.png", optimize=True)
            meta["frames"].append({"file": f"{name}_{i}.png", "pivot": [round(px), round(py)],
                                   "size": [f.width, f.height]})
        (out / f"{name}.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
        print(f"  {name}: {len(frames)} кадр(ов), масштаб {scale:.3f}")
    print(f"Готово. Папка: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
