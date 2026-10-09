class_name PauseView
extends Control
## Пауза в бою и экран настроек (он же открывается из меню).
## Управление: вверх/вниз — пункт, влево/вправо — значение, ЛР/ЛН/Enter — выбрать,
## СН/Esc/Options — назад. Настройки применяются сразу и сохраняются при выходе со страницы.

signal resume
signal restart
signal to_select
signal to_title
signal ai_changed(level: int)
signal sound(name: String)

enum Page { MAIN, SETTINGS, MOVES, CONTROLS }

const MAIN_ITEMS := ["Продолжить", "Заново", "Приёмы", "Настройки", "Выбор бойца", "Главное меню"]
const SETTING_ITEMS := ["Музыка", "Звуки", "Диктор", "Вибрация", "Соперник", "Полный экран",
	"Подсказки на экране", "Язык", "Управление", "Назад"]
const CONTROL_ITEMS := ["ЛР — лёгкий удар рукой", "ЛН — лёгкий удар ногой", "СР — сильный удар рукой",
	"СН — сильный удар ногой", "Блок", "Сбросить", "Назад"]
const CONTROLS_ITEM := 8          # пункт «Управление» в настройках
const CONFIRM := InputBits.LP | InputBits.LK | InputBits.START
const BACK := InputBits.HK
const COLOR_GOLD := Color(1, 0.85, 0.3)
const COLOR_TEXT := Color(0.95, 0.95, 0.97)
const COLOR_DIM := Color(0.7, 0.72, 0.8)
const REPEAT_DELAY := 18          # удержание влево/вправо: первый повтор через столько тиков
const REPEAT_EVERY := 5

## Спецприёмы бойцов — для страницы «Приёмы».
const SPECIALS := {
	"ilya": [
		["Назад, вперёд + рука", "Бросок палицы — снаряд по дуге (ЛР ближе, СР дальше)"],
		["Вниз, вниз + нога", "Удар оземь — волна по земле, блок сидя или прыжок"],
		["Вперёд, вперёд + рука", "Богатырский таран — рывок, держит один удар"],
		["Назад, назад + рука", "Мельница — дальний захват, вырваться нельзя"],
	],
	"dracula": [
		["Назад, вперёд + рука", "Стая летучих мышей — быстрый снаряд"],
		["Вниз, вниз + нога", "Туманный рывок — неуязвим, появляется за спиной"],
		["Вперёд, вперёд + рука", "Гипнотический взгляд — ударивший застывает"],
		["Назад, назад + рука", "Укус — захват, лечит Дракулу"],
	],
	"lenta": [
		["Назад, вперёд + рука", "Рилс — быстрый снаряд-экран"],
		["Вниз, вниз + нога", "Свайп — неуязвима, появляется за спиной"],
		["Вперёд, вперёд + рука", "Автоплей — рывок, держит один удар"],
		["Назад, назад + рука", "Алгоритм — захват, забирает всю шкалу"],
	],
	"koschei": [
		["Назад, вперёд + рука", "Кощеева игла — быстрый тонкий снаряд"],
		["Вниз, вниз + нога", "Бессмертие — удар проходит сквозь кости, ударивший застывает"],
		["Вперёд, вперёд + рука", "Удар кладенцом — выпад мечом с шагом"],
		["Назад, назад + рука", "Похищение — захват, крадёт шкалу силы"],
	],
	"hercules": [
		["Назад, вперёд + рука", "Валун — тяжёлый камень по дуге"],
		["Вниз, вниз + нога", "Землетрясение — волна по земле, блок сидя или прыжок"],
		["Вперёд, вперёд + рука", "Немейский натиск — рывок, держит два удара"],
		["Назад, назад + рука", "Объятия Антея — мощный захват, вырваться нельзя"],
	],
	"athena": [
		["Назад, вперёд + рука", "Копьё Паллады — быстрый дальний снаряд"],
		["Вниз, вниз + нога", "Эгида — удар щитом, держит два удара"],
		["Вперёд, вперёд + рука", "Сова Паллады — неуязвимый взлёт против прыжков"],
		["Назад, назад + рука", "Суд мудрости — захват, вырваться нельзя"],
	],
	"medusa": [
		["Назад, вперёд + рука", "Яд — плевок по дуге"],
		["Вниз, вниз + нога", "Каменный взгляд — короткий луч, соперник каменеет"],
		["Вперёд, вперёд + рука", "Хвост змеи — скольжение с подсечкой, блок сидя"],
		["Назад, назад + рука", "Змеиные объятия — захват, лечит Медузу"],
	],
	"sunwukong": [
		["Назад, вперёд + рука", "Обезьянки из волосков — быстрый снаряд"],
		["Вниз, вниз + нога", "Облако — неуязвим, появляется за спиной"],
		["Вперёд, вперёд + рука", "Посох Жуи — удар через пол-арены"],
		["Назад, назад + рука", "Прыжок Царя обезьян — неуязвимый взлёт против прыжков"],
	],
	"anubis": [
		["Назад, вперёд + рука", "Скарабеи — ползут по земле, блок сидя"],
		["Вниз, вниз + нога", "Песчаный смерч — вихрь вперёд-вверх, против прыжков"],
		["Вперёд, вперёд + рука", "Хопеш — шаг с мечом, держит один удар"],
		["Назад, назад + рука", "Взвешивание сердца — захват, забирает секцию шкалы"],
	],
}
const COMMON := [
	["Назад + ЛН", "подсечка"],
	["Назад + СН", "удар с разворота"],
	["Вниз + СР", "апперкот"],
	["ЛР вплотную", "бросок (вырваться — ЛР)"],
	["Тап «вперёд» в момент удара", "парирование"],
	["Спецприём + блок", "усиленный (1 секция)"],
	["Блок + СР + СН", "суперприём (вся шкала)"],
	["Вперёд, назад + СР", "Добивание (после решающего нокаута)"],
]

