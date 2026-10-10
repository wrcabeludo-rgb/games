#!/usr/bin/env python3
"""Раскладка кадров анимаций бойца по опорной точке, с полупрозрачной стойкой — проверка рывков и размера.
Использование (из game/): python3 ../tools/sheet_preview.py art/fighters <боец> <анимации через запятую> <выход.png>"""
import json, sys
from PIL import Image, ImageDraw
base = sys.argv[1]; who = sys.argv[2]; anims = sys.argv[3].split(","); out = sys.argv[4]
def load(a):
    m = json.load(open(f"{base}/{who}/{a}.json"))
    return [(Image.open(f"{base}/{who}/{f['file']}").convert("RGBA"), f["pivot"]) for f in m["frames"]]
idle = load("idle")[0]
CW, CH = 560, 900
rows = []
for a in anims:
    fr = load(a)
    row = Image.new("RGBA", (CW * len(fr), CH), (40, 40, 48, 255))
    d = ImageDraw.Draw(row)
    for i, (img, pv) in enumerate(fr):
        ox, oy = i * CW + CW // 2, CH - 120
        g = idle[0].copy(); g.putalpha(g.getchannel("A").point(lambda v: v * 0.25))
        row.alpha_composite(g, (ox - idle[1][0], oy - idle[1][1]))
        row.alpha_composite(img, (ox - int(pv[0]), oy - int(pv[1])))
        d.line([(i * CW, oy), ((i + 1) * CW, oy)], fill=(255, 80, 80, 255), width=2)
        d.line([(ox, 0), (ox, CH)], fill=(80, 200, 255, 255), width=1)
        d.text((i * CW + 8, 8), f"{a} {i+1}  h={img.height}", fill=(255, 255, 255, 255))
    rows.append(row)
W = max(r.width for r in rows); H = sum(r.height for r in rows)
sheet = Image.new("RGBA", (W, H), (20, 20, 24, 255))
y = 0
for r in rows:
    sheet.alpha_composite(r, (0, y)); y += r.height
sheet = sheet.resize((W // 3, H // 3))
sheet.save(out)
