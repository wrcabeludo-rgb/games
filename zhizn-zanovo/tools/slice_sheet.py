# Режет лист-раскадровку (сетка сцен на белом фоне) на отдельные картинки и подключает их в игру.
# Запуск из zhizn-zanovo/:  python3 tools/slice_sheet.py <лист.png> <A|B|C> [--preview out.png]
# Ячейки ищутся по белым промежуткам (строки и столбцы почти без тёмных пикселей), порядок — слева направо, сверху вниз.
import sys, os, json, re
from PIL import Image, ImageOps

SHEETS = {
    'A': ['mom_phone', 'dacha', 'garage', 'hospital', 'newborn', 'school', 'teen_door', 'family_table', 'grandkid'],
    'B': ['dorm', 'kitchen_night', 'moto', 'couple_walk', 'wedding', 'quarrel', 'station', 'office', 'rain_window'],
    'C': ['army', 'market', 'newyear', 'airport', 'campfire', 'graduation', 'cemetery', 'old_dance', 'sea'],
}
ROOT = os.path.join(os.path.dirname(__file__), '..')

def bands(profile, thr, min_gap):
    """Отрезки «содержимого» между белыми промежутками."""
    out, inside, start, gap = [], False, 0, 0
    for i, v in enumerate(profile + [0] * (min_gap + 1)):
        if v > thr:
            if not inside: inside, start = True, i
            gap = 0
        elif inside:
            gap += 1
            if gap > min_gap: out.append((start, i - gap + 1)); inside = False
    return out

def cells(img):
    g = ImageOps.grayscale(img); W, H = g.size; px = g.load()
    dark = lambda x, y: px[x, y] < 200
    cols = [sum(1 for y in range(0, H, 2) if dark(x, y)) for x in range(W)]
    rows = [sum(1 for x in range(0, W, 2) if dark(x, y)) for y in range(H)]
    xs = [b for b in bands(cols, 1, W // 80) if b[1] - b[0] > W // 8]
    ys = [b for b in bands(rows, 1, H // 80) if b[1] - b[0] > H // 8]
    return [(x0, y0, x1, y1) for (y0, y1) in ys for (x0, x1) in xs]

def fit32(im):
    """Дополнить белым до 3:2 и привести к 1200×800 (линии масштабируются чисто)."""
    W, H = im.size; tw = max(W, int(H * 1.5)); th = max(H, int(W / 1.5))
    tw, th = max(tw, int(th * 1.5)), max(th, int(tw / 1.5))
    canvas = Image.new('RGB', (tw, th), 'white'); canvas.paste(im, ((tw - W) // 2, (th - H) // 2))
    return canvas.resize((1200, 800), Image.LANCZOS)

def main():
    src, sheet = sys.argv[1], sys.argv[2].upper()
    keys = SHEETS[sheet]
    img = Image.open(src).convert('RGB')
    cs = cells(img)
    print('найдено ячеек:', len(cs))
    if len(cs) != len(keys):
        print('Ожидалось %d. Лист не режется ровно — проверьте сетку (лучше перегенерировать).' % len(keys)); sys.exit(1)
    os.makedirs(os.path.join(ROOT, 'art', 'scenes'), exist_ok=True)
    os.makedirs(os.path.join(ROOT, 'art_src', 'sheets'), exist_ok=True)
    img.save(os.path.join(ROOT, 'art_src', 'sheets', 'sheet_%s.png' % sheet))
    pad = 6
    for (x0, y0, x1, y1), key in zip(cs, keys):
        part = img.crop((max(0, x0 - pad), max(0, y0 - pad), min(img.width, x1 + pad), min(img.height, y1 + pad)))
        fit32(part).save(os.path.join(ROOT, 'art', 'scenes', key + '.webp'), 'WEBP', quality=85, method=6)
        print('  ', key)
    # подключить в игру
    p = os.path.join(ROOT, 'js', 'data', 'art.js'); s = open(p, encoding='utf8').read()
    m = re.search(r"Z\.SCENES = (\{.*?\});", s, re.S)
    have = json.loads(m.group(1)) if m else {}
    for k in keys: have[k] = 'art/scenes/%s.webp' % k
    line = 'Z.SCENES = ' + json.dumps(have, ensure_ascii=False, sort_keys=True) + ';'
    s = s.replace(m.group(0), line) if m else s.replace('})();', '  ' + line + '\n})();')
    open(p, 'w', encoding='utf8').write(s)
    print('подключено в js/data/art.js')
    if '--preview' in sys.argv:
        out = sys.argv[sys.argv.index('--preview') + 1]
        thumbs = [Image.open(os.path.join(ROOT, 'art', 'scenes', k + '.webp')).resize((300, 200)) for k in keys]
        pv = Image.new('RGB', (900, 600), 'white')
        for i, t in enumerate(thumbs): pv.paste(t, ((i % 3) * 300, (i // 3) * 200))
        pv.save(out); print('превью:', out)

if __name__ == '__main__':
    main()
