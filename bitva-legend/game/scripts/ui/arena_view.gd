class_name ArenaView
extends Control
## Отрисовка арены и бойцов по состоянию Sim. Только чтение: в логику боя не вмешивается.
## Пока вместо спрайтов — цветные фигуры, фон — заглушка «Перекрёстка миров».

const GROUND_Y := 620                 # линия земли на экране (при высоте 720)
const PARALLAX_HILLS := 0.35
const COLOR_GROUND := Color(0.2, 0.17, 0.16)
const COLOR_LINE := Color(0.32, 0.28, 0.26)
const SKY_LIGHT := Color(0.95, 0.72, 0.38)   # сторона света
const SKY_DARK := Color(0.32, 0.08, 0.16)    # сторона тьмы
const SKY_TOP := Color(0.08, 0.07, 0.14)

var show_debug := false
var _font := SystemFont.new()
var _sim: Sim
var _cam_x := 0.0


func _ready() -> void:
	_font.font_names = PackedStringArray(["Segoe UI", "Arial", "DejaVu Sans", "Noto Sans"])


func show_state(sim: Sim) -> void:
	_sim = sim
	queue_redraw()


## Камера следит за серединой между бойцами и не выходит за края арены.
func _update_camera() -> void:
	var mid := (_sim.fighters[0].x + _sim.fighters[1].x) / 2.0 / Sim.SUB
	var half_view := size.x / 2.0
	_cam_x = clampf(mid, half_view, Sim.ARENA_WIDTH - half_view)
	if Sim.ARENA_WIDTH < size.x:
		_cam_x = Sim.ARENA_WIDTH / 2.0


func to_screen(world_x_px: float, height_px: float) -> Vector2:
	return Vector2(world_x_px - _cam_x + size.x / 2.0, GROUND_Y - height_px)


func _draw() -> void:
	if _sim == null:
		return
	_update_camera()
	_draw_sky()
	_draw_hills()
	_draw_ground()
	for f in _sim.fighters:
		_draw_shadow(f)
	for f in _sim.fighters:
		_draw_fighter(f)
	if show_debug:
		for f in _sim.fighters:
			_draw_debug(f)


func _draw_sky() -> void:
	# Небо меняется от света (левый край арены) к тьме (правый край).
	var steps := 24
	var w := size.x / steps
	for i in steps:
		var world_x := _cam_x - size.x / 2.0 + (i + 0.5) * w
		var t := clampf(world_x / Sim.ARENA_WIDTH, 0.0, 1.0)
		var horizon := SKY_LIGHT.lerp(SKY_DARK, t)
		var top := Rect2(i * w, 0, w + 1, GROUND_Y * 0.5)
		var low := Rect2(i * w, GROUND_Y * 0.5, w + 1, GROUND_Y * 0.5)
		draw_rect(top, SKY_TOP.lerp(horizon, 0.35))
		draw_rect(low, SKY_TOP.lerp(horizon, 0.8))


func _draw_hills() -> void:
	var offset := -_cam_x * PARALLAX_HILLS
	var pts := PackedVector2Array()
	pts.append(Vector2(0, GROUND_Y))
	var x := 0.0
	while x <= size.x + 20:
		var wx := x - offset
		var h := 70.0 + 40.0 * sin(wx * 0.011) + 25.0 * sin(wx * 0.027 + 1.3)
		pts.append(Vector2(x, GROUND_Y - h))
		x += 20
	pts.append(Vector2(size.x, GROUND_Y))
	draw_colored_polygon(pts, Color(0.12, 0.1, 0.14, 0.85))


func _draw_ground() -> void:
	draw_rect(Rect2(0, GROUND_Y, size.x, size.y - GROUND_Y), COLOR_GROUND)
	draw_line(Vector2(0, GROUND_Y), Vector2(size.x, GROUND_Y), COLOR_LINE, 3)
	# Метки каждые 100 пикселей — чтобы было видно движение камеры.
	var first := int(floor((_cam_x - size.x / 2.0) / 100.0)) * 100
	for wx in range(first, int(_cam_x + size.x / 2.0) + 100, 100):
		var p := to_screen(wx, 0)
		draw_line(p, p + Vector2(-30, 40), COLOR_LINE, 2)
	# Камень на перекрёстке в центре арены.
	var stone := to_screen(Sim.ARENA_WIDTH / 2.0, 0)
	draw_rect(Rect2(stone + Vector2(-46, -150), Vector2(92, 150)), Color(0.42, 0.4, 0.42))
	draw_rect(Rect2(stone + Vector2(-46, -150), Vector2(92, 150)), Color(0.25, 0.24, 0.26), false, 3)
	_text_centered(stone + Vector2(0, -112), "НАЛЕВО", 13, Color(0.15, 0.14, 0.16))
	_text_centered(stone + Vector2(0, -92), "ПОЙДЁШЬ…", 13, Color(0.15, 0.14, 0.16))
	# Стены по краям арены.
	for wall_x in [0.0, float(Sim.ARENA_WIDTH)]:
		var w := to_screen(wall_x, 0)
		draw_rect(Rect2(w.x - 12, 0, 24, GROUND_Y), Color(0.05, 0.05, 0.07))


