# Спрайты бойцов — ТЗ и промпты

**Правило:** у каждого листа — свой полный промпт целиком, без шаблонов и подстановок. Копируйте как есть.

## Как это устроено

1. **Модельный лист** (как выглядит боец) генерируется первым. Когда он понравится — его прикладывают
   **референсом ко всем листам этого бойца** (и к модельному листу соперника — для единого стиля).
2. **Лист анимации** — 3–6 кадров одного движения в ряд на одной картинке. Внутри одной картинки нейросеть
   держит бойца одинаковым гораздо лучше, чем в отдельных генерациях.
3. Всё — на сплошном пурпурном фоне `#FF00FF`, боец смотрит **вправо** (влево игра отражает сама).
4. Я прогоняю листы через `tools/process_fighter_art.py`: убираю фон, режу на кадры, привожу к одному масштабу,
   ставлю опорную точку под ступни. Анимацию между ключевыми кадрами дорабатывает игра (сдвиги, «смазы», тряска).

**Перед отправкой проверьте:** боец одинаковый во всех кадрах (лицо, борода/причёска, одежда, оружие);
кадры не касаются друг друга и краёв; ступни на одной линии; нет теней, земли, текста; на бойце нет
розового и фиолетового. Отправка — картинкой в чат с подписью «Илья — стойка» и т. п.

## Бойцы

**Илья Муромец** — мультяшный богатырь-великан, добродушный, но грозный. Огромная грудь-бочка, широченные плечи,
короткие крепкие ноги, руки-брёвна. Окладистая русая борода до пояса, кустистые брови, румяные щёки.
Шлем-шишак с острым навершием и кольчужной бармицей; кольчуга поверх длинного красного кафтана с золотой каймой;
широкий кожаный пояс с большой пряжкой; синие шаровары; красные сапоги с загнутыми носами.
Палица — толстая деревянная рукоять с железным шаром в шипах.

**Дракула** — готический красавец, высокий и стройный, театрально-самовлюблённый. Бледная серо-белая кожа,
зачёсанные назад чёрные волосы с острым мысиком, светящиеся красные глаза, острые уши, клыки в ухмылке.
Чёрный плащ с высоким стоячим воротником и тёмно-красной (не фиолетовой!) подкладкой, чёрный фрак,
бордовый жилет, белое жабо, чёрные брюки, лакированные сапоги, длинные бледные пальцы с чёрными когтями.

## Партия 1 (подэтапы 3.1–3.2): модельные листы и пробный проход Ильи

| # | Файл | Формат | Что | Кадров |
|---|---|---|---|---|
| 1 | `ilya/model` | 16:9, макс. разрешение | Модельный лист Ильи | 3 вида |
| 2 | `dracula/model` | 16:9, макс. разрешение | Модельный лист Дракулы | 3 вида |
| 3 | `ilya/idle` | 16:9, макс. разрешение, референс: модельный лист Ильи | Боевая стойка, дыхание (цикл) | 4 |
| 4 | `ilya/st_lp` | 16:9, макс. разрешение, референс: модельный лист Ильи | Лёгкий удар рукой (джеб) | 3 |

### 1. Илья — модельный лист (`ilya/model`)

