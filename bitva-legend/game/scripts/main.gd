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


func _ready() -> void:
	add_child(sound)
	menu.sound.connect(func(n: String): sound.play(n))
	menu.voice.connect(func(n: String): sound.say([n] as Array[String]))
	menu.setup(arena.sprites)
	menu.fight_requested.connect(_start_fight)
	var start_screen := MenuView.Screen.TITLE
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot=") or arg.begins_with("--demo") or arg.begins_with("--chars=") \
				or arg == "--training":
			in_menu = false
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")
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
		elif arg.begins_with("--demo-ai="):
			ai.level = int(arg.trim_prefix("--demo-ai=")) as AiController.Level
	# «--screen=title|select [--picked]» — снимок меню (вместе с --screenshot).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			in_menu = true
			start_screen = MenuView.Screen.SELECT if arg.ends_with("select") else MenuView.Screen.TITLE
	if in_menu:
		_open_menu(start_screen)
		if "--picked" in OS.get_cmdline_user_args():
			menu.picked = [true, true]
	else:
		menu.visible = false


func _physics_process(_delta: float) -> void:
	reader.single_player = ai.level != AiController.Level.OFF
	if in_menu:
		menu.vs_ai = reader.single_player
		menu.ai_label = "Соперник: %s   ·   F3 или Options — сменить" % \
			("второй игрок" if ai.level == AiController.Level.OFF else "ИИ, " + ai.level_name())
		menu.step(PackedInt32Array([reader.read(0), reader.read(1)]))
		if _screenshot_path != "" and menu.tick == _shot_at:
			_save_screenshot.call_deferred()
		return
	var frame := PackedInt32Array([reader.read(0), reader.read(1)])
	if _screenshot_path != "":
		frame = DemoInput.frame(sim.tick)
	if ai.level != AiController.Level.OFF:
		frame[1] = ai.get_input(sim, 1)
	sim.step(frame)
	sound.update(sim, ai.level != AiController.Level.OFF)
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
	if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_BACK:
		_reset()
		return
	if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_START:
		if not in_menu and sim.phase == Sim.Phase.MATCH_END:
			_open_menu(MenuView.Screen.SELECT)
		else:
			_cycle_ai()
		return
	if in_menu and pad != null:
		return
	if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_TOUCHPAD:
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
				if menu.screen == MenuView.Screen.SELECT:
					menu.open(MenuView.Screen.TITLE)
				else:
					get_tree().quit()
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
			reader.notify("Спрайты бойцов: " + ("включены" if arena.use_sprites else "выключены (заглушки)"))
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
		KEY_ESCAPE:
			_open_menu(MenuView.Screen.SELECT)


func _open_menu(screen: MenuView.Screen) -> void:
	in_menu = true
	arena.visible = false
	hud.visible = false
	menu.cursor = PackedInt32Array([MenuView.ROSTER.find(chars[0]), MenuView.ROSTER.find(chars[1])])
	menu.open(screen)
	sound.menu()


func _start_fight(picked: PackedStringArray) -> void:
	chars = picked
	in_menu = false
	menu.visible = false
	arena.visible = true
	hud.visible = true
	_reset()


func _reset() -> void:
	sim = Sim.new(true, chars)
	if training:
		sim.set_training(true)
	ai.reset()


func _toggle_training() -> void:
	training = not training
	# Манекен в тренировке — ИИ: если был выключен, включаем средний.
	if training and ai.level == AiController.Level.OFF:
		ai.level = AiController.Level.MEDIUM
	_reset()
	reader.notify("ТРЕНИРОВКА · соперник — ИИ (%s), F3 или Options — сменить" % ai.level_name() if training else "Тренировка выключена — обычный бой")


func _cycle_ai() -> void:
	ai.next_level()
	reader.notify("ИИ соперника: %s" % ai.level_name())


func _cycle_char(p: int) -> void:
	var ids: Array = FighterData.CHARACTERS.keys()
	chars[p] = ids[(ids.find(chars[p]) + 1) % ids.size()]
	_reset()


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
