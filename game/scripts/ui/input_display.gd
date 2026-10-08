class_name InputDisplay
extends Control
## Отладочный экран сборки 1.1: показывает ввод обоих игроков.
## Рисуется фигурами, а не символами шрифта, чтобы не зависеть от шрифтов Windows.

const VERSION := "1.1"
const COLOR_TEXT := Color(0.92, 0.92, 0.95)
const COLOR_DIM := Color(0.55, 0.55, 0.62)
const COLOR_PANEL := Color(0.12, 0.12, 0.17)
const COLOR_OFF := Color(0.22, 0.22, 0.3)
const PLAYER_COLORS := [Color(0.91, 0.77, 0.42), Color(0.75, 0.3, 0.4)]
const PANEL_SIZE := Vector2(580, 520)
const HISTORY_ROWS := 20

var _font := SystemFont.new()
var _sim: Sim
var _reader: InputReader


func _ready() -> void:
	_font.font_names = PackedStringArray(["Segoe UI", "Arial", "DejaVu Sans", "Noto Sans"])


func show_state(sim: Sim, reader: InputReader) -> void:
	_sim = sim
	_reader = reader
	queue_redraw()


func _draw() -> void:
	if _sim == null:
		return
	var w := size.x
	_text(Vector2(40, 44), "БИТВА ЛЕГЕНД", 28, COLOR_TEXT)
	_text(Vector2(300, 44), "сборка %s · проверка ввода" % VERSION, 18, COLOR_DIM)
	_text(Vector2(w - 260, 44), "тик %d · %d FPS" % [_sim.tick, Engine.get_frames_per_second()], 18, COLOR_DIM)
	var gap := (w - PANEL_SIZE.x * 2) / 3.0
	for p in Sim.PLAYERS:
		_draw_player(p, Vector2(gap + p * (PANEL_SIZE.x + gap), 70))
	_draw_footer()


func _draw_player(p: int, origin: Vector2) -> void:
	var accent: Color = PLAYER_COLORS[p]
	draw_rect(Rect2(origin, PANEL_SIZE), COLOR_PANEL)
	draw_rect(Rect2(origin, Vector2(PANEL_SIZE.x, 4)), accent)
	_text(origin + Vector2(20, 38), "ИГРОК %d" % (p + 1), 24, accent)
	_text(origin + Vector2(20, 64), _reader.device_label(p), 15, COLOR_DIM)

	var bits := _sim.inputs[p]
	_draw_stick(origin + Vector2(110, 190), bits, accent)
	_draw_face_buttons(origin + Vector2(110, 380), bits, accent)
	_draw_history(p, origin + Vector2(290, 100), accent)


func _draw_stick(center: Vector2, bits: int, accent: Color) -> void:
	draw_circle(center, 70, COLOR_OFF)
	draw_arc(center, 70, 0, TAU, 48, COLOR_DIM, 2)
	var n := InputBits.numpad(bits)
	var dot := center + InputBits.numpad_vector(n) * 46
	draw_circle(dot, 22, accent if n != 5 else COLOR_DIM)
	_text(center + Vector2(-70, 100), "направление: %d" % n, 15, COLOR_DIM)


## Кнопки расположены как на DualSense: треугольник сверху, квадрат слева,
## круг справа, крест снизу. R1 (блок) — над ними.
func _draw_face_buttons(center: Vector2, bits: int, accent: Color) -> void:
	var r := 26.0
	var d := 52.0
	_pad_button(center + Vector2(0, -d), r, bits & InputBits.HP, accent, "triangle", "СР")
	_pad_button(center + Vector2(-d, 0), r, bits & InputBits.LP, accent, "square", "ЛР")
	_pad_button(center + Vector2(d, 0), r, bits & InputBits.HK, accent, "circle", "СН")
	_pad_button(center + Vector2(0, d), r, bits & InputBits.LK, accent, "cross", "ЛН")
	var block_rect := Rect2(center + Vector2(d + 30, -d - 70), Vector2(70, 30))
	draw_rect(block_rect, accent if bits & InputBits.BLOCK else COLOR_OFF)
	_text(block_rect.position + Vector2(8, 22), "R1 БЛ", 15,
		Color.BLACK if bits & InputBits.BLOCK else COLOR_TEXT)