```
Character model sheet for a 2D fighting game: ILYA MUROMETS, the legendary Russian bogatyr, as a cartoon giant hero — good-natured but formidable. Three full-body views of the SAME character side by side with clear empty space between them, all at exactly the same scale, feet on one flat horizontal line: LEFT — strict side view facing RIGHT (the main view), MIDDLE — front view, RIGHT — back view. Standing upright in a relaxed neutral pose, arms slightly away from the body, holding his mace in the right hand pointing down. Design: huge barrel chest and enormous broad shoulders, short sturdy legs, log-thick arms, heroic exaggerated proportions (about 5 heads tall); thick light-brown beard reaching the belt, bushy eyebrows, rosy cheeks, confident kind smirk; pointed conical steel shishak helmet with a small spike on top and a chainmail aventail covering the neck; steel chainmail shirt worn over a long crimson-red kaftan with golden trim reaching the knees; wide brown leather belt with a big round bronze buckle; baggy dark-blue trousers tucked into red leather boots with upturned toes. Weapon: a massive mace (palitsa) — thick dark wooden handle and a heavy iron ball covered with short spikes. HD hand-painted cartoon style like modern 2D fighting games (Skullgirls, BlazBlue), bold clean dark-plum outline (#24141F), cel shading with 2–3 tones and soft gradients, crisp sharp details, strong readable silhouette. Warm key light from the upper left, cool pale-blue rim light on the right side. Background: perfectly flat solid magenta #FF00FF, no gradient, no floor, no cast shadow. Do not use pink, magenta or purple on the character. NO text, NO labels, NO arrows, NO watermark, NO frame.
```

### 2. Дракула — модельный лист (`dracula/model`)

```
Character model sheet for a 2D fighting game: COUNT DRACULA as a gothic handsome cartoon villain — tall, slim, elegant, theatrically vain and arrogant. Three full-body views of the SAME character side by side with clear empty space between them, all at exactly the same scale, feet on one flat horizontal line: LEFT — strict side view facing RIGHT (the main view), MIDDLE — front view, RIGHT — back view. Standing upright in a proud neutral pose, one hand on the chest, the other slightly raised with long fingers. Design: tall and slender with long legs (about 7.5 heads tall), sharp angular face, pale grey-white skin (not pink), black hair slicked back with a sharp widow's peak, glowing red eyes, pointed ears, a smug smirk showing small fangs; long black cape with a tall stiff standing collar and a DEEP DARK-RED lining (#7A1418, not purple); black tailcoat, dark burgundy-red waistcoat with tiny gold buttons, white lace jabot with a red gem brooch, slim black trousers, polished black boots; long pale fingers with sharp black claws. HD hand-painted cartoon style like modern 2D fighting games (Skullgirls, BlazBlue), bold clean dark-plum outline (#24141F), cel shading with 2–3 tones and soft gradients, crisp sharp details, strong readable silhouette. Warm key light from the upper left, cool pale-blue moonlight rim light on the right side. Background: perfectly flat solid magenta #FF00FF, no gradient, no floor, no cast shadow. Do not use pink, magenta or purple on the character. NO text, NO labels, NO arrows, NO watermark, NO frame.
```

### 3. Илья — стойка (`ilya/idle`), 4 кадра

```
Sprite sheet for a 2D fighting game: 4 animation frames of the SAME character in one horizontal row, left to right, evenly spaced with clear empty magenta space between the frames, no frame touches another or the image edge. The character is ILYA MUROMETS exactly as in the attached model sheet: cartoon giant bogatyr with huge barrel chest, broad shoulders, short sturdy legs, thick light-brown beard to the belt, pointed conical steel shishak helmet with chainmail aventail, chainmail over a long crimson-red kaftan with golden trim, wide brown belt with a round bronze buckle, baggy dark-blue trousers, red boots with upturned toes, massive spiked iron mace. Strict side view facing RIGHT, full body visible, both feet planted on ONE flat horizontal ground line at the same height in every frame, the same size in every frame. Animation: FIGHTING STANCE BREATHING LOOP — knees bent, feet apart, body turned toward the right, front (right) fist raised in front of the chin in a guard, the mace held in the rear hand and resting on his shoulder. Frame 1: neutral stance. Frame 2: inhaling, chest and shoulders rise slightly. Frame 3: peak of the breath, beard lifts a little. Frame 4: exhaling, shoulders lower back. The changes between frames are SMALL and subtle; the feet do not move at all. HD hand-painted cartoon style like modern 2D fighting games (Skullgirls, BlazBlue), bold clean dark-plum outline (#24141F), cel shading with 2–3 tones and soft gradients, crisp sharp details. Warm key light from the upper left, cool pale-blue rim light on the right side. Background: perfectly flat solid magenta #FF00FF, no gradient, no floor, no cast shadow. Do not use pink, magenta or purple on the character. NO text, NO frame numbers, NO watermark, NO borders.
```

