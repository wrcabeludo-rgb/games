extends Node
## Главный цикл: каждый тик (60 в секунду) читает ввод, продвигает симуляцию
## и просит отрисовку обновиться. Логика боя живёт только в Sim.

## Персонажи игроков: F4 и F5 перебирают, тачпад на геймпаде меняет местами.
var chars := PackedStringArray(["ilya", "dracula"])
var sim := Sim.new(true, chars)
var reader := InputReader.new()
## ИИ за игрока 2: F3 или Options на геймпаде игрока 1 переключает уровень.
var ai := AiController.new(20261008)
## Тренировка: F6 или тачпад с зажатым R1.
var training := false
## Отладка: «-- --screenshot=путь.png [--shot-at=тик] [--debug] [--demo-hp=N] [--demo-wins=N]»
## подаёт записанный ввод, сохраняет кадр на заданном тике и выходит.
var _screenshot_path := ""
var _shot_at := DemoInput.LENGTH

@onready var arena: ArenaView = $ArenaView
@onready var hud: Hud = $Hud
@onready var menu: MenuView = $MenuView
## Меню (стартовый экран, выбор бойцов) или бой. С отладочными ключами игра сразу начинает бой.
var in_menu := true
var sound := SoundDirector.new()
var rumble := Rumble.new()
## Пауза и настройки — поверх боя и меню.
var pause := PauseView.new()
## Кнопки, зажатые в момент закрытия паузы: не считаются, пока их не отпустят
## (иначе «Продолжить» крестом сразу дал бы удар ЛН).
var _mask := 0
## Аркада: текущая лестница (null — обычный бой) и кнопки прошлого тика (для нажатий после матча).
var arcade: Arcade = null
## Арена текущего боя (Arenas): «--arena=id» для снимков, иначе выбирается на экране «ПРОТИВ».
var arena_id := ""
var _arcade_prev := 0


