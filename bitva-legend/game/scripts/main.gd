extends Node
## Главный цикл: каждый тик (60 в секунду) читает ввод, продвигает симуляцию
## и просит интерфейс перерисоваться. Логика боя живёт только в Sim.

var sim := Sim.new()
var reader := InputReader.new()
## Отладка: «-- --screenshot=путь.png» подаёт сценарий ввода, сохраняет кадр и выходит.
var _screenshot_path := ""

@onready var display: InputDisplay = $InputDisplay


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")


func _physics_process(_delta: float) -> void:
	var frame := PackedInt32Array([reader.read(0), reader.read(1)])
	if _screenshot_path != "":
		frame = DemoInput.frame(sim.tick)
	sim.step(frame)
	display.show_state(sim, reader)
	if _screenshot_path != "" and sim.tick == DemoInput.LENGTH:
		_save_screenshot.call_deferred()


func _save_screenshot() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_screenshot_path)
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F11:
		_toggle_fullscreen()
	elif key.physical_keycode == KEY_ESCAPE:
		get_tree().quit()


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
