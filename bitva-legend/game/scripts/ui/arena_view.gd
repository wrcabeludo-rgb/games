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
var _shake := Vector2.ZERO


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
	# Тряска на попадании: сильнее в начале заморозки, знак меняется каждый тик.
	_shake = Vector2.ZERO
	if _sim.hitstop > 0 and _sim.hitstop_total > 0:
		var amp := minf(2.0 + _sim.hitstop_total * 0.6, 12.0)
		var k := float(_sim.hitstop) / _sim.hitstop_total
		var sgn := 1.0 if _sim.tick % 2 == 0 else -1.0
		_shake = Vector2(sgn * amp * k, -sgn * amp * k * 0.5)


func to_screen(world_x_px: float, height_px: float) -> Vector2:
	return Vector2(world_x_px - _cam_x + size.x / 2.0, GROUND_Y - height_px) + _shake


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
	for pr in _sim.projectiles:
		_draw_projectile(pr)
	for p in Sim.PLAYERS:
		_draw_spark(p)
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
	if f.state == Fighter.State.DOWN:
		_draw_down(f)
		return
	if f.is_intangible():
		_draw_mist(f)
		return
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
		Fighter.State.HITSTUN:
			lean = -0.15
			if f.low_pose:
				h = f.data.crouch_height
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			lean = -0.06 if f.state == Fighter.State.BLOCKSTUN else 0.0
			if f.low_pose:
				h = f.data.crouch_height
		Fighter.State.AIR_HIT:
			lean = -0.4
		Fighter.State.ATTACK:
			if f.is_crouching():
				h = f.data.crouch_height
			elif f.move_phase() == 1:
				lean = 0.08
	var head_r := w * 0.32
	var body_top := base.y - h + head_r * 1.6
	var shift := Vector2(dir * lean * h, 0)
	var color: Color = f.data.color
	# Вспышка у получившего удар во время заморозки.
	if f.is_stunned() and _sim.hitstop > 0:
		color = color.lerp(Color.WHITE, 0.55)
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
	if f.has_armor():
		# Броня тарана — оранжевое свечение.
		var glow := PackedVector2Array(body)
		glow.append(body[0])
		draw_polyline(glow, Color(1, 0.6, 0.15, 0.85), 6)
	if f.is_countering():
		# Гипнотический взгляд — фиолетовая аура и горящие глаза.
		draw_arc(head, head_r + 10, 0, TAU, 32, Color(0.7, 0.3, 1.0, 0.6), 4)
		draw_circle(head + Vector2(float(f.facing) * head_r * 0.4, -head_r * 0.25), head_r * 0.22, Color(0.85, 0.4, 1.0))
	if f.hypnotized:
		# Загипнотизирован — спираль над головой.
		var c := head + Vector2(0, -head_r - 26)
		var prev := c
		for i in 24:
			var a := i * 0.55 + _sim.tick * 0.25
			var pt := c + Vector2.from_angle(a) * (i * 0.9)
			draw_line(prev, pt, Color(0.75, 0.4, 1.0), 2.5)
			prev = pt
	# Нос и глаз со стороны взгляда.
	var nose := PackedVector2Array([
		head + Vector2(dir * head_r * 0.8, -head_r * 0.15),
		head + Vector2(dir * head_r * 1.45, head_r * 0.15),
		head + Vector2(dir * head_r * 0.8, head_r * 0.4),
	])
	draw_colored_polygon(nose, color.darkened(0.45))
	draw_circle(head + Vector2(dir * head_r * 0.4, -head_r * 0.25), head_r * 0.14, Color.WHITE)
	var body_h := base.y - body_top
	var shoulder := Vector2(base.x + dir * w * 0.2, body_top + body_h * 0.25) + shift * 0.75
	if f.move >= 0:
		_draw_attack(f, shoulder, Vector2(base.x + dir * w * 0.15, base.y - body_h * 0.45), color)
	elif f.state == Fighter.State.BLOCK or f.state == Fighter.State.BLOCKSTUN:
		_draw_guard(f, shoulder, body_h, dir, color)
	elif _is_celebrating(f):
		# Победная поза: рука вверх, у Ильи — с палицей.
		var hand := shoulder + Vector2(dir * 48, -body_h * 0.5)
		draw_line(shoulder, hand, color.darkened(0.3), 12)
		if f.id == "ilya":
			draw_circle(hand + Vector2(0, -20), 24, Color(0.36, 0.3, 0.26))
		else:
			draw_circle(hand, 9, color.darkened(0.45))
	else:
		# Рука вперёд — тоже подсказка, куда смотрит боец.
		draw_line(shoulder, shoulder + Vector2(dir * w * 0.55, body_h * 0.2), color.darkened(0.3), 10)
	# Линии скорости за спиной в беге и отскоке.
	if f.state == Fighter.State.RUN or f.state == Fighter.State.BACKDASH:
		var behind := -signf(float(f.vx)) if f.vx != 0 else -dir
		for i in 3:
			var ly := base.y - h * (0.3 + 0.2 * i)
			var lx := base.x + behind * (w * 0.7 + 10 * i)
			draw_line(Vector2(lx, ly), Vector2(lx + behind * 50, ly), Color(1, 1, 1, 0.45), 3)