func _ready() -> void:
	Settings.load_file()
	Settings.apply()
	ai.level = clampi(Settings.ai_level, 0, AiController.LEVEL_NAMES.size() - 1) as AiController.Level
	add_child(sound)
	add_child(pause)
	pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause.sound.connect(func(n: String): sound.play(n))
	pause.restart.connect(_reset)
	pause.to_select.connect(func():
		_end_arcade()
		_open_menu(MenuView.Screen.SELECT))
	pause.to_title.connect(func():
		_end_arcade()
		_open_menu(MenuView.Screen.TITLE))
	pause.ai_changed.connect(_set_ai)
	pause.visibility_changed.connect(func():
		hud.paused = pause.visible
		hud.queue_redraw()
		if not pause.visible:
			_mask = reader.read(0) | reader.read(1))
	menu.sound.connect(func(n: String): sound.play(n))
	menu.voice.connect(func(n: String): sound.say([n] as Array[String]))
	menu.setup(arena.sprites)
	hud.setup(arena.sprites)
	menu.fight_requested.connect(_start_fight)
	menu.arcade_picked.connect(_start_arcade)
	menu.ending_done.connect(func():
		_end_arcade()
		_open_menu(MenuView.Screen.TITLE))
	var start_screen := MenuView.Screen.TITLE
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot=") or arg.begins_with("--demo") or arg.begins_with("--chars=") \
				or arg == "--training":
			in_menu = false
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")
			ai.level = AiController.Level.OFF   # снимки — по записанному вводу, без сохранённого ИИ
		elif arg.begins_with("--shot-at="):
			_shot_at = int(arg.trim_prefix("--shot-at="))
		elif arg == "--debug":
			arena.show_debug = true
		elif arg.begins_with("--demo-hp="):
			sim.fighters[1].hp = int(arg.trim_prefix("--demo-hp="))
		elif arg.begins_with("--demo-wins="):
			sim.wins[0] = int(arg.trim_prefix("--demo-wins="))
		elif arg.begins_with("--demo="):
			DemoInput.scenario = arg.trim_prefix("--demo=")
		elif arg.begins_with("--chars="):
			chars = PackedStringArray(arg.trim_prefix("--chars=").split(","))
			sim = Sim.new(true, chars)
		elif arg == "--training":
			training = true
			sim.set_training(true)
		elif arg.begins_with("--demo-meter="):
			for f in sim.fighters:
				f.meter = int(arg.trim_prefix("--demo-meter="))
		elif arg.begins_with("--lang="):
			Settings.lang = arg.trim_prefix("--lang=")
			Settings.apply()
		elif arg.begins_with("--arena="):
			arena_id = arg.trim_prefix("--arena=")
		elif arg.begins_with("--demo-ai="):
			ai.level = int(arg.trim_prefix("--demo-ai=")) as AiController.Level
	# «--screen=title|select [--picked]» — снимок меню (вместе с --screenshot).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			in_menu = true
			start_screen = MenuView.Screen.SELECT if arg.ends_with("select") or arg.ends_with("versus") \
				else MenuView.Screen.TITLE
	# «--pause=main|settings|moves» — снимок паузы поверх боя (вместе с --screenshot).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pause="):
			for i in 40:
				sim.step(DemoInput.frame(sim.tick))
			arena.show_state(sim)
			hud.show_state(sim, reader, ai)
			_open_pause(false)
			pause.page = {"main": PauseView.Page.MAIN, "settings": PauseView.Page.SETTINGS,
				"moves": PauseView.Page.MOVES, "controls": PauseView.Page.CONTROLS}[arg.trim_prefix("--pause=")]
	if in_menu:
		_open_menu(start_screen)
		if "--picked" in OS.get_cmdline_user_args():
			menu.picked = [true, true]
		if "--screen=versus" in OS.get_cmdline_user_args():
			menu.start_versus()
		# «--screen=ladder [--stage=N]» и «--screen=ending» — снимки аркады за бойца chars[0].
		if "--screen=ladder" in OS.get_cmdline_user_args():
			_start_arcade(chars[0])
			for arg in OS.get_cmdline_user_args():
				if arg.begins_with("--stage="):
					arcade.stage = int(arg.trim_prefix("--stage="))
			_show_ladder()
		if "--screen=ending" in OS.get_cmdline_user_args():
			menu.open_ending(chars[0])
	else:
		menu.visible = false
	if arena_id == "":
		arena_id = Arenas.for_versus(chars[0], chars[1], 1)
	_apply_arena()


func _physics_process(_delta: float) -> void:
	reader.single_player = ai.level != AiController.Level.OFF
	if pause.visible:
		pause.step(reader.read(0) | reader.read(1))
		if _screenshot_path != "" and Engine.get_physics_frames() == _shot_at:
			_save_screenshot.call_deferred()
		return
	var raw := PackedInt32Array([reader.read(0), reader.read(1)])
	_mask &= raw[0] | raw[1]
	raw[0] &= ~_mask
	raw[1] &= ~_mask
	if in_menu:
		menu.vs_ai = reader.single_player
		menu.ai_label = Loc.t("Аркада: восемь боёв против ИИ") if menu.arcade else Loc.t("Соперник: %s   ·   F3 — сменить   ·   Options / F10 — настройки") % \
			(Loc.t("второй игрок") if ai.level == AiController.Level.OFF else Loc.t("ИИ, ") + Loc.t(ai.level_name()))
		menu.step(raw)
		if _screenshot_path != "" and menu.tick == _shot_at:
			_save_screenshot.call_deferred()
		return
	var frame := raw
	if _screenshot_path != "":
		frame = DemoInput.frame(sim.tick)
	if ai.level != AiController.Level.OFF:
		frame[1] = ai.get_input(sim, 1)
	sim.step(frame)
	if arcade != null:
		_arcade_step(raw[0] | raw[1])
	sound.update(sim, ai.level != AiController.Level.OFF)
	rumble.update(sim, reader)
	arena.show_state(sim)
	hud.show_state(sim, reader, ai)
	if _screenshot_path != "" and sim.tick == _shot_at:
		_save_screenshot.call_deferred()