var page := Page.MAIN
var cursor := 0
## Бойцы матча (для страницы «Приёмы») и уровень ИИ (для пункта «Соперник»).
var chars := PackedStringArray(["ilya", "dracula"])
var ai_level := 0
## Открыто из меню (без боя): только страница настроек, «Назад» закрывает.
var settings_only := false
## Управление: столбец (0 — геймпад, 1 — клавиатура) и ожидание новой кнопки.
var control_col := 0
var waiting := false

var _font: Font = load("res://fonts/RussoOne-Regular.ttf")
var _title_font: Font = load("res://fonts/RuslanDisplay-Regular.ttf")
var _prev := 0
var _hold := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open(only_settings := false) -> void:
	settings_only = only_settings
	page = Page.SETTINGS if only_settings else Page.MAIN
	cursor = 0
	_prev = -1      # кнопка, которой открыли паузу, ещё зажата — первый тик не считаем
	visible = true
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


func close() -> void:
	waiting = false
	if page == Page.SETTINGS or page == Page.CONTROLS:
		Settings.save_file()
	visible = false


## Один тик паузы: bits — ввод обоих игроков вместе.
func step(bits: int) -> void:
	if waiting:
		_prev = bits
		return
	if _prev < 0:
		_prev = bits
		return
	var press := bits & ~_prev
	_prev = bits
	# Удержание влево/вправо — значение листается само.
	var lr := bits & (InputBits.LEFT | InputBits.RIGHT)
	_hold = _hold + 1 if lr != 0 else 0
	if _hold > REPEAT_DELAY and (_hold - REPEAT_DELAY) % REPEAT_EVERY == 0:
		press |= lr
	if press == 0:
		return
	queue_redraw()
	var items := _items()
	if press & BACK:
		_back()
		return
	if press & InputBits.UP:
		cursor = (cursor + items.size() - 1) % items.size()
		sound.emit("ui_move")
	elif press & InputBits.DOWN:
		cursor = (cursor + 1) % items.size()
		sound.emit("ui_move")
	if page == Page.CONTROLS and press & (InputBits.LEFT | InputBits.RIGHT):
		control_col = 1 - control_col
		sound.emit("ui_move")
	elif page == Page.SETTINGS and press & (InputBits.LEFT | InputBits.RIGHT) and cursor < CONTROLS_ITEM:
		_change(cursor, 1 if press & InputBits.RIGHT else -1)
	elif press & CONFIRM:
		_confirm()


