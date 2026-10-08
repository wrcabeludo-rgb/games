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
const BAR_Y := 30.0
const BAR_H := 26.0
const BAR_GAP := 70.0       # от центра экрана до внутреннего края полоски
const BAR_MARGIN := 30.0    # от края экрана до внешнего края полоски
const TRAIL_DELAY := 30     # «красный след» урона начинает убывать через столько кадров
const TRAIL_SPEED := 6.0    # и тает со скоростью столько очков здоровья за кадр

var show_inputs := false
var _font := SystemFont.new()
var _sim: Sim
var _reader: InputReader
var _ai: AiController
## «След» урона — только для красоты, в симуляции не участвует.
var _trail := [Fighter.MAX_HP * 1.0, Fighter.MAX_HP * 1.0]
var _trail_wait := [0, 0]
var _last_hp := [Fighter.MAX_HP, Fighter.MAX_HP]


func _ready() -> void:
	_font.font_names = PackedStringArray(["Segoe UI", "Arial", "DejaVu Sans", "Noto Sans"])
	_font.font_weight = 600


func show_state(sim: Sim, reader: InputReader, ai: AiController) -> void:
	_sim = sim
	_reader = reader
	_ai = ai
	_update_trails()
	queue_redraw()


func _update_trails() -> void:
	for p in Sim.PLAYERS:
		var hp := _sim.fighters[p].hp
		if hp > _last_hp[p] or hp >= _trail[p]:
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
		_draw_meter(p)
	_draw_timer()
	_draw_super_name()
	_draw_announcement()
	_draw_footer()
	_draw_pad_notice()


# --- Полоски здоровья ----------------------------------------------------

## Полоска игрока: убывает к внешнему краю, как в Street Fighter.
func _bar_rect(p: int) -> Rect2:
	var w := size.x / 2.0 - BAR_GAP - BAR_MARGIN
	var x := BAR_MARGIN if p == 0 else size.x / 2.0 + BAR_GAP
	return Rect2(x, BAR_Y, w, BAR_H)


func _draw_bar(p: int) -> void:
	var f := _sim.fighters[p]
	var r := _bar_rect(p)
	var right := p == 1
	draw_rect(r.grow(3), Color(0, 0, 0, 0.75))
	draw_rect(r, Color(0.18, 0.16, 0.2))
	var hp_w := r.size.x * f.hp / Fighter.MAX_HP
	var trail_w: float = r.size.x * _trail[p] / Fighter.MAX_HP
	# Полоски прижаты к внешнему краю: у игрока 1 — к левому, у игрока 2 — к правому.
	var trail_rect := Rect2(r.position.x if not right else r.end.x - trail_w, r.position.y, trail_w, r.size.y)
	draw_rect(trail_rect, COLOR_TRAIL)
	var low := f.hp < Fighter.MAX_HP / 4
	var col := COLOR_HP_LOW if low else COLOR_HP
	var hp_rect := Rect2(r.position.x if not right else r.end.x - hp_w, r.position.y, hp_w, r.size.y)
	draw_rect(hp_rect, col)
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x, 6)), col.lightened(0.35))
	draw_rect(r.grow(3), COLOR_GOLD.darkened(0.3), false, 2)
	# Имя под полоской, у внешнего края; победы в раундах — у внутреннего.
	var name_x := r.position.x if not right else r.end.x
	_text(Vector2(name_x, r.end.y + 26), f.data.name, 22, f.color().lightened(0.25), right)
	var who := "Игрок %d · %s" % [p + 1, _reader.device_label(p)]
	if p == 1 and _ai.level != AiController.Level.OFF:
		who = "ИИ · %s (F3 или Options — сменить)" % _ai.level_name()
	_text(Vector2(name_x, r.end.y + 46), who, 13, COLOR_GOLD if who.begins_with("ИИ") else COLOR_DIM, right)
	for i in Sim.WINS_NEEDED:
		var cx := r.end.x - 12 - i * 26 if not right else r.position.x + 12 + i * 26
		var c := Vector2(cx, r.end.y + 18)
		var won := i < _sim.wins[p]
		draw_circle(c, 9, COLOR_GOLD if won else Color(0.15, 0.13, 0.17))
		draw_arc(c, 9, 0, TAU, 20, COLOR_GOLD.darkened(0.3), 2)


