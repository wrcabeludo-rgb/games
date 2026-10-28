# Карты Медузы: Остров Горгон (её карта) и Эгейский берег (общая карта Афины и Медузы)
Каждая карта — 3 картинки: небо, середина, пол. Движение игра сделает сама, роликов не нужно.
Референсы: к небу — прежняя картинка карты (`gorgon_isle.webp` / `coast.webp`, прислал файлами); к середине и полу — прежняя картинка и готовое небо этой же карты.

## Остров Горгон (`gorgon_isle`)

### 1. Небо и даль (`sky`, 16:9)
```
PROMPT:
Match the art style, palette and lighting of the attached reference image (the Isle of the Gorgons stage). Wide 2D fighting game stage background layer, SKY AND FAR DISTANCE ONLY, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view, a perfectly flat horizontal horizon at 60% of the image height. A gloomy stormy afternoon over a grey-green sea: heavy slate and teal storm clouds, a pale cold sun breaking through a gap in the clouds in the middle with soft rays, a dark choppy sea with white foam, distant black jagged rocky islets and sea stacks in mist, far away on the horizon a ruined Greek shrine on a lonely rock. The bottom 40% of the image below the horizon is the sea and mist only. Medium saturation, calm behind the fighters. NO foreground rocks, NO statues, NO cave, NO ground in the foreground, NO characters, NO snakes, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
foreground objects, statues, cave, trees in the foreground, ground, floor, characters, people, snakes, birds in the foreground, lightning bolts, text, letters, watermark, signature, frame, border, tilted horizon, perspective, blur, depth of field, photo, 3D render, magenta
```

### 2. Середина: пещера Горгон и окаменевшие воины (`forest`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Isle of the Gorgons stage and its sky layer). MIDDLE-GROUND layer of a 2D fighting game stage on a flat solid magenta background, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view. All objects stand on one flat horizontal line at the very bottom edge of the image. In the CENTER: a huge dark mouth of a sea cave in black volcanic rock, its entrance framed by ruined Greek columns overgrown with dark ivy, two cracked stone braziers with cold green flames on both sides of the entrance, carved stone snake heads above the arch. On the LEFT: grey stone statues of petrified Greek warriors frozen in fear — one raising a shield, one with a broken spear — standing among black rocks and a dead twisted olive tree. On the RIGHT: more black jagged rocks, a broken marble statue of a hero lying on its side, cracked amphorae and an old shattered shield half buried in the rocks. The tallest objects reach 80% of the image height. Everything around and between the objects is perfectly flat solid magenta #FF00FF: no sky, no sea, no clouds, no gradient, no shadow. Do not use pink, magenta or purple anywhere on the objects. NO characters, NO living people, NO living snakes, NO text, NO letters, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, clouds, sea, sun, background landscape, gradient background, floor in the foreground, characters, people, Medusa, living snakes, blood, pink, magenta, purple, violet on the objects, text, letters, watermark, signature, frame, perspective, blur, depth of field, photo, 3D render
```

### 3. Пол (`ground`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Isle of the Gorgons stage and its sky layer). GROUND layer of a 2D fighting game stage, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view of a flat floor seen slightly from above. The top edge of the floor is ONE perfectly straight horizontal line at exactly 55% from the top of the image; below it a flat floor of cracked dark grey volcanic stone slabs with old worn carvings of snakes, wet patches reflecting the cold light, small puddles of sea water, scattered pebbles and shells, in the bottom left corner a stone hand of a broken statue and dark seaweed, in the bottom right corner black rocks with white sea foam. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Everything ABOVE the floor line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the floor. NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, sea horizon, statues standing, cave, background, gradient background, characters, people, living snakes, blood, pink, magenta, purple, violet on the floor, text, letters, watermark, signature, frame, tilted floor line, strong perspective, blur, depth of field, photo, 3D render
```

## Эгейский берег (`coast`) — Эллада Афины слева, остров Горгон справа

### 1. Небо и даль (`sky`, 16:9)
```
PROMPT:
Match the art style, palette and lighting of the attached reference image (the Aegean Shore stage). Wide 2D fighting game stage background layer, SKY AND FAR DISTANCE ONLY, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view, a perfectly flat horizontal horizon at 60% of the image height. The LEFT half is a bright sunny Greek morning: a clear azure sky with soft white clouds, the sun high on the left, a calm turquoise sea glittering with light, a far-away white marble temple of Athena on a golden cliff. The RIGHT half is a gloomy storm over a grey-green sea: heavy slate storm clouds, rain streaks far away, dark choppy waves, and on the horizon the black jagged silhouette of the Isle of the Gorgons. A smooth painterly transition in the middle. The bottom 40% of the image below the horizon is the sea only. Medium saturation, calm behind the fighters. NO foreground objects, NO ground in the foreground, NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
foreground objects, columns in the foreground, trees in the foreground, ground, floor, characters, people, snakes, ships, birds in the foreground, lightning bolts, text, letters, watermark, signature, frame, border, tilted horizon, perspective, blur, depth of field, photo, 3D render, magenta
```

### 2. Середина: утёс с храмом, оливы, чёрные скалы (`forest`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Aegean Shore stage and its sky layer). MIDDLE-GROUND layer of a 2D fighting game stage on a flat solid magenta background, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view. All objects stand on one flat horizontal line at the very bottom edge of the image. On the LEFT, in bright sunlight: a golden limestone cliff with white marble steps and a small marble portico with two columns, silver-green olive trees, a stone owl statue of Athena on a pedestal, blue painted pottery. In the CENTER: a low sandy dune with a beached old Greek boat and a few wooden posts. On the RIGHT, in cold storm light: black jagged sea rocks with white foam at their feet, a grey stone statue of a petrified warrior frozen in fear, a dead twisted tree and a broken shield. The tallest objects reach 75% of the image height. Everything around and between the objects is perfectly flat solid magenta #FF00FF: no sky, no sea, no clouds, no gradient, no shadow. Do not use pink, magenta or purple anywhere on the objects. NO characters, NO living people, NO text, NO letters, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, clouds, sea, sun, background landscape, gradient background, floor in the foreground, characters, people, Athena, Medusa, snakes, pink, magenta, purple, violet on the objects, text, letters, watermark, signature, frame, perspective, blur, depth of field, photo, 3D render
```

### 3. Пол (`ground`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Aegean Shore stage and its sky layer). GROUND layer of a 2D fighting game stage, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view of a flat floor seen slightly from above. The top edge of the floor is ONE perfectly straight horizontal line at exactly 55% from the top of the image; below it a flat beach: on the left warm golden sand in bright sun with seashells, a fallen olive branch and a broken white marble column fragment in the corner; on the right cold wet grey sand and dark pebbles in storm light, with tangled seaweed and a small black rock with sea foam in the corner; a smooth transition of light in the middle. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Everything ABOVE the floor line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the floor. NO characters, NO footprints, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, sea horizon, waves, trees, columns standing, background, gradient background, characters, people, footprints, pink, magenta, purple, violet on the floor, text, letters, watermark, signature, frame, tilted floor line, strong perspective, blur, depth of field, photo, 3D render
```