## Esc / Options: с главной страницы — продолжить бой, с остальных — назад.
func back_or_resume() -> void:
	if waiting:
		waiting = false
		queue_redraw()
		return
	_back()


## Ожидание новой кнопки: ловим событие устройства раньше игры. Esc / Options — отмена.
func _input(event: InputEvent) -> void:
	if not visible or not waiting:
		return
	var bit: int = Settings.ACTIONS[cursor]
	var key := event as InputEventKey
	var btn := event as InputEventJoypadButton
	var axis := event as InputEventJoypadMotion
	var done := false
	if key != null and key.pressed and not key.echo:
		if key.physical_keycode in [KEY_ESCAPE, KEY_F10, KEY_ENTER, KEY_KP_ENTER] or control_col != 1:
			if key.physical_keycode == KEY_ESCAPE:
				waiting = false
			get_viewport().set_input_as_handled()
			queue_redraw()
			return
		Settings.bind(Settings.key_map, bit, key.physical_keycode)
		done = true
	elif btn != null and btn.pressed and control_col == 0:
		if btn.button_index in [JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_GUIDE, JOY_BUTTON_TOUCHPAD] \
				or btn.button_index >= JOY_BUTTON_DPAD_UP and btn.button_index <= JOY_BUTTON_DPAD_RIGHT:
			if btn.button_index == JOY_BUTTON_START:
				waiting = false
			get_viewport().set_input_as_handled()
			queue_redraw()
			return
		Settings.bind(Settings.pad_map, bit, btn.button_index)
		done = true
	elif axis != null and control_col == 0 and axis.axis_value >= 0.6 \
			and axis.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		Settings.bind(Settings.pad_map, bit, Settings.PAD_L2 if axis.axis == JOY_AXIS_TRIGGER_LEFT else Settings.PAD_R2)
		done = true
	if done:
		waiting = false
		_prev = -1     # новая кнопка ещё зажата — не считать её нажатием в меню
		sound.emit("ui_confirm")
		get_viewport().set_input_as_handled()
		queue_redraw()


func _items() -> Array:
	match page:
		Page.MAIN:
			return MAIN_ITEMS
		Page.SETTINGS:
			return SETTING_ITEMS
		Page.CONTROLS:
			return CONTROL_ITEMS
	return ["Назад"]


func _back() -> void:
	sound.emit("ui_back")
	if page == Page.MAIN or (page == Page.SETTINGS and settings_only):
		close()
		resume.emit()
		return
	if page == Page.CONTROLS:
		Settings.save_file()
		page = Page.SETTINGS
		cursor = CONTROLS_ITEM
		queue_redraw()
		return
	if page == Page.SETTINGS:
		Settings.save_file()
	cursor = 3 if page == Page.SETTINGS else 2
	page = Page.MAIN
	queue_redraw()


func _confirm() -> void:
	sound.emit("ui_confirm")
	match page:
		Page.MAIN:
			match cursor:
				0:
					close()
					resume.emit()
				1:
					close()
					restart.emit()
				2:
					page = Page.MOVES
					cursor = 0
				3:
					page = Page.SETTINGS
					cursor = 0
				4:
					close()
					to_select.emit()
				5:
					close()
					to_title.emit()
		Page.SETTINGS:
			if cursor == SETTING_ITEMS.size() - 1:
				_back()
			elif cursor == CONTROLS_ITEM:
				page = Page.CONTROLS
				cursor = 0
			else:
				_change(cursor, 1)
		Page.CONTROLS:
			if cursor == CONTROL_ITEMS.size() - 1:
				_back()
			elif cursor == CONTROL_ITEMS.size() - 2:
				Settings.reset_controls()
			else:
				waiting = true
		Page.MOVES:
			_back()