func _save_screenshot() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_screenshot_path)
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	var pad := event as InputEventJoypadButton
	var key_ev := event as InputEventKey
	var key_down := key_ev != null and key_ev.pressed and not key_ev.echo
	# Пауза открыта: Esc / Options — назад (с главной страницы — продолжить бой).
	if pause.visible:
		if (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_START) \
				or (key_down and key_ev.physical_keycode in [KEY_ESCAPE, KEY_F10]):
			pause.back_or_resume()
		elif key_down and key_ev.physical_keycode == KEY_F11:
			_toggle_fullscreen()
		return
	# Настройки из меню: Options или F10.
	if in_menu and ((pad != null and pad.pressed and pad.button_index == JOY_BUTTON_START) \
			or (key_down and key_ev.physical_keycode == KEY_F10)):
		_open_pause(true)
		return
	if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_BACK:
		_reset()
		return
	if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_START:
		if sim.phase == Sim.Phase.MATCH_END and arcade != null:
			return
		if sim.phase == Sim.Phase.MATCH_END:
			_open_menu(MenuView.Screen.SELECT)
		else:
			_open_pause(false)
		return
	if in_menu and pad != null:
		return
	if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_TOUCHPAD and arcade == null:
		var r1 := Input.is_joy_button_pressed(pad.device, JOY_BUTTON_RIGHT_SHOULDER) \
			or Input.get_joy_axis(pad.device, JOY_AXIS_TRIGGER_RIGHT) >= 0.5
		if r1:
			_toggle_training()
		else:
			chars = PackedStringArray([chars[1], chars[0]])
			_reset()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if in_menu:
		match key.physical_keycode:
			KEY_F3:
				_cycle_ai()
			KEY_F11:
				_toggle_fullscreen()
			KEY_ESCAPE:
				if menu.screen != MenuView.Screen.TITLE:
					_end_arcade()
					menu.open(MenuView.Screen.TITLE)
				else:
					get_tree().quit()
		return
	if arcade != null and key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_F3, KEY_F4, KEY_F5, KEY_F6]:
		return
	if key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and sim.phase == Sim.Phase.MATCH_END:
		_open_menu(MenuView.Screen.SELECT)
		return
	match key.physical_keycode:
		KEY_F1:
			hud.show_inputs = not hud.show_inputs
		KEY_F2:
			arena.show_debug = not arena.show_debug
		KEY_F3:
			_cycle_ai()
		KEY_F7:
			arena.use_sprites = not arena.use_sprites
			reader.notify(Loc.t("Спрайты бойцов: ") + Loc.t("включены" if arena.use_sprites else "выключены (заглушки)"))
		KEY_F6:
			_toggle_training()
		KEY_F4:
			_cycle_char(0)
		KEY_F5:
			_cycle_char(1)
		KEY_R:
			_reset()
		KEY_F11:
			_toggle_fullscreen()
		KEY_ESCAPE, KEY_F10:
			_open_pause(false)


func _open_pause(only_settings: bool) -> void:
	pause.chars = chars
	pause.ai_level = ai.level
	pause.open(only_settings)
	for pad in Input.get_connected_joypads():
		Input.stop_joy_vibration(pad)


func _set_ai(level: int) -> void:
	ai.level = level as AiController.Level
	ai.reset()


func _open_menu(screen: MenuView.Screen) -> void:
	in_menu = true
	arena.visible = false
	hud.visible = false
	menu.cursor = PackedInt32Array([MenuView.ROSTER.find(chars[0]), MenuView.ROSTER.find(chars[1])])
	menu.open(screen)
	sound.menu()


