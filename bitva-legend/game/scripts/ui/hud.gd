class_name Hud
extends Control
## Интерфейс боя: полоски здоровья со «следом» урона, таймер, победы в раундах,
## объявления («РАУНД 1», «БОЙ!», «НОКАУТ!»), история ввода (F1), подсказки.

const COLOR_TEXT := Color(0.95, 0.95, 0.97)
const COLOR_DIM := Color(0.75, 0.75, 0.8)
const COLOR_SHADE := Color(0, 0, 0, 0.45)
const COLOR_HP := Color(0.98, 0.82, 0.25)
const COLOR_HP_LOW := Color(0.92, 0.3, 0.18)
const COLOR_TRAIL := Color(0.85, 0.12, 0.12)
const COLOR_GOLD := Color(1, 0.85, 0.3)
const HISTORY_ROWS := 14
const BAR_Y := 26.0
const BAR_H := 26.0
const SLANT := 14.0         # скос внутреннего края полоски, px
const MEDAL_X := 58.0       # центр медальона с портретом от края экрана
const MEDAL_R := 34.0
const TIMER_R := 44.0
## Лица на портретах экрана выбора (select_1.png): область для медальона, px кадра.
const FACES := {"ilya": Rect2(480, 25, 240, 240), "dracula": Rect2(650, 30, 220, 220)}
const TRAIL_DELAY := 30     # «красный след» урона начинает убывать через столько кадров
const TRAIL_SPEED := 6.0    # и тает со скоростью столько очков здоровья за кадр

var show_inputs := false
var paused := false          # открыта пауза — своя подсказка внизу не нужна
## Аркада: подпись «бой N из 7» и своя подсказка после матча (пусто — обычный бой).
var arcade_label := ""
## Название арены — показывается во вступлении первого раунда.
var arena_label := ""
var match_hint := ""
var _font: Font = load("res://fonts/RussoOne-Regular.ttf")
var _title_font: Font = load("res://fonts/RuslanDisplay-Regular.ttf")
var _sprites: FighterSprites
var _sim: Sim
var _reader: InputReader
var _ai: AiController
## «След» урона — только для красоты, в симуляции не участвует.
var _trail := [Fighter.MAX_HP * 1.0, Fighter.MAX_HP * 1.0]
var _trail_wait := [0, 0]
var _last_hp := [Fighter.MAX_HP, Fighter.MAX_HP]


func _ready() -> void:
	pass


func setup(sprites: FighterSprites) -> void:
	_sprites = sprites


func show_state(sim: Sim, reader: InputReader, ai: AiController) -> void:
	_sim = sim
	_reader = reader
	_ai = ai
	_update_trails()
	queue_redraw()


func _update_trails() -> void:
	for p in Sim.PLAYERS:
		var hp := _sim.fighters[p].hp
		if hp > _last_hp[p] or hp >= _trail[p] or hp == _sim.fighters[p].max_hp:
			_trail[p] = float(hp)  # новый раунд или лечение
		elif hp < _last_hp[p]:
			_trail_wait[p] = TRAIL_DELAY
		elif _trail_wait[p] > 0:
			_trail_wait[p] -= 1
		else:
			_trail[p] = maxf(_trail[p] - TRAIL_SPEED, hp)
		_last_hp[p] = hp


func _draw() -> void:
	if _sim == null:
		return
	for p in Sim.PLAYERS:
		_draw_bar(p)
		if show_inputs:
			_draw_history(p, Vector2(size.x - 40.0 if p == 1 else 40.0, 150), p == 1)
		_draw_combo(p, p == 1)
		_draw_parry(p, p == 1)
		_draw_meter(p)
	_draw_timer()
	if arena_label != "" and _sim.phase == Sim.Phase.INTRO and _sim.round_num == 1:
		_text(Vector2(size.x / 2.0, 150), arena_label, 22, Color(1, 1, 1, 0.85), false, true, 2, _title_font)
	if arcade_label != "" and _sim.phase != Sim.Phase.MATCH_END:
		_text(Vector2(size.x / 2.0, 104), arcade_label, 15, Color(1, 0.85, 0.3, 0.8), false, true, 1)
	_draw_super_name()
	_draw_announcement()
	_draw_finish_command()
	_draw_win_quote()
	_draw_footer()
	_draw_pad_notice()