## Изменить настройку i на шаг d (для переключателей — по кругу).
func _change(i: int, d: int) -> void:
	match i:
		0:
			Settings.music = clampi(Settings.music + d, 0, Settings.VOLUME_MAX)
		1:
			Settings.sfx = clampi(Settings.sfx + d, 0, Settings.VOLUME_MAX)
		2:
			Settings.voice = clampi(Settings.voice + d, 0, Settings.VOLUME_MAX)
		3:
			Settings.rumble = wrapi(Settings.rumble + d, 0, Settings.RUMBLE_NAMES.size())
			if Settings.rumble > 0:
				for pad in Input.get_connected_joypads():
					Input.start_joy_vibration(pad, 0.4 * Settings.RUMBLE_SCALE[Settings.rumble],
						0.6 * Settings.RUMBLE_SCALE[Settings.rumble], 0.25)
		4:
			ai_level = wrapi(ai_level + d, 0, AiController.LEVEL_NAMES.size())
			Settings.ai_level = ai_level
			ai_changed.emit(ai_level)
		5:
			Settings.fullscreen = not Settings.fullscreen
		6:
			Settings.hints = not Settings.hints
		7:
			var i_lang := wrapi(Loc.LANGS.find(Settings.lang) + d, 0, Loc.LANGS.size())
			Settings.lang = Loc.LANGS[i_lang]
		_:
			return
	Settings.apply()
	sound.emit("ui_move" if i != 1 else "hit_light")


func _value(i: int) -> String:
	match i:
		0:
			return _bar(Settings.music)
		1:
			return _bar(Settings.sfx)
		2:
			return _bar(Settings.voice)
		3:
			return Settings.RUMBLE_NAMES[Settings.rumble]
		4:
			return Loc.t("второй игрок") if ai_level == 0 else Loc.t("ИИ, ") + Loc.t(AiController.LEVEL_NAMES[ai_level])
		5:
			return "да" if Settings.fullscreen else "нет"
		6:
			return "показывать" if Settings.hints else "скрыть"
		7:
			return Loc.LANG_NAMES[Loc.LANGS.find(Settings.lang)]
	return ""


static func _bar(v: int) -> String:
	return "■".repeat(v) + "□".repeat(Settings.VOLUME_MAX - v)


# --- Отрисовка -------------------------------------------------------------

func _draw() -> void:
	size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.82))
	var cx := size.x / 2.0
	match page:
		Page.MAIN:
			_title(cx, "ПАУЗА")
			_list(MAIN_ITEMS, cx, 240, false)
		Page.SETTINGS:
			_title(cx, "НАСТРОЙКИ")
			_list(SETTING_ITEMS, cx, 196, true)
		Page.MOVES:
			_draw_moves()
		Page.CONTROLS:
			_draw_controls()
	var hint := "↑↓ — пункт   ·   ←→ — изменить   ·   Enter / крест — выбрать   ·   Esc / круг — назад"
	if page == Page.CONTROLS:
		hint = "Нажмите новую кнопку   ·   Esc / Options — отмена" if waiting \
			else "↑↓ — действие   ·   ←→ — геймпад / клавиатура   ·   Enter / крест — назначить   ·   Esc / круг — назад"
	_text(Vector2(cx, size.y - 24), hint, 16, COLOR_DIM, 0)


func _title(cx: float, s: String) -> void:
	_text(Vector2(cx, 130), s, 56, COLOR_GOLD, 0, _title_font)


func _list(items: Array, cx: float, y0: float, values: bool) -> void:
	for i in items.size():
		var y := y0 + i * 48.0
		var sel := i == cursor
		if sel:
			draw_rect(Rect2(cx - 330, y - 34, 660, 46), Color(1, 0.85, 0.3, 0.18))
			draw_rect(Rect2(cx - 330, y - 34, 660, 46), COLOR_GOLD, false, 2.0)
		var col := COLOR_GOLD if sel else COLOR_TEXT
		if values and i < items.size() - 1 and _value(i) != "":
			_text(Vector2(cx - 300, y), items[i], 26, col, -1)
			var v := _value(i)
			_text(Vector2(cx + 300, y), ("◀ " + v + " ▶") if sel else v, 24, col, 1)
		else:
			_text(Vector2(cx, y), items[i], 28, col, 0)