func _start_fight(picked: PackedStringArray) -> void:
	chars = picked
	arena_id = menu.arena
	if arcade != null:
		ai.level = arcade.ai_level()
	in_menu = false
	menu.visible = false
	arena.visible = true
	hud.visible = true
	_reset()


func _apply_arena() -> void:
	arena.set_arena(arena_id)
	hud.arena_label = Loc.t(Arenas.data(arena_id).name)


func _reset() -> void:
	_apply_arena()
	sim = Sim.new(true, chars)
	sim.auto_rematch = arcade == null
	if training and arcade == null:
		sim.set_training(true)
	ai.reset()
	hud.arcade_label = "" if arcade == null else Loc.t("АРКАДА · БОЙ %d ИЗ %d") % [arcade.stage + 1, arcade.ladder.size()]
	hud.match_hint = ""


## Аркада: игрок выбрал бойца — строим лестницу и показываем башню.
func _start_arcade(id: String) -> void:
	arcade = Arcade.new(id, MenuView.ROSTER, Time.get_ticks_usec())
	training = false
	_show_ladder()


func _show_ladder() -> void:
	in_menu = true
	arena.visible = false
	hud.visible = false
	menu.cursor = PackedInt32Array([MenuView.ROSTER.find(arcade.player), MenuView.ROSTER.find(arcade.opponent())])
	menu.open_ladder(arcade)
	sound.menu()


## Аркада закончилась (пройдена или брошена): ИИ — снова как в настройках.
func _end_arcade() -> void:
	if arcade == null:
		return
	arcade = null
	menu.arcade = false
	ai.level = clampi(Settings.ai_level, 0, AiController.LEVEL_NAMES.size() - 1) as AiController.Level
	ai.reset()
	hud.arcade_label = ""
	hud.match_hint = ""


## Аркада после матча: удар — дальше (победа) или ещё раз (поражение); Enter / Options после поражения — выход.
func _arcade_step(bits: int) -> void:
	var press := bits & ~_arcade_prev
	_arcade_prev = bits
	if sim.phase != Sim.Phase.MATCH_END:
		return
	var won := sim.match_winner() == 0
	if won:
		hud.match_hint = "Удар — эпилог" if arcade.is_final() else "Удар — следующий бой"
	else:
		hud.match_hint = "Удар — ещё раз   ·   Enter или Options — выйти"
	if sim.phase_frame < Sim.REMATCH_DELAY:
		return
	var attack := InputBits.LP | InputBits.LK | InputBits.HP | InputBits.HK
	if won and press & (attack | InputBits.START):
		if arcade.advance():
			var id: String = arcade.player
			in_menu = true
			arena.visible = false
			hud.visible = false
			menu.open_ending(id)
			sound.menu()
		else:
			_show_ladder()
	elif not won and press & attack:
		arcade.continues += 1
		_reset()
	elif not won and press & InputBits.START:
		_end_arcade()
		_open_menu(MenuView.Screen.TITLE)


func _toggle_training() -> void:
	training = not training
	# Манекен в тренировке — ИИ: если был выключен, включаем средний.
	if training and ai.level == AiController.Level.OFF:
		ai.level = AiController.Level.MEDIUM
	_reset()
	reader.notify(Loc.t("ТРЕНИРОВКА · соперник — ИИ (%s), F3 или Options — сменить") % Loc.t(ai.level_name()) \
		if training else Loc.t("Тренировка выключена — обычный бой"))


func _cycle_ai() -> void:
	ai.next_level()
	Settings.ai_level = ai.level
	Settings.save_file()
	reader.notify(Loc.t("ИИ соперника: %s") % Loc.t(ai.level_name()))


func _cycle_char(p: int) -> void:
	var ids: Array = FighterData.CHARACTERS.keys()
	chars[p] = ids[(ids.find(chars[p]) + 1) % ids.size()]
	_reset()


func _toggle_fullscreen() -> void:
	Settings.fullscreen = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
	Settings.apply()
	Settings.save_file()