# --- Полоски здоровья ----------------------------------------------------

## Полоска игрока (скошенный прямоугольник): от медальона с портретом к таймеру.
## Убывает к внешнему краю, как в Street Fighter.
func _bar_rect(p: int) -> Rect2:
	var x0 := MEDAL_X + MEDAL_R + 6.0
	var w := size.x / 2.0 - TIMER_R - 14.0 - x0
	return Rect2(x0 if p == 0 else size.x / 2.0 + TIMER_R + 14.0, BAR_Y, w, BAR_H)


## Четырёхугольник со скосом: у игрока 1 скошен правый (внутренний) край, у игрока 2 — левый.
func _slant(r: Rect2, right: bool, k := 1.0) -> PackedVector2Array:
	var s := SLANT * k
	if right:
		return PackedVector2Array([r.position + Vector2(s, 0), Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end - Vector2(s, 0),
		Vector2(r.position.x, r.end.y)])


## Заливка градиентом сверху вниз.
func _fill(pts: PackedVector2Array, top: Color, bottom: Color) -> void:
	draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


## Часть полоски шириной w от внешнего края (с тем же скосом у внутреннего).
func _bar_part(r: Rect2, w: float, right: bool) -> Rect2:
	return Rect2(r.position.x if not right else r.end.x - w, r.position.y, w, r.size.y)


func _draw_bar(p: int) -> void:
	var f := _sim.fighters[p]
	var r := _bar_rect(p)
	var right := p == 1
	# Рамка: тёмная подложка, золотой кант.
	var frame := _slant(r.grow(4), right, 1.4)
	draw_colored_polygon(frame, Color(0.05, 0.03, 0.06, 0.92))
	_fill(_slant(r, right), Color(0.16, 0.12, 0.16), Color(0.08, 0.06, 0.09))
	# След урона: первые кадры — белая вспышка, потом красный.
	var trail_w: float = r.size.x * _trail[p] / f.max_hp
	if trail_w > 1.0:
		var fresh: bool = _trail_wait[p] > TRAIL_DELAY - 6
		var tc := Color(1, 0.95, 0.85) if fresh else COLOR_TRAIL
		_fill(_slant(_bar_part(r, trail_w, right), right), tc, tc.darkened(0.35))
	# Здоровье: золото, на исходе — красное и пульсирует.
	var hp_w := r.size.x * f.hp / f.max_hp
	if hp_w > 1.0:
		var low := f.hp < f.max_hp / 4
		var top := COLOR_HP.lightened(0.25)
		var bottom := COLOR_HP.darkened(0.25)
		if low:
			var pulse := 0.5 + 0.5 * sin(_sim.tick * 0.25)
			top = COLOR_HP_LOW.lightened(0.2 + 0.25 * pulse)
			bottom = COLOR_HP_LOW.darkened(0.3)
		var hr := _bar_part(r, hp_w, right)
		_fill(_slant(hr, right), top, bottom)
		# Блик по верху полоски.
		var gloss := Rect2(hr.position + Vector2(0, 2), Vector2(hr.size.x, 5))
		draw_colored_polygon(_slant(gloss, right, 0.25), Color(1, 1, 1, 0.28))
	_outline(frame, COLOR_GOLD.darkened(0.15), 2.0)
	_draw_medal(p)
	# Имя под полоской у медальона; победы в раундах — у таймера.
	var name_x := r.position.x + 4 if not right else r.end.x - 4
	_text(Vector2(name_x, r.end.y + 27), f.data.name, 21, COLOR_TEXT, right, false, 2, _title_font)
	var tag := ""
	var cpu := p == 1 and _ai.level != AiController.Level.OFF
	if cpu:
		tag = Loc.t("ИИ · ") + Loc.t(_ai.level_name())
	elif Settings.hints:
		tag = Loc.t("Игрок %d · %s") % [p + 1, _reader.device_label(p)]
	if tag != "":
		_text(Vector2(name_x, r.end.y + 46), tag, 13, COLOR_GOLD if cpu else COLOR_DIM, right)
	for i in _sim.wins_needed:
		var cx := r.end.x - 22 - i * 26 if not right else r.position.x + 22 + i * 26
		_draw_gem(Vector2(cx, r.end.y + 17), i < _sim.wins[p])