## Шкала силы: три секции под именем; полные секции светятся.
func _draw_meter(p: int) -> void:
	var f := _sim.fighters[p]
	var r := _bar_rect(p)
	var right := p == 1
	var w := 300.0
	var box := Rect2(r.position.x if not right else r.end.x - w, r.end.y + 58, w, 12)
	draw_rect(box.grow(2), Color(0, 0, 0, 0.75))
	var full := f.meter / Fighter.METER_SECTION
	var seg_w := w / 3.0
	for i in 3:
		var fill := clampf(float(f.meter - i * Fighter.METER_SECTION) / Fighter.METER_SECTION, 0.0, 1.0)
		var idx := i if not right else 2 - i
		var seg := Rect2(box.position.x + idx * seg_w, box.position.y, seg_w - 3, box.size.y)
		draw_rect(seg, Color(0.12, 0.12, 0.2))
		var fw := seg.size.x * fill
		var col := Color(0.35, 0.65, 1.0) if fill >= 1.0 else Color(0.25, 0.4, 0.7)
		if full == 3 and _sim.tick % 20 < 10:
			col = Color(1, 0.85, 0.3)
		draw_rect(Rect2(seg.position.x if not right else seg.end.x - fw, seg.position.y, fw, seg.size.y), col)
	var label := "СИЛА %d" % full
	if full >= 1:
		label += " · спецприём + блок — усиленный"
	if full == 3:
		label += " · СУПЕР: блок + СР + СН"
	_text(Vector2(box.position.x if not right else box.end.x, box.end.y + 16), label, 12, COLOR_GOLD if full == 3 else COLOR_DIM, right)


## Название суперприёма во время паузы и ролика.
func _draw_super_name() -> void:
	for f in _sim.fighters:
		var flash := f.state == Fighter.State.ATTACK and f.move_frame == 1 and _sim.hitstop > 0
		if f.is_super() and (flash or f.state == Fighter.State.THROWING):
			var y := size.y * 0.38
			draw_rect(Rect2(0, y - 52, size.x, 70), Color(0, 0, 0, 0.45))
			_text(Vector2(size.x / 2.0, y), f.move_data().name + "!", 54, f.color().lightened(0.4), false, true, 3)


func _draw_timer() -> void:
	var c := Vector2(size.x / 2.0, BAR_Y + BAR_H / 2.0)
	var box := Rect2(c - Vector2(46, 34), Vector2(92, 68))
	draw_rect(box, Color(0, 0, 0, 0.75))
	draw_rect(box, COLOR_GOLD.darkened(0.3), false, 2)
	var seconds := ceili(_sim.timer / 60.0)
	var col := COLOR_HP_LOW if seconds <= 10 and _sim.phase == Sim.Phase.FIGHT else COLOR_TEXT
	_text(c + Vector2(0, 17), "%02d" % seconds, 46, col, false, true)


# --- Объявления ----------------------------------------------------------