## Рука или нога во время удара: замах, удар до края хитбокса, возврат.
func _draw_attack(f: Fighter, shoulder: Vector2, hip: Vector2, color: Color) -> void:
	var m := f.move_data()
	if not m.has("box"):
		_draw_throw(f, shoulder, color)
		return
	var b: Array = m.box
	var dir := float(f.facing)
	var button: int = f.move % 4
	var is_kick := button == 1 or button == 3
	var origin := hip if is_kick else shoulder
	var tip := to_screen(float(f.x) / Sim.SUB + dir * (b[0] + b[2] * 0.85), float(f.y) / Sim.SUB + b[1] + b[3] / 2.0)
	var end := tip
	match f.move_phase():
		0:
			var t: float = float(f.move_frame) / m.startup
			end = origin + Vector2(-dir * 25.0 * t, -10.0 * t)
		2:
			var rec: int = m.get("recovery", 12)
			var r := clampf(float(f.move_frame - m.startup - m.active) / rec, 0.0, 1.0)
			end = tip.lerp(origin + Vector2(dir * 20, 0), r)
	var limb_color := color.darkened(0.3)
	draw_line(origin, end, limb_color, 18.0 if is_kick else 14.0)
	draw_circle(end, 10.0 if is_kick else 9.0, limb_color.darkened(0.2))
	var with_mace: bool = button == 2 or Fighter.MOVES[f.move] == "sp_ff_l"
	if with_mace and f.id == "ilya" and not _sim.has_projectile(_sim.fighters.find(f)):
		# Палица.
		draw_circle(end, 24, Color(0.36, 0.3, 0.26))
		for i in 6:
			var a := TAU * i / 6.0
			draw_line(end + Vector2.from_angle(a) * 20, end + Vector2.from_angle(a) * 32, Color(0.25, 0.2, 0.18), 5)
	elif button == 2 and f.id == "dracula":
		# Когти.
		var v := (end - origin).normalized()
		for i in 3:
			var side := v.orthogonal() * (i - 1) * 8.0
			draw_line(end + side, end + side + v * 22, Color(0.95, 0.9, 0.85), 3)


## Победитель раунда празднует через секунду после конца раунда.
func _is_celebrating(f: Fighter) -> bool:
	var ph := _sim.phase
	if ph != Sim.Phase.ROUND_END and ph != Sim.Phase.MATCH_END:
		return false
	if _sim.phase_frame < 50 and ph == Sim.Phase.ROUND_END:
		return false
	var w := _sim.round_winner if ph == Sim.Phase.ROUND_END else _sim.match_winner()
	return w >= 0 and w < 2 and _sim.fighters[w] == f and f.is_grounded_actionable()


## Поверженный боец лежит на земле.
func _draw_down(f: Fighter) -> void:
	var base := to_screen(float(f.x) / Sim.SUB, 0)
	var length: float = f.data.height * 0.8
	var thick: float = Fighter.DOWN_HEIGHT * 0.8
	var head_side := -float(f.facing)
	var color: Color = f.data.color.darkened(0.15)
	var body := Rect2(base.x - length / 2.0, base.y - thick, length, thick)
	draw_rect(body, color)
	draw_rect(body, color.darkened(0.45), false, 3)
	var head := Vector2(base.x + head_side * (length / 2.0 + 18), base.y - 24)
	draw_circle(head, 24, color.lightened(0.15))
	draw_arc(head, 24, 0, TAU, 24, color.darkened(0.45), 3)
	# Звёздочки над головой.
	for i in 3:
		var a := _sim.tick * 0.12 + TAU * i / 3.0
		var star := head + Vector2(cos(a) * 30, -36 + sin(a) * 8)
		draw_circle(star, 5, Color(1, 0.9, 0.4))