## Медальон с портретом бойца у внешнего края полоски.
func _draw_medal(p: int) -> void:
	var f := _sim.fighters[p]
	var c := Vector2(MEDAL_X if p == 0 else size.x - MEDAL_X, BAR_Y + BAR_H / 2.0 + 4)
	draw_circle(c, MEDAL_R + 5, Color(0.05, 0.03, 0.06))
	draw_circle(c, MEDAL_R, f.color().darkened(0.55))
	_draw_face_circle(f.id, c, MEDAL_R, p == 1, Color.WHITE)
	# Кант медальона; когда шкала силы полна — светится.
	var full := f.meter >= Fighter.METER_MAX
	var ring := COLOR_GOLD if not full else COLOR_GOLD.lerp(Color.WHITE, 0.5 + 0.5 * sin(_sim.tick * 0.3))
	draw_arc(c, MEDAL_R + 2, 0, TAU, 48, ring, 3.0, true)
	draw_arc(c, MEDAL_R + 6, 0, TAU, 48, Color(0.05, 0.03, 0.06), 2.0, true)


## Лицо бойца в круге (веер треугольников с UV); mirror — смотрит влево.
func _draw_face_circle(id: String, c: Vector2, r: float, mirror: bool, tint: Color) -> void:
	var face := _face(id)
	if face.is_empty():
		return
	var tex: Texture2D = face[0]
	var src: Rect2 = face[1]
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var flip := -1.0 if mirror else 1.0
	for i in 40:
		var a := TAU * i / 40.0
		var v := Vector2(cos(a), sin(a))
		pts.append(c + v * r)
		var uv := src.position + src.size * (Vector2(0.5 + 0.5 * v.x * flip, 0.5 + 0.5 * v.y))
		uvs.append(uv / tex.get_size())
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(tint)
	draw_polygon(pts, cols, uvs, tex)


## Лицо бойца с портрета экрана выбора: [текстура, область] или пусто.
func _face(id: String) -> Array:
	if _sprites == null:
		return []
	var a := _sprites.anim(id, "select")
	if a.is_empty() or not FACES.has(id):
		return []
	return [a.tex[0], FACES[id]]


## Победа в раунде — золотой ромб, нет победы — пустой.
func _draw_gem(c: Vector2, won: bool) -> void:
	var r := 9.0
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, Color(0.05, 0.03, 0.06))
	var inner := PackedVector2Array([c + Vector2(0, -r + 3), c + Vector2(r - 3, 0), c + Vector2(0, r - 3), c + Vector2(-r + 3, 0)])
	if won:
		draw_polygon(inner, PackedColorArray([COLOR_GOLD.lightened(0.4), COLOR_GOLD, COLOR_GOLD.darkened(0.3), COLOR_GOLD]))
	_outline(pts, COLOR_GOLD.darkened(0.15), 1.5)


func _outline(pts: PackedVector2Array, color: Color, width: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, color, width, true)


