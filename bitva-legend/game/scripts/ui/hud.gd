class_name Hud
extends Control
## Интерфейс поверх арены: имена бойцов, история ввода (F1), подсказки.

const COLOR_TEXT := Color(0.95, 0.95, 0.97)
const COLOR_DIM := Color(0.75, 0.75, 0.8)
const COLOR_SHADE := Color(0, 0, 0, 0.45)
const HISTORY_ROWS := 16

var show_inputs := true
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
	for p in Sim.PLAYERS:
		var f := _sim.fighters[p]
		var right := p == 1
		var x := w - 40.0 if right else 40.0
		_text(Vector2(x, 44), f.data.name, 26, f.data.color.lightened(0.2), right)
		_text(Vector2(x, 68), "Игрок %d · %s" % [p + 1, _reader.device_label(p)], 14, COLOR_DIM, right)
		_draw_hp(f, Vector2(x, 80), right)
		if show_inputs:
			_draw_history(p, Vector2(x, 118), right)
		_draw_combo(p, right)
	var version: String = ProjectSettings.get_setting("application/config/version")
	var stage: String = ProjectSettings.get_setting("application/config/description")
	_text(Vector2(w / 2.0, 30), "БИТВА ЛЕГЕНД · сборка %s · %s" % [version, stage], 15, COLOR_DIM, false, true)
	_text(Vector2(w / 2.0, 50), "%d FPS" % Engine.get_frames_per_second(), 13, COLOR_DIM, false, true)
	var hint := "R1 / L — блок (вниз — нижний) · F1 — история ввода · F2 — хитбоксы · R или Create — сброс · F11 — полный экран · Esc — выход"
	draw_rect(Rect2(0, size.y - 34, w, 34), COLOR_SHADE)
	_text(Vector2(w / 2.0, size.y - 12), hint, 14, COLOR_TEXT, false, true)


## Временная полоска здоровья (полноценный интерфейс боя — в подэтапе 1.6).
func _draw_hp(f: Fighter, origin: Vector2, right: bool) -> void:
	var w := 360.0
	var x0 := origin.x - w if right else origin.x
	draw_rect(Rect2(x0, origin.y, w, 14), Color(0, 0, 0, 0.6))
	var k := float(f.hp) / Fighter.MAX_HP
	var fill := w * k
	var fx := x0 + (w - fill) if right else x0
	draw_rect(Rect2(fx, origin.y, fill, 14), Color(0.95, 0.8, 0.25).lerp(Color(0.9, 0.2, 0.15), 1.0 - k))
	_text(Vector2(origin.x + (-w - 8 if right else w + 8), origin.y + 13), str(f.hp), 14, COLOR_TEXT, right)


## Счётчик комбо — на стороне атакующего, пока соперник оглушён.
func _draw_combo(p: int, right: bool) -> void:
	var d := _sim.fighters[1 - p]
	if d.combo < 2 or not d.is_stunned():
		return
	var x := size.x * (0.72 if right else 0.28)
	_text(Vector2(x, 220), "%d %s!" % [d.combo, _plural_hits(d.combo)], 40, Color(1, 0.85, 0.3), false, true)


static func _plural_hits(n: int) -> String:
	if n % 10 == 1 and n % 100 != 11:
		return "УДАР"
	if n % 10 >= 2 and n % 10 <= 4 and (n % 100 < 12 or n % 100 > 14):
		return "УДАРА"
	return "УДАРОВ"


## Колонка истории ввода. Направления показаны относительно экрана.
func _draw_history(p: int, origin: Vector2, right: bool) -> void:
	var h: Array = _sim.history[p]
	var dir := -1.0 if right else 1.0
	var accent: Color = _sim.fighters[p].data.color.lightened(0.3)
	draw_rect(Rect2(origin.x - (150 if right else 0), origin.y - 6, 150, HISTORY_ROWS * 20 + 10), COLOR_SHADE)
	for i in mini(h.size(), HISTORY_ROWS):
		var bits: int = h[i][0]
		var frames: int = h[i][1]
		var y := origin.y + 10 + i * 20
		var color := COLOR_TEXT if i == 0 else COLOR_DIM
		var col := origin.x + dir * 10
		_text(Vector2(col, y + 5), str(frames), 14, color, right)
		_draw_arrow(Vector2(origin.x + dir * 58, y), InputBits.numpad(bits), 7, accent if i == 0 else COLOR_DIM)
		var names := PackedStringArray()
		for pair in InputBits.BUTTON_LABELS:
			if bits & pair[0]:
				names.append(pair[1])
		_text(Vector2(origin.x + dir * 78, y + 5), " ".join(names), 14, color, right)


func _draw_arrow(c: Vector2, n: int, s: float, color: Color) -> void:
	if n == 5:
		draw_circle(c, 3, color)
		return
	var v := InputBits.numpad_vector(n)
	var tip := c + v * s
	draw_line(c - v * s, tip, color, 2)
	var side := v.orthogonal() * s * 0.5
	draw_colored_polygon(PackedVector2Array([tip + v * 3, tip - v * s * 0.6 + side, tip - v * s * 0.6 - side]), color)


func _text(pos: Vector2, s: String, font_size: int, color: Color, align_right := false, centered := false) -> void:
	var width := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if align_right:
		pos.x -= width
	elif centered:
		pos.x -= width / 2.0
	draw_string(_font, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.6))
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