## Блок: скрещённые руки перед собой и полупрозрачный щит.
func _draw_guard(f: Fighter, shoulder: Vector2, body_h: float, dir: float, color: Color) -> void:
	var front := shoulder + Vector2(dir * f.data.push_half * 0.9, body_h * 0.15)
	var arm := color.darkened(0.3)
	draw_line(shoulder, front + Vector2(0, -body_h * 0.12), arm, 12)
	draw_line(shoulder + Vector2(0, body_h * 0.2), front + Vector2(0, body_h * 0.05), arm, 12)
	var glow := 0.55 if f.state == Fighter.State.BLOCKSTUN else 0.3
	var c := front + Vector2(-dir * 6, 0)
	var r := body_h * 0.28
	draw_arc(c, r, -PI / 2.6 if dir > 0 else PI - PI / 2.6, (PI / 2.6) if dir > 0 else PI + PI / 2.6,
		16, Color(0.45, 0.75, 1.0, glow), 6)


## Туманный рывок: вместо тела — клубы тумана.
func _draw_mist(f: Fighter) -> void:
	var base := to_screen(float(f.x) / Sim.SUB, float(f.y) / Sim.SUB)
	var h: float = f.data.height
	for i in 7:
		var a := _sim.tick * 0.2 + i * 0.9
		var c := base + Vector2(cos(a) * 30, -h * (0.15 + 0.11 * i))
		draw_circle(c, 26 - i * 1.5, Color(0.55, 0.45, 0.65, 0.35))


## Поза броска снаряда: замах назад-вверх, затем рука вперёд.
func _draw_throw(f: Fighter, shoulder: Vector2, color: Color) -> void:
	var m := f.move_data()
	var dir := float(f.facing)
	var t := clampf(float(f.move_frame) / m.startup, 0.0, 1.0)
	var hand: Vector2
	if f.move_frame < m.startup:
		hand = shoulder + Vector2(-dir * 40 * t, -70 * t)  # замах
	else:
		hand = shoulder + Vector2(dir * 70, -10)            # бросок
	draw_line(shoulder, hand, color.darkened(0.3), 13)
	if f.id == "ilya" and f.move_frame < m.startup:
		draw_circle(hand, 24, Color(0.36, 0.3, 0.26))  # палица в руке до броска
	elif f.id == "dracula":
		draw_circle(hand, 10 + 6 * t, Color(0.55, 0.1, 0.2, 0.6))  # тёмная сила в ладони


## Снаряд: палица крутится в полёте, летучие мыши машут крыльями.
func _draw_projectile(pr: PackedInt32Array) -> void:
	var c := to_screen(float(pr[Sim.Proj.X]) / Sim.SUB, float(pr[Sim.Proj.Y]) / Sim.SUB)
	var age := pr[Sim.Proj.AGE]
	var dir := signf(float(pr[Sim.Proj.VX]))
	if pr[Sim.Proj.KIND] == 2:
		# Волна от удара оземь: бегущие по земле камни и пыль.
		var hw := float(pr[Sim.Proj.HW]) / Sim.SUB
		var ground := to_screen(float(pr[Sim.Proj.X]) / Sim.SUB, 0)
		for i in 5:
			var ox := (i - 2) * hw * 0.4
			var hgt := 18.0 + 14.0 * absf(sin(age * 0.6 + i))
			var rock := PackedVector2Array([ground + Vector2(ox - 10, 0), ground + Vector2(ox, -hgt), ground + Vector2(ox + 10, 0)])
			draw_colored_polygon(rock, Color(0.5, 0.42, 0.34))
		draw_circle(ground + Vector2(-dir * hw * 0.7, -8), 12, Color(0.75, 0.68, 0.55, 0.5))
	elif pr[Sim.Proj.KIND] == 0:
		var a := age * 0.35 * dir
		var handle := Vector2.from_angle(a) * 34
		draw_line(c - handle, c, Color(0.45, 0.32, 0.2), 9)
		draw_circle(c + handle * 0.25, 24, Color(0.36, 0.3, 0.26))
		for i in 6:
			var sa := a + TAU * i / 6.0
			draw_line(c + handle * 0.25 + Vector2.from_angle(sa) * 20, c + handle * 0.25 + Vector2.from_angle(sa) * 32, Color(0.25, 0.2, 0.18), 5)
	else:
		var hw := float(pr[Sim.Proj.HW]) / Sim.SUB
		for i in 3:
			var off := Vector2(-dir * (i * hw * 0.55 - hw * 0.4), sin(age * 0.5 + i * 2.1) * 10 + (i - 1) * 9)
			var b := c + off
			var flap := 8.0 + 7.0 * sin(age * 0.9 + i)
			var ink := Color(0.12, 0.05, 0.1)
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([b, b + Vector2(side * 17, -flap), b + Vector2(side * 7, 6)]), ink)
			draw_circle(b, 5, ink)
			draw_circle(b + Vector2(dir * 3, -1), 2, Color(1, 0.3, 0.3))
	if show_debug:
		_debug_box(Sim._proj_box(pr), Color(1, 0.2, 0.2, 0.95))


