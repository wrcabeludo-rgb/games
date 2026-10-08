#!/usr/bin/env python3
"""Обработка арта арены «Перекрёсток миров» (см. docs/ART_ARENA.md).

Берёт картинки из папки (как их выдала нейросеть) и кладёт готовые слои в game/art/arena/:
  - убирает пурпурный фон #FF00FF (хромакей) и пурпурную кайму по краям;
  - режет листы (тучи, вороны) на отдельные объекты по пустому месту между ними и обрезает поля;
  - приводит размеры к нужным для 1080p.

Запуск: python3 tools/process_arena_art.py <папка с исходниками>
Ожидаемые имена: sky, moon, clouds, mountains, forest, stone, ground, foreground, ravens (.png/.jpg/.webp).
Полосу (mountains, forest, ground, foreground) можно прислать панелями: forest_1, forest_2, forest_3 — склеятся.
Отсутствующие слои пропускаются — в игре вместо них останутся заглушки.
"""
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

# Куда класть результат (ART_OUT — для проверок, по умолчанию — в игру).
OUT = Path(os.environ.get("ART_OUT", Path(__file__).resolve().parent.parent / "game" / "art" / "arena"))
KEY = np.array([255, 0, 255], dtype=np.float32)
M_SAFE = 45.0      # «пурпурность» до этого — полностью непрозрачно
M_FULL = 200.0     # от этого — полностью прозрачно, между — плавный край
EDGE_PX = 10       # ширина полосы у краёв, где убирается пурпурный отсвет (нейросеть подкрашивает края)

# Ширина слоёв в пикселях 1080p (= ширина слоя в игре × 1.5, см. ArenaScenery.layer_w).
SKY_SIZE = (1980, 1080)
# Полосы — в двойном разрешении 720p (= 1440p): на большом мониторе во весь экран не мылятся.
# Лес шире слоя: в игре он рисуется крупнее, края уходят за кадр (см. ArenaScenery.FOREST_HEIGHT).
STRIP_WIDTH = {"mountains": 2704, "forest": 6000, "ground": 4000, "foreground": 4432}
MOON_SIZE = 320
STONE_HEIGHT = 300
CLOUD_MAX_WIDTH = 720
RAVEN_HEIGHT = 220


def find(src: Path, name: str):
    for ext in (".png", ".jpg", ".jpeg", ".webp"):
        p = src / (name + ext)
        if p.exists():
            return p
    return None


