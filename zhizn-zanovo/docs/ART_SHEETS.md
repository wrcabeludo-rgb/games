# «Жизнь заново» — листы-раскадровки (стиль «линер»)

Один лист = 9 сцен (сетка 3×3) в одном стиле: тонкий чёрный линер, только контуры. Лист режется скриптом
`python3 tools/slice_sheet.py <лист.png> <A|B|C>` (из `zhizn-zanovo/`) на отдельные картинки `art/scenes/<ключ>.webp`
и сразу подключается в игру (`js/data/art.js`). Сцена показывается над событиями своей темы в любом возрасте.

Генерировать в ChatGPT («Создать изображение»), горизонтальный формат 3:2 (1536×1024). Если ChatGPT нарисует меньше
или больше 9 ячеек, сетку сбил — лучше перегенерировать. Можно приложить картинку линера 80-х
(`art_src/stage/liner.png`) как образец стиля: «Use the attached image as the style reference».

## Лист A — семья и родители
```
A storyboard sheet: a 3 by 3 grid of NINE separate illustrations on one white page, every panel exactly the same size, horizontal 3:2 panels, separated by wide clean white gutters, no borders, no frames, no panel numbers, no text. All nine panels are drawn in one identical style: minimalist line art made only with a thin black fineliner pen on clean white paper, clean confident contour lines, uniform thin line weight, absolutely no shading, no hatching, no grey tones, no color, no fills, lots of empty white space. The same main character appears in several panels: an ordinary Russian man, seen from behind or in profile at a distance, face never detailed. Panels, left to right, top to bottom:
1) an elderly mother at a kitchen window talking on an old landline phone, a pot of geraniums on the sill;
2) a country house (dacha) garden: an elderly couple at a wooden table under an apple tree, a man walking towards them with a bag;
3) a father and his adult son seen from behind working together under the open hood of an old car in a garage, tools on the wall;
4) a long hospital corridor with a bench, a man sitting and waiting, a door with a small round window;
5) a young father holding a tiny newborn wrapped in a blanket, seen over his shoulder;
6) a first-grade schoolchild with a huge bouquet and a big backpack holding a man's hand at the school gate;
7) a closed bedroom door with a teenager's sticker-covered surface, a man standing in the hallway with his hand raised to knock;
8) a family dinner table seen from above: plates, a salad bowl, several hands passing dishes;
9) a grandfather and a small grandchild fishing together on a wooden pier at a lake.
Negative: shading, hatching, cross-hatching, grey tones, pencil texture, color, watercolor, fills, heavy black areas, panel borders, frames, numbers, captions, text, letters, logos, watermark, photorealism, 3D render, anime, detailed faces, uneven panel sizes, merged panels.
```

## Лист B — друзья, любовь, дорога, работа
```
A storyboard sheet: a 3 by 3 grid of NINE separate illustrations on one white page, every panel exactly the same size, horizontal 3:2 panels, separated by wide clean white gutters, no borders, no frames, no panel numbers, no text. All nine panels are drawn in one identical style: minimalist line art made only with a thin black fineliner pen on clean white paper, clean confident contour lines, uniform thin line weight, absolutely no shading, no hatching, no grey tones, no color, no fills, lots of empty white space. The same main character appears in several panels: an ordinary Russian man, seen from behind or in profile at a distance, face never detailed. Panels, left to right, top to bottom:
1) a student dormitory room at night: young people sitting on beds, one plays an acoustic guitar;
2) two friends at a small kitchen table late at night, two mugs, a single hanging lamp, seen from the side;
3) a motorcycle with two riders on an empty country road going to the horizon;
4) a young couple walking along a river embankment holding hands, seen from behind, a bridge in the distance;
5) a simple wedding: a couple seen from behind under a garden arch with string lights, guests' silhouettes;
6) a man and a woman sitting at opposite ends of a kitchen table, turned away from each other, tense silence;
7) a railway platform with a train, a woman waving from the window, a man standing on the platform;
8) an office desk by a large window with a city view, a laptop, a stack of papers, a cup, an empty chair;
9) a man standing at a window streaked with rain, seen from behind, hands in pockets.
Negative: shading, hatching, cross-hatching, grey tones, pencil texture, color, watercolor, fills, heavy black areas, panel borders, frames, numbers, captions, text, letters, logos, watermark, photorealism, 3D render, anime, detailed faces, uneven panel sizes, merged panels.
```

## Лист C — особые повороты
```
A storyboard sheet: a 3 by 3 grid of NINE separate illustrations on one white page, every panel exactly the same size, horizontal 3:2 panels, separated by wide clean white gutters, no borders, no frames, no panel numbers, no text. All nine panels are drawn in one identical style: minimalist line art made only with a thin black fineliner pen on clean white paper, clean confident contour lines, uniform thin line weight, absolutely no shading, no hatching, no grey tones, no color, no fills, lots of empty white space. The same main character appears in several panels: an ordinary Russian man, seen from behind or in profile at a distance, face never detailed. Panels, left to right, top to bottom:
1) army barracks: rows of metal bunk beds, a young soldier sitting on a bed writing a letter;
2) an outdoor market stall with fruit and scales, a young seller in an apron behind the counter;
3) a decorated New Year tree in a small apartment, a bowl of tangerines on the table, a clock;
4) an airport departure hall with big windows, a man with one suitcase looking at a plane outside;
5) a campfire at night near tents by a river, friends sitting around it;
6) a graduation: a young man in a gown throwing a cap into the air in front of a university building;
7) a quiet cemetery in birch trees, a man standing with flowers in front of a simple headstone, gentle and calm;
8) an elderly couple dancing slowly in a small living room, a record player on a shelf;
9) a seaside beach at sunset: a family's bags and towels on the sand, footprints leading to the water.
Negative: shading, hatching, cross-hatching, grey tones, pencil texture, color, watercolor, fills, heavy black areas, panel borders, frames, numbers, captions, text, letters, logos, watermark, photorealism, 3D render, anime, detailed faces, uneven panel sizes, merged panels.
```
