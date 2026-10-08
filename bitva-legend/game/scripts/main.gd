extends Node
## Главный цикл: каждый тик (60 в секунду) читает ввод, продвигает симуляцию
## и просит отрисовку обновиться. Логика боя живёт только в Sim.

var sim := Sim.new()
var reader := InputReader.new()
## Отладка: «-- --screenshot=путь.png [--shot-at=тик] [--debug] [--demo-hp=N] [--demo-wins=N]»
## подаёт записанный ввод, сохраняет кадр на заданном тике и выходит.
var _screenshot_path := ""
var _shot_at := DemoInput.LENGTH

@onready var arena: ArenaView = $ArenaView
@onready var hud: Hud = $Hud


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
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


func _physics_process(_delta: float) -> void:
	var frame := PackedInt32Array([reader.read(0), reader.read(1)])
	if _screenshot_path != "":
		frame = DemoInput.frame(sim.tick)
	sim.step(frame)
	arena.show_state(sim)
	hud.show_state(sim, reader)
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
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_F1:
			hud.show_inputs = not hud.show_inputs
		KEY_F2:
			arena.show_debug = not arena.show_debug
		KEY_R:
			_reset()
		KEY_F11:
			_toggle_fullscreen()
		KEY_ESCAPE:
			get_tree().quit()


func _reset() -> void:
	sim = Sim.new()


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
