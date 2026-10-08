class_name ArenaView
extends Control
## Отрисовка арены и бойцов по состоянию Sim. Только чтение: в логику боя не вмешивается.
## Пока вместо спрайтов — цветные фигуры. Фон арены — ArenaScenery.

const GROUND_Y := 640                 # линия земли на экране (при высоте 720)

var show_debug := false
var _font := SystemFont.new()
var _sim: Sim
var _cam_x := 0.0
var _shake := Vector2.ZERO
var _scenery := ArenaScenery.new()
var sprites := FighterSprites.new()
## Спрайты бойцов (где они уже есть); F7 — переключить на заглушки и обратно.
var use_sprites := true


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
	_scenery.update(_cam_x, _shake, _sim.tick, size, GROUND_Y, Sim.ARENA_WIDTH)
	_scenery.draw_back(self)
	_draw_walls()
	_draw_super_backdrop()
	for f in _sim.fighters:
		_draw_shadow(f)
	for f in _sim.fighters:
		_draw_fighter(f)
	for pr in _sim.projectiles:
		_draw_projectile(pr)
	_scenery.draw_front(self)
	for p in Sim.PLAYERS:
		_draw_spark(p)
	if show_debug:
		for f in _sim.fighters:
			_draw_debug(f)


## Стены по краям арены.
func _draw_walls() -> void:
	for wall_x in [0.0, float(Sim.ARENA_WIDTH)]:
		var w := to_screen(wall_x, 0)
		draw_rect(Rect2(w.x - 12, 0, 24, GROUND_Y), Color(0.05, 0.05, 0.07))


## Суперприём: затемнение; у Ильи — молнии с неба, у Дракулы — кровавая луна.
func _draw_super_backdrop() -> void:
	for p in Sim.PLAYERS:
		var f := _sim.fighters[p]
		if not f.is_super():
			continue
		var flash := f.state == Fighter.State.ATTACK and f.move_frame == 1 and _sim.hitstop > 0
		var cinema := f.state == Fighter.State.THROWING
		if not flash and not cinema:
			continue
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.0, 0.05, 0.6 if cinema else 0.45))
		var foe := _sim.fighters[1 - p]
		var foe_top := to_screen(float(foe.x) / Sim.SUB, float(foe.y) / Sim.SUB + foe.data.height * 0.6)
		if f.id == "dracula":
			var moon := Vector2(size.x * 0.5, 170)
			draw_circle(moon, 120, Color(0.65, 0.05, 0.08, 0.9))
			draw_circle(moon + Vector2(-30, -20), 26, Color(0.5, 0.03, 0.06, 0.8))
			draw_circle(moon + Vector2(40, 30), 16, Color(0.5, 0.03, 0.06, 0.8))
		else:
			draw_circle(Vector2(size.x * 0.5, -60), 260, Color(1, 0.9, 0.5, 0.25))
		if not cinema:
			continue
		var t := f.state_frame
		# Серия ударов: вспышка каждые 10 тиков, в конце — самая большая.
		var beat := t % 10
		var k := 1.0 - beat / 10.0
		if f.id == "ilya" and beat < 4:
			# Молния бьёт в соперника.
			var pts := PackedVector2Array([Vector2(foe_top.x + 40, 0)])
			var seg := 7
			for i in range(1, seg + 1):
				var jitter := 28.0 * sin(t * 1.7 + i * 2.3)
				pts.append(Vector2(foe_top.x + jitter * (1.0 - float(i) / seg), foe_top.y * i / seg))
			draw_polyline(pts, Color(0.85, 0.9, 1.0), 6)
			draw_polyline(pts, Color(1, 1, 1), 2)
		elif f.id == "dracula":
			# Стая кружит вокруг соперника.
			for i in 7:
				var a := t * 0.25 + TAU * i / 7.0
				var b := foe_top + Vector2(cos(a) * 90, sin(a) * 50)
				var ink := Color(0.1, 0.02, 0.06)
				for side in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([b, b + Vector2(side * 18, -8), b + Vector2(side * 7, 6)]), ink)
		var r := (40.0 + 30.0 * k) * (1.6 if t > 80 else 1.0)
		for i in 10:
			var a := TAU * i / 10.0 + t * 0.2
			draw_line(foe_top, foe_top + Vector2.from_angle(a) * r * (1.0 if i % 2 == 0 else 0.55), Color(1, 0.95, 0.6, k), 4)


func _draw_shadow(f: Fighter) -> void:
	var p := to_screen(float(f.x) / Sim.SUB, 0)
	var scale := clampf(1.0 - float(f.y) / Sim.SUB / 400.0, 0.4, 1.0)
	var r: float = f.data.push_half * 1.3 * scale
	draw_set_transform(p, 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)


