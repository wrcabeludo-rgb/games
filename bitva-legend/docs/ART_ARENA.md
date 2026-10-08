# Арт арены «Перекрёсток миров» — ТЗ и промпты

Арена собрана из 9 слоёв. Чем дальше слой, тем медленнее он движется за камерой (параллакс).
Слева — светлая Русь (закат, берёзы, холмы с куполами), справа — тёмные Карпаты (луна, сухие деревья, замок).
В центре — камень на перепутье. Тучи плывут, вороны летают, луна мерцает, деревья и трава качаются,
туман у земли — анимацию делает игра, от картинок нужны только статичные кадры.

## Как генерировать

**Правило:** у каждого спрайта — свой полный промпт целиком, без шаблонов и подстановок.

1. **Сначала небо (слой 1).** Когда оно понравится, прикладывайте его **референсом** ко всем следующим
   генерациям с припиской: *«Match the art style, palette and lighting of the attached image.»*
   Так все слои будут в одном стиле.
2. **Формат:** 21:9 там, где указано (если такого нет — 16:9), максимальное разрешение (2K/4K).
3. **Пурпурный фон.** Всё, кроме неба, — на сплошном пурпурном фоне `#FF00FF`. Я вырежу его автоматически.
   Если на картинке фон не ровный (градиент, тень, текстура) — перегенерируйте.
4. **Проверка перед отправкой:** нет людей, текста, подписей, рамок; объекты не обрезаны краем;
   на самих объектах нет розового и фиолетового (иначе вырежется вместе с фоном).
5. **Отправка:** просто приложите картинки в чат и напишите, какой это слой. Остальное — `tools/process_arena_art.py`.

## Общий стиль (уже вставлен в каждый промпт)

- HD-мультяшный фон для 2D-файтинга: рисованный вид, чистые контуры тёмно-сливового цвета `#24141F`
  средней толщины, заливка с мягкими градиентами, слегка преувеличенные «сказочные» формы.
- Вид строго сбоку, без перспективы: горизонт ровный, дорога идёт слева направо.
- Фон тише бойцов: средняя насыщенность и контраст, без мелкой пестроты — бойцы должны читаться.
- Палитра. Свет: золото `#F2B45A`, янтарь `#D9822B`, персик `#F6D2A2`, берёзовая зелень `#6E8B3D`.
  Тьма: ночной багрянец `#4A1029`, тёмный фиолет `#2A1838`, лунный свет `#E8E4D8`, холодный серо-синий `#5B5A78`.
- Свет: закатное солнце слева у горизонта, луна справа вверху.

## Слои

| # | Файл | Формат | Что это | Параллакс |
|---|---|---|---|---|
| 1 | sky | 21:9 | Небо: закат слева → ночь со звёздами справа | 0.04 |
| 2 | moon | 1:1, пурпур | Луна | 0.07 |
| 3 | clouds | 21:9, пурпур, сетка 3×2 | 6 туч | 0.14 + дрейф |
| 4 | mountains | 21:9, пурпур | Дальние холмы и горы, церковь, замок | 0.1 |
| 5 | ravens | 3:2, пурпур, сетка 3×2 | 6 кадров взмаха ворона | 0.2 + полёт |
| 6 | forest | 21:9, пурпур | Деревья: берёзы → сухие деревья | 0.3 |
| 7 | stone | 3:4, пурпур | Камень на перепутье | 1.0 |
| 8 | ground | 21:9, пурпур | Земля: дорога, по которой ходят бойцы | 1.0 |
| 9 | foreground | 21:9, пурпур | Трава и кусты перед бойцами | 1.3 |

### 1. Небо — `sky` (21:9, без пурпура)

