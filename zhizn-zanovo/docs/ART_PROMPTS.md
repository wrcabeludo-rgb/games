# «Жизнь заново» — промпты иллюстраций

## Замысел
Стиль рисунка меняется вместе с возрастом героя (`Z.STYLES` в `engine.js`):

| Возраст | Стиль | id |
|---|---|---|
| 18–29 | цветные карандаши | `pencils` |
| 30–39 | гелевые ручки | `gel` |
| 40–49 | фломастеры | `markers` |
| 50–59 | акриловые краски | `acrylic` |
| 60–69 | акварель пастельных оттенков | `watercolor` |
| 70–100 | простой карандаш: чёткие, простые, красивые линии | `graphite` |

Общие правила для всех картинок:
- Героя видно со спины, в профиль издалека или вполоборота **без деталей лица** — чтобы каждый игрок узнал в нём себя.
- Россия/постсоветский город, но без примет конкретного года: никаких смартфонов крупным планом, логотипов, надписей.
- Формат 3:2, горизонтальный (1536×1024). Никакого текста, букв, подписей, рамок.
- Тёплое, бережное настроение: игра терапевтическая.

Готовые картинки кладём в `art/<стиль>/<тема>.webp` (1200×800) и вписываем в `js/data/art.js`.
Темы (`Z.themeOf`): `stage` (обложка периода), `parents`, `friends`, `love`, `family`, `work`, `youth`, `gray`, `old`, `life`.

## Партия 1: обложки периодов (6 картинок)

### 1. 18–29 · цветные карандаши → `art/pencils/stage.webp`
```
Hand-drawn illustration made entirely with colored pencils on textured white paper: visible pencil strokes, soft cross-hatching, warm layered colors, slightly unfinished edges where the paper shows through. Scene: early morning in a shabby student dormitory room. A young man of about 18 with short messy dark hair sits on the edge of a narrow metal bed, seen from behind, looking out of a large window at a city waking up under a pink-orange dawn sky. On the old desk: a stack of textbooks, a student ID card, a mug of tea, an acoustic guitar leaning on the wall. A roommate sleeps under a blanket on the other bed. Peeling ceiling, a jacket hanging on a chair. Mood: the first morning of a second chance, hope, everything still ahead. Horizontal composition 3:2, calm empty space in the sky. No text, no letters, no logos, no smartphones, no visible face details.
Negative: photorealism, 3D render, digital painting look, anime, cartoon exaggeration, text, letters, watermark, signature, frame, border, logos, modern smartphone, visible detailed face, dark horror mood, oversaturated neon colors.
```

### 2. 30–39 · гелевые ручки → `art/gel/stage.webp`
```
Illustration drawn with gel pens on white paper: crisp smooth ink lines, dense parallel hatching, bright saturated gel-pen colors (cobalt blue, violet, emerald, coral), a few shimmering metallic and glitter gel accents on lights and highlights, small doodle-like details. Scene: a summer evening on the balcony of an ordinary apartment block. A man of about 35 with short dark hair, seen from behind, leans on the balcony railing and looks at the city lights. Behind him through the open balcony door a warm kitchen glows, where a woman's silhouette is setting the table and a small child's drawing is stuck to the fridge. On the balcony: a child's bicycle, drying laundry, a pot of tomatoes, a toolbox. Mood: building a life, busy and full, a moment of quiet gratitude. Horizontal composition 3:2. No text, no letters, no logos, no visible face details.
Negative: photorealism, 3D render, watercolor, oil paint, anime, text, letters, watermark, signature, frame, border, logos, detailed faces, gloomy mood.
```

