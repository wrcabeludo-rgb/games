#!/usr/bin/env python3
"""Оживление дальнего плана арены: вода течёт, окна мерцают, из труб идёт дым.

Использование: python3 tools/make_arena_life.py [папка арены в game/art/…]   (по умолчанию game/art/arena)

Берёт mountains.png и описание мест (LIFE ниже, координаты — пиксели mountains.png):
  water     — многоугольники воды: внутри них гладкие пиксели (без мазков деревьев и камней) считаются водой;
  fall      — водопады (прямоугольник): струи бегут вниз;
  chimneys  — трубы, из которых идёт дым;
  windows   — ищутся сами: тёплые яркие пятна в заданной полосе.
Пишет water_<n>.png (кадры по горизонтали, цикл) и life.json — их рисует ArenaScenery поверх дальнего плана.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

FRAMES = 16

# «Перепутье»: река слева (закат в воде), река у Карпат, вода под мостом, водопад у замка.
LIFE = {
    "water": [
        [(1345, 376), (1505, 368), (1600, 392), (1700, 408), (1845, 418), (1845, 442), (1720, 440), (1660, 470),
         (1600, 472), (1555, 448), (1450, 432), (1375, 425), (1350, 400)],
        [(2150, 525), (2280, 520), (2400, 515), (2460, 500), (2500, 482), (2550, 478), (2580, 480), (2580, 495),
         (2520, 510), (2480, 525), (2430, 540), (2350, 545), (2250, 545), (2150, 540)],
        [(2420, 550), (2500, 560), (2600, 575), (2700, 585), (2800, 592), (2900, 598), (2900, 620), (2800, 617),
         (2650, 612), (2520, 605), (2450, 590), (2420, 570)],
    ],
    "fall": [(3560, 298, 3614, 418)],
    "chimneys": [(338, 345), (478, 330), (558, 370), (630, 368), (742, 372), (1045, 375), (1090, 405), (1235, 350),
                 (2990, 430), (3290, 428)],
    "windows_band": (2700, 0, 3700, 520),
    "windows_skip": [(2700, 150, 3260, 280)],   # освещённые закатом вершины гор — не окна
}


def roughness(gray: np.ndarray) -> np.ndarray:
    g = Image.fromarray(gray.astype(np.uint8)).filter(ImageFilter.FIND_EDGES)
    g = Image.fromarray(np.clip(np.asarray(g, float) * 3, 0, 255).astype(np.uint8)).filter(ImageFilter.BoxBlur(3))
    return np.asarray(g, float)


def tile_noise(w: int, h: int, seed: int, sx: float, sy: float) -> np.ndarray:
    """Гладкий шум, повторяющийся по x с периодом w (чтобы блики текли по кругу)."""
    rng = np.random.default_rng(seed)
    small = rng.random((max(2, int(h / sy)), max(2, int(w / sx))))
    small = np.concatenate([small, small[:, :1]], 1)  # шов по x
    img = Image.fromarray((small * 255).astype(np.uint8)).resize((w + int(w / small.shape[1]) + 1, h), Image.BICUBIC)
    return np.asarray(img, float)[:, :w] / 255.0


def make_water(src: np.ndarray, mask: np.ndarray, box, flow_x: bool, seed: int) -> Image.Image:
    x0, y0, x1, y1 = box
    sub = src[y0:y1, x0:x1].astype(float)
    m = mask[y0:y1, x0:x1].astype(float)
    m = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)), float) / 255.0
    h, w = m.shape
    lum = sub[..., :3].mean(2)
    out = Image.new("RGBA", (w * FRAMES, h))
    if flow_x:
        period = w
        noise = tile_noise(period, h, seed, 18.0, 2.5)        # вытянутые вдоль течения блики
    else:
        period = h
        noise = tile_noise(period, w, seed, 14.0, 1.5).T      # струи водопада: вытянуты по вертикали
    ys, xs = np.mgrid[0:h, 0:w]
    for f in range(FRAMES):
        ph = f / FRAMES
        # Рябь: строки чуть сдвигаются по синусоиде (на водопаде — столбцы).
        if flow_x:
            dx = np.round(np.sin((ys / 3.0 + ph) * 2 * np.pi) * 1.0).astype(int)
            sx = np.clip(xs + dx, 0, w - 1)
            frame = sub[ys, sx].copy()
            n = noise[ys, (xs - int(ph * period)) % period]
        else:
            frame = sub.copy()
            n = noise[(ys - int(ph * period)) % period, xs]
        glint = np.clip((n - 0.62) * 3.2, 0, 1) * (0.35 + 0.65 * np.clip(lum / 200.0, 0, 1))
        k = 0.55 if flow_x else 0.75
        frame[..., :3] = frame[..., :3] + (255 - frame[..., :3]) * (glint * k)[..., None]
        frame[..., 3] = m * 255
        out.paste(Image.fromarray(np.clip(frame, 0, 255).astype(np.uint8), "RGBA"), (f * w, 0))
    return out


def find_windows(src: np.ndarray, band) -> list:
    """Окна: тёплые яркие пятна, заметно светлее своего окружения (а не освещённые края стен)."""
    x0, y0, x1, y1 = band
    sub = src[y0:y1, x0:x1].astype(float)
    r, g, b = sub[..., 0], sub[..., 1], sub[..., 2]
    lum = sub[..., :3].mean(2)
    around = np.asarray(Image.fromarray(lum.astype(np.uint8)).filter(ImageFilter.BoxBlur(7)), float)
    hot = (r > 200) & (g > 120) & (b < 120) & (r - b > 110) & (lum - around > 45) & (sub[..., 3] > 200)
    windows = []
    for y, x in zip(*np.nonzero(hot)):
        p = (int(x + x0), int(y + y0))
        for w in windows:
            if abs(w[0] - p[0]) < 7 and abs(w[1] - p[1]) < 7:
                w[2] += 1
                break
        else:
            windows.append([p[0], p[1], 1])
    windows = [w for w in windows if w[2] >= 3]
    windows.sort(key=lambda w: -w[2])
    return windows[:70]


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "game/art/arena"
    img = Image.open(folder / "mountains.png").convert("RGBA")
    src = np.asarray(img)
    gray = src[..., :3].mean(2)
    rough = roughness(gray)
    meta = {"size": [img.width, img.height], "water": [], "windows": [], "chimneys": LIFE["chimneys"]}
    n = 0
    for poly in LIFE["water"]:
        pm = Image.new("L", img.size, 0)
        ImageDraw.Draw(pm).polygon(poly, fill=255)
        # Слева вода гладкая — отсекаем мазки крон; справа картинка вся в мелких деталях — только тёмные ели.
        mask = (np.asarray(pm) > 0) & (src[..., 3] > 200)
        mask &= (rough < 85) if n == 0 else (gray > 70)
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        n += 1
        make_water(src, mask, box, True, n).save(folder / f"water_{n}.png", optimize=True)
        meta["water"].append({"file": f"water_{n}.png", "rect": [box[0], box[1], box[2] - box[0], box[3] - box[1]],
                              "frames": FRAMES, "period": 3.0})
    for x0, y0, x1, y1 in LIFE["fall"]:
        sub = src[y0:y1, x0:x1]
        mask = np.zeros(gray.shape, bool)
        mask[y0:y1, x0:x1] = (sub[..., :3].mean(2) > 95) & (sub[..., 3] > 200)
        n += 1
        make_water(src, mask, (x0, y0, x1, y1), False, n).save(folder / f"water_{n}.png", optimize=True)
        meta["water"].append({"file": f"water_{n}.png", "rect": [x0, y0, x1 - x0, y1 - y0], "frames": FRAMES, "period": 1.2})
    meta["windows"] = [w for w in find_windows(src, LIFE["windows_band"])
                       if not any(a <= w[0] < c and b <= w[1] < d for a, b, c, d in LIFE["windows_skip"])]
    (folder / "life.json").write_text(json.dumps(meta, ensure_ascii=False))
    print(f"вода: {len(meta['water'])} участков, окон: {len(meta['windows'])}, труб: {len(meta['chimneys'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