```
Wide 2D fighting game stage background, SKY ONLY. HD hand-painted cartoon style, smooth soft gradients, epic fairy-tale mood. Strict side view, perfectly flat horizontal horizon at the very bottom edge. The LEFT half is a warm golden sunset over ancient Rus: glowing amber, gold and peach tones (#F2B45A, #D9822B, #F6D2A2), the sun disk half-hidden at the far-left horizon with soft rays. The RIGHT half is a gothic Carpathian night: deep crimson and dark violet (#4A1029, #2A1838) with scattered small stars. A smooth, painterly transition between day and night in the middle, slightly magical (thin golden and violet light streaks meeting). Darker toward the top edge. NO moon, NO clouds, NO mountains, NO trees, NO ground, NO characters, NO text, NO letters, NO watermark, NO frame or border. Medium saturation, it must stay calm behind the fighters.
```

### 2. Луна — `moon` (1:1)

```
A single big full moon, 2D game asset. HD hand-painted cartoon style, clean dark-plum outline (#24141F), soft cel shading. Pale ivory moonlight color (#E8E4D8) with gentle blue-grey craters (#5B5A78), a faint hint of crimson tint on one edge (vampire moon). Perfectly round, centered, filling about 70% of the image, nothing cut off. NO glow, NO halo, NO stars, NO clouds around it — just the moon disk. Background: perfectly flat solid magenta #FF00FF, no gradient, no shadow, no texture. Do not use pink or purple on the moon itself. NO text, NO watermark, NO frame.
```

### 3. Тучи — `clouds` (21:9, сетка 3×2)

```
Sprite sheet of 6 separate fluffy cartoon clouds arranged in a neat 3 columns × 2 rows grid, each cloud centered in its own cell with clear empty space around it, no cloud touches another or the image edge. 2D fighting game stage asset, HD hand-painted cartoon style, soft painterly cel shading, NO outlines at all (no dark contour line around the clouds, edges defined only by light and shadow). Clouds are NEUTRAL light grey-white with soft lavender-grey shadows on the bottom (the game will tint them warm or cold), lit from the upper left. Different shapes: 2 long flat stretched clouds, 2 medium puffy cumulus clouds, 2 small wispy clouds. Background: perfectly flat solid magenta #FF00FF, no gradient, no shadow, no texture. Do not use pink or purple on the clouds. NO text, NO watermark, NO grid lines, NO frame.
```

### 4. Дальние горы — `mountains` (21:9)

```
Wide horizontal strip of distant landscape silhouettes for a 2D fighting game parallax layer. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), soft atmospheric gradients, low contrast because it is far away. Strict side view. The landscape spans the FULL width edge to edge and occupies only the bottom 45% of the image. LEFT half: soft rolling green-golden hills of ancient Rus at sunset, warm haze, a tiny wooden church with onion domes on a hilltop, birch groves as tiny silhouettes. RIGHT half: sharp jagged dark-violet Carpathian peaks under the night, a small gothic castle with pointed towers and one lit window on the highest cliff. Smooth transition between the two worlds in the middle. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple in the landscape. NO characters, NO text, NO watermark, NO frame.
```

### 5. Ворон — `ravens` (3:2, сетка 3×2)

```
Sprite sheet of a flight animation cycle: the SAME cartoon raven drawn 6 times in a neat 3 columns × 2 rows grid, frames in reading order left-to-right, top-to-bottom: wings fully up, wings half up, wings level, wings half down, wings fully down, wings returning up. Side view, flying to the RIGHT, identical design, size and position in every frame, only the wings change. 2D fighting game asset, HD hand-painted cartoon style, clean dark-plum outline (#24141F), glossy blue-black feathers with subtle violet-grey highlights, small bright yellow eye, slightly comic expressive shape. Each raven centered in its cell with empty space around it, nothing touches the cell borders. Background: perfectly flat solid magenta #FF00FF, no gradient, no shadow. Do not use pink or purple on the raven. NO text, NO watermark, NO grid lines, NO frame.
```

### 6. Лес — `forest` (21:9)