func _draw_shadow(f: Fighter) -> void:
	var p := to_screen(float(f.x) / Sim.SUB, 0)
	var scale := clampf(1.0 - float(f.y) / Sim.SUB / 400.0, 0.4, 1.0)
	var r: float = f.data.push_half * 1.3 * scale
	draw_set_transform(p, 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)


## Боец-заглушка: тело, голова и «нос», показывающий, куда он смотрит.
func _draw_fighter(f: Fighter) -> void:
	var base := to_screen(float(f.x) / Sim.SUB, float(f.y) / Sim.SUB)
	var h: float = f.data.height
	var w: float = f.data.push_half * 2.0
	match f.state:
		Fighter.State.CROUCH:
			h = f.data.crouch_height
		Fighter.State.PREJUMP, Fighter.State.LAND:
			h *= 0.85
			w *= 1.1
		Fighter.State.AIR:
			h *= 0.8
	var dir := float(f.facing)
	# Наклон корпуса: вперёд в беге, назад при торможении и отскоке.
	var lean := 0.0
	match f.state:
		Fighter.State.RUN:
			lean = 0.22
			h *= 0.92
		Fighter.State.RUN_STOP:
			lean = -0.1
		Fighter.State.BACKDASH:
			lean = -0.2
			h *= 0.95
	var head_r := w * 0.32
	var body_top := base.y - h + head_r * 1.6
	var shift := Vector2(dir * lean * h, 0)
	var color: Color = f.data.color
	var body := PackedVector2Array([
		Vector2(base.x - w / 2.0, base.y),
		Vector2(base.x + w / 2.0, base.y),
		Vector2(base.x + w / 2.0, body_top) + shift,
		Vector2(base.x - w / 2.0, body_top) + shift,
	])
	draw_colored_polygon(body, color)
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, color.darkened(0.45), 3)
	var head := Vector2(base.x, base.y - h + head_r) + shift * 1.1
	draw_circle(head, head_r, color.lightened(0.15))
	draw_arc(head, head_r, 0, TAU, 32, color.darkened(0.45), 3)
	# Нос и глаз со стороны взгляда.
	var nose := PackedVector2Array([
		head + Vector2(dir * head_r * 0.8, -head_r * 0.15),
		head + Vector2(dir * head_r * 1.45, head_r * 0.15),
		head + Vector2(dir * head_r * 0.8, head_r * 0.4),
	])
	draw_colored_polygon(nose, color.darkened(0.45))
	draw_circle(head + Vector2(dir * head_r * 0.4, -head_r * 0.25), head_r * 0.14, Color.WHITE)
	# Рука вперёд — тоже подсказка, куда смотрит боец.
	var body_h := base.y - body_top
	var shoulder := Vector2(base.x + dir * w * 0.2, body_top + body_h * 0.25) + shift * 0.75
	draw_line(shoulder, shoulder + Vector2(dir * w * 0.55, body_h * 0.2), color.darkened(0.3), 10)
	# Линии скорости за спиной в беге и отскоке.
	if f.state == Fighter.State.RUN or f.state == Fighter.State.BACKDASH:
		var behind := -signf(float(f.vx)) if f.vx != 0 else -dir
		for i in 3:
			var ly := base.y - h * (0.3 + 0.2 * i)
			var lx := base.x + behind * (w * 0.7 + 10 * i)
			draw_line(Vector2(lx, ly), Vector2(lx + behind * 50, ly), Color(1, 1, 1, 0.45), 3)


## Отладка (F2): рамка «тела» для столкновений, состояние, координаты.
func _draw_debug(f: Fighter) -> void:
	var x := float(f.x) / Sim.SUB
	var y := float(f.y) / Sim.SUB
	var ph := float(f.push_height()) / Sim.SUB
	var half := float(f.push_half()) / Sim.SUB
	var tl := to_screen(x - half, y + ph)
	draw_rect(Rect2(tl, Vector2(half * 2, ph)), Color(0.3, 0.9, 1.0), false, 2)
	var origin := to_screen(x, y)
	draw_line(origin + Vector2(-8, 0), origin + Vector2(8, 0), Color.WHITE, 2)
	draw_line(origin + Vector2(0, -8), origin + Vector2(0, 8), Color.WHITE, 2)
	var label := "%s · %d\nx %d  y %d" % [Fighter.STATE_NAMES[f.state], f.state_frame, int(x), int(y)]
	var lines := label.split("\n")
	for i in lines.size():
		_text_centered(tl + Vector2(half, -34 + i * 18), lines[i], 14, Color(0.3, 0.9, 1.0))


func _text_centered(pos: Vector2, s: String, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, pos - Vector2(width / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