## Кадр спрайта: опорная точка (центр бойца на земле) — в позиции бойца; смотрит влево — отражаем.
func _draw_sprite(f: Fighter, tex: Texture2D, pivot: Vector2, breathe := false) -> void:
	var base := to_screen(float(f.x) / Sim.SUB, float(f.y) / Sim.SUB)
	var tint := Color(0.75, 0.85, 1.0) if f.alt else Color.WHITE
	if f.is_stunned() and _sim.hitstop > 0:
		tint = Color(1.0, 0.75, 0.7)  # получил удар — краснеет на время заморозки
	draw_set_transform(base, 0, Vector2(FighterSprites.SCALE * f.facing, FighterSprites.SCALE))
	if breathe:
		var phase := 0.5 - 0.5 * cos(TAU * float(_sim.tick) / FighterSprites.BREATH_TICKS)
		FighterSprites.draw_breathing(self, tex, pivot, tint, f.data.height * 2.0, phase)
	else:
		draw_texture(tex, -pivot, tint)
	draw_set_transform(Vector2.ZERO)
	if f.staggered:
		var head := base + Vector2(0, -float(f.data.height) - 10)
		for i in 3:
			var a := _sim.tick * 0.2 + TAU * i / 3.0
			draw_circle(head + Vector2(cos(a) * 40, sin(a) * 8), 6, Color(1, 0.9, 0.3))


## Боец-заглушка: тело, голова и «нос», показывающий, куда он смотрит.
func _draw_fighter(f: Fighter) -> void:
	if use_sprites and not f.is_intangible():
		var fr := sprites.frame_for(f, _sim.tick)
		if not fr.is_empty():
			_draw_sprite(f, fr[0], fr[1], fr.size() > 2 and fr[2])
			return
	if f.state == Fighter.State.DOWN:
		_draw_down(f, true)
		return
	if f.state == Fighter.State.KNOCKDOWN and f.state_frame < Fighter.KNOCKDOWN_TICKS - 10:
		_draw_down(f, false)
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
		Fighter.State.KNOCKDOWN:
			h = f.data.crouch_height * 0.8  # поднимается
		Fighter.State.THROWN:
			lean = -0.2
			h *= 0.95
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
	var color: Color = f.color()
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
	if f.ex and f.state == Fighter.State.ATTACK and f.move >= Fighter.SPECIAL_BASE and f.move < Fighter.MOVE_SWEEP:
		# Усиленный спецприём — золотое сияние.
		var aura := PackedVector2Array(body)
		aura.append(body[0])
		draw_polyline(aura, Color(1, 0.85, 0.3, 0.6 + 0.3 * sin(_sim.tick * 0.6)), 8)
	if f.has_armor():
		# Броня тарана — оранжевое свечение.
		var glow := PackedVector2Array(body)
		glow.append(body[0])
		draw_polyline(glow, Color(1, 0.6, 0.15, 0.85), 6)
	if f.is_countering():
		# Гипнотический взгляд — фиолетовая аура и горящие глаза.
		draw_arc(head, head_r + 10, 0, TAU, 32, Color(0.7, 0.3, 1.0, 0.6), 4)
		draw_circle(head + Vector2(float(f.facing) * head_r * 0.4, -head_r * 0.25), head_r * 0.22, Color(0.85, 0.4, 1.0))
	if f.staggered:
		# Ошеломлён парированием — звёздочки кружат над головой.
		for i in 3:
			var a := _sim.tick * 0.2 + TAU * i / 3.0
			var sp := head + Vector2(cos(a) * head_r * 1.2, -head_r - 14 + sin(a) * 6)
			draw_circle(sp, 6, Color(1, 0.9, 0.3))
			draw_circle(sp, 3, Color(1, 1, 0.8))
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
	elif f.state == Fighter.State.THROWING:
		# Держит соперника обеими руками.
		var grip := shoulder + Vector2(dir * w * 0.85, body_h * 0.05)
		draw_line(shoulder, grip, color.darkened(0.3), 13)
		draw_line(shoulder + Vector2(0, body_h * 0.18), grip + Vector2(0, body_h * 0.12), color.darkened(0.3), 13)
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
	if f.state == Fighter.State.THROWING and m.has("cinema"):
		# Ролик суперприёма: удары один за другим.
		var t := f.state_frame
		var dir := float(f.facing)
		var reach := shoulder + Vector2(dir * (75.0 + 30.0 * sin(t * 0.9)), -20.0 + 40.0 * cos(t * 0.9))
		draw_line(shoulder, reach, color.darkened(0.3), 15)
		if f.id == "ilya":
			draw_circle(reach, 30, Color(0.36, 0.3, 0.26))
		else:
			_draw_claws(reach, (reach - shoulder).normalized())
		return
	if m.has("grab"):
		# Захват: руки тянутся вперёд.
		var reach := shoulder + Vector2(float(f.facing) * (40.0 + 6.0 * f.move_frame), 10)
		draw_line(shoulder, reach, color.darkened(0.3), 13)
		draw_circle(reach, 11, color.darkened(0.45))
		return
	if not m.has("box"):
		_draw_throw(f, shoulder, color)
		return
	var b: Array = m.box
	var dir := float(f.facing)
	var button: int = f.move % 4
	var is_kick: bool = (button == 1 or button == 3 or m.get("kick", 0) == 1) and not f.is_super()
	var origin := hip if is_kick else shoulder
	var tip := to_screen(float(f.x) / Sim.SUB + dir * (b[0] + b[2] * 0.85), float(f.y) / Sim.SUB + b[1] + b[3] / 2.0)
	if m.get("uppercut", 0):
		# Апперкот: кулак у земли перед собой → вверх над головой.
		var low := to_screen(float(f.x) / Sim.SUB + dir * (b[0] + b[2] * 0.6), float(f.y) / Sim.SUB + 40)
		var high := to_screen(float(f.x) / Sim.SUB + dir * (b[0] + b[2] * 0.45), float(f.y) / Sim.SUB + b[1] + b[3] * 0.9)
		tip = high
		if f.move_phase() == 0:
			tip = low
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
	var with_mace: bool = button == 2 or Fighter.MOVES[f.move] == "sp_ff_l" or f.is_super()
	if with_mace and f.id == "ilya" and not _sim.has_projectile(_sim.fighters.find(f)):
		# Палица.
		draw_circle(end, 24, Color(0.36, 0.3, 0.26))
		for i in 6:
			var a := TAU * i / 6.0
			draw_line(end + Vector2.from_angle(a) * 20, end + Vector2.from_angle(a) * 32, Color(0.25, 0.2, 0.18), 5)
	elif (button == 2 or f.is_super()) and f.id == "dracula":
		_draw_claws(end, (end - origin).normalized())