```
Wide horizontal strip of trees for a 2D fighting game parallax layer (middle distance, behind the fighters). Generate in 4K. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, CRISP SHARP details: clearly defined leaf clusters, bark texture and branch silhouettes, no blur, no soft focus, no depth of field, no painterly smudging, medium-low contrast so the fighters in front stay readable. Strict side view, all tree trunks stand on one flat horizontal ground line at the very bottom edge. The trees span the FULL width edge to edge, tallest trees reach about 70% of the image height, with gaps between groups. LEFT half: warm Russian birch grove and a mighty old oak at sunset — white birch trunks with black marks, golden-green foliage (#6E8B3D, #F2B45A). RIGHT half: twisted leafless gothic trees with crooked claw-like branches, dark violet bark (#2A1838) with cold moonlight rim light (#E8E4D8). In the middle the birches gradually turn into dead trees. Everything around the trees is perfectly flat solid magenta #FF00FF (no sky, no ground, no gradient, no shadow). Do not use pink or purple on the trees. NO characters, NO animals, NO text, NO watermark, NO frame.
```

### 6б. Лес тремя панелями — `forest_1`, `forest_2`, `forest_3` (максимальное разрешение) ✅ в игре с 2.7.1

Одна картинка на всю арену даёт мыло на большом мониторе. Три панели склеиваются в полосу ~5900 px;
в игре лес рисуется крупно, края полосы уходят за кадр (в центре — дуб). Генерировать с референсом неба и леса.

**forest_1**
```
Panel 1 of 3 of a wide side-scrolling forest strip for a 2D fighting game background (the three panels will be placed side by side, left to right). Generate at the maximum resolution (4K). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering: every leaf cluster, bark crack and branch tip clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view, no perspective. All tree trunks stand on ONE flat horizontal ground line at the very bottom edge of the image, the tallest trees reach about 60% of the image height, the same tree scale as the attached reference. Trees and bushes must NOT touch or be cut by the left and right image edges — leave about 3% of empty space on both sides. Warm Russian birch grove at golden sunset: white birch trunks with black marks, golden-green foliage (#6E8B3D, #F2B45A), small fir trees and golden bushes between them. Everything around the trees is perfectly flat solid magenta #FF00FF (no sky, no ground plane, no gradient, no shadow). Do not use pink or purple on the trees. NO characters, NO animals, NO text, NO watermark, NO frame.
```

**forest_2**
```
Panel 2 of 3 of a wide side-scrolling forest strip for a 2D fighting game background (the three panels will be placed side by side, left to right). Generate at the maximum resolution (4K). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering: every leaf cluster, bark crack and branch tip clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view, no perspective. All tree trunks stand on ONE flat horizontal ground line at the very bottom edge of the image, the tallest trees reach about 60% of the image height, the same tree scale as the attached reference. Trees and bushes must NOT touch or be cut by the left and right image edges — leave about 3% of empty space on both sides. A mighty ancient oak in the center with a huge rounded crown, a few birches around it; on the right side of the panel the birches start to lose leaves and turn grey. Everything around the trees is perfectly flat solid magenta #FF00FF (no sky, no ground plane, no gradient, no shadow). Do not use pink or purple on the trees. NO characters, NO animals, NO text, NO watermark, NO frame.
```

**forest_3**
```
Panel 3 of 3 of a wide side-scrolling forest strip for a 2D fighting game background (the three panels will be placed side by side, left to right). Generate at the maximum resolution (4K). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering: every leaf cluster, bark crack and branch tip clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view, no perspective. All tree trunks stand on ONE flat horizontal ground line at the very bottom edge of the image, the tallest trees reach about 60% of the image height, the same tree scale as the attached reference. Trees and bushes must NOT touch or be cut by the left and right image edges — leave about 3% of empty space on both sides. Gothic Carpathian dead forest at night: twisted leafless trees with crooked claw-like branches, broken stumps, dark violet bark (#2A1838) with cold moonlight rim light (#E8E4D8). Everything around the trees is perfectly flat solid magenta #FF00FF (no sky, no ground plane, no gradient, no shadow). Do not use pink or purple on the trees. NO characters, NO animals, NO text, NO watermark, NO frame.
```

