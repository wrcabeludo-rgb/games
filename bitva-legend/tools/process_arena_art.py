#!/usr/bin/env python3
"""Обработка арта арены «Перекрёсток миров» (см. docs/ART_ARENA.md).

Берёт картинки из папки (как их выдала нейросеть) и кладёт готовые слои в game/art/arena/:
  - убирает пурпурный фон #FF00FF (хромакей) и пурпурную кайму по краям;
  - режет листы 3×2 (тучи, вороны) на отдельные картинки и обрезает пустые поля;
  - приводит размеры к нужным для 1080p.

Запуск: python3 tools/process_arena_art.py <папка с исходниками>
Ожидаемые имена: sky, moon, clouds, mountains, forest, stone, ground, foreground, ravens (.png/.jpg/.webp).
Отсутствующие слои пропускаются — в игре вместо них останутся заглушки.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "game" / "art" / "arena"
KEY = np.array([255, 0, 255], dtype=np.float32)
KEY_FULL = 90.0    # ближе к пурпурному — полностью прозрачно
KEY_EDGE = 170.0   # дальше — полностью непрозрачно, между — плавный край

# Ширина слоёв в пикселях 1080p (= ширина слоя в игре × 1.5, см. ArenaScenery.layer_w).
SKY_SIZE = (1980, 1080)
STRIP_WIDTH = {"mountains": 2200, "forest": 2520, "ground": 3000, "foreground": 3330}
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
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    dist = np.sqrt(((rgb - KEY) ** 2).sum(axis=2))
    alpha = np.clip((dist - KEY_FULL) / (KEY_EDGE - KEY_FULL), 0.0, 1.0)
    # Убираем пурпурный отсвет на краях: красный и синий не выше зелёного + запас.
    edge = alpha < 1.0
    g = rgb[..., 1]
    for ch in (0, 2):
        rgb[..., ch] = np.where(edge, np.minimum(rgb[..., ch], g + 40), rgb[..., ch])
    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


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
    """Заполнить size целиком, обрезав лишнее по центру."""
    tw, th = size
    k = max(tw / img.width, th / img.height)
    img = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
    l = (img.width - tw) // 2
    t = (img.height - th) // 2
    return img.crop((l, t, l + tw, t + th))


def grid(img: Image.Image, cols: int = 3, rows: int = 2):
    cw, ch = img.width / cols, img.height / rows
    for r in range(rows):
        for c in range(cols):
            yield img.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))


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
        if p := find(src, name):
            save(resize_w(trim_vertical(chroma_key(Image.open(p))), width), name)
            done += 1
    if p := find(src, "stone"):
        save(resize_h(trim(chroma_key(Image.open(p))), STONE_HEIGHT), "stone")
        done += 1
    if p := find(src, "clouds"):
        for i, cell in enumerate(grid(chroma_key(Image.open(p))), 1):
            cloud = trim(cell)
            if cloud.width > CLOUD_MAX_WIDTH:
                cloud = resize_w(cloud, CLOUD_MAX_WIDTH)
            save(cloud, f"cloud_{i}")
        done += 1
    if p := find(src, "ravens"):
        # Кадры одной высоты, чтобы ворон не «прыгал» при взмахах.
        frames = [trim(cell) for cell in grid(chroma_key(Image.open(p)))]
        tallest = max(f.height for f in frames)
        for i, f in enumerate(frames, 1):
            canvas = Image.new("RGBA", (f.width, tallest), (0, 0, 0, 0))
            canvas.paste(f, (0, (tallest - f.height) // 2))
            save(resize_h(canvas, RAVEN_HEIGHT), f"raven_{i}")
        done += 1
    print(f"Готово слоёв: {done}. Папка: {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