## Шкала силы: в нижнем углу, три скошенные секции; полные светятся, полная шкала — переливается.
func _draw_meter(p: int) -> void:
	var f := _sim.fighters[p]
	var right := p == 1
	var w := 260.0
	var y := size.y - 34.0
	var x0 := 92.0 if not right else size.x - 92.0 - w
	var full := f.meter / Fighter.METER_SECTION
	# Число секций — в ромбе у края экрана.
	var c := Vector2(54 if not right else size.x - 54, y + 7)
	var d := PackedVector2Array([c + Vector2(0, -24), c + Vector2(24, 0), c + Vector2(0, 24), c + Vector2(-24, 0)])
	draw_colored_polygon(d, Color(0.05, 0.03, 0.06, 0.92))
	_outline(d, COLOR_GOLD.darkened(0.15), 2.0)
	var num_col := Color(0.55, 0.8, 1.0) if full < 3 else COLOR_GOLD.lerp(Color.WHITE, 0.5 + 0.5 * sin(_sim.tick * 0.3))
	_text(c + Vector2(0, 10), str(full), 26, num_col, false, true, 2)
	var seg_w := w / 3.0
	for i in 3:
		var fill := clampf(float(f.meter - i * Fighter.METER_SECTION) / Fighter.METER_SECTION, 0.0, 1.0)
		var idx := i if not right else 2 - i
		var seg := Rect2(x0 + idx * seg_w, y, seg_w - 6, 14)
		var shape := _slant(seg.grow(2), right, 0.8)
		draw_colored_polygon(shape, Color(0.05, 0.03, 0.06, 0.92))
		_fill(_slant(seg, right, 0.6), Color(0.13, 0.13, 0.22), Color(0.07, 0.07, 0.12))
		if fill > 0.0:
			var top := Color(0.5, 0.78, 1.0) if fill >= 1.0 else Color(0.3, 0.45, 0.75)
			if full == 3:
				top = COLOR_GOLD.lerp(Color.WHITE, 0.4 + 0.4 * sin(_sim.tick * 0.3 + i))
			var part := Rect2(seg.position.x if not right else seg.end.x - seg.size.x * fill, seg.position.y,
				seg.size.x * fill, seg.size.y)
			_fill(_slant(part, right, 0.6), top, top.darkened(0.4))
		_outline(shape, COLOR_GOLD.darkened(0.35), 1.0)
	var label := "СУПЕР ГОТОВ!" if full == 3 else "СИЛА"
	_text(Vector2(x0 if not right else x0 + w, y - 6), label, 13, COLOR_GOLD if full == 3 else COLOR_DIM, right)


## Название суперприёма во время паузы и ролика.
func _draw_super_name() -> void:
	for f in _sim.fighters:
		var flash := f.state == Fighter.State.ATTACK and f.move_frame == 1 and _sim.hitstop > 0
		if f.is_super() and (flash or f.state == Fighter.State.THROWING):
			var y := size.y * 0.38
			_banner(y, 70)
			_text(Vector2(size.x / 2.0, y), Loc.t(f.move_data().name) + "!", 54, f.color().lightened(0.4), false, true, 3, _title_font)


## Таймер — восьмиугольник с двойным золотым кантом.
func _draw_timer() -> void:
	var c := Vector2(size.x / 2.0, BAR_Y + BAR_H / 2.0 + 6)
	var pts := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		pts.append(c + Vector2(cos(a), sin(a)) * TIMER_R)
		inner.append(c + Vector2(cos(a), sin(a)) * (TIMER_R - 6))
	draw_colored_polygon(pts, Color(0.05, 0.03, 0.06, 0.95))
	draw_polygon(inner, PackedColorArray([Color(0.22, 0.12, 0.14), Color(0.22, 0.12, 0.14), Color(0.1, 0.05, 0.08),
		Color(0.1, 0.05, 0.08), Color(0.1, 0.05, 0.08), Color(0.1, 0.05, 0.08), Color(0.22, 0.12, 0.14), Color(0.22, 0.12, 0.14)]))
	_outline(pts, COLOR_GOLD.darkened(0.1), 2.5)
	_outline(inner, COLOR_GOLD.darkened(0.5), 1.0)
	if _sim.training:
		_text(c + Vector2(0, 16), "∞", 44, COLOR_TEXT, false, true, 2)
		_text(c + Vector2(0, TIMER_R + 26), "ТРЕНИРОВКА · F6 или R1 + тачпад — выйти", 14, COLOR_GOLD, false, true, 2)
		return
	var seconds := ceili(_sim.timer / 60.0)
	var col := COLOR_HP_LOW if seconds <= 10 and _sim.phase == Sim.Phase.FIGHT else COLOR_TEXT
	_text(c + Vector2(0, 15), "%02d" % seconds, 40, col, false, true, 2)