### 3. 40–49 · фломастеры → `art/markers/stage.webp`
```
Illustration drawn with felt-tip markers on white paper: bold saturated colors, visible streaky marker strokes and overlapping layers where strokes cross, clean black fineliner outlines, slightly naive hand-made feel like a sketchbook page. Scene: late night in a family kitchen. A man of about 45 with short dark hair greying at the temples sits at the kitchen table, seen from behind and slightly to the side, a cup of tea in his hands, work papers pushed aside. On the table: a teenager's headphones, a school diary, a bowl of apples, reading glasses. Through the window — a night courtyard with a few lit windows of the neighbouring building. On the wall: family photos and a calendar. Mood: the middle of the road, tired but thinking clearly, choosing what really matters. Horizontal composition 3:2. No text, no letters, no logos, no visible face details.
Negative: photorealism, 3D render, watercolor softness, oil paint, anime, text, letters on paper or calendar, watermark, signature, frame, border, logos, detailed faces, horror mood.
```

### 4. 50–59 · акриловые краски → `art/acrylic/stage.webp`
```
Painting in acrylic paints on canvas: thick confident brushstrokes, opaque layered color, visible brush texture and a little palette-knife impasto, rich warm autumn palette (ochre, rust, deep green, cadmium yellow). Scene: an autumn garden at an old country house (dacha). A man of about 55 with short grey-streaked hair, seen from behind, stands under an apple tree with a basket of apples. On the porch of the wooden house an elderly couple — his parents — sit on a bench under a blanket; in the distance by the gate two adult children are arriving with bags. Low golden evening sun, fallen leaves, a wooden fence, smoke from a bathhouse chimney. Mood: harvest, gratitude, the generations together. Horizontal composition 3:2. No text, no letters, no logos, no visible face details.
Negative: photorealism, 3D render, watercolor, pencil drawing, anime, text, letters, watermark, signature, frame, border, logos, detailed faces, gloomy mood.
```

### 5. 60–69 · пастельная акварель → `art/watercolor/stage.webp`
```
Delicate watercolor painting in soft pastel tones (powder blue, lavender, peach, mint, pale lemon) on cotton watercolor paper: wet-in-wet washes, gentle color blooms, soft edges, lots of luminous white paper, a few fine pencil lines showing through. Scene: a quiet riverside promenade in a small town on a spring morning. A man of about 65 with short white hair, seen from behind, sits on a wooden bench next to a small grandchild who points at ducks on the water. A fishing rod and a thermos lean on the bench. Willows with fresh leaves, a footbridge in the mist, distant church domes and rooftops. Mood: tenderness, slowness, passing on what you know. Horizontal composition 3:2. No text, no letters, no logos, no visible face details.
Negative: photorealism, 3D render, saturated colors, heavy dark tones, oil paint, markers, anime, text, letters, watermark, signature, frame, border, logos, detailed faces.
```

### 6. 70–100 · простой карандаш → `art/graphite/stage.webp`
```
Drawing with a single graphite pencil on clean white paper: clear, simple, beautiful confident lines, economical contour drawing with only light delicate shading, a lot of empty white space, elegant like a master's sketch. Monochrome grey only. Scene: an old man of about 85 with white hair, seen from behind, sits in an armchair by a large window, the same kind of window as in a student dormitory; on his knees he holds an old photograph of a group of young students laughing. On the windowsill: a pair of glasses, a cup, a small potted plant; outside the window — the bare outline of a tree and a few birds. Mood: the circle closes, peace, gratitude for two lives. Horizontal composition 3:2. No text, no letters, no logos, no visible face details.
Negative: color, colored pencils, ink wash, heavy dark shading, smudged charcoal, photorealism, 3D render, anime, text, letters, watermark, signature, frame, border, logos, detailed faces.
```

## Партия 2 (потом): темы в каждом стиле
Для каждого из 6 стилей — 9 тем: `parents` (родители), `friends` (друзья), `love` (любовь), `family` (дом и дети),
`work` (работа), `youth` (студенчество, только `pencils`), `gray` (серый период), `old` (старость, только
`watercolor` и `graphite`), `life` (быт и праздники). Промпты напишу, когда утвердим стиль по первой партии.
