class_name InputBits
extends RefCounted
## Состояние ввода одного игрока за один тик — битовая маска.
## По сети в будущем будет передаваться только это число.

const UP := 1
const DOWN := 2
const LEFT := 4
const RIGHT := 8
const LP := 16     # лёгкий удар рукой
const LK := 32     # лёгкий удар ногой
const HP := 64     # сильный удар рукой
const HK := 128    # сильный удар ногой
const BLOCK := 256
const START := 512

const DIRS := UP | DOWN | LEFT | RIGHT
const BUTTONS := LP | LK | HP | HK | BLOCK

## Кнопки атаки и блока в порядке показа: [бит, подпись].
const BUTTON_LABELS := [[LP, "НР"], [LK, "НН"], [HP, "ВР"], [HK, "ВН"], [BLOCK, "БЛ"]]


## Одновременное «влево + вправо» или «вверх + вниз» считается нейтралью.
static func clean_socd(bits: int) -> int:
	if (bits & LEFT) != 0 and (bits & RIGHT) != 0:
		bits &= ~(LEFT | RIGHT)
	if (bits & UP) != 0 and (bits & DOWN) != 0:
		bits &= ~(UP | DOWN)
	return bits


## Направление в нотации цифровой клавиатуры (5 — нейтраль, 6 — вправо, 2 — вниз...).
static func numpad(bits: int) -> int:
	var x := 0
	if (bits & LEFT) != 0:
		x = -1
	elif (bits & RIGHT) != 0:
		x = 1
	var y := 0
	if (bits & DOWN) != 0:
		y = -1
	elif (bits & UP) != 0:
		y = 1
	return 5 + x + y * 3


## Единичный вектор направления для отрисовки (ось Y вниз, как на экране).
@warning_ignore("integer_division")
static func numpad_vector(n: int) -> Vector2:
	var x := (n - 1) % 3 - 1
	var y := 1 - (n - 1) / 3
	return Vector2(x, y).normalized()
