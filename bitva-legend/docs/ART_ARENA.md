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
