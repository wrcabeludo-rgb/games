#!/usr/bin/env python3
"""Карта из 3 картинок (3.17.57): небо / дальняя стена, середина на пурпуре, пол на пурпуре.

Исходники: art_src/arenas_live/<арена>/sky.*, forest.*, ground.* (как их выдала нейросеть, 16:9).
Результат: game/art/arenas/<арена>/layer_sky.png, layer_mid.png, layer_floor.png + layers.json:
  mid_bottom — доля высоты layer_mid, где стоят объекты (низ непрозрачной части);
  floor_top  — доля высоты layer_floor, где проходит линия пола (верх непрозрачной части).
Пурпур вырезается так же, как у слоёв «Перепутья» (process_arena_art.chroma_key).
Игра рисует слои в ArenaScenery._draw_layers3; движение (облака, качание, огонь) — её дело.

Запуск (из bitva-legend/): python3 tools/process_layers3.py <арена> [<арена> …]
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from process_arena_art import chroma_key  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
WIDTH = 3200   # 1440p с запасом на параллакс: экран 2560, слой шире на четверть


def src(folder: Path, name: str) -> Image.Image:
    for ext in (".png", ".webp", ".jpg", ".jpeg"):
        p = folder / (name + ext)
        if p.exists():
            return Image.open(p).convert("RGB")
    raise SystemExit(f"нет {folder}/{name}.*")


def fit_w(img: Image.Image) -> Image.Image:
    return img.resize((WIDTH, round(img.height * WIDTH / img.width)), Image.LANCZOS)


def keyed(img: Image.Image) -> Image.Image:
    return chroma_key(fit_w(img))


def rows_with(img: Image.Image, share: float = 0.02) -> np.ndarray:
    a = np.asarray(img.getchannel("A")) > 128
    return np.nonzero(a.mean(1) > share)[0]


def main() -> int:
    for arena in sys.argv[1:]:
        folder = ROOT / "art_src/arenas_live" / arena
        out = ROOT / "game/art/arenas" / arena
        out.mkdir(parents=True, exist_ok=True)
        fit_w(src(folder, "sky")).save(out / "layer_sky.png", optimize=True)
        mid = keyed(src(folder, "forest"))
        rows = rows_with(mid)
        mid_bottom = (rows.max() + 1) / mid.height if rows.size else 1.0
        mid.save(out / "layer_mid.png", optimize=True)
        floor = keyed(src(folder, "ground"))
        rows = rows_with(floor, 0.6)
        floor_top = rows.min() / floor.height if rows.size else 0.55
        floor.save(out / "layer_floor.png", optimize=True)
        meta = {"mid_bottom": round(float(mid_bottom), 4), "floor_top": round(float(floor_top), 4)}
        (out / "layers.json").write_text(json.dumps(meta))
        print(f"  {arena}: {meta}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