def chroma_key(img: Image.Image) -> Image.Image:
    """Прозрачность по «пурпурности» m = min(R, B) − G: у фона ≈ 250, у обычных цветов ≤ 0,
    у тёмно-фиолетовой коры ≈ 20–40 (остаётся непрозрачной). На краях цвет «отмешивается»
    от пурпурного, чтобы не было розового ореола."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    m = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    alpha = np.clip((M_FULL - m) / (M_FULL - M_SAFE), 0.0, 1.0)
    a = np.maximum(alpha, 0.05)[..., None]
    fg = (rgb - (1.0 - alpha[..., None]) * KEY) / a
    # Сжатие (webp/jpeg) размазывает пурпурный на соседние пиксели: в полосе EDGE_PX у краёв
    # убираем пурпурный оттенок совсем (R и B не выше G). Внутри объектов цвета не трогаем.
    edge = _dilate(alpha < 0.99, EDGE_PX)
    tint = np.maximum(np.minimum(fg[..., 0], fg[..., 2]) - fg[..., 1], 0) * edge
    fg[..., 0] -= tint
    fg[..., 2] -= tint
    # Яркий розовый отсвет (красный ≫ зелёного, синий не ниже зелёного) у краёв → тёплый оранжевый.
    # Тёмную фиолетовую кору (R < 140) не трогаем.
    r, g, b = fg[..., 0], fg[..., 1], fg[..., 2]
    pink = edge & (r > 140) & (r > g * 1.3) & (b > g * 0.7) & (b > 80)  # чистый красный (мало синего) не трогаем
    fg[..., 2] = np.where(pink, np.minimum(b, g * 0.55), b)
    fg[..., 1] = np.where(pink, np.maximum(g, r * 0.62), g)
    fg = np.clip(fg, 0, 255)
    # Полупрозрачный край берёт цвет ближайших непрозрачных соседей изнутри:
    # смесь «жёлтая листва + пурпур» иначе остаётся розовой каймой.
    fg = _bleed_inside_color(fg, alpha)
    fg[alpha <= 0] = 0
    out = np.dstack([fg, alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def _bleed_inside_color(fg: np.ndarray, alpha: np.ndarray, steps: int = 4) -> np.ndarray:
    known = alpha >= 0.99
    col = fg.copy()
    for _ in range(steps):
        acc = np.zeros_like(col)
        cnt = np.zeros(alpha.shape, dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            shifted_known = np.roll(known, (dy, dx), axis=(0, 1))
            shifted_col = np.roll(col, (dy, dx), axis=(0, 1))
            acc += shifted_col * shifted_known[..., None]
            cnt += shifted_known
        new = (~known) & (cnt > 0) & (alpha > 0)
        col[new] = acc[new] / cnt[new][:, None]
        known = known | new
    return col


def strip_outline(img: Image.Image, band: int = 7, luma_max: float = 120.0) -> Image.Image:
    """Убрать тёмный контур по краю (тучи без обводки): тёмные пиксели у края становятся прозрачными,
    край смягчается."""
    a = np.asarray(img).astype(np.float32)
    alpha = a[..., 3] / 255.0
    luma = a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11
    near_edge = _dilate(alpha < 0.99, band)
    dark = near_edge & (luma < luma_max)
    alpha = np.where(dark, 0.0, alpha)
    # Мягкий край: полупрозрачная кромка в 1 px.
    soft = _dilate(alpha < 0.5, 1) & (alpha >= 0.5)
    alpha = np.where(soft, alpha * 0.55, alpha)
    a[..., 3] = alpha * 255
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def sharpen(img: Image.Image) -> Image.Image:
    """Чуть резче (нейросеть даёт мягкие текстуры); прозрачность не трогаем."""
    rgb = img.convert("RGB").filter(ImageFilter.UnsharpMask(radius=2, percent=90, threshold=2))
    out = rgb.convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out


def _dilate(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(r):
        grown = out.copy()
        grown[1:, :] |= out[:-1, :]
        grown[:-1, :] |= out[1:, :]
        grown[:, 1:] |= out[:, :-1]
        grown[:, :-1] |= out[:, 1:]
        out = grown
    return out


def trim(img: Image.Image, pad: int = 4) -> Image.Image:
    box = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if box is None:
        return img
    l, t, r, b = box
    return img.crop((max(l - pad, 0), max(t - pad, 0), min(r + pad, img.width), min(b + pad, img.height)))


def trim_vertical(img: Image.Image) -> Image.Image:
    box = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if box is None:
        return img
    return img.crop((0, box[1], img.width, box[3]))


def resize_w(img: Image.Image, w: int) -> Image.Image:
    return img.resize((w, max(1, round(img.height * w / img.width))), Image.LANCZOS)


def resize_h(img: Image.Image, h: int) -> Image.Image:
    return img.resize((max(1, round(img.width * h / img.height)), h), Image.LANCZOS)


def cover(img: Image.Image, size) -> Image.Image:
    """Заполнить size целиком, обрезав лишнее: по ширине — по центру, по высоте — сверху
    (низ с горизонтом и солнцем сохраняется)."""
    tw, th = size
    k = max(tw / img.width, th / img.height)
    img = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
    l = (img.width - tw) // 2
    t = img.height - th
    return img.crop((l, t, l + tw, t + th))


def _runs(filled: np.ndarray, min_gap: int):
    """Отрезки подряд идущих True, разделённые не меньше чем min_gap пустыми."""
    runs, start, gap = [], None, 0
    for i, v in enumerate(filled):
        if v:
            if start is None:
                start = i
            gap = 0
            end = i
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                runs.append((start, end + 1))
                start = None
    if start is not None:
        runs.append((start, end + 1))
    return runs


def split_objects(img: Image.Image, min_gap: int = 12, min_share: float = 0.002):
    """Отдельные объекты листа (тучи, кадры ворона): сначала ряды по пустым полосам,
    в каждом ряду — объекты по пустым столбцам. Нейросеть не всегда попадает в клетки сетки,
    поэтому режем по пустому месту между объектами. Порядок — слева направо, сверху вниз."""
    alpha = np.asarray(img.getchannel("A")) > 24
    total = alpha.size
    for top, bottom in _runs(alpha.any(axis=1), min_gap):
        band = alpha[top:bottom]
        for left, right in _runs(band.any(axis=0), min_gap):
            if band[:, left:right].sum() < total * min_share:
                continue  # пылинка
            yield trim(img.crop((left, top, right, bottom)))


def _eye(img: Image.Image):
    """Центр жёлтого глаза ворона (или центр картинки, если глаз не найден)."""
    a = np.asarray(img).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    ys, xs = np.where((r > 190) & (g > 140) & (b < 90) & (al > 200))
    if len(xs) == 0:
        return img.width / 2, img.height / 2
    return float(xs.mean()), float(ys.mean())


def align_by_eye(frames):
    """Кадры анимации на общем холсте так, чтобы глаз был в одной точке: тело не дрожит, двигаются крылья."""
    eyes = [_eye(f) for f in frames]
    left = max(e[0] for e in eyes)
    top = max(e[1] for e in eyes)
    right = max(f.width - e[0] for f, e in zip(frames, eyes))
    bottom = max(f.height - e[1] for f, e in zip(frames, eyes))
    size = (round(left + right), round(top + bottom))
    out = []
    for f, (ex, ey) in zip(frames, eyes):
        canvas = Image.new("RGBA", size, (0, 0, 0, 0))
        canvas.paste(f, (round(left - ex), round(top - ey)))
        out.append(canvas)
    return out


def stitch(panels):
    """Панели одной полосы — встык слева направо, низом (линией земли) на одном уровне."""
    parts = [p.crop(p.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox() or (0, 0, p.width, p.height))
             for p in panels]
    height = max(p.height for p in parts)
    out = Image.new("RGBA", (sum(p.width for p in parts), height), (0, 0, 0, 0))
    x = 0
    for p in parts:
        out.alpha_composite(p, (x, height - p.height))
        x += p.width
    return out


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / (name + ".png"), optimize=True)
    print(f"  {name}.png  {img.width}×{img.height}")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 1
    src = Path(sys.argv[1])
    done = 0
    if p := find(src, "sky"):
        save(cover(Image.open(p).convert("RGB"), SKY_SIZE), "sky")
        done += 1
    if p := find(src, "moon"):
        moon = trim(chroma_key(Image.open(p)))
        save(moon.resize((MOON_SIZE, MOON_SIZE), Image.LANCZOS), "moon")
        done += 1
    for name, width in STRIP_WIDTH.items():
        # Полосу можно прислать панелями name_1, name_2, … (слева направо) — склеим в одну.
        panels = [q for i in range(1, 7) if (q := find(src, f"{name}_{i}"))]
        if panels:
            strip = stitch([chroma_key(Image.open(q)) for q in panels])
        elif p := find(src, name):
            strip = chroma_key(Image.open(p))
        else:
            continue
        strip = trim_vertical(strip)
        if strip.width > width:
            strip = resize_w(strip, width)
        save(sharpen(strip), name)
        done += 1
    if p := find(src, "stone"):
        save(resize_h(trim(chroma_key(Image.open(p))), STONE_HEIGHT), "stone")
        done += 1
    if p := find(src, "clouds"):
        for i, cloud in enumerate(split_objects(strip_outline(chroma_key(Image.open(p)))), 1):
            if cloud.width > CLOUD_MAX_WIDTH:
                cloud = resize_w(cloud, CLOUD_MAX_WIDTH)
            save(cloud, f"cloud_{i}")
        done += 1
    if p := find(src, "ravens"):
        for i, frame in enumerate(align_by_eye(list(split_objects(chroma_key(Image.open(p))))), 1):
            save(resize_h(frame, RAVEN_HEIGHT), f"raven_{i}")
        done += 1
    print(f"Готово слоёв: {done}. Папка: {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
