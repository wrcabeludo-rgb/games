# Перевал — общая карта Геракла и Кощея (`pass`), живая, из 3 слоёв
Сейчас у карты одна картинка-заглушка. Делаем как Сад Гесперид: 3 картинки (небо, середина, пол) + ролик неба.
К каждой картинке прикладывайте референсом нынешнюю картинку Перевала (`pass.webp`, прислал файлом), к 2а и 3а — ещё и картинку 1а.
Ролики середины и пола Veo в прошлый раз делать отказался — если получатся, присылайте, нет — игра оживит их сама.

### 1а. Картинка — небо и даль (`pass/sky`, 16:9)
```
PROMPT:
Match the art style, palette and lighting of the attached reference image (the Mountain Pass stage). Wide 2D fighting game stage background layer, SKY AND FAR DISTANCE ONLY, 16:9. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, crisp sharp details. Strict side view, a perfectly flat horizontal horizon at 60% of the image height. The LEFT half is a warm golden late afternoon over distant sunlit Greek mountains: amber, gold and soft orange sky, the low sun near the far-left horizon, faraway golden peaks with a tiny white ruined temple. The RIGHT half is a gloomy green-grey dusk over a distant dark northern taiga: murky olive-green and slate sky with heavy clouds, faraway black hills of firs and on the highest crag a tiny thin black tower with one glowing green window. A smooth painterly transition in the middle, a deep misty gorge between the two halves. Below the horizon only soft mist and far hills. NO bridge, NO foreground objects, NO ground in the foreground, NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
foreground objects, bridge, statues, trees in the foreground, ground, floor, characters, people, animals, text, letters, watermark, signature, frame, border, tilted horizon, strong perspective, blur, depth of field, photo, 3D render, magenta
```

### 1б. Ролик — небо (`pass/sky`, 8–10 с)
```
PROMPT:
The camera is completely static for the whole video: no zoom, no pan, no camera movement. A calm living sky exactly as in the image: on the left the warm golden clouds drift very slowly to the left and the low sun glows softly; on the right the heavy green-grey clouds slowly roll and churn, a faint green light pulses gently in the window of the distant black tower; mist slowly drifts in the gorge in the middle; a few tiny distant birds glide far away on the left. The mountains, hills and the tower do not move. Everything moves slowly and smoothly so the video can loop seamlessly: the last frame looks exactly like the first frame. The style, colors and composition stay exactly as in the image. Silent video, no audio.

NEGATIVE PROMPT:
camera movement, zoom, pan, fast motion, lightning, rain, storm, the sun moving, day turning to night, new objects appearing, characters, people, text, watermark, morphing, flicker, scene change
```

### 2а. Картинка — середина: горы, мост, тайга (`pass/forest`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Mountain Pass stage and its sky layer). MIDDLE-GROUND layer of a 2D fighting game stage on a flat solid magenta background, 16:9. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, crisp sharp details. Strict side view. All objects stand on one flat horizontal line at the very bottom edge of the image. On the LEFT: sunlit golden-ochre rocks of Greece with two broken white marble columns of a ruined temple of Zeus, a big marble lion statue lying on a rock and two dark cypresses. In the CENTER: an old arched stone bridge over a deep gorge, a thin waterfall falling from the rocks under the bridge. On the RIGHT: dark rocks overgrown with dense tall black-green firs of the northern taiga, a crooked dead tree with a raven's nest and an old wooden signpost with no letters. The tallest objects reach 80% of the image height. Everything around and between the objects is perfectly flat solid magenta #FF00FF: no sky, no clouds, no gradient, no shadow. Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, clouds, sun, background landscape, gradient background, floor in the foreground, characters, people, animals, birds, pink, magenta, purple, violet on the objects, text, letters, watermark, signature, frame, perspective, blur, depth of field, photo, 3D render
```

### 3а. Картинка — пол (`pass/ground`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Mountain Pass stage and its sky layer). GROUND layer of a 2D fighting game stage, 16:9. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, crisp sharp details. Strict side view of a flat floor seen slightly from above. The top edge of the floor is ONE perfectly straight horizontal line at exactly 55% from the top of the image; below it a flat mountain road of large worn grey paving stones: on the left warm and sunlit with a few fallen golden leaves and a broken marble fragment in the corner, on the right cold and shadowy with fir needles, small mossy stones and a patch of thin frost in the corner. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Everything ABOVE the floor line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the floor. NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, trees, columns, bridge, background, horizon, gradient background, characters, people, pink, magenta, purple, violet on the floor, text, letters, watermark, signature, frame, tilted floor line, strong perspective, blur, depth of field, photo, 3D render
```