## Полоса-подложка под надписью, края растворяются.
func _banner(y: float, h: float) -> void:
	var clear := Color(0, 0, 0, 0)
	var dark := Color(0, 0, 0, 0.5)
	var top := y - h * 0.72
	for half in 2:
		var x0 := 0.0 if half == 0 else size.x / 2.0
		var c0 := clear if half == 0 else dark
		var c1 := dark if half == 0 else clear
		draw_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x0 + size.x / 2.0, top),
			Vector2(x0 + size.x / 2.0, top + h), Vector2(x0, top + h)]), PackedColorArray([c0, c1, c1, c0]))
	draw_line(Vector2(size.x * 0.2, top), Vector2(size.x * 0.8, top), Color(1, 0.85, 0.3, 0.5), 1.5)
	draw_line(Vector2(size.x * 0.2, top + h), Vector2(size.x * 0.8, top + h), Color(1, 0.85, 0.3, 0.5), 1.5)


# --- Объявления ----------------------------------------------------------

func _draw_announcement() -> void:
	if paused:
		return
	var big := ""
	var small := ""
	var color := COLOR_GOLD
	match _sim.phase:
		Sim.Phase.INTRO:
			if _sim.last_bout:
				big = "ПОСЛЕДНИЙ БОЙ"
			elif _sim.wins[0] == 1 and _sim.wins[1] == 1:
				big = "ФИНАЛЬНЫЙ РАУНД"
			else:
				big = Loc.t("РАУНД %d") % _sim.round_num
		Sim.Phase.FIGHT:
			if _sim.phase_frame < 45:
				big = "БОЙ!"
				color = Color(1, 0.4, 0.25)
		Sim.Phase.ROUND_END:
			match _sim.end_reason:
				Sim.EndReason.KO:
					big = "НОКАУТ!"
					color = Color(1, 0.3, 0.2)
				Sim.EndReason.DOUBLE_KO:
					big = "ДВОЙНОЙ НОКАУТ!"
					color = Color(1, 0.3, 0.2)
				Sim.EndReason.TIME:
					big = "ВРЕМЯ!"
			if _sim.phase_frame > 60:
				small = "НИЧЬЯ" if _sim.round_winner == 2 \
					else Loc.t("Раунд за: %s") % Loc.t(_sim.fighters[_sim.round_winner].data.name)
		Sim.Phase.FINISH:
			big = "ДОБИВАЙ!"
			color = Color(1, 0.3, 0.2)
			small = Loc.t("Вперёд, назад + СР · %d") % ceili((Sim.FINISH_TICKS - _sim.phase_frame) / 60.0)
		Sim.Phase.FINISHER:
			if _sim.phase_frame > 20:
				big = "ДОБИВАНИЕ!"
				color = COLOR_GOLD
		Sim.Phase.MATCH_END:
			var w := _sim.match_winner()
			big = "НИЧЬЯ" if w == 2 else Loc.t("%s ПОБЕЖДАЕТ!") % Loc.t(_sim.fighters[w].data.name)
			if w != 2:
				color = _sim.fighters[w].color().lightened(0.35)
			if _sim.phase_frame >= Sim.REMATCH_DELAY:
				small = match_hint if match_hint != "" else "Удар — реванш   ·   Enter или Options — выбор бойца"
	if big == "":
		return
	var y := size.y * 0.3
	_banner(y + (12 if small != "" else 0), 92 + (40 if small != "" else 0))
	_text(Vector2(size.x / 2.0, y), big, 64, color, false, true, 3, _title_font)
	if small != "":
		_text(Vector2(size.x / 2.0, y + 46), small, 22, COLOR_TEXT, false, true, 2)


