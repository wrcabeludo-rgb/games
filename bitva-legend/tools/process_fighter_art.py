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
       "h:<кадр>:<px>"   — кадр № <кадр> высотой <px> (1440p): для приседа, блока, прыжка;
       число           — масштаб вручную.
  grid: [столбцов, рядов] — лист сеткой (8 кадров = [4, 2], 12 = [4, 3]); порядок — слева направо, сверху вниз.
  reverse: true — проигрывать задом наперёд (шаг назад, нарисованный как шаг вперёд).
  hit / hit_end: номера ударных кадров (с 1) — показываются в активной фазе удара; до них — замах, после — возврат.
  skip: [номера кадров с 1] — выбросить бракованные кадры.
  pivot_y "bottom_center" — центр по ширине, низ кадра (лёжа, в полёте).
  part_frames: сколько кадров в каждой части (лист прислан частями <имя>_p1, <имя>_p2, …).
  pivot_y: "feet" (по умолчанию — задняя ступня стоит на месте), "body" (по центру фигуры — ходьба, бег)
           или "center" (кадры в воздухе).
"""
import json
import re
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


def frames_of(sheet: Image.Image, expected: int, grid=None):
    """Кадры листа (слева направо, сверху вниз): по пустому месту между ними. Если нейросеть нарисовала
    кадры вплотную — режем каждый ряд по самым «тонким» столбцам возле равных долей и чистим чужие обрезки.
    grid = [столбцов, рядов] — для листов сеткой (8 кадров = 4 × 2, 12 = 4 × 3)."""
    frames = list(split_objects(sheet, min_gap=10))
    if not expected or len(frames) == expected:
        return frames
    cols, rows = grid if grid else (expected, 1)
    print(f"    кадры касаются друг друга ({len(frames)} вместо {expected}) — режу сеткой {cols}×{rows} по тонким местам")
    alpha_rows = np.asarray(sheet.getchannel("A")) > 24
    lines = alpha_rows.sum(axis=1).astype(np.float32)
    hstep = sheet.height / rows
    ycuts = [0]
    for r in range(1, rows):
        lo, hi = int(r * hstep - hstep * 0.2), int(r * hstep + hstep * 0.2)
        ycuts.append(lo + int(np.argmin(lines[lo:hi])))
    ycuts.append(sheet.height)
    out = []
    for r in range(rows):
        band = sheet.crop((0, ycuts[r], sheet.width, ycuts[r + 1]))
        cols_sum = (np.asarray(band.getchannel("A")) > 24).sum(axis=0).astype(np.float32)
        w = band.width / cols
        cuts = [0]
        for i in range(1, cols):
            lo, hi = int(i * w - w * 0.2), int(i * w + w * 0.2)
            cuts.append(lo + int(np.argmin(cols_sum[lo:hi])))
        cuts.append(band.width)
        for i in range(cols):
            if len(out) == expected:
                break
            cell = _keep_main(band.crop((cuts[i], 0, cuts[i + 1], band.height)))
            box = cell.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
            if box:
                out.append(cell.crop(box))
    return out


def _keep_main(cell: Image.Image, step: int = 4) -> Image.Image:
    """Оставить в клетке только главный объект (самое большое связное пятно и всё, что к нему примыкает);
    обрезки соседних кадров — убрать. Поиск — по уменьшенной в step раз маске."""
    a = np.asarray(cell.getchannel("A")) > 24
    small = a[::step, ::step]
    h, w = small.shape
    label = np.zeros((h, w), dtype=np.int32)
    sizes = [0]
    for y0 in range(h):
        for x0 in range(w):
            if not small[y0, x0] or label[y0, x0]:
                continue
            n = len(sizes)
            stack = [(y0, x0)]
            label[y0, x0] = n
            size = 0
            while stack:
                y, x = stack.pop()
                size += 1
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and small[yy, xx] and not label[yy, xx]:
                        label[yy, xx] = n
                        stack.append((yy, xx))
            sizes.append(size)
    if len(sizes) <= 2:
        return cell
    main = int(np.argmax(sizes))
    # Мелкие отдельные пятна рядом с главным (линии скорости, кончик плаща) оставляем, если они
    # не у края клетки — у края это обрезки соседей.
    keep = label == main
    for n in range(1, len(sizes)):
        if n == main:
            continue
        ys, xs = np.where(label == n)
        if xs.min() > 1 and xs.max() < w - 2:
            keep |= label == n
    mask = np.kron(keep, np.ones((step, step), dtype=bool))[: a.shape[0], : a.shape[1]]
    arr = np.asarray(cell).copy()
    arr[..., 3] = np.where(mask, arr[..., 3], 0)
    return Image.fromarray(arr, "RGBA")


def feet(frame: Image.Image):
    """Задняя ступня (левый край ступней — боец смотрит вправо), центр ступней и низ ступней."""
    a = np.asarray(frame.getchannel("A")) > 24
    ys, xs = np.where(a)
    if len(xs) == 0:
        return frame.width / 2, frame.width / 2, frame.height
    bottom = ys.max()
    band = xs[ys >= bottom - max(2, int(frame.height * FEET_BAND))]
    return float(np.percentile(band, 2)), float(band.mean()), float(bottom)


def centroid(frame: Image.Image):
    a = np.asarray(frame.getchannel("A")) > 24
    ys, xs = np.where(a)
    return float(xs.mean()), float(ys.mean())


def pivot(frame: Image.Image, mode: str, ref: dict):
    """Опорная точка = центр бойца на земле.
    feet — кадры привязаны к задней ступне (она стоит на месте, пока боец бьёт), центр — правее её
           на столько же, сколько в стойке;
    body — привязка по центру масс фигуры (ходьба, бег, отскок: ступни не стоят на месте),
           смещение до «центра на земле» — как в стойке;
    center — центр кадра (в воздухе)."""
    if mode == "bottom_center":
        a = np.asarray(frame.getchannel("A")) > 24
        ys, xs = np.where(a)
        return float((xs.min() + xs.max()) / 2), float(ys.max())
    if mode == "center":
        return centroid(frame)
    if mode == "body":
        cx, cy = centroid(frame)
        return cx + ref["body_dx"], cy + ref["body_dy"]
    rear, _, bottom = feet(frame)
    return rear + ref["center_offset"], bottom


def _fit_scale(fit, frames, who) -> float:
    """Масштаб части по правилу fit: число или "h:<кадр>:<px>" (кадр с 1 внутри части)."""
    if isinstance(fit, (int, float)):
        return float(fit)
    _, idx, px = str(fit).split(":")
    return float(px) / frames[int(idx) - 1].height


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
    files = sorted(p for p in src.iterdir() if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp")
                   and not p.stem.startswith(("model", "old_")))
    # Длинную анимацию можно прислать частями: idle_p1, idle_p2, … — кадры склеятся по порядку.
    parts = {}
    for f in files:
        m = re.match(r"^(.*)_p(\d+)$", f.stem)
        parts.setdefault(m.group(1) if m else f.stem, []).append((int(m.group(2)) if m else 0, f))
    sheets = [Path(name) for name in parts]
    # Сначала стойка (по ней — центр бойца), потом листы с собственным масштабом, потом наследующие.
    sheets.sort(key=lambda p: (p.stem != "idle", str(cfg.get(p.stem, {}).get("fit", "stand")).startswith("inherit")))
    ref = None  # по первому кадру стойки: от задней ступни и от центра масс до центра бойца на земле
    scales = {}       # масштаб листа
    heights = {}      # высота исходного листа — для наследования масштаба
    for p in sheets:
        name = p.stem
        opt = cfg.get(name, {})
        group = [f for _, f in sorted(parts[name])]
        raw = Image.open(group[0])
        heights[name] = raw.height
        if len(group) == 1:
            frames = frames_of(chroma_key(raw), opt.get("frames", 0), opt.get("grid"))
        else:
            # Части могут прийти в разном разрешении: у каждой — свой масштаб (parts_fit, как fit),
            # тогда общий масштаб листа — 1.
            frames = []
            pf = opt.get("part_frames", 0)
            for i, f in enumerate(group):
                n = pf[i] if isinstance(pf, list) else pf
                part = frames_of(chroma_key(Image.open(f)), n, opt.get("grid"))
                if "parts_fit" in opt:
                    k = _fit_scale(opt["parts_fit"][i], part, who)
                    part = [x.resize((max(1, round(x.width * k)), max(1, round(x.height * k))), Image.LANCZOS)
                            for x in part]
                frames += part
        # Бракованные кадры (лишняя рука и т. п.) можно выбросить: "skip": [3] — номера с 1.
        if opt.get("skip"):
            frames = [f for i, f in enumerate(frames, 1) if i not in opt["skip"]]
        # Порядок кадров после пропуска: "order": [1, 2, 4, 3] (номера с 1).
        if opt.get("order"):
            frames = [frames[i - 1] for i in opt["order"]]
        if "parts_fit" in opt:
            opt = dict(opt, fit=1.0)
        fit = opt.get("fit", "stand")
        if isinstance(fit, (int, float)):
            scale = float(fit)
        elif str(fit).startswith("h:"):
            # h:<кадр>:<px> — кадр № такой-то должен быть такой высоты (присед, блок с поднятой палицей…).
            _, idx, px = str(fit).split(":")
            scale = float(px) / frames[int(idx) - 1].height
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
        # Ударные кадры (с 1): hit — первый кадр активной фазы, hit_end — последний.
        for k in ("hit", "hit_end", "reverse", "air_frames"):
            if k in opt:
                meta[k] = opt[k]
        for i, f in enumerate(frames, 1):
            f = f.resize((max(1, round(f.width * scale)), max(1, round(f.height * scale))), Image.LANCZOS)
            f = sharpen(f)
            if ref is None:
                rear, mid, bottom = feet(f)
                cx, cy = centroid(f)
                ref = {"center_offset": mid - rear, "body_dx": mid - cx, "body_dy": bottom - cy}
            px, py = pivot(f, opt.get("pivot_y", "feet"), ref)
            f.save(out / f"{name}_{i}.png", optimize=True)
            meta["frames"].append({"file": f"{name}_{i}.png", "pivot": [round(px), round(py)],
                                   "size": [f.width, f.height]})
        (out / f"{name}.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
        print(f"  {name}: {len(frames)} кадр(ов), масштаб {scale:.3f}")
    print(f"Готово. Папка: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