func _draw_controls() -> void:
	var cx := size.x / 2.0
	_title(cx, "УПРАВЛЕНИЕ")
	var y0 := 210.0
	_text(Vector2(cx + 150, y0 - 44), "Геймпад", 20, COLOR_GOLD if control_col == 0 else COLOR_DIM, 0)
	_text(Vector2(cx + 380, y0 - 44), "Клавиатура (игрок 1)", 20, COLOR_GOLD if control_col == 1 else COLOR_DIM, 0)
	for i in CONTROL_ITEMS.size():
		var y := y0 + i * 48.0
		var sel := i == cursor
		var col := COLOR_GOLD if sel else COLOR_TEXT
		if sel:
			draw_rect(Rect2(cx - 520, y - 34, 1040, 46), Color(1, 0.85, 0.3, 0.18))
			draw_rect(Rect2(cx - 520, y - 34, 1040, 46), COLOR_GOLD, false, 2.0)
		if i >= Settings.ACTIONS.size():
			_text(Vector2(cx, y), CONTROL_ITEMS[i], 26, col, 0)
			continue
		_text(Vector2(cx - 490, y), CONTROL_ITEMS[i], 24, col, -1)
		var bit: int = Settings.ACTIONS[i]
		for c in 2:
			var v := Settings.pad_name(Settings.pad_map[bit]) if c == 0 else Settings.key_name(Settings.key_map[bit])
			var here := sel and c == control_col
			if here and waiting:
				v = "…" if (Engine.get_process_frames() / 20) % 2 == 0 else "?"
			var x := cx + (150.0 if c == 0 else 380.0)
			if here:
				draw_rect(Rect2(x - 100, y - 30, 200, 38), Color(1, 0.85, 0.3, 0.35 if waiting else 0.2))
			_text(Vector2(x, y), v, 22, COLOR_GOLD if here else COLOR_TEXT, 0)


func _process(_delta: float) -> void:
	if visible and waiting:
		queue_redraw()


func _draw_moves() -> void:
	var cx := size.x / 2.0
	_title(cx, "ПРИЁМЫ")
	var y := 190.0
	for p in 2:
		var id := chars[p]
		var x := size.x * (0.27 if p == 0 else 0.73)
		_text(Vector2(x, y), FighterData.get_data(id).name, 26, COLOR_GOLD, 0)
		var yy := y + 36.0
		for st in FighterData.get_data(id).get("strings", []):
			var keys: Array[String] = []
			for key in st.moves:
				keys.append(Loc.t(Fighter.MOVE_LABELS[Fighter.BUTTON_OF[(key as String).right(2)]]) \
					+ (Loc.t(" (низ)") if (key as String).begins_with("cr_") else ""))
			_text(Vector2(x, yy), "%s: %s" % [Loc.t(st.name), ", ".join(keys)], 16, COLOR_TEXT, 0)
			yy += 24.0
		yy += 8.0
		if not SPECIALS.has(id):
			_text(Vector2(x, yy + 10), "Спецприёмы — скоро", 16, COLOR_DIM, 0)
		for row in SPECIALS.get(id, []):
			_text(Vector2(x, yy), row[0], 16, COLOR_GOLD, 0)
			_text(Vector2(x, yy + 20), row[1], 15, COLOR_TEXT, 0)
			yy += 46.0
	var y2 := 530.0
	_text(Vector2(cx, y2), "У всех бойцов", 22, COLOR_GOLD, 0)
	for i in COMMON.size():
		var col := i % 2
		var row := i / 2
		var x := size.x * (0.27 if col == 0 else 0.73)
		_text(Vector2(x, y2 + 30 + row * 24), "%s — %s" % [Loc.t(COMMON[i][0]), Loc.t(COMMON[i][1])], 15, COLOR_TEXT, 0)
	_text(Vector2(cx, size.y - 54), "ЛР, ЛН, СР, СН — лёгкий и сильный удар рукой и ногой · попавшая строка (и в блок) отменяется в спецприём", 15, COLOR_DIM, 0)


## align: -1 — по левому краю, 0 — по центру, 1 — по правому.
func _text(pos: Vector2, s: String, font_size: int, color: Color, align: int, font: Font = null) -> void:
	var fnt: Font = font if font != null else _font
	s = Loc.t(s)
	var w := fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := pos.x - (w / 2.0 if align == 0 else (w if align == 1 else 0.0))
	draw_string_outline(fnt, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.06, 0.02, 0.05, 0.9))
	draw_string(fnt, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
