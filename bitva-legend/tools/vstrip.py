#!/usr/bin/env python3
"""Пронумерованная лента кадров ролика (для выбора кадров): python3 tools/vstrip.py <видео> <out.png> <с> <по> <шаг> [столбцов]
Кадры с 1, обрезка по общей рамке фигуры на пурпуре."""
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

FFMPEG = "/Users/a1/bin/ffmpeg"
v, out, a, b, st = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
cols = int(sys.argv[6]) if len(sys.argv) > 6 else 8
p = subprocess.run([FFMPEG, "-v", "error", "-i", v, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True).stdout
A = np.frombuffer(p, np.uint8).reshape(-1, 720, 1280, 3)
idx = list(range(a, min(b, len(A)) + 1, st))
fr = [A[i - 1] for i in idx]
u = np.zeros((720, 1280), bool)
for f in fr:
    u |= (np.minimum(f[..., 0], f[..., 2]).astype(int) - f[..., 1]) < 100
u[630:] = False
ys, xs = np.where(u)
x0, x1, y0, y1 = max(xs.min() - 10, 0), min(xs.max() + 10, 1280), max(ys.min() - 10, 0), min(ys.max() + 20, 720)
s = min(1, 220 / (y1 - y0))
tw, th = int((x1 - x0) * s), int((y1 - y0) * s)
c = Image.new("RGB", (tw * cols, (th + 14) * ((len(fr) + cols - 1) // cols)), "white")
d = ImageDraw.Draw(c)
for k, (i, f) in enumerate(zip(idx, fr)):
    X, Y = (k % cols) * tw, (k // cols) * (th + 14)
    c.paste(Image.fromarray(f[y0:y1, x0:x1]).resize((tw, th)), (X, Y + 14))
    d.text((X + 2, Y), str(i), fill="black")
c.save(out)
print(len(A), (x0, x1, y0, y1))
