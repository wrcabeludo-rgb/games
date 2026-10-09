# Кощеево царство — своя карта Кощея (`koschei_realm`)

Холодные зелёные сумерки. Слева — мёртвый чёрный замок Кощея, ворота открыты, внутри чахнет золото. В центре вдали — огромный дуб на скале посреди моря-океана, на нём на цепях висит сундук (отдельной картинкой: игра его покачивает, а при поражении Кощея сундук дёрнется). Справа — берег и мёртвые холмы. Земля — мёртвая дорога с костями и ржавым оружием витязей.

Как делать: сначала небо (1), дальше прикладывайте его референсом ко всем остальным. Полосы — тремя панелями слева направо; для стыковки прикладывайте и предыдущую панель. Формат 21:9, максимальное разрешение. Обработка: `python3 tools/process_arena_art.py <папка> koschei_realm`.

## 1. Небо (`koschei_realm/sky`, 21:9, без пурпура)

Без референса. Луну не рисовать — она отдельной картинкой.

```
Wide 2D fighting game stage background for the stage «Koschei's Realm» from Russian fairy tales, SKY ONLY. HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. Smooth soft gradients, eerie fairy-tale mood. Strict side view, perfectly flat horizontal horizon at the very bottom edge. A cold dead twilight: the sky is a sickly green-grey (#3E5A44, #6F8F6A) fading to near-black charcoal green (#141C18) at the top edge; low layers of cold greenish mist lie along the horizon; a few thin long torn clouds; a faint pale light glows low in the upper left where the moon will be (do NOT draw the moon itself). NO moon, NO stars, NO mountains, NO trees, NO buildings, NO ground, NO characters, NO text, NO letters, NO watermark, NO frame or border. Medium-low saturation, it must stay calm behind the fighters. Format 21:9, maximum resolution.
```

## 2. Луна (`koschei_realm/moon`, 1:1)

