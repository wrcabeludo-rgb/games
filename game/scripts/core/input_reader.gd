class_name InputReader
extends RefCounted
## Читает клавиатуру и геймпады и превращает их в битовые маски InputBits.
## Это единственное место, где игра обращается к устройствам ввода.
## Клавиши проверяются по физическому положению, поэтому работают при любой раскладке.

## Клавиатура: [бит, клавиша] для каждого игрока.
const KEYS := [
	[
		[InputBits.UP, KEY_W], [InputBits.DOWN, KEY_S],
		[InputBits.LEFT, KEY_A], [InputBits.RIGHT, KEY_D],
		[InputBits.LP, KEY_U], [InputBits.HP, KEY_I],
		[InputBits.LK, KEY_J], [InputBits.HK, KEY_K],
		[InputBits.BLOCK, KEY_L], [InputBits.START, KEY_ENTER],
	],
	[
		[InputBits.UP, KEY_UP], [InputBits.DOWN, KEY_DOWN],
		[InputBits.LEFT, KEY_LEFT], [InputBits.RIGHT, KEY_RIGHT],
		[InputBits.LP, KEY_KP_4], [InputBits.HP, KEY_KP_5],
		[InputBits.LK, KEY_KP_1], [InputBits.HK, KEY_KP_2],
		[InputBits.BLOCK, KEY_KP_6], [InputBits.START, KEY_KP_ENTER],
	],
]

## Геймпад (раскладка DualSense / Xbox): [бит, кнопка].
## Квадрат — ЛР, крест — ЛН, треугольник — СР, круг — СН, R1 — блок.
const PAD_BUTTONS := [
	[InputBits.LP, JOY_BUTTON_X],
	[InputBits.LK, JOY_BUTTON_A],
	[InputBits.HP, JOY_BUTTON_Y],
	[InputBits.HK, JOY_BUTTON_B],
	[InputBits.BLOCK, JOY_BUTTON_RIGHT_SHOULDER],
	[InputBits.START, JOY_BUTTON_START],
	[InputBits.UP, JOY_BUTTON_DPAD_UP],
	[InputBits.DOWN, JOY_BUTTON_DPAD_DOWN],
	[InputBits.LEFT, JOY_BUTTON_DPAD_LEFT],
	[InputBits.RIGHT, JOY_BUTTON_DPAD_RIGHT],
]

const STICK_DEADZONE := 0.5
const TRIGGER_THRESHOLD := 0.5


## Геймпад игрока: первый подключённый — игроку 1, второй — игроку 2. -1, если нет.
func pad_for(player: int) -> int:
	var pads := Input.get_connected_joypads()
	pads.sort()
	return pads[player] if player < pads.size() else -1


func read(player: int) -> int:
	var bits := 0
	for pair in KEYS[player]:
		if Input.is_physical_key_pressed(pair[1]):
			bits |= pair[0]
	var pad := pad_for(player)
	if pad >= 0:
		bits |= _read_pad(pad)
	return bits


func device_label(player: int) -> String:
	var pad := pad_for(player)
	var keys := "WASD" if player == 0 else "стрелки"
	if pad < 0:
		return "клавиатура (%s)" % keys
	return "%s + клавиатура (%s)" % [Input.get_joy_name(pad), keys]


func _read_pad(pad: int) -> int:
	var bits := 0
	for pair in PAD_BUTTONS:
		if Input.is_joy_button_pressed(pad, pair[1]):
			bits |= pair[0]
	var x := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
	if x <= -STICK_DEADZONE:
		bits |= InputBits.LEFT
	elif x >= STICK_DEADZONE:
		bits |= InputBits.RIGHT
	if y <= -STICK_DEADZONE:
		bits |= InputBits.UP
	elif y >= STICK_DEADZONE:
		bits |= InputBits.DOWN
	if Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) >= TRIGGER_THRESHOLD:
		bits |= InputBits.BLOCK
	return bits