func _draw_claws(end: Vector2, v: Vector2) -> void:
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
func _draw_down(f: Fighter, stars: bool) -> void:
	var base := to_screen(float(f.x) / Sim.SUB, 0)
	var length: float = f.data.height * 0.8
	var thick: float = Fighter.DOWN_HEIGHT * 0.8
	var head_side := -float(f.facing)
	var color: Color = f.color().darkened(0.15)
	var body := Rect2(base.x - length / 2.0, base.y - thick, length, thick)
	draw_rect(body, color)
	draw_rect(body, color.darkened(0.45), false, 3)
	var head := Vector2(base.x + head_side * (length / 2.0 + 18), base.y - 24)
	draw_circle(head, 24, color.lightened(0.15))
	draw_arc(head, 24, 0, TAU, 24, color.darkened(0.45), 3)
	# Звёздочки над головой — только у поверженного.
	for i in (3 if stars else 0):
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
	# Виды 3–5 — усиленные версии 0–2: то же, но с сиянием.
	var kind := pr[Sim.Proj.KIND] % 3
	if pr[Sim.Proj.KIND] >= 3:
		var glow_at := c if kind != 2 else to_screen(float(pr[Sim.Proj.X]) / Sim.SUB, 20)
		draw_circle(glow_at, float(pr[Sim.Proj.HW]) / Sim.SUB * 1.3, Color(1, 0.8, 0.3, 0.35))
	if kind == 2:
		# Волна от удара оземь: бегущие по земле камни и пыль.
		var hw := float(pr[Sim.Proj.HW]) / Sim.SUB
		var ground := to_screen(float(pr[Sim.Proj.X]) / Sim.SUB, 0)
		for i in 5:
			var ox := (i - 2) * hw * 0.4
			var hgt := 18.0 + 14.0 * absf(sin(age * 0.6 + i))
			var rock := PackedVector2Array([ground + Vector2(ox - 10, 0), ground + Vector2(ox, -hgt), ground + Vector2(ox + 10, 0)])
			draw_colored_polygon(rock, Color(0.5, 0.42, 0.34))
		draw_circle(ground + Vector2(-dir * hw * 0.7, -8), 12, Color(0.75, 0.68, 0.55, 0.5))
	elif kind == 0:
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
	if kind == 5:
		# Парирование — синяя вспышка и расходящееся кольцо.
		draw_circle(c, 30.0 * k + 6.0, Color(0.6, 0.85, 1.0, k * 0.8))
		draw_arc(c, 18.0 + age * 5.0, 0, TAU, 32, Color(0.4, 0.7, 1.0, k), 5)
		for i in 8:
			var a := TAU * i / 8.0
			draw_line(c + Vector2.from_angle(a) * (20.0 + age * 3.0), c + Vector2.from_angle(a) * (34.0 + age * 5.0), Color(0.85, 0.95, 1.0, k), 3)
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