### 7. Камень на перепутье — `stone` (3:4)

```
A single legendary crossroads stone from Russian fairy tales ("if you go left..."), 2D fighting game prop. HD hand-painted cartoon style, clean dark-plum outline (#24141F), cel shading. A big tall weathered grey boulder with a slightly flat front face, carved with a few lines of ANCIENT ILLEGIBLE runic-looking engravings (no readable letters), patches of green moss at the bottom, a few cracks, a small raven feather stuck in a crack. Lit warm-gold from the left and cold moonlight from the right. Side view, standing on a tiny patch of grass at the bottom, centered, fully visible with empty space around. Background: perfectly flat solid magenta #FF00FF, no gradient, no cast shadow. Do not use pink or purple on the stone. NO characters, NO readable text, NO watermark, NO frame.
```

### 8. Земля — `ground` (21:9)

```
Wide horizontal strip of ground for a 2D fighting game stage — the floor where fighters stand. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading. Strict side view, NO perspective: the top edge of the ground is a perfectly straight horizontal line at 35% from the top of the image, and the ground fills everything below it to the bottom edge, spanning the FULL width edge to edge. Along the top edge — a thin strip of grass tufts. Below — a packed dirt crossroads road with wheel ruts running left to right, small pebbles. LEFT half: warm sunlit earth and golden grass. RIGHT half: cold dark earth, withered grass, a couple of old bones and a broken cart wheel half buried. Keep the surface calm and low-detail in the middle so fighters stay readable. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple in the ground. NO characters, NO text, NO watermark, NO frame.
```

### 9. Передний план — `foreground` (21:9)

```
Wide horizontal strip of foreground vegetation for a 2D fighting game, it will be drawn IN FRONT of the fighters at the very bottom of the screen. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading, darker and more saturated than the background (it is close to the camera, in shadow). Strict side view. Tall grass tufts, ferns and a few low bushes growing from the bottom edge, at most 25% of the image height, spanning the FULL width edge to edge with uneven gaps (the fighters must stay visible between them). LEFT half: green-golden grass and wildflowers. RIGHT half: dry dark-violet grass and thorny weeds. Everything above the vegetation is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple on the plants. NO characters, NO text, NO watermark, NO frame.
```

## Статус

| Слой | Статус |
|---|---|
| все 9 слоёв | ✅ в игре (2.5.3). Исходники — `art_src/arena/` (первый вариант леса — `old_forest_v1.webp`) |

Заметки по полученному:
- 2.6.1: лес перегенерирован по новому промпту (чётко, деревья на половину высоты) — исходники прошлых версий: `old_forest_v1.webp`, `old_forest_v2.webp`.
- 2.6: у туч контур снимается скриптом (`strip_outline`), камень утоплен в дорогу и отбрасывает тень,
  полосы (горы, лес, передний план) скрипт делает чуть резче. Промпты туч (без контура) и леса (чётко, 4K)
  обновлены выше — если перегенерировать, станет ещё лучше.
- Лес перегенерирован ниже (деревья на половину высоты) — так над бойцами больше неба.
- Кадры ворона выравниваются по жёлтому глазу, чтобы тело не дрожало между кадрами.
- Земля сжата по высоте до 60%, передний план опущен: видны только верхушки травы перед ногами бойцов.
- Небо пришло 3:2 — подходит: обрезается сверху, горизонт с солнцем сохраняется.
- Нейросеть подкрашивает края объектов розовым отсветом от пурпурного фона — скрипт это вычищает
  (полоса 10 px у краёв). Если на ваших картинках кайма всё же заметна — пишите.

## Что делаю я, когда получу картинки