func _pad_button(c: Vector2, r: float, pressed: int, accent: Color, shape: String, label: String) -> void:
	draw_circle(c, r, accent if pressed else COLOR_OFF)
	var ink := Color.BLACK if pressed else COLOR_TEXT
	var s := r * 0.45
	match shape:
		"triangle":
			var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.8), c + Vector2(-s, s * 0.8), c + Vector2(0, -s)])
			draw_polyline(pts, ink, 2.5)
		"square":
			draw_rect(Rect2(c - Vector2(s, s) * 0.85, Vector2(s, s) * 1.7), ink, false, 2.5)
		"circle":
			draw_arc(c, s, 0, TAU, 24, ink, 2.5)
		"cross":
			draw_line(c + Vector2(-s, -s), c + Vector2(s, s), ink, 2.5)
			draw_line(c + Vector2(s, -s), c + Vector2(-s, s), ink, 2.5)
	_text(c + Vector2(-12, r + 18), label, 14, COLOR_DIM)


## История как в тренировке Street Fighter: сколько тиков держали, направление, кнопки.
func _draw_history(p: int, origin: Vector2, accent: Color) -> void:
	_text(origin + Vector2(0, -10), "история ввода (тики)", 15, COLOR_DIM)
	var row_h := 20.0
	var h: Array = _sim.history[p]
	for i in mini(h.size(), HISTORY_ROWS):
		var bits: int = h[i][0]
		var frames: int = h[i][1]
		var y := origin.y + 14 + i * row_h
		var color := COLOR_TEXT if i == 0 else COLOR_DIM
		_text(Vector2(origin.x, y + 6), str(frames), 15, color)
		_draw_arrow(Vector2(origin.x + 62, y), InputBits.numpad(bits), 8, accent if i == 0 else COLOR_DIM)
		var names := PackedStringArray()
		for pair in InputBits.BUTTON_LABELS:
			if bits & pair[0]:
				names.append(pair[1])
		_text(Vector2(origin.x + 84, y + 6), " ".join(names), 15, color)


func _draw_arrow(c: Vector2, n: int, s: float, color: Color) -> void:
	if n == 5:
		draw_circle(c, 3, color)
		return
	var v := InputBits.numpad_vector(n)
	var tip := c + v * s
	draw_line(c - v * s, tip, color, 2)
	var side := v.orthogonal() * s * 0.5
	draw_colored_polygon(PackedVector2Array([tip + v * 3, tip - v * s * 0.6 + side, tip - v * s * 0.6 - side]), color)


func _draw_footer() -> void:
	var y := size.y - 74
	_text(Vector2(40, y), "Геймпад: квадрат — ЛР, крест — ЛН, треугольник — СР, круг — СН, R1 или R2 — блок, стик или крестовина — движение", 15, COLOR_DIM)
	_text(Vector2(40, y + 22), "Игрок 1: WASD, U — ЛР, J — ЛН, I — СР, K — СН, L — блок.   Игрок 2: стрелки, Num4 — ЛР, Num1 — ЛН, Num5 — СР, Num2 — СН, Num6 — блок", 15, COLOR_DIM)
	var pads := Input.get_connected_joypads()
	var pads_text := "геймпадов: %d" % pads.size()
	for pad in pads:
		pads_text += "   [%d] %s" % [pad, Input.get_joy_name(pad)]
	_text(Vector2(40, y + 44), pads_text + "      F11 — полный экран, Esc — выход", 15, COLOR_TEXT)


func _text(pos: Vector2, s: String, font_size: int, color: Color) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