Картинка 1 — небо.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). A single big low moon for a 2D fighting game background, drawn alone in the center of the image. HD hand-painted cartoon style, clean dark-plum outline (#24141F), cel shading. A cold pale moon with a sickly green-white tint (#DDE8CF), soft grey-green craters, a thin strip of greenish mist crossing its lower part. Everything around the moon is perfectly flat solid magenta #FF00FF (no sky, no glow, no halo, no gradient). Do not use pink, magenta or purple on the moon. NO text, NO watermark, NO frame.
```

## 3. Дальний план, панель 1 — замок Кощея (`koschei_realm/mountains_1`, 21:9)

Картинка 1 — небо.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 1 of 3 of a wide FAR BACKGROUND landscape strip for a 2D fighting game parallax layer (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. It is far away: soft atmospheric colors and lower contrast than the foreground, but the shapes and small details stay sharp and clean. Strict side view. The landscape spans the FULL width of the panel edge to edge (it continues into the next panels) and occupies only the bottom 55% of the image; the terrain and the sea horizon at the left and right edges of the panel are at the same height as in the other panels so the strip joins without steps. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). Koschei's dead castle on a black rocky hill: a gloomy fairy-tale Russian fortress of BLACK stone with tall pointed tent roofs and onion domes of tarnished dark gold, crooked towers, walls with jagged battlements. NO lights in the windows — the windows are dark, only a faint poison-green glimmer (#7CFF6B) deep inside a few of them. The big castle GATE in the front wall stands WIDE OPEN, and through the opening heaps of treasure are visible inside: mountains of tarnished dull-gold coins, chests, goblets and crowns, covered in grey cobwebs and dust, glinting weakly. The dark sea horizon starts at the right edge of the panel. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 4. Дальний план, панель 2 — дуб на скале (`koschei_realm/mountains_2`, 21:9)

Картинки: 1 — небо, 2 — панель 1.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 2 of 3 of a wide FAR BACKGROUND landscape strip for a 2D fighting game parallax layer (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. It is far away: soft atmospheric colors and lower contrast than the foreground, but the shapes and small details stay sharp and clean. Strict side view. The landscape spans the FULL width of the panel edge to edge (it continues into the next panels) and occupies only the bottom 55% of the image; the terrain and the sea horizon at the left and right edges of the panel are at the same height as in the other panels so the strip joins without steps. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). In the CENTER: a lone high steep rock rising from a cold dark grey-green sea (#2E3A33) with slow white-grey foam at its foot; on top of the rock grows ONE enormous ancient gnarled OAK, leafless and twisted, with a massive trunk and huge crooked branches spreading wide like claws — the tallest object of the whole strip, its crown reaching the top of the landscape area. One thick horizontal branch sticks out to the RIGHT of the trunk and is completely EMPTY: nothing hangs from it (a chest will be added there separately). To the left and right of the rock — the flat calm dark sea up to the horizon, a few small black rocks in the water. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 5. Дальний план, панель 3 — берег и мёртвые холмы (`koschei_realm/mountains_3`, 21:9)

Картинки: 1 — небо, 2 — панель 2.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 3 of 3 of a wide FAR BACKGROUND landscape strip for a 2D fighting game parallax layer (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. It is far away: soft atmospheric colors and lower contrast than the foreground, but the shapes and small details stay sharp and clean. Strict side view. The landscape spans the FULL width of the panel edge to edge (it continues into the next panels) and occupies only the bottom 55% of the image; the terrain and the sea horizon at the left and right edges of the panel are at the same height as in the other panels so the strip joins without steps. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). The dark sea continues from the left and ends at a rocky black shore; behind it low dead hills covered with bare black forest, a broken old watchtower of black stone on a hill, a ruined wooden bridge over a dark ravine, cold green mist lying in the hollows. Everything above the landscape is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 6. Средний план, панель 1 (`koschei_realm/forest_1`, 21:9)

Картинка 1 — небо.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 1 of 3 of a wide MIDDLE-GROUND strip for a 2D fighting game parallax layer — it stands behind the fighters (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Slightly muted colors so the fighters in front stay readable. Strict side view. The objects stand on one flat horizontal line at the very bottom edge of the image, are 50–85% of the image height, with uneven gaps between them; objects at the left and right edges continue into the neighbouring panels. Foliage and branches are BIG, simple, clearly separated shapes with clean outlines — no tiny noisy texture. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). A dead enchanted forest near the castle: tall leafless black trees with twisted claw-like branches, a broken black stone gate pillar with a hanging rusty chain, a crooked iron fence with spikes, a few thin dark fir trees, dead grey bushes. Everything around the objects is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 7. Средний план, панель 2 (`koschei_realm/forest_2`, 21:9)

Картинки: 1 — небо, 2 — панель 1.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 2 of 3 of a wide MIDDLE-GROUND strip for a 2D fighting game parallax layer — it stands behind the fighters (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Slightly muted colors so the fighters in front stay readable. Strict side view. The objects stand on one flat horizontal line at the very bottom edge of the image, are 50–85% of the image height, with uneven gaps between them; objects at the left and right edges continue into the neighbouring panels. Foliage and branches are BIG, simple, clearly separated shapes with clean outlines — no tiny noisy texture. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). The dead forest continues: bare twisted trees, an old overturned treasure chest spilling a few tarnished coins on the ground, a stone idol overgrown with grey moss, two ravens' empty nests in the branches, dead grey bushes. Everything around the objects is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 8. Средний план, панель 3 (`koschei_realm/forest_3`, 21:9)

Картинки: 1 — небо, 2 — панель 2.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 3 of 3 of a wide MIDDLE-GROUND strip for a 2D fighting game parallax layer — it stands behind the fighters (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Slightly muted colors so the fighters in front stay readable. Strict side view. The objects stand on one flat horizontal line at the very bottom edge of the image, are 50–85% of the image height, with uneven gaps between them; objects at the left and right edges continue into the neighbouring panels. Foliage and branches are BIG, simple, clearly separated shapes with clean outlines — no tiny noisy texture. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). The dead forest thins out toward the shore: bare twisted trees bent by the sea wind, a fallen dead trunk, a tall grey standing stone, dry reeds, dead grey bushes. Everything around the objects is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 9. Земля, панель 1 (`koschei_realm/ground_1`, 21:9)

Картинка 1 — небо.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 1 of 3 of a wide side-scrolling GROUND strip for a 2D fighting game stage — the floor where the fighters stand (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view of a flat floor seen slightly from above. The top edge of the ground is ONE perfectly straight horizontal line at exactly 35% from the top of the image, the same height in all three panels; the ground fills everything below it down to the bottom edge and spans the FULL width of the panel edge to edge. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). A dead road of cracked black-grey flagstones overgrown with dead grey grass; along the far edge — scattered old bones, a skull, a rusty broken sword stuck in the ground, a dented rusty knight's helmet (shishak), a few tarnished coins. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 10. Земля, панель 2 (`koschei_realm/ground_2`, 21:9)

Картинки: 1 — небо, 2 — панель 1.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 2 of 3 of a wide side-scrolling GROUND strip for a 2D fighting game stage — the floor where the fighters stand (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view of a flat floor seen slightly from above. The top edge of the ground is ONE perfectly straight horizontal line at exactly 35% from the top of the image, the same height in all three panels; the ground fills everything below it down to the bottom edge and spans the FULL width of the panel edge to edge. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). The same dead road continues: cracked flagstones, dead grey grass, a rusty round shield lying flat at the far edge, a broken spear, a few bones and an old rusty chain. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 11. Земля, панель 3 (`koschei_realm/ground_3`, 21:9)

Картинки: 1 — небо, 2 — панель 2.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 3 of 3 of a wide side-scrolling GROUND strip for a 2D fighting game stage — the floor where the fighters stand (the three panels will be placed side by side, left to right, and must join seamlessly). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Strict side view of a flat floor seen slightly from above. The top edge of the ground is ONE perfectly straight horizontal line at exactly 35% from the top of the image, the same height in all three panels; the ground fills everything below it down to the bottom edge and spans the FULL width of the panel edge to edge. The middle band of the floor is calm and low-detail so the fighters standing on it stay readable. Palette of the stage: cold sickly green mist (#6F8F6A, #3E5A44), dead grey-green and charcoal (#2E3A33, #1C2420), black stone, tarnished dull gold (#B08A3C) as the only warm accent, faint glowing poison-green lights (#7CFF6B). The road turns into grey rocky shore ground: flat grey stones, dead grass, pebbles, a rusty helmet and a broken sword near the far edge, a few small tide puddles reflecting the green sky. Everything ABOVE the ground line is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 12. Передний план, панель 1 (`koschei_realm/foreground_1`, 21:9)

Картинка 1 — небо.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 1 of 3 of a wide FOREGROUND strip for a 2D fighting game — it is drawn IN FRONT of the fighters at the very bottom of the screen (the three panels will be placed side by side, left to right). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Darker and more saturated than the background (close to the camera, in shadow). Strict side view. Objects grow from the bottom edge, at most 25% of the image height, with uneven gaps between the clumps (the fighters must stay visible between them). Nothing is cut by the left and right image edges — leave about 3% of empty space on both sides. Dead grey grass and dry thistles, a rusty dented helmet half-sunk into the ground, a few bones, dark dead bushes. Everything above them is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 13. Передний план, панель 2 (`koschei_realm/foreground_2`, 21:9)

Картинки: 1 — небо, 2 — панель 1.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 2 of 3 of a wide FOREGROUND strip for a 2D fighting game — it is drawn IN FRONT of the fighters at the very bottom of the screen (the three panels will be placed side by side, left to right). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Darker and more saturated than the background (close to the camera, in shadow). Strict side view. Objects grow from the bottom edge, at most 25% of the image height, with uneven gaps between the clumps (the fighters must stay visible between them). Nothing is cut by the left and right image edges — leave about 3% of empty space on both sides. Dead grey grass and thorny dry weeds, a skull, the hilt of a rusty sword sticking up, a small heap of tarnished coins in the grass. Everything above them is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 14. Передний план, панель 3 (`koschei_realm/foreground_3`, 21:9)

Картинки: 1 — небо, 2 — панель 2.

```
Match the art style, palette and lighting of the attached reference image (the sky of this stage). Panel 3 of 3 of a wide FOREGROUND strip for a 2D fighting game — it is drawn IN FRONT of the fighters at the very bottom of the screen (the three panels will be placed side by side, left to right). HD hand-painted cartoon style, clean dark-plum outlines (#24141F), cel shading with soft gradients. CRISP SHARP high-detail rendering at the maximum resolution (4K): every edge and small detail clearly defined, no blur, no soft focus, no depth of field, no haze, no painterly smudging. Darker and more saturated than the background (close to the camera, in shadow). Strict side view. Objects grow from the bottom edge, at most 25% of the image height, with uneven gaps between the clumps (the fighters must stay visible between them). Nothing is cut by the left and right image edges — leave about 3% of empty space on both sides. Dry reeds and dead grey grass, grey stones, a broken spear shaft, a rusty chain lying in the grass. Everything above them is perfectly flat solid magenta #FF00FF (no sky, no gradient, no shadow). Do not use pink, magenta or purple anywhere on the objects. NO characters, NO animals, NO people, NO text, NO letters, NO readable symbols, NO watermark, NO frame.
```

## 15. Сундук на цепях (`koschei_realm/chest`, 3:4)

Картинки: 1 — небо, 2 — дальний план, панель 2 (дуб).

```
Match the art style, palette and lighting of the attached reference images. A single object for a 2D fighting game background, drawn alone in the center of the image, strict side view: the FAIRY-TALE CHEST in which Koschei's death is hidden — a heavy old forged iron-bound chest of dark oak with rusty iron bands, a big rusty padlock and tarnished gold corners, hanging on FOUR heavy iron CHAINS; the chains converge upward into one big iron ring at the very top center of the image (the ring will be attached to the oak branch). HD hand-painted cartoon style, clean dark-plum outline (#24141F), cel shading with 2–3 tones, crisp sharp details. Cold green light from the upper left. Everything around the chest and chains is perfectly flat solid magenta #FF00FF (no sky, no branch, no tree, no gradient, no shadow). Do not use pink, magenta or purple on the object. NO text, NO letters, NO watermark, NO frame.
```
