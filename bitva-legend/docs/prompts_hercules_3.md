# Геракл — защита, урон, падение, броски, суперприём, радость, добивания

## Опросник (30.10)
- Блок стоя — закидывает непробиваемую львиную шкуру вперёд, как щит; сидя — накрывается ею с головой.
- Урон — боксёр: в голову голова дёргается, трясёт ею и ухмыляется; сильный — ноги подкашиваются, шаг назад;
  в корпус — сгибается с выдохом; по ногам — приседает на одну ногу.
- Падение — тяжело рушится на спину; вставание — вскакивает «на кип» и разминает шею.
- Его бросают — общая поза «летит» + обычное падение (без своих листов бросаемого).
- Суперприём «Двенадцать подвигов» — ролик без соперника: рывок, в «кино» шквал из 12 кулаков, апперкот в небо
  (соперника рисует игра, как у Кощея).
- Добивание — «нокаут и счёт»: один апперкот, соперник ложится, Геракл считает на пальцах до десяти, как судья,
  и поднимает себе руку.
- Радость после выбора — 1: натягивает львиную пасть и рычит; 2: пара боксёрских ударов в воздух и подмигивание.
- Бросок через бедро и Объятия Антея — роликом без соперника (как бросок Кощея).

## I. Блоки (`block`, `block_low`) — стартовая `hercules_stance_start.png`
```
Animate this 2D fighting game character in strict side view as a flat 2D cartoon character that never turns toward the camera, always facing right, with exactly the same design, colors, size and drawing style. He is a tall lean ancient Greek boxer in a lion pelt. There is no opponent. 0-1 s: boxer's guard. 1-4 s: he whips the lion pelt cape forward and holds it in front of his body with both arms like a shield, the lion head over his head, braced and breathing behind it, then lowers it back to guard. 4-5 s: guard. 5-6 s: he drops into a deep low crouch. 6-9 s: in the crouch he pulls the lion pelt over himself and hides completely under it like under a shield, breathing, then throws it back. 9-10 s: he holds the deep crouch, fists up. Static camera, no zoom, no pan; he keeps the same size and stays on the grey floor strip. Exactly two arms and two legs. The background above the floor stays flat solid magenta the whole time. Sound: rustle of fur, no music, no speech.
```

## J. Урон (`hit_high`, `hit_heavy`, `hit_body`, `hit_legs`) — стартовая `hercules_stance_start.png`
```
Animate this 2D fighting game character in strict side view as a flat 2D cartoon character that never turns toward the camera, always facing right, with exactly the same design, colors, size and drawing style. He is a tall lean ancient Greek boxer in a lion pelt. There is no opponent and nothing touches him: he only reacts as if hit by invisible punches, four times, returning to his guard after each. 0-2 s: his head snaps back as if punched in the face, he shakes his head and grins. 2-4.5 s: a heavy blow: his knees buckle, he staggers one step back and recovers. 4.5-7 s: as if punched in the stomach, he doubles over with a grunt and straightens up. 7-9 s: as if kicked in the shin, he dips down on one leg and straightens up. 9-10 s: guard. Static camera, no zoom, no pan; he keeps the same size and stays on the grey floor strip. Exactly two arms and two legs. The background above the floor stays flat solid magenta the whole time. Sound: short grunts, no music, no speech.
```

## K. Падение и вставание (`fall`, `get_up`) — стартовая `hercules_stance_start.png`
```
Animate this 2D fighting game character in strict side view as a flat 2D cartoon character that never turns toward the camera, always facing right, with exactly the same design, colors, size and drawing style. He is a tall lean ancient Greek boxer in a lion pelt. There is no opponent. 0-1 s: boxer's guard. 1-3 s: as if knocked out by a huge invisible blow, he flies back and crashes heavily onto his back on the grey floor, the lion pelt spread under him. 3-6 s: he lies still on his back on the floor, chest breathing. 6-8 s: he swings his legs up and springs back onto his feet in one move with a kip-up, without using his hands. 8-10 s: he rolls his neck and shoulders and returns to his boxer's guard. The whole body stays fully inside the frame. Static camera, no zoom, no pan; he keeps the same size and stays on the grey floor strip. Exactly two arms and two legs. The background above the floor stays flat solid magenta the whole time. Sound: a heavy thud and a confident grunt, no music, no speech.
```

## L. Суперприём «Двенадцать подвигов» (`super`, `super_cinema`) — стартовая `hercules_stance_start.png`
```
Animate this 2D fighting game character in strict side view as a flat 2D cartoon character that never turns toward the camera, always facing right, with exactly the same design, colors, size and drawing style. He is a tall lean ancient Greek boxer in a lion pelt. There is no opponent; he punches the empty air in front of him in place. 0-1 s: boxer's guard. 1-2.5 s: he dashes forward on the spot and throws a hard straight punch. 2.5-8 s: a furious flurry of twelve fast boxing punches into the air in front of him at head and body height, jabs, hooks and crosses, both fists blurring, roaring. 8-9.5 s: a final huge uppercut, rising on his toes with the fist high above his head. 9.5-10 s: back to guard. The whole body and both fists stay fully inside the frame. Static camera, no zoom, no pan; he keeps the same size and stays on the grey floor strip. Exactly two arms and two legs. The background above the floor stays flat solid magenta the whole time. Sound: rapid punches and a roar, no music, no speech.
```

