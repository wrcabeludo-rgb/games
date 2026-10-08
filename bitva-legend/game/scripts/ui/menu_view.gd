class_name MenuView
extends Control
## Стартовый экран и выбор бойцов. Арт — game/art/menu/ (title.png) и листы бойцов
## select (портрет) и select_win (радуется после выбора), см. docs/ART_FIGHTERS.md.
## Пока арта нет — рисуются заглушки: градиент, луна, стойка бойца.

signal fight_requested(chars: PackedStringArray)
signal sound(name: String)        # звук интерфейса: ui_move, ui_confirm, ui_back
signal voice(name: String)        # фраза диктора

enum Screen { TITLE, SELECT }

## Сетка выбора 4×2: пустая строка — закрытое место (боец ещё не готов).
const ROSTER := ["ilya", "dracula", "", "", "", "", "", ""]
const COLS := 4
const CELL := Vector2(104, 104)
const CELL_GAP := 12.0
const GRID_Y := 396.0
const READY_TICKS := 100        # после выбора обоих — столько тиков радуются, потом бой
const WIN_TICKS := 48           # анимация «радуется» проигрывается за столько тиков и замирает
const PORTRAIT_SCALE := 0.38    # портреты по пояс (кадр 900 px) — около 360 px на экране
const COLOR_GOLD := Color(1, 0.85, 0.3)
const COLOR_TEXT := Color(0.95, 0.95, 0.97)
const COLOR_DIM := Color(0.7, 0.72, 0.8)
const COLOR_P := [Color(0.35, 0.65, 1.0), Color(1.0, 0.35, 0.3)]
const CONFIRM := InputBits.LP | InputBits.LK | InputBits.START
const BACK := InputBits.HK

var screen := Screen.TITLE
var tick := 0
## Курсоры игроков (индекс в ROSTER), выбран ли боец и с какого тика.
var cursor := PackedInt32Array([0, 1])
var picked := [false, false]
var picked_at := PackedInt32Array([0, 0])
## Против ИИ первый игрок выбирает обоих бойцов по очереди.
var vs_ai := false
var ai_label := ""

var _font := SystemFont.new()
var _sprites: FighterSprites
var _title: Texture2D
var _sky: Texture2D
var _moon: Texture2D
var _prev := PackedInt32Array([0, 0])
var _ready_tick := -1


func _ready() -> void:
	_font.font_names = PackedStringArray(["Segoe UI", "Arial", "DejaVu Sans", "Noto Sans"])
	_font.font_weight = 700
	if ResourceLoader.exists("res://art/menu/title.png"):
		_title = load("res://art/menu/title.png")
	# Экран выбора — ночное небо арены (на заставке те же герои: рядом с портретами путались бы).
	if ResourceLoader.exists("res://art/arena/sky.png"):
		_sky = load("res://art/arena/sky.png")
	if ResourceLoader.exists("res://art/arena/moon.png"):
		_moon = load("res://art/arena/moon.png")


func setup(sprites: FighterSprites) -> void:
	_sprites = sprites


func open(s: Screen) -> void:
	screen = s
	tick = 0
	picked = [false, false]
	_ready_tick = -1
	visible = true
	queue_redraw()


## Один тик меню: bits — ввод обоих игроков (InputBits).
func step(bits: PackedInt32Array) -> void:
	tick += 1
	var press := PackedInt32Array([bits[0] & ~_prev[0], bits[1] & ~_prev[1]])
	_prev = bits
	if tick > 1:
		if screen == Screen.TITLE:
			if (press[0] | press[1]) & (CONFIRM | InputBits.HP):
				sound.emit("ui_confirm")
				open(Screen.SELECT)
				voice.emit("choose_your_character")
		else:
			_step_select(press)
	queue_redraw()


func _step_select(press: PackedInt32Array) -> void:
	if _ready_tick >= 0:
		if tick - _ready_tick >= READY_TICKS:
			fight_requested.emit(PackedStringArray([ROSTER[cursor[0]], ROSTER[cursor[1]]]))
		return
	for p in 2:
		var who := _chooser(p)
		if who < 0 or press[p] == 0:
			continue
		if press[p] & BACK:
			_back(p)
			continue
		if picked[who]:
			continue
		var c := cursor[who]
		if press[p] & InputBits.LEFT:
			c = c - 1 if c % COLS > 0 else c + COLS - 1
		elif press[p] & InputBits.RIGHT:
			c = c + 1 if c % COLS < COLS - 1 else c - COLS + 1
		elif press[p] & (InputBits.UP | InputBits.DOWN):
			c = (c + COLS) % ROSTER.size()
		if c != cursor[who]:
			sound.emit("ui_move")
		cursor[who] = c
		if press[p] & CONFIRM and ROSTER[c] != "":
			picked[who] = true
			picked_at[who] = tick
			sound.emit("ui_confirm")
	if picked[0] and picked[1]:
		_ready_tick = tick


