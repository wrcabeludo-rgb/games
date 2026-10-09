class_name Settings
extends RefCounted
## Настройки игрока: громкость, вибрация, экран, подсказки, сложность ИИ.
## Хранятся в user://settings.cfg (на Windows — %APPDATA%\Godot\app_userdata\Битва легенд\).
## Применяются сразу при изменении; на ход боя не влияют.

const PATH := "user://settings.cfg"
const VOLUME_MAX := 10
## Шины звука: громкость каждой — своя настройка.
const BUSES := {"music": "Music", "sfx": "SFX", "voice": "Voice"}
## Вибрация: 0 — выключена, 1 — обычная, 2 — сильная (множитель силы).
const RUMBLE_NAMES := ["выключена", "обычная", "сильная"]
const RUMBLE_SCALE := [0.0, 0.6, 1.0]

static var music := 7
static var sfx := 8
static var voice := 8
static var rumble := 1
static var fullscreen := false
static var hints := false          # подсказки по клавишам и номер сборки внизу экрана
static var ai_level := 0           # AiController.Level
static var lang := Loc.system_default()

## Переназначаемые действия: удары и блок. Направления и Options/Enter не переназначаются.
const ACTIONS := [InputBits.LP, InputBits.LK, InputBits.HP, InputBits.HK, InputBits.BLOCK]
## Курки геймпада — оси, а не кнопки; в раскладке у них свои номера.
const PAD_L2 := 100
const PAD_R2 := 101
## Квадрат — ЛР, крест — ЛН, треугольник — СР, круг — СН, R1 — блок.
const DEFAULT_PAD := {InputBits.LP: JOY_BUTTON_X, InputBits.LK: JOY_BUTTON_A, InputBits.HP: JOY_BUTTON_Y,
	InputBits.HK: JOY_BUTTON_B, InputBits.BLOCK: JOY_BUTTON_RIGHT_SHOULDER}
const DEFAULT_KEYS := {InputBits.LP: KEY_U, InputBits.LK: KEY_J, InputBits.HP: KEY_I,
	InputBits.HK: KEY_K, InputBits.BLOCK: KEY_L}
## Раскладка геймпада (общая для всех геймпадов) и клавиатуры первого игрока: действие → кнопка.
static var pad_map: Dictionary = DEFAULT_PAD.duplicate()
static var key_map: Dictionary = DEFAULT_KEYS.duplicate()


static func load_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music = clampi(cfg.get_value("audio", "music", music), 0, VOLUME_MAX)
	sfx = clampi(cfg.get_value("audio", "sfx", sfx), 0, VOLUME_MAX)
	voice = clampi(cfg.get_value("audio", "voice", voice), 0, VOLUME_MAX)
	rumble = clampi(cfg.get_value("pad", "rumble", rumble), 0, RUMBLE_NAMES.size() - 1)
	fullscreen = bool(cfg.get_value("screen", "fullscreen", fullscreen))
	hints = bool(cfg.get_value("screen", "hints", hints))
	ai_level = int(cfg.get_value("game", "ai_level", ai_level))
	lang = str(cfg.get_value("game", "lang", lang))
	if not lang in Loc.LANGS:
		lang = "ru"
	for bit in ACTIONS:
		pad_map[bit] = int(cfg.get_value("controls", "pad_%d" % bit, pad_map[bit]))
		key_map[bit] = int(cfg.get_value("controls", "key_%d" % bit, key_map[bit]))


static func save_file() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "voice", voice)
	cfg.set_value("pad", "rumble", rumble)
	cfg.set_value("screen", "fullscreen", fullscreen)
	cfg.set_value("screen", "hints", hints)
	cfg.set_value("game", "ai_level", ai_level)
	cfg.set_value("game", "lang", lang)
	for bit in ACTIONS:
		cfg.set_value("controls", "pad_%d" % bit, pad_map[bit])
		cfg.set_value("controls", "key_%d" % bit, key_map[bit])
	cfg.save(PATH)


## Назначить кнопку действию; если она уже занята другим действием — они меняются местами.
static func bind(map: Dictionary, bit: int, code: int) -> void:
	for other in map:
		if other != bit and map[other] == code:
			map[other] = map[bit]
	map[bit] = code


static func reset_controls() -> void:
	pad_map = DEFAULT_PAD.duplicate()
	key_map = DEFAULT_KEYS.duplicate()


## Подпись кнопки геймпада (по DualSense).
static func pad_name(code: int) -> String:
	match code:
		JOY_BUTTON_A: return "Крест"
		JOY_BUTTON_B: return "Круг"
		JOY_BUTTON_X: return "Квадрат"
		JOY_BUTTON_Y: return "Треугольник"
		JOY_BUTTON_LEFT_SHOULDER: return "L1"
		JOY_BUTTON_RIGHT_SHOULDER: return "R1"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		PAD_L2: return "L2"
		PAD_R2: return "R2"
	return "#%d" % code


static func key_name(code: int) -> String:
	return OS.get_keycode_string(DisplayServer.keyboard_get_label_from_physical(code) if DisplayServer.get_name() != "headless" else code)


## Громкость шин и режим окна — по текущим значениям.
static func apply() -> void:
	Loc.lang = lang
	for key in BUSES:
		var idx := _bus(BUSES[key])
		var level: int = {"music": music, "sfx": sfx, "voice": voice}[key]
		AudioServer.set_bus_mute(idx, level == 0)
		AudioServer.set_bus_volume_db(idx, linear_to_db(float(level) / VOLUME_MAX))
	if DisplayServer.get_name() == "headless":
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)


## Номер шины по имени; если её нет — создаётся (выход — в общую шину Master).
static func _bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


static func bus_name(key: String) -> String:
	_bus(BUSES[key])
	return BUSES[key]