### 4. Илья — лёгкий удар рукой (`ilya/st_lp`), 3 кадра

```
Sprite sheet for a 2D fighting game: 3 animation frames of the SAME character in one horizontal row, left to right, evenly spaced with clear empty magenta space between the frames, no frame touches another or the image edge. The character is ILYA MUROMETS exactly as in the attached model sheet: cartoon giant bogatyr with huge barrel chest, broad shoulders, short sturdy legs, thick light-brown beard to the belt, pointed conical steel shishak helmet with chainmail aventail, chainmail over a long crimson-red kaftan with golden trim, wide brown belt with a round bronze buckle, baggy dark-blue trousers, red boots with upturned toes, massive spiked iron mace. Strict side view facing RIGHT, full body visible, both feet planted on ONE flat horizontal ground line at the same height in every frame, the same size in every frame. Animation: QUICK STRAIGHT JAB with the front (right) fist — the mace stays in the rear hand resting on his shoulder in all frames. Frame 1 (wind-up): the front fist pulled slightly back, shoulders twisting, weight shifting. Frame 2 (hit): the front arm fully extended straight forward to the right at shoulder height, big fist punching forward, body leaning into the punch, beard swinging forward, a few short speed lines behind the fist. Frame 3 (recovery): the arm half retracted back toward the guard. Feet stay planted in the same place in all frames. HD hand-painted cartoon style like modern 2D fighting games (Skullgirls, BlazBlue), bold clean dark-plum outline (#24141F), cel shading with 2–3 tones and soft gradients, crisp sharp details, dynamic and punchy. Warm key light from the upper left, cool pale-blue rim light on the right side. Background: perfectly flat solid magenta #FF00FF, no gradient, no floor, no cast shadow. Do not use pink, magenta or purple on the character. NO text, NO frame numbers, NO watermark, NO borders.
```

## Полный список анимаций (промпты — по партиям в следующих подэтапах)

Ключевые кадры; промежуточные дорабатывает игра. Одинаково для обоих бойцов, кроме приёмов.

| Анимация | Кадров | Подэтап |
|---|---|---|
| idle — стойка | 4 | 3.2 / 3.6 |
| st_lp — лёгкий рукой | 3 | 3.2 / 3.7 |
| walk_f / walk_b — шаг вперёд / назад | 6 / 6 | 3.3 / 3.6 |
| run — бег, backdash — отскок | 6 / 3 | 3.3 / 3.6 |
| crouch — присед (переход + поза) | 2 | 3.3 / 3.6 |
| jump — подготовка, взлёт, верх, падение, приземление | 5 | 3.3 / 3.6 |
| block / block_low — блок стоя / сидя | 2 / 2 | 3.3 / 3.6 |
| st_lk, st_hp, st_hk — остальные удары стоя | 3–4 | 3.4 / 3.7 |
| cr_lp, cr_lk, cr_hp (апперкот), cr_hk | 3–4 | 3.4 / 3.7 |
| j_lp, j_lk, j_hp, j_hk — удары в прыжке | 2–3 | 3.4 / 3.7 |
| sweep, round — подсечка, с разворота | 4 | 3.4 / 3.7 |
| hit_high, hit_low — получил удар | 2 / 2 | 3.4 / 3.7 |
| air_hit, knockdown, get_up — отброшен, лежит, встаёт | 3 / 2 / 3 | 3.4 / 3.7 |
| throw, thrown — бросок / брошен | 4 / 3 | 3.4 / 3.7 |
| спецприёмы (4 у каждого), super | 4–6 | 3.5 / 3.8 |
| win, ko — победа, нокаут | 3 / 2 | 3.5 / 3.8 |