## Чей курсор двигает игрок p: против ИИ первый ведёт сначала своего бойца, потом соперника.
func _chooser(p: int) -> int:
	if not vs_ai:
		return p
	if p != 0:
		return -1
	return 0 if not picked[0] else 1


func _back(p: int) -> void:
	sound.emit("ui_back")
	if vs_ai and p == 0 and picked[0]:
		picked[1 if picked[1] else 0] = false
	elif picked[p]:
		picked[p] = false
	else:
		open(Screen.TITLE)


# --- Отрисовка -------------------------------------------------------------

func _draw() -> void:
	_draw_background()
	if screen == Screen.TITLE:
		_draw_title()
	else:
		_draw_select()


func _draw_background() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if screen == Screen.TITLE and _title != null:
		# Заставка целиком (на широком мониторе — с полями), чтобы герои не уходили за край экрана.
		draw_rect(r, Color.BLACK)
		draw_texture_rect(_title, _contain(_title.get_size()), false)
		# Низ затемнён — на нём название и подсказка.
		var clear := Color(0, 0, 0, 0)
		var dark := Color(0, 0, 0, 0.8)
		var y0 := size.y * 0.6
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(size.x, y0), size, Vector2(0, size.y)]),
			PackedColorArray([clear, clear, dark, dark]))
		return
	if screen == Screen.SELECT and _sky != null:
		draw_texture_rect(_sky, _cover(_sky.get_size()), false, Color(0.55, 0.55, 0.65))
		if _moon != null:
			var ms := _moon.get_size() * (220.0 / _moon.get_height())
			draw_texture_rect(_moon, Rect2(Vector2(size.x / 2.0, 230) - ms / 2.0, ms), false, Color(0.8, 0.8, 0.85))
		return
	# Заглушка: ночное небо и луна.
	var top := Color(0.05, 0.06, 0.13)
	var bottom := Color(0.2, 0.1, 0.16)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(0, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	var moon := Vector2(size.x * 0.5, size.y * 0.3)
	for i in 6:
		draw_circle(moon, 90 + i * 22, Color(0.9, 0.9, 1.0, 0.035))
	draw_circle(moon, 80, Color(0.93, 0.92, 0.85))


## Прямоугольник, в который картинка вписывается целиком, по центру.
func _contain(img: Vector2) -> Rect2:
	var k := minf(size.x / img.x, size.y / img.y)
	var s := img * k
	return Rect2((size - s) / 2.0, s)


## Прямоугольник, которым картинка закрывает весь экран без искажений.
func _cover(img: Vector2) -> Rect2:
	var k := maxf(size.x / img.x, size.y / img.y)
	var s := img * k
	return Rect2((size - s) / 2.0, s)


func _draw_title() -> void:
	var cx := size.x / 2.0
	# Название — внизу, на затемнении: вверху заставки лица героев и луна.
	var y := size.y - 150 if _title != null else 190.0
	_text_c(Vector2(cx + 4, y + 6), "БИТВА ЛЕГЕНД", 80, Color(0.25, 0.05, 0.05, 0.9))
	_text_c(Vector2(cx, y), "БИТВА ЛЕГЕНД", 80, COLOR_GOLD)
	_text_c(Vector2(cx, y + 38), "CLASH OF LEGENDS", 22, COLOR_TEXT)
	if (tick / 30) % 2 == 0:
		_text_c(Vector2(cx, size.y - 62), "Нажмите Enter или крест", 26, COLOR_TEXT)
	_text_c(Vector2(cx, size.y - 30), "Options / F10 — настройки   ·   Esc — выход   ·   F11 — полный экран", 16, COLOR_DIM)


func _draw_select() -> void:
	var cx := size.x / 2.0
	draw_rect(Rect2(0, 0, size.x, 70), Color(0, 0, 0, 0.45))
	_text_c(Vector2(cx, 48), "ВЫБОР БОЙЦА", 36, COLOR_GOLD)
	for p in 2:
		_draw_preview(p)
	_draw_grid()
	draw_rect(Rect2(0, size.y - 64, size.x, 64), Color(0, 0, 0, 0.6))
	var hint := "←→↑↓ — выбор   ·   Enter / крест — подтвердить   ·   K / круг — назад"
	_text_c(Vector2(cx, size.y - 22), hint, 16, COLOR_DIM)
	_text_c(Vector2(cx, size.y - 46), ai_label, 16, COLOR_DIM)
	if _ready_tick >= 0 and (tick / 8) % 2 == 0:
		_text_c(Vector2(cx, 360), "В БОЙ!", 44, COLOR_GOLD)


func _cell_rect(i: int) -> Rect2:
	var w := COLS * CELL.x + (COLS - 1) * CELL_GAP
	var x0 := (size.x - w) / 2.0
	var pos := Vector2(x0 + (i % COLS) * (CELL.x + CELL_GAP), GRID_Y + (i / COLS) * (CELL.y + CELL_GAP))
	return Rect2(pos, CELL)


func _draw_grid() -> void:
	for i in ROSTER.size():
		var r := _cell_rect(i)
		var id: String = ROSTER[i]
		draw_rect(r, Color(0.08, 0.08, 0.1, 0.9))
		if id == "":
			draw_rect(r.grow(-6), Color(0.22, 0.22, 0.24))
			_text_c(r.get_center() + Vector2(0, 16), "?", 48, Color(0.4, 0.4, 0.42))
		else:
			_draw_face(id, r)
		draw_rect(r, Color(0.5, 0.45, 0.35), false, 2.0)
	# Курсоры: у первого — синяя рамка, у второго — красная (вместе — двойная).
	for who in 2:
		var r := _cell_rect(cursor[who]).grow(4.0 + who * 5.0 * float(cursor[0] == cursor[1]))
		var col: Color = COLOR_P[who]
		if not picked[who] and (tick / 10) % 3 == 0:
			col = col.lightened(0.4)
		draw_rect(r, col, false, 4.0)
		var tag := ("ИИ" if vs_ai and who == 1 else "%dP" % (who + 1))
		_text_c(r.position + Vector2(22 + who * (r.size.x - 44), -6), tag, 16, col)


## Лицо бойца в клетке сетки: верх портрета (или стойки, пока портрета нет).
func _draw_face(id: String, r: Rect2) -> void:
	var a := _sprites.anim(id, "select")
	var portrait := not a.is_empty()
	if not portrait:
		a = _sprites.anim(id, "idle")
	if a.is_empty():
		_text_c(r.get_center(), FighterData.get_data(id).name, 12, COLOR_TEXT)
		return
	var tex: Texture2D = a.tex[0]
	var ts := tex.get_size()
	# Портрет по пояс, лицом к игроку: лицо — верх по центру. Стойка (пока портрета нет) — голова справа.
	var side := minf(ts.x, ts.y * 0.5) if portrait else ts.x * 0.62
	var src := Rect2((ts.x - side) * (0.5 if portrait else 0.55), 0, side, side)
	draw_texture_rect_region(tex, r.grow(-4), src)


func _draw_preview(p: int) -> void:
	var id: String = ROSTER[cursor[p]] if ROSTER[cursor[p]] != "" else ""
	var x := size.x * (0.16 if p == 0 else 0.84)
	var feet := Vector2(x, size.y - 70)
	var name: String = FighterData.get_data(id).name if id != "" else "???"
	# Рамка портрета: у первого игрока — слева от сетки, у второго — справа; цвет игрока, выбран — золото.
	var panel := Rect2(x - 190, 84, 380, size.y - 64 - 84)
	draw_rect(panel, Color(0, 0, 0, 0.35))
	draw_rect(panel, COLOR_P[p] if not picked[p] else COLOR_GOLD, false, 3.0)
	_text_c(Vector2(x + 2, 122), name, 34, Color(0, 0, 0, 0.7))
	_text_c(Vector2(x, 120), name, 34, COLOR_P[p] if not picked[p] else COLOR_GOLD)
	if picked[p]:
		_text_c(Vector2(x, 156), "ГОТОВ!", 24, COLOR_GOLD)
	if id == "":
		return
	var face := 1.0 if p == 0 else -1.0
	var waist := Vector2(x, size.y - 64)       # портрет по пояс — низ кадра у нижнего края экрана
	var since := tick - picked_at[p]
	var win := _sprites.anim(id, "select_win")
	if picked[p] and not win.is_empty():
		var n: int = win.tex.size()
		var i := mini(since * n / WIN_TICKS, n - 1)
		draw_set_transform(waist, 0, Vector2(PORTRAIT_SCALE * face, PORTRAIT_SCALE))
		draw_texture(win.tex[i], -win.pivot[i])
		draw_set_transform(Vector2.ZERO)
		return
	var a := _sprites.anim(id, "select")
	var k := PORTRAIT_SCALE
	var at := waist
	if a.is_empty():
		a = _sprites.anim(id, "idle")  # портрета ещё нет — стойка покрупнее
		k = 0.62
		at = feet
	# Портреты нарисованы с поворотом вправо; второй игрок — зеркально: герои смотрят друг на друга.
	if a.is_empty():
		return
	# Выбран, а анимации радости нет — подпрыгивает.
	var hop := 0.0
	if picked[p] and since < 30:
		hop = sin(PI * since / 30.0) * 40.0
	var tex: Texture2D = a.tex[0]
	var phase := 0.5 - 0.5 * cos(TAU * float(tick) / FighterSprites.BREATH_TICKS)
	draw_set_transform(at - Vector2(0, hop), 0, Vector2(k * face, k))
	FighterSprites.draw_breathing(self, tex, a.pivot[0], Color.WHITE, tex.get_height() * 0.9, phase, 8.0)
	draw_set_transform(Vector2.ZERO)


func _text_c(pos: Vector2, s: String, font_size: int, color: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, pos - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
