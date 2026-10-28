# Перевал (`pass`) — карта из 3 картинок, без роликов
Небо готово (`sky`, прислано). Осталось 2 картинки. Прикладывайте референсами: картинку неба (`sky`) и прежнюю картинку Перевала (`pass_reference.webp`).
Движение (облака, туман, огонёк башни, качание елей) игра сделает сама.

### 2. Середина: горы, мост, тайга (`forest`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the sky layer of the Mountain Pass stage: a golden sunset over Greek mountains on the left, a gloomy green-grey dusk over a dark taiga with a black tower on the right). MIDDLE-GROUND layer of a 2D fighting game stage on a flat solid magenta background, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view. All objects stand on one flat horizontal line at the very bottom edge of the image. On the LEFT, lit by the warm golden sunset light: sunlit golden-ochre rocks with two broken white marble columns of a ruined temple of Zeus, a big marble lion statue lying on a rock and two dark cypresses. In the CENTER: an old arched stone bridge over a deep gorge, a thin waterfall falling from the rocks under the bridge, wisps of grey mist in the gorge. On the RIGHT, in cold green-grey dusk light: dark rocks overgrown with dense tall black-green firs of the northern taiga, a crooked dead tree with a raven's nest and an old wooden signpost with no letters. The tallest objects reach 80% of the image height. Everything around and between the objects is perfectly flat solid magenta #FF00FF: no sky, no clouds, no distant mountains, no tower, no gradient, no shadow. Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO text, NO letters, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, clouds, sun, distant mountains, tower, background landscape, gradient background, floor in the foreground, characters, people, animals, birds, pink, magenta, purple, violet on the objects, text, letters, watermark, signature, frame, perspective, blur, depth of field, photo, 3D render
```

### 3. Пол (`ground`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the sky layer of the Mountain Pass stage: warm golden sunset light on the left, cold green-grey dusk on the right). GROUND layer of a 2D fighting game stage, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark outlines, cel shading with soft gradients, crisp sharp details, no blur. Strict side view of a flat floor seen slightly from above. The top edge of the floor is ONE perfectly straight horizontal line at exactly 55% from the top of the image; below it a flat mountain road of large worn grey paving stones: on the left warm and sunlit with a few fallen golden leaves and a broken marble fragment in the corner, on the right cold and shadowy with fir needles, small mossy stones and a patch of thin frost in the corner; a smooth transition of light in the middle. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Everything ABOVE the floor line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the floor. NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, trees, columns, bridge, background, horizon, gradient background, characters, people, pink, magenta, purple, violet on the floor, text, letters, watermark, signature, frame, tilted floor line, strong perspective, blur, depth of field, photo, 3D render
```