`tools/process_arena_art.py <папка>` — вырезает пурпурный фон и кайму, режет сетки 3×2 на кадры,
обрезает пустые поля, приводит размеры к 1080p и кладёт результат в `game/art/arena/`.
Игра подхватывает каждый слой отдельно: пока слоя нет, на его месте остаётся заглушка.

## Партия: чёткая земля, трава, дальний план, новый камень (3.8)

Всё — с референсом: прикладывайте текущее небо (`art_src/arena/sky`) и дописка уже в промпте. Полосы — тремя панелями, они склеятся; для стыковки прикладывайте и предыдущую панель. Максимальное разрешение.

### Земля, панель 1 — светлая Русь (`arena/ground_1`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 1 of 3 of a wide side-scrolling GROUND strip for a 2D fighting game stage — the floor where the fighters stand (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view of a flat floor seen slightly from above. The top edge of the ground is ONE perfectly straight horizontal line at exactly 35% from the top of the image, the same height in all three panels; the ground fills everything below it down to the bottom edge and spans the FULL width of the panel edge to edge (the left and right edges continue into the next panels). Layout from top to bottom, the same in all panels: a strip of dense short grass tufts along the top edge (about 12% of the image height), then a wide packed dirt road running left to right with wheel ruts, small pebbles and a few flat stones — the road is calm and low-detail in its middle band so the fighters standing on it stay readable — then grass again near the bottom edge. LEFT world — warm ancient Rus at golden sunset: sunlit warm brown earth, golden-green grass with small white and yellow wildflowers, a few chamomiles, warm light from the left. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Земля, панель 2 — перекрёсток (`arena/ground_2`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 2 of 3 of a wide side-scrolling GROUND strip for a 2D fighting game stage — the floor where the fighters stand (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view of a flat floor seen slightly from above. The top edge of the ground is ONE perfectly straight horizontal line at exactly 35% from the top of the image, the same height in all three panels; the ground fills everything below it down to the bottom edge and spans the FULL width of the panel edge to edge (the left and right edges continue into the next panels). Layout from top to bottom, the same in all panels: a strip of dense short grass tufts along the top edge (about 12% of the image height), then a wide packed dirt road running left to right with wheel ruts, small pebbles and a few flat stones — the road is calm and low-detail in its middle band so the fighters standing on it stay readable — then grass again near the bottom edge. CENTER — THE CROSSROADS: in the middle of the panel a second dirt road crosses the main one — it comes from the far grass line at the top (narrowing into the distance) and continues down to the bottom edge toward the viewer, forming a clear cross of four roads; at the crossing the earth is trampled with hoof prints and wheel ruts. The left half of the panel is still warm and sunlit, the right half gradually becomes cold, darker and withered. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Земля, панель 3 — тёмные Карпаты (`arena/ground_3`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 3 of 3 of a wide side-scrolling GROUND strip for a 2D fighting game stage — the floor where the fighters stand (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view of a flat floor seen slightly from above. The top edge of the ground is ONE perfectly straight horizontal line at exactly 35% from the top of the image, the same height in all three panels; the ground fills everything below it down to the bottom edge and spans the FULL width of the panel edge to edge (the left and right edges continue into the next panels). Layout from top to bottom, the same in all panels: a strip of dense short grass tufts along the top edge (about 12% of the image height), then a wide packed dirt road running left to right with wheel ruts, small pebbles and a few flat stones — the road is calm and low-detail in its middle band so the fighters standing on it stay readable — then grass again near the bottom edge. RIGHT world — gothic Carpathian night: cold dark grey-brown earth under moonlight (#5B5A78, #E8E4D8 highlights), withered dry grass, a few old bones, a broken cart wheel half buried at the edge of the road, small sharp rocks. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Трава переднего плана, панель 1 (`arena/foreground_1`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 1 of 3 of a wide FOREGROUND vegetation strip for a 2D fighting game — it is drawn IN FRONT of the fighters at the very bottom of the screen (the three panels will be placed side by side, left to right). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Darker and more saturated than the background (close to the camera, in shadow). Strict side view. Tall grass tufts, ferns and a few low bushes growing from the bottom edge, at most 25% of the image height, with uneven gaps between the clumps (the fighters must stay visible between them). Plants must NOT be cut by the left and right image edges — leave about 3% of empty space on both sides. Warm sunlit Rus: lush green-golden grass, ferns, chamomiles and cornflowers, a small round golden bush. Everything above the vegetation is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Трава переднего плана, панель 2 (`arena/foreground_2`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 2 of 3 of a wide FOREGROUND vegetation strip for a 2D fighting game — it is drawn IN FRONT of the fighters at the very bottom of the screen (the three panels will be placed side by side, left to right). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Darker and more saturated than the background (close to the camera, in shadow). Strict side view. Tall grass tufts, ferns and a few low bushes growing from the bottom edge, at most 25% of the image height, with uneven gaps between the clumps (the fighters must stay visible between them). Plants must NOT be cut by the left and right image edges — leave about 3% of empty space on both sides. Transition: on the left green grass and ferns, toward the right the grass becomes dry and grey, a small thorny bush. Everything above the vegetation is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Трава переднего плана, панель 3 (`arena/foreground_3`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 3 of 3 of a wide FOREGROUND vegetation strip for a 2D fighting game — it is drawn IN FRONT of the fighters at the very bottom of the screen (the three panels will be placed side by side, left to right). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Darker and more saturated than the background (close to the camera, in shadow). Strict side view. Tall grass tufts, ferns and a few low bushes growing from the bottom edge, at most 25% of the image height, with uneven gaps between the clumps (the fighters must stay visible between them). Plants must NOT be cut by the left and right image edges — leave about 3% of empty space on both sides. Dark Carpathian night: dry dark-grey grass, thorny weeds and thistles with cold moonlight rim light (#E8E4D8), a few dead twigs. Everything above the vegetation is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Дальний план, панель 1 — русские деревни (`arena/mountains_1`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 1 of 3 of a wide FAR BACKGROUND landscape strip for a 2D fighting game parallax layer (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. It is far away: soft atmospheric colors and lower contrast than the foreground, but the shapes and small details stay sharp and clean. Strict side view. The landscape spans the FULL width of the panel edge to edge (it continues into the next panels) and occupies only the bottom 50% of the image; the hills at the left and right edges of the panel are at the same height as in the other panels so the strip joins without steps. Ancient Rus at golden sunset: soft rolling green-golden hills, a village of small wooden log houses (izbas) with carved window frames and thin smoke from chimneys, a wooden fence, golden wheat fields with haystacks, a windmill, and on the highest hill a white stone church with golden onion domes. Warm golden haze. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no clouds, no moon, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Дальний план, панель 2 — переход (`arena/mountains_2`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 2 of 3 of a wide FAR BACKGROUND landscape strip for a 2D fighting game parallax layer (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. It is far away: soft atmospheric colors and lower contrast than the foreground, but the shapes and small details stay sharp and clean. Strict side view. The landscape spans the FULL width of the panel edge to edge (it continues into the next panels) and occupies only the bottom 50% of the image; the hills at the left and right edges of the panel are at the same height as in the other panels so the strip joins without steps. Transition between the worlds: on the left a small Russian village on a hill by a winding river with a wooden bridge, birch groves as tiny silhouettes; toward the right the hills turn rocky and grey, the first jagged dark peaks rise, the light becomes cold and violet. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no clouds, no moon, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Дальний план, панель 3 — Карпаты и замок (`arena/mountains_3`, 21:9)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). Panel 3 of 3 of a wide FAR BACKGROUND landscape strip for a 2D fighting game parallax layer (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. It is far away: soft atmospheric colors and lower contrast than the foreground, but the shapes and small details stay sharp and clean. Strict side view. The landscape spans the FULL width of the panel edge to edge (it continues into the next panels) and occupies only the bottom 50% of the image; the hills at the left and right edges of the panel are at the same height as in the other panels so the strip joins without steps. Gothic Carpathian night: sharp jagged dark-violet mountain peaks (#2A1838) with cold moonlight on the edges (#E8E4D8), a big gothic castle with tall pointed towers and a few warm lit windows on the highest cliff, a winding road up to it, and below the castle a small dark village of steep-roofed houses with a couple of lit windows. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no clouds, no moon, no gradient, no shadow). Do not use pink or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.
```

### Камень на перепутье с надписью (`arena/stone`, 3:4)

```
Match the art style, palette and lighting of the attached reference image (the current stage sky). A single legendary CROSSROADS STONE from Russian fairy tales and the bylina about Ilya Muromets, a 2D fighting game prop, 3:4 image at the maximum resolution. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every blade of grass, pebble, crack and edge clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. A big massive tall grey boulder, much larger and heavier than a man, with a flat smooth front face like a stele, weathered edges, a few cracks, patches of green moss and small grass at its foot. On the flat front face there is a CARVED INSCRIPTION in old Russian Cyrillic capital letters, deeply chiseled into the stone, perfectly readable, exactly these three lines and nothing else:
«ПРЯМО ЕХАТЬ — УБИТУ БЫТЬ»
«НАПРАВО ЕХАТЬ — ЖЕНАТУ БЫТЬ»
«НАЛЕВО ЕХАТЬ — БОГАТУ БЫТЬ»
Write every word exactly as given, letter by letter, in Russian Cyrillic, centered, large clear letters, no other words, no extra symbols. Lit warm-gold from the left and cold moonlight from the right. Side view, the stone stands upright on a small patch of grass at the bottom, centered, fully visible with empty space around. Background: perfectly flat solid magenta #FF00FF, no gradient, no cast shadow. Do not use pink or purple on the stone. NO characters, NO watermark, NO frame.
```

### Заставка, герои целиком в кадре (`menu/title`, 16:9) — картинки 1–2: модельные листы, 3: текущая заставка

```
Edit task. Image 1 is the approved model sheet of ILYA MUROMETS, image 2 is the approved model sheet of COUNT DRACULA, image 3 is the current title screen. Redraw the title screen of image 3 with the SAME scene, style and composition, but make BOTH characters smaller so that they fit COMPLETELY inside the image with a margin: the whole figures from the top of the helmet and hair to the soles of the boots, the whole spiked mace and the whole spread cape are inside the frame, nothing touches or is cut by the left, right, top or bottom edge — leave at least 6% of empty space between every part of the characters and every edge of the image. Each character occupies about 60% of the image height, their feet stand on the road at about 85% of the image height. ILYA MUROMETS on the LEFT facing RIGHT, COUNT DRACULA on the RIGHT facing LEFT, staring at each other; copy their faces, costumes and colors faithfully from images 1 and 2. Keep the big full moon in the upper center, the crossroads stone in the middle, the misty road, the warm golden light on the left and the cold blue moonlight on the right. Keep the CENTER of the bottom 25% of the image (the road between the two characters) darker and simple for the game logo. Wide 16:9 image at maximum resolution. Anatomy rules: correct anatomy, each character has EXACTLY TWO arms and two legs. NO text, NO logo, NO letters, NO watermark, NO borders.
```

**Статус партии 3.8:** ground_1–3 ✅ в игре (3.7.5): панели склеены с плавным перетеканием (12%), земля рисуется в своих пропорциях
шире арены (×1.3), перекрёсток — по центру за камнем. stone ✅ (3.7.6): камень с надписью из былины, в игре 260 px (боец — 300). foreground_1–3 ✅ (3.7.7). mountains ✅ (3.7.8): в игре панели 1 и 3 (деревня и замок), переходная панель сохранена как mountains_transition.webp — с ней полоса слишком широкая, церковь и замок уходили за кадр. Ждём: menu/title.
