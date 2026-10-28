# Сад Гесперид (`hesperides`) — карта из 3 картинок (без роликов)
К каждой картинке прикладывайте референсом нынешнюю картинку Сада (`hesperides_reference.webp`), к 2 и 3 — ещё и готовую картинку 1.
Движение (облака, блики на воде, качание дерева) игра сделает сама.

### 1. Небо и даль (`sky`, 16:9)
```
PROMPT:
Match the art style, palette and lighting of the attached reference image (the Garden of the Hesperides stage). Wide 2D fighting game stage background layer, SKY AND FAR DISTANCE ONLY, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, crisp sharp details, no blur. Strict side view, a perfectly flat horizontal horizon at 60% of the image height. A warm golden sunset: an orange, rose-gold and soft violet sky with soft layered clouds, the setting sun low over a calm sea on the right with a golden glitter path on the water, distant rocky islands and sea stacks in soft mist, and far away on the right horizon the huge hazy silhouette of the titan Atlas holding up the sky on his shoulders. The bottom 40% of the image below the horizon is the calm sea and soft mist only. Medium saturation, calm behind the fighters. NO trees, NO columns, NO garden, NO ground in the foreground, NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
trees, foreground objects, columns, garden, apple tree, dragon, ground, floor, characters, people, birds in the foreground, text, letters, watermark, signature, frame, border, tilted horizon, perspective, blur, depth of field, photo, 3D render, magenta
```

### 2. Середина: дерево и сад (`forest`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Garden of the Hesperides stage and its sky layer). MIDDLE-GROUND layer of a 2D fighting game stage on a flat solid magenta background, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, crisp sharp details, no blur. Strict side view. All objects stand on one flat horizontal line at the very bottom edge of the image. In the center the great sacred apple tree with a thick twisted trunk and a wide crown full of shining golden apples, a huge golden dragon's tail with big scales coiled around its roots and the rocks below it; on the left a small round marble rotunda with a blue dome, a marble fountain with water falling down a few stone steps, dark cypresses; on the right two tall marble columns wrapped with flowering vines and a stone vase with flowers; a low marble balustrade with benches runs along the bottom between them. The crown of the tree reaches 85% of the image height. Everything around and between the objects is perfectly flat solid magenta #FF00FF: no sky, no clouds, no sea, no gradient, no shadow. Do not use pink, magenta or purple anywhere on the objects (the flowers are white, gold and red). NO characters, NO dragon head, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, clouds, sea, sunset, sun, background landscape, gradient background, floor in the foreground, characters, people, nymphs, dragon head, pink, magenta, purple, violet on the objects, text, letters, watermark, signature, frame, perspective, blur, depth of field, photo, 3D render
```

### 3. Пол (`ground`, 16:9, на пурпуре)
```
PROMPT:
Match the art style, palette and lighting of the attached reference images (the Garden of the Hesperides stage and its sky layer). GROUND layer of a 2D fighting game stage, 16:9, maximum resolution. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients, crisp sharp details, no blur. Strict side view of a flat floor seen slightly from above. The top edge of the floor is ONE perfectly straight horizontal line at exactly 55% from the top of the image; below it a flat garden terrace of large pale cream stone tiles with fine cracks, warm sunset light, scattered golden autumn leaves and a few fallen golden apples near the left and right edges, low flowering bushes and white lilies along the very bottom corners. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Everything ABOVE the floor line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the floor. NO characters, NO text, NO watermark, NO frame.

NEGATIVE PROMPT:
sky, trees, columns, background, horizon, gradient background, characters, people, pink, magenta, purple, violet on the floor, text, letters, watermark, signature, frame, tilted floor line, strong perspective, blur, depth of field, photo, 3D render
```