## Добивание: команда по шагам (введённые — золотые) и дистанция.
func _draw_finish_command() -> void:
	if paused or _sim.phase != Sim.Phase.FINISH:
		return
	var steps := ["→", "←", Loc.t("СР")]
	var cx := size.x / 2.0
	var y := size.y * 0.3 + 100
	for i in 3:
		var done := i < _sim.finish_step
		var box := Rect2(cx - 150 + i * 105, y - 34, 90, 50)
		draw_rect(box, Color(0.04, 0.02, 0.05, 0.85))
		draw_rect(box, COLOR_GOLD if done else Color(0.6, 0.6, 0.65), false, 2.0)
		_text(box.get_center() + Vector2(0, 12), steps[i], 30, COLOR_GOLD if done else COLOR_TEXT, false, true, 2)
	if not _sim.finish_in_range():
		_text(Vector2(cx, y + 50), "Подойди ближе!", 22, Color(1, 0.45, 0.35), false, true, 2)


## Конец матча: портрет победителя (поза победы с экрана выбора) выезжает со своей стороны,
## внизу — плашка с его репликой.
func _draw_win_quote() -> void:
	if paused or _sim.phase != Sim.Phase.MATCH_END or _sim.phase_frame < 20:
		return
	var w := _sim.match_winner()
	if w < 0 or w > 1:
		return
	var winner := _sim.fighters[w]
	var right := w == 1
	var t := smoothstep(20.0, 44.0, float(_sim.phase_frame))
	# Затемнение снизу, чтобы портрет и плашка читались.
	var clear := Color(0, 0, 0, 0)
	var dark := Color(0, 0, 0, 0.55 * t)
	draw_polygon(PackedVector2Array([Vector2(0, size.y * 0.45), Vector2(size.x, size.y * 0.45), size, Vector2(0, size.y)]),
		PackedColorArray([clear, clear, dark, dark]))
	var x := size.x * (0.82 if right else 0.18) + (1.0 - t) * 420.0 * (1.0 if right else -1.0)
	_draw_portrait(winner.id, Vector2(x, size.y), right)
	var q := Quotes.win(winner.id, _sim.fighters[1 - w].id, _sim.tick - _sim.phase_frame)
	if q == "" or _sim.phase_frame < 44:
		return
	var box := Rect2(size.x * (0.06 if right else 0.36), size.y - 150, size.x * 0.58, 104)
	draw_rect(box, Color(0.04, 0.02, 0.05, 0.88))
	draw_rect(box, winner.color().lightened(0.3), false, 2.0)
	_text(box.position + Vector2(18, 28), winner.data.name, 17, winner.color().lightened(0.35), false, false, 1, _title_font)
	var shown := q.left(mini(q.length(), int((_sim.phase_frame - 44) * 1.6)))
	draw_multiline_string(_font, box.position + Vector2(18, 58), "«%s»" % shown if Loc.lang == "ru" else "“%s”" % shown,
		HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 36, 20, 2, COLOR_TEXT)
	# Ответ проигравшего (только пары-соперники): над плашкой победителя, с его стороны,
	# с маленьким затемнённым портретом. Появляется, когда победитель договорил.
	var loser := _sim.fighters[1 - w]
	var a := Quotes.lose(loser.id, winner.id, _sim.tick - _sim.phase_frame)
	var start := 44 + int(q.length() / 1.6) + 40
	if a == "" or _sim.phase_frame < start:
		return
	var k := smoothstep(float(start), float(start + 14), float(_sim.phase_frame))
	var lb := Rect2(box.position.x + (0.0 if right else box.size.x * 0.22), box.position.y - 92, box.size.x * 0.78, 80)
	# Портрет — у внешнего края плашки, со стороны проигравшего.
	var face_c := Vector2(lb.position.x + 44 if right else lb.end.x - 44, lb.get_center().y)
	var text_x := lb.position.x + (96.0 if right else 14.0)
	draw_rect(lb, Color(0.03, 0.02, 0.04, 0.85 * k))
	draw_rect(lb, Color(loser.color().darkened(0.2), 0.8 * k), false, 2.0)
	draw_circle(face_c, 34, Color(0.05, 0.03, 0.06, k))
	_draw_face_circle(loser.id, face_c, 31, not right, Color(0.5, 0.5, 0.56, k))
	draw_arc(face_c, 33, 0, TAU, 40, Color(loser.color().darkened(0.2), k), 2.0, true)
	_text(Vector2(text_x, lb.position.y + 24), loser.data.name, 15, Color(loser.color().lightened(0.2), 0.85 * k), false, false, 1, _title_font)
	var ans := a.left(mini(a.length(), int((_sim.phase_frame - start) * 1.6)))
	draw_multiline_string(_font, Vector2(text_x, lb.position.y + 50), "«%s»" % ans if Loc.lang == "ru" else "“%s”" % ans,
		HORIZONTAL_ALIGNMENT_LEFT, lb.size.x - 110, 17, 2, Color(COLOR_TEXT, 0.8 * k))


