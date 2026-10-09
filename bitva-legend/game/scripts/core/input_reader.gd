class_name InputReader
extends RefCounted
## Читает клавиатуру и геймпады и превращает их в битовые маски InputBits.
## Это единственное место, где игра обращается к устройствам ввода.
## Клавиши проверяются по физическому положению, поэтому работают при любой раскладке.

## Клавиатура: [бит, клавиша] для каждого игрока. Удары и блок первого игрока — из Settings.key_map
## (переназначаются в настройках), у второго — постоянные.
const KEYS := [
	[
		[InputBits.UP, KEY_W], [InputBits.DOWN, KEY_S],
		[InputBits.LEFT, KEY_A], [InputBits.RIGHT, KEY_D],
		[InputBits.START, KEY_ENTER],
	],
	[
		[InputBits.UP, KEY_UP], [InputBits.DOWN, KEY_DOWN],
		[InputBits.LEFT, KEY_LEFT], [InputBits.RIGHT, KEY_RIGHT],
		[InputBits.LP, KEY_KP_4], [InputBits.HP, KEY_KP_5],
		[InputBits.LK, KEY_KP_1], [InputBits.HK, KEY_KP_2],
		[InputBits.BLOCK, KEY_KP_6], [InputBits.START, KEY_KP_ENTER],
	],
]

## Геймпад (раскладка DualSense / Xbox): [бит, кнопка]. Удары и блок — из Settings.pad_map.
const PAD_BUTTONS := [
	[InputBits.START, JOY_BUTTON_START],
	[InputBits.UP, JOY_BUTTON_DPAD_UP],
	[InputBits.DOWN, JOY_BUTTON_DPAD_DOWN],
	[InputBits.LEFT, JOY_BUTTON_DPAD_LEFT],
	[InputBits.RIGHT, JOY_BUTTON_DPAD_RIGHT],
]

## Одиночная игра (против ИИ): первым игроком управляет любой подключённый геймпад —
## на случай, если Windows видит лишний «виртуальный» геймпад и настоящий оказался вторым.
var single_player := false

## Отключения геймпадов за сессию и последнее событие — чтобы было видно, если геймпад «отваливается».
var pad_drops := 0
var pad_notice := ""
var pad_notice_ms := -100000


func _init() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)


## Крупная плашка по центру экрана на 4 секунды (геймпады, смена ИИ, тренировка).
func notify(text: String) -> void:
	pad_notice = text
	pad_notice_ms = Time.get_ticks_msec()


func _on_joy_changed(device: int, connected: bool) -> void:
	if not connected:
		pad_drops += 1
	var name := Input.get_joy_name(device) if connected else Loc.t("геймпад %d") % device
	pad_notice = (Loc.t("Подключён: %s") % name) if connected \
		else (Loc.t("ГЕЙМПАД ОТКЛЮЧИЛСЯ (%s) · отключений: %d") % [name, pad_drops])
	pad_notice_ms = Time.get_ticks_msec()

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
	if player == 0:
		for bit in Settings.key_map:
			if Input.is_physical_key_pressed(Settings.key_map[bit]):
				bits |= bit
	if single_player:
		if player == 0:
			for pad in Input.get_connected_joypads():
				bits |= _read_pad(pad)
		return bits
	var pad := pad_for(player)
	if pad >= 0:
		bits |= _read_pad(pad)
	return bits


func device_label(player: int) -> String:
	var drops := Loc.t(" · отключений геймпада: %d") % pad_drops if pad_drops > 0 and player == 0 else ""
	return _device_label(player) + drops


func _device_label(player: int) -> String:
	var keys := "WASD" if player == 0 else Loc.t("стрелки")
	if single_player and player == 0:
		var n := Input.get_connected_joypads().size()
		return Loc.t("любой геймпад (%d) + клавиатура (%s)") % [n, keys] if n > 0 else Loc.t("клавиатура (%s)") % keys
	var pad := pad_for(player)
	if pad < 0:
		return Loc.t("клавиатура (%s)") % keys
	return Loc.t("%s + клавиатура (%s)") % [Input.get_joy_name(pad), keys]


func _read_pad(pad: int) -> int:
	var bits := 0
	for pair in PAD_BUTTONS:
		if Input.is_joy_button_pressed(pad, pair[1]):
			bits |= pair[0]
	var r2_bound := false
	for bit in Settings.pad_map:
		var code: int = Settings.pad_map[bit]
		r2_bound = r2_bound or code == Settings.PAD_R2
		var down := false
		if code == Settings.PAD_L2:
			down = Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT) >= TRIGGER_THRESHOLD
		elif code == Settings.PAD_R2:
			down = Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) >= TRIGGER_THRESHOLD
		else:
			down = Input.is_joy_button_pressed(pad, code)
		if down:
			bits |= bit
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
	# R2 — запасной блок, пока он не назначен другому действию.
	if not r2_bound and Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) >= TRIGGER_THRESHOLD:
		bits |= InputBits.BLOCK
	return bits
