# Главное меню — «Расколотый мир»

Опросник (31.10): фон — расколотый мир (слева свет, справа тьма, в центре трещина-портал Скроллера); живое — портал
(пульсирует, искры), летучие мыши и вороны, молнии и облака на тёмной стороне; бойцы — по пояс Илья (слева) и Дракула
(справа), дышат и подмигивают. Остальные бойцы пока скрыты (второй ряд сетки закрыт).

## 1. Фон (`art_src/menu/bg.png`, ChatGPT, «Создать изображение», 16:9)
```
PROMPT:
A wide 16:9 background painting for the title screen of a 2D fighting game, HD hand-painted fantasy style like modern 2D fighting games (Skullgirls, BlazBlue), rich detail, no characters, no people, no text. The world is split in two halves by a huge glowing vertical crack in the sky and the ground in the exact center of the image: the crack is a jagged rift of bright cyan-white and electric-blue light, as if reality is torn open, with a few floating rock fragments around it. LEFT HALF — the side of light at golden sunset: a wide Russian steppe with birch groves and a wooden fortress with onion domes far away, and a white marble Greek temple with columns on a hill, warm golden and orange sky with soft clouds, warm light. RIGHT HALF — the side of darkness at night under a heavy storm: black jagged mountains, a gothic vampire castle with tall spires on a cliff with a few lit windows, a huge dead twisted oak, cold blue moonlight, dark purple-grey storm clouds — use dark blue and grey for the storm, not pink or magenta. The bottom third of the image is an empty rocky plateau in the foreground, darker, calm and free of objects (the game draws the menu and the heroes over it). The sky in the upper part stays fairly open with no birds and no lightning bolts (the game animates them). Cinematic, symmetrical composition, high contrast between the warm left and the cold right. NO text, NO logo, NO watermark, NO frame, NO characters, NO animals.

NEGATIVE PROMPT:
people, characters, heroes, animals, birds, bats, lightning bolts, text, letters, logo, title, watermark, frame, border, pink, magenta, purple sky, anime, photo, 3D render, blurry
```

## 2. Облака для анимации (`art_src/menu/clouds.png`, тот же стиль)
```
PROMPT:
Four separate dark storm clouds for a 2D game, HD hand-painted fantasy style matching image 1 (the right, dark half of the title screen background): heavy dark blue-grey storm clouds with soft lit edges of cold moonlight, each cloud wide and flat, horizontal, with clear empty space between them, arranged in ONE horizontal row, 16:9 image. Background: perfectly flat solid magenta #FF00FF, no gradient. The clouds must not use pink, magenta or purple. NO text, NO lightning, NO birds.

NEGATIVE PROMPT:
lightning, birds, text, watermark, pink or magenta clouds, purple, gradient background, frame
```

## 3. Живые портреты для заставки (`title_idle` у Ильи и Дракулы, Veo в Gemini) — стартовые `<боец>_portrait_start.png`
Один ролик на бойца, 10 с, зацикливается (первый и последний кадр — поза картинки). {WHO} — описание бойца.
```
Animate this 2D fighting game character-select portrait, half-body front view exactly as in the image: {WHO}. He keeps exactly the same face, costume, colors, proportions and hand-painted style in every frame; the first frame and the last frame are exactly the pose of the image. He stays in this pose the whole time, calm and confident, breathing slowly so his chest and shoulders gently rise and fall. At about 3 seconds he gives the viewer a quick sly wink with one eye and a small smile, then looks straight at the viewer again. At about 7 seconds he blinks once naturally. Small natural movements only: no walking, no turning around, no big gestures. Static camera, no zoom, no pan. There is no second character. The background stays flat solid magenta. Exactly two arms and two hands. Silent video, no audio.
```
Илья: {WHO} = a huge bearded Russian bogatyr warrior in chainmail and a pointed helmet with a spiked mace on his shoulder.
Дракула: {WHO} = a pale handsome vampire count with pointed ears, red eyes and a black-and-red high-collar cape.