## Портрет бойца по пояс (последний кадр радости, иначе портрет выбора); справа — зеркально, к центру.
func _draw_portrait(id: String, waist: Vector2, mirror: bool) -> void:
	if _sprites == null:
		return
	var a := _sprites.anim(id, "select_win")
	if a.is_empty():
		a = _sprites.anim(id, "select")
	if a.is_empty():
		return
	var n: int = a.tex.size()
	var k := 0.42
	draw_set_transform(waist, 0, Vector2(-k if mirror else k, k))
	draw_texture(a.tex[n - 1], -a.pivot[n - 1])
	draw_set_transform(Vector2.ZERO)


## Счётчик комбо — на стороне атакующего, пока соперник оглушён.
func _draw_combo(p: int, right: bool) -> void:
	var d := _sim.fighters[1 - p]
	if d.combo < 2 or not d.is_stunned():
		return
	var x := size.x * (0.75 if right else 0.25)
	_text(Vector2(x, 210), str(d.combo), 64, COLOR_GOLD, false, true, 3)
	_text(Vector2(x, 240), Loc.t(_plural_hits(d.combo)) + "!", 26, COLOR_GOLD.lightened(0.3), false, true, 2, _title_font)
	_text(Vector2(x, 266), Loc.t("урон %d") % d.combo_damage, 18, COLOR_TEXT, false, true, 2)


## «ПАРИРОВАНИЕ!» на стороне парировавшего.
func _draw_parry(p: int, right: bool) -> void:
	var base := p * 4
	var age := _sim.tick - _sim.sparks[base]
	if _sim.sparks[base + 3] != 5 or age < 0 or age > 50:
		return
	var x := size.x * (0.75 if right else 0.25)
	_text(Vector2(x, 300), "ПАРИРОВАНИЕ!", 32, Color(0.55, 0.85, 1.0), false, true, 2, _title_font)


static func _plural_hits(n: int) -> String:
	if n % 10 == 1 and n % 100 != 11:
		return "УДАР"
	if n % 10 >= 2 and n % 10 <= 4 and (n % 100 < 12 or n % 100 > 14):
		return "УДАРА"
	return "УДАРОВ"


## Геймпад отключился или подключился — крупная плашка на 4 секунды.
func _draw_pad_notice() -> void:
	if Time.get_ticks_msec() - _reader.pad_notice_ms > 4000:
		return
	var bad := _reader.pad_notice.begins_with("ГЕЙМПАД") or _reader.pad_notice.begins_with("GAMEPAD")
	draw_rect(Rect2(size.x / 2.0 - 380, 250, 760, 44), Color(0.5, 0.05, 0.05, 0.85) if bad else COLOR_SHADE)
	_text(Vector2(size.x / 2.0, 280), _reader.pad_notice, 20, COLOR_TEXT, false, true)