func _draw_announcement() -> void:
	var big := ""
	var small := ""
	var color := COLOR_GOLD
	match _sim.phase:
		Sim.Phase.INTRO:
			big = "ФИНАЛЬНЫЙ РАУНД" if _sim.wins[0] == 1 and _sim.wins[1] == 1 else "РАУНД %d" % _sim.round_num
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
					else "Раунд за: %s" % _sim.fighters[_sim.round_winner].data.name
		Sim.Phase.MATCH_END:
			var w := _sim.match_winner()
			big = "НИЧЬЯ" if w == 2 else "%s ПОБЕЖДАЕТ!" % _sim.fighters[w].data.name
			if w != 2:
				color = _sim.fighters[w].color().lightened(0.35)
			if _sim.phase_frame >= Sim.REMATCH_DELAY:
				small = "Нажми любую кнопку удара — реванш"
	if big == "":
		return
	var y := size.y * 0.3
	draw_rect(Rect2(0, y - 62, size.x, 84 + (40 if small != "" else 0)), Color(0, 0, 0, 0.35))
	_text(Vector2(size.x / 2.0, y), big, 60, color, false, true, 3)
	if small != "":
		_text(Vector2(size.x / 2.0, y + 46), small, 24, COLOR_TEXT, false, true)


## Счётчик комбо — на стороне атакующего, пока соперник оглушён.
func _draw_combo(p: int, right: bool) -> void:
	var d := _sim.fighters[1 - p]
	if d.combo < 2 or not d.is_stunned():
		return
	var x := size.x * (0.75 if right else 0.25)
	_text(Vector2(x, 200), "%d %s!" % [d.combo, _plural_hits(d.combo)], 40, COLOR_GOLD, false, true, 2)
	_text(Vector2(x, 232), "урон %d" % d.combo_damage, 22, COLOR_TEXT, false, true, 2)


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
	var bad := _reader.pad_notice.begins_with("ГЕЙМПАД")
	draw_rect(Rect2(size.x / 2.0 - 380, 250, 760, 44), Color(0.5, 0.05, 0.05, 0.85) if bad else COLOR_SHADE)
	_text(Vector2(size.x / 2.0, 280), _reader.pad_notice, 20, COLOR_TEXT, false, true)


func _draw_footer() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	var stage: String = ProjectSettings.get_setting("application/config/description")
	var hint := "R1/L — блок · F3/Options — ИИ · F4/F5 или тачпад — бойцы · F1 — ввод · F2 — хитбоксы · R/Create — новый матч · F11 · Esc"
	draw_rect(Rect2(0, size.y - 30, size.x, 30), COLOR_SHADE)
	_text(Vector2(size.x / 2.0, size.y - 10), hint, 13, COLOR_TEXT, false, true)
	_text(Vector2(12, size.y - 38), "сборка %s · %s · %d FPS" % [version, stage, Engine.get_frames_per_second()], 12, COLOR_DIM)
	_text(Vector2(size.x - 12, size.y - 74), _strings_hint(_sim.fighters[0]), 13, COLOR_GOLD, true)
	_text(Vector2(size.x - 12, size.y - 56), "Спецприёмы: назад, вперёд + рука · вниз, вниз + нога · вперёд, вперёд + рука · назад, назад + рука — захват", 13, COLOR_GOLD, true)
	_text(Vector2(size.x - 12, size.y - 38), "Назад + ЛН — подсечка · назад + СН — с разворота · вниз + СР — апперкот · ЛР вплотную — бросок (ЛР в ответ — вырваться)", 13, COLOR_GOLD, true)


## Строки ударов первого игрока: «ЛР, ЛР, СР · ЛН, СН…».
static func _strings_hint(f: Fighter) -> String:
	var parts: Array[String] = []
	for st in f.data.get("strings", []):
		var keys: Array[String] = []
		for key in st.moves:
			var label: String = Fighter.MOVE_LABELS[Fighter.BUTTON_OF[(key as String).right(2)]]
			keys.append(label + (" (низ)" if (key as String).begins_with("cr_") else ""))
		parts.append(", ".join(keys))
	return "Строки: %s — попавший удар (и в блок) отменяется в спецприём" % " · ".join(parts)


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


func _text(pos: Vector2, s: String, font_size: int, color: Color, align_right := false,
		centered := false, shadow := 1) -> void:
	var width := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if align_right:
		pos.x -= width
	elif centered:
		pos.x -= width / 2.0
	draw_string(_font, pos + Vector2(shadow, shadow), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.7))
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
