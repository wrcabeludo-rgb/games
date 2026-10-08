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
	cfg.save(PATH)


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