func _draw_footer() -> void:
	# По умолчанию экран чистый: подсказки — в паузе («Приёмы»), включить здесь — в настройках.
	if not Settings.hints:
		if not paused and _sim.phase == Sim.Phase.INTRO:
			_text(Vector2(size.x / 2.0, size.y - 14), "Esc / Options — пауза, приёмы и настройки", 15, COLOR_DIM, false, true)
		return
	var version: String = ProjectSettings.get_setting("application/config/version")
	var stage: String = ProjectSettings.get_setting("application/config/description")
	var hint := "R1/L — блок · F3/Options — ИИ · F4/F5/тачпад — бойцы · F6/R1+тачпад — тренировка · F7 — спрайты · F1 — ввод · F2 — хитбоксы · R/Create — заново · F11 · Esc"
	draw_rect(Rect2(0, size.y - 92, size.x, 62), Color(0, 0, 0, 0.35))  # подложка под подсказки
	draw_rect(Rect2(0, size.y - 30, size.x, 30), COLOR_SHADE)
	_text(Vector2(size.x / 2.0, size.y - 10), hint, 13, COLOR_TEXT, false, true)
	_text(Vector2(12, size.y - 98), Loc.t("сборка %s · %s · %d FPS") % [version, stage, Engine.get_frames_per_second()], 12, COLOR_DIM)
	_text(Vector2(size.x - 12, size.y - 74), _strings_hint(_sim.fighters[0]), 13, COLOR_GOLD, true)
	_text(Vector2(size.x - 12, size.y - 56), "Спецприёмы: назад, вперёд + рука · вниз, вниз + нога · вперёд, вперёд + рука · назад, назад + рука — захват", 13, COLOR_GOLD, true)
	_text(Vector2(size.x - 12, size.y - 38), "Назад + ЛН — подсечка · назад + СН — с разворота · вниз + СР — апперкот · ЛР вплотную — бросок · тап «вперёд» в момент удара — парирование", 13, COLOR_GOLD, true)


## Строки ударов первого игрока: «ЛР, ЛР, СР · ЛН, СН…».
static func _strings_hint(f: Fighter) -> String:
	var parts: Array[String] = []
	for st in f.data.get("strings", []):
		var keys: Array[String] = []
		for key in st.moves:
			var label: String = Fighter.MOVE_LABELS[Fighter.BUTTON_OF[(key as String).right(2)]]
			keys.append(Loc.t(label) + (Loc.t(" (низ)") if (key as String).begins_with("cr_") else ""))
		parts.append(", ".join(keys))
	return Loc.t("Строки: %s — попавший удар (и в блок) отменяется в спецприём") % " · ".join(parts)


# --- История ввода (F1) --------------------------------------------------

## Колонка истории ввода. Направления показаны относительно экрана.
func _draw_history(p: int, origin: Vector2, right: bool) -> void:
	var h: Array = _sim.history[p]
	var dir := -1.0 if right else 1.0
	var accent: Color = _sim.fighters[p].color().lightened(0.3)
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


## Текст с тёмной обводкой (outline px) и тенью. font — по умолчанию Russo One.
func _text(pos: Vector2, s: String, font_size: int, color: Color, align_right := false,
		centered := false, outline := 1, font: Font = null) -> void:
	var fnt: Font = font if font != null else _font
	s = Loc.t(s)
	var width := fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if align_right:
		pos.x -= width
	elif centered:
		pos.x -= width / 2.0
	var dark := Color(0.06, 0.02, 0.05, 0.9)
	draw_string(fnt, pos + Vector2(outline + 1, outline + 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.5))
	draw_string_outline(fnt, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline * 2 + 2, dark)
	draw_string(fnt, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