## Искра попадания: вспышка-звезда, у сильных ударов крупнее.
func _draw_spark(p: int) -> void:
	var base := p * 4
	var age := _sim.tick - _sim.sparks[base]
	if age < 0 or age > 14:
		return
	var kind := _sim.sparks[base + 3]
	var heavy := kind == 1
	var c := to_screen(float(_sim.sparks[base + 1]) / Sim.SUB, float(_sim.sparks[base + 2]) / Sim.SUB)
	var k := 1.0 - age / 14.0
	if kind == 3:
		# Удар в броню — оранжевое кольцо.
		draw_arc(c, 20.0 + age * 3.0, 0, TAU, 24, Color(1, 0.6, 0.15, k), 5)
		return
	if kind == 4:
		# Контратака — фиолетовая спираль.
		var prev := c
		for i in 30:
			var a := i * 0.5 + age * 0.3
			var pt := c + Vector2.from_angle(a) * (i * (1.5 + age * 0.2))
			draw_line(prev, pt, Color(0.75, 0.4, 1.0, k), 3)
			prev = pt
		return
	if kind == 2:
		# Блок — голубые расходящиеся дуги.
		for i in 3:
			var rr := 14.0 + age * 3.0 + i * 9.0
			draw_arc(c, rr, 0, TAU, 24, Color(0.5, 0.8, 1.0, k * (1.0 - i * 0.25)), 3)
		return
	var r := (46.0 if heavy else 30.0) * (0.6 + 0.4 * k)
	var col := Color(1.0, 0.95, 0.6, k)
	var rays := 10 if heavy else 7
	for i in rays:
		var a := TAU * i / rays + age * 0.15
		var ray_len := r * (1.0 if i % 2 == 0 else 0.55)
		draw_line(c, c + Vector2.from_angle(a) * ray_len, col, 4.0 if heavy else 3.0)
	draw_circle(c, r * 0.35, Color(1, 1, 1, k))


## Отладка (F2): рамка «тела» для столкновений, состояние, координаты.
func _draw_debug(f: Fighter) -> void:
	var x := float(f.x) / Sim.SUB
	var y := float(f.y) / Sim.SUB
	var ph := float(f.push_height()) / Sim.SUB
	var half := float(f.push_half()) / Sim.SUB
	var tl := to_screen(x - half, y + ph)
	draw_rect(Rect2(tl, Vector2(half * 2, ph)), Color(0.3, 0.9, 1.0), false, 2)
	# Уязвимые зоны — зелёные, хитбокс — красный (бледный, если сейчас не бьёт).
	for hb in f.hurtboxes():
		_debug_box(hb, Color(0.3, 1.0, 0.4, 0.8))
	if f.move >= 0:
		_debug_box(f.hitbox(), Color(1, 0.2, 0.2, 0.95) if f.is_active() else Color(1, 0.5, 0.5, 0.35))
	var origin := to_screen(x, y)
	draw_line(origin + Vector2(-8, 0), origin + Vector2(8, 0), Color.WHITE, 2)
	draw_line(origin + Vector2(0, -8), origin + Vector2(0, 8), Color.WHITE, 2)
	var label := "%s · %d\nx %d  y %d" % [Fighter.STATE_NAMES[f.state], f.state_frame, int(x), int(y)]
	if f.move >= 0:
		var m := f.move_data()
		label = "%s %s · тик %d/%d\nx %d  y %d" % [Fighter.MOVES[f.move], ["замах", "БЬЁТ", "возврат"][f.move_phase()],
			f.move_frame, m.startup + m.active - 1 + m.get("recovery", 0), int(x), int(y)]
	var lines := label.split("\n")
	for i in lines.size():
		_text_centered(tl + Vector2(half, -34 + i * 18), lines[i], 14, Color(0.3, 0.9, 1.0))


func _debug_box(b: PackedInt32Array, color: Color) -> void:
	var a := to_screen(float(b[0]) / Sim.SUB, float(b[3]) / Sim.SUB)
	var c := to_screen(float(b[1]) / Sim.SUB, float(b[2]) / Sim.SUB)
	draw_rect(Rect2(a, c - a), color, false, 2)
	draw_rect(Rect2(a, c - a), Color(color, 0.12))


func _text_centered(pos: Vector2, s: String, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, pos - Vector2(width / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
