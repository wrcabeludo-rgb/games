# Храм Афины (`temple`) — карта из 3 картинок
Референсы: к 1 — прежняя картинка Храма (`temple_reference.webp`); к 2 и 3 — прежняя картинка и готовая картинка 1.
Движение (огонь в чашах, солнечные лучи, пылинки в свете) игра сделает сама.

### 1. Задний план: дальняя стена и вид наружу (`sky`, 16:9)
```
PROMPT:
Match the art style, palette and lighting of the attached reference image (the Temple of Athena stage). Wide 2D fighting game stage background layer, BACK WALL OF THE TEMPLE ONLY, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view, perfectly frontal flat back wall. The inner back wall of a great white marble Greek temple in warm afternoon light: in the center a tall colossal statue of Athena in a golden helmet with a spear and a round shield with an owl, standing on a high pedestal, softly lit by a beam of sunlight from above; on both sides tall open arches between marble pilasters show a bright blue sky with soft white clouds and a distant calm sea and olive groves of Greece; painted friezes of owls and olive branches along the top, hanging bronze lamps. The lower 40% of the image is the base of the wall and the pedestal, calm and low-detail. Medium saturation, calm behind the fighters. NO columns in the foreground, NO floor in the foreground, NO characters, NO people, NO text, NO letters, NO watermark, NO frame.

NEGATIVE PROMPT:
foreground columns, floor, characters, people, Athena alive, Medusa, snakes, text, letters, inscriptions, watermark, signature, frame, border, tilted lines, strong perspective, blur, depth of field, photo, 3D render, magenta
```

### 2. Середина: колонны и убранство зала (`forest`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Temple of Athena stage and its back wall layer). MIDDLE-GROUND layer of a 2D fighting game stage on a flat solid magenta background, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view. All objects stand on one flat horizontal line at the very bottom edge of the image. On the LEFT and on the RIGHT: two pairs of tall fluted white marble Ionic columns with gilded capitals, reaching the top edge of the image, joined at the top by a marble architrave with a painted frieze. Between and near them: tall bronze tripod braziers with warm fire, marble benches, a small altar with offerings of olive branches and amphorae, a stand with old Greek bronze armor and shields, a wooden loom with an unfinished tapestry, a marble owl on a low pillar. The CENTER of the image stays EMPTY magenta, so the back wall and the statue are visible behind. Everything around and between the objects is perfectly flat solid magenta #FF00FF: no back wall, no sky, no gradient, no shadow. Do not use pink, magenta or purple anywhere on the objects. NO characters, NO people, NO text, NO letters, NO watermark, NO frame.

NEGATIVE PROMPT:
back wall, sky, statue of Athena, background, gradient background, floor in the foreground, objects in the center, characters, people, pink, magenta, purple, violet on the objects, text, letters, watermark, signature, frame, perspective, blur, depth of field, photo, 3D render
```

### 3. Пол (`ground`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Temple of Athena stage and its back wall layer). GROUND layer of a 2D fighting game stage, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view of a flat floor seen slightly from above. The top edge of the floor is ONE perfectly straight horizontal line at exactly 55% from the top of the image; below it a polished white and pale gold marble floor with a large mosaic border of a Greek meander pattern and an owl medallion near the bottom center, warm sunlight patches falling from the arches, soft reflections; scattered olive leaves and a fallen bronze helmet in the bottom left corner, a cracked marble fragment and a few rose petals in red and white in the bottom right corner. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Everything ABOVE the floor line is perfectly flat solid magenta #FF00FF (no wall, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the floor. NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
wall, columns, sky, background, horizon, gradient background, characters, people, pink, magenta, purple, violet on the floor, text, letters, watermark, signature, frame, tilted floor line, strong perspective, blur, depth of field, photo, 3D render
```
