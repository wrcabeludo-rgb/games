#!/usr/bin/env python3
"""Нейросетевое увеличение картинок в 2 раза (Real-ESRGAN, модель для рисованной графики).

Использование: python3 tools/upscale.py <вход> <выход>
Модель: tools/models/anime6B.pth (RealESRGAN_x4plus_anime_6B). Картинка увеличивается в 4 раза
и уменьшается до 2× — линии остаются резкими, без мыла. Считается кусками, чтобы хватило памяти.
Считает на видеокарте, если она есть: NVIDIA (cuda) или Apple M1/M2/M3 (mps), иначе на процессоре.
Куски, где только пурпурный фон (листы бойцов, слои карт), нейросеть не считает — заливаются #FF00FF.
"""
import sys
from pathlib import Path

import numpy as np
import torch
from PIL import Image
from spandrel import ModelLoader

MODEL = Path(__file__).resolve().parent / "models" / "anime6B.pth"
TILE = 256
PAD = 16


def device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if getattr(torch.backends, "mps", None) is not None and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def upscale(img: Image.Image) -> Image.Image:
    dev = device()
    model = ModelLoader().load_from_file(str(MODEL)).model.eval().to(dev)
    torch.set_num_threads(max(1, torch.get_num_threads()))
    a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    h, w, _ = a.shape
    out = np.zeros((h * 4, w * 4, 3), np.float32)
    with torch.no_grad():
        for y in range(0, h, TILE):
            for x in range(0, w, TILE):
                y0, x0 = max(0, y - PAD), max(0, x - PAD)
                y1, x1 = min(h, y + TILE + PAD), min(w, x + TILE + PAD)
                cy, cx = (y - y0) * 4, (x - x0) * 4
                th, tw = min(TILE, h - y) * 4, min(TILE, w - x) * 4
                piece = a[y0:y1, x0:x1]
                if (np.minimum(piece[..., 0], piece[..., 2]) - piece[..., 1] > 90 / 255).all():
                    out[y * 4:y * 4 + th, x * 4:x * 4 + tw] = (1.0, 0.0, 1.0)  # только пурпурный фон
                    continue
                t = torch.from_numpy(np.ascontiguousarray(piece.transpose(2, 0, 1))).unsqueeze(0).to(dev)
                r = model(t)[0].float().cpu().numpy().transpose(1, 2, 0)
                out[y * 4:y * 4 + th, x * 4:x * 4 + tw] = r[cy:cy + th, cx:cx + tw]
    big = Image.fromarray((np.clip(out, 0, 1) * 255).round().astype(np.uint8))
    return big.resize((w * 2, h * 2), Image.LANCZOS)


if __name__ == "__main__":
    upscale(Image.open(sys.argv[1])).save(sys.argv[2])