## M. Бросок через бедро и Объятия Антея (`throw`, `sp_bb_l`) — стартовая `hercules_stance_start.png`
```
Animate this 2D fighting game character in strict side view as a flat 2D cartoon character that never turns toward the camera, always facing right, with exactly the same design, colors, size and drawing style. He is a tall lean ancient Greek boxer in a lion pelt. There is no opponent: he grapples an invisible man in front of him in place, his hands closing on empty air. 0-1 s: boxer's guard. 1-4 s: a hip throw: he grabs the air in front of him at belt and shoulder height, turns his hip in and heaves forward and down over his hip, then straightens up and flexes his biceps. 4-5 s: guard. 5-9 s: a bear hug: he wraps both arms around the empty air in front of his chest, lifts and squeezes hard with a strained face, shakes it, then slams it down to the floor in front of him. 9-10 s: guard. Static camera, no zoom, no pan; he keeps the same size and stays on the grey floor strip. Exactly two arms and two legs. The background above the floor stays flat solid magenta the whole time. Sound: effort grunts and a heavy thud, no music, no speech.
```

## N. Радость после выбора (`select_win`, `select_win_b`) — стартовая `hercules_portrait_start.png` (портрет по пояс)
```
Animate this 2D fighting game character-select portrait: a tall lean ancient Greek boxer in a lion pelt, half-body front view exactly as in the image, he looks at the viewer; he keeps exactly the same face, lion hood, colors, proportions and hand-painted style in every frame. The first frame, the middle frame at 5 s and the last frame are exactly the pose of the image. 0-5 s: he pulls the lion's head with the open fanged jaws down over his forehead, roars like a lion with his fists raised, then pushes the hood back and returns to the pose of the image. 5-10 s: he throws two quick boxing punches toward the viewer, then winks at the viewer with a sly grin and returns to the pose of the image. Static camera, no zoom, no pan. There is no second character. The background stays flat solid magenta. Exactly two arms and two hands. Sound: a lion roar and two whooshes, no music, no speech.
```

## Портрет (`select`, ChatGPT, режим редактирования)
Картинка 1 — модельный лист `art_src/fighters/hercules/model.png`, картинка 2 — стойка `art_src/start_images/hercules_stance_start.png`.
```
PROMPT:
Edit task. Image 1 is the approved model sheet of HERCULES, image 2 is his approved fighting stance. Redraw THIS EXACT character — copy his design faithfully from the attached images: the same face with the short thick ginger beard and moustache, narrow smiling eyes with laugh lines and the sly half-smile, the same Nemean lion pelt worn as a hood with the open fanged jaws over his head and his face fully visible under it, the golden mane over his shoulders, the lion paws knotted on his chest, the white chiton with the gold meander border over one shoulder, the bronze lion bracers and the brown leather wraps on his fists, the same tall lean boxer build, colors, line thickness and shading. Do NOT redesign anything, only change the pose. New content: ONE large character-select portrait, 16:9 image. A close-up HALF-BODY shot from the top of the lion head down to the waist — the body is cut off at the waist exactly by the bottom edge of the image; FRONT VIEW: he faces the camera, his face, chest and both shoulders turned toward the viewer, he LOOKS STRAIGHT INTO THE CAMERA, directly at the player, eye contact; he is in the center and fills the full height of the image with clear empty magenta space above the lion head: the top of the lion's ears is at about 8% below the top edge, nothing touches the top edge. Anatomy rules: correct anatomy, EXACTLY TWO arms and two hands — count them, there is NO third arm and NO extra hand anywhere; natural joints. Pose: a confident ancient Greek boxer, both wrapped fists raised loosely in front of his chest in a relaxed guard, a warm sly grin, eyes looking straight at the viewer. Calm, still pose (the game adds breathing by itself), mouth closed. HD hand-painted cartoon style like modern 2D fighting games (Skullgirls, BlazBlue), exactly like image 1, bold clean dark outline, cel shading with 2–3 tones and soft gradients, crisp sharp details. Warm golden key light from the upper left, cool pale-blue rim light on the right side. Background: perfectly flat solid magenta #FF00FF, no gradient, no floor, no cast shadow. Do not use pink, magenta or purple anywhere on the character. NO text, NO frame numbers, NO watermark, NO borders.

NEGATIVE PROMPT:
side view, profile, back view, full body, legs, feet, floor, cast shadow, extra arms, extra hands, weapon, club, redesign, different face, hair on the head, black hair, bulky bodybuilder, anime style, pink, magenta or purple on the character, gradient background, text, letters, watermark, frame, border, blur, photo, 3D render
```
