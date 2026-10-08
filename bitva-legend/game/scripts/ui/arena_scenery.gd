class_name ArenaScenery
extends RefCounted
## Арена «Перекрёсток миров»: слои фона с параллаксом и анимацией.
## Слева — светлая Русь (закат, берёзы, холмы с куполами), справа — тёмные Карпаты
## (луна, звёзды, сухие деревья, замок). Посередине — камень на перепутье.
##
## Если в res://art/arena/ лежит картинка слоя — рисуется она (см. docs/ART_ARENA.md),
## иначе — заглушка из фигур. Всё только для красоты: в симуляции боя не участвует.
##
## Параллакс: слой с коэффициентом k сдвигается на k от движения камеры.
## k = 0 — неподвижен (небо), k = 1 — вместе с бойцами (земля), k > 1 — передний план.

const ART_DIR := "res://art/arena/"
const K_SKY := 0.04
const K_MOON := 0.07
const K_CLOUDS := 0.14
const K_MOUNTAINS := 0.25
const K_RAVENS := 0.32
const K_FOREST := 0.55
const K_FOG := 0.8
const K_GROUND := 1.0
const K_FRONT := 1.3

const SKY_LIGHT := Color(0.98, 0.74, 0.4)    # закат над Русью
const SKY_DARK := Color(0.3, 0.07, 0.17)     # ночь над Карпатами
const SKY_TOP := Color(0.08, 0.07, 0.15)
const INK := Color(0.1, 0.06, 0.1)

var ground_y := 620.0
var view := Vector2(1280, 720)
var arena_w := 2000.0
var cam_x := 640.0
var shake := Vector2.ZERO
var t := 0.0                # время в секундах (по тикам боя — скриншоты повторяемы)

var _tex := {}
var _clouds: Array[Texture2D] = []
var _raven_frames: Array[Texture2D] = []


func _init() -> void:
	for name in ["sky", "moon", "mountains", "forest", "stone", "ground", "foreground"]:
		var tex := _load(name)
		if tex != null:
			_tex[name] = tex
	for i in range(1, 9):
		var c := _load("cloud_%d" % i)
		if c != null:
			_clouds.append(c)
	for i in range(1, 9):
		var r := _load("raven_%d" % i)
		if r != null:
			_raven_frames.append(r)


static func _load(name: String) -> Texture2D:
	var path := ART_DIR + name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


func update(c_x: float, c_shake: Vector2, tick: int, view_size: Vector2, ground: float, arena: float) -> void:
	cam_x = c_x
	shake = c_shake
	t = tick / 60.0
	view = view_size
	ground_y = ground
	arena_w = arena


## Ширина слоя: столько, чтобы при любом положении камеры он закрывал экран.
func layer_w(k: float) -> float:
	return view.x + (arena_w - view.x) * k


## Экранная x левого края слоя.
func layer_x(k: float) -> float:
	return (view.x / 2.0 - cam_x) * k + shake.x * minf(k, 1.0)


## Доля «тьмы» в точке слоя: 0 — светлая сторона, 1 — тёмная.
func darkness(k: float, x_on_layer: float) -> float:
	return clampf(x_on_layer / layer_w(k), 0.0, 1.0)


# --- Задний план (до бойцов) ---------------------------------------------

func draw_back(c: CanvasItem) -> void:
	_draw_sky(c)
	_draw_moon(c)
	_draw_clouds(c)
	_draw_mountains(c)
	_draw_ravens(c)
	_draw_forest(c)
	_draw_fog(c)
	_draw_ground(c)
	_draw_stone(c)


## Передний план (поверх бойцов): трава и кусты у нижнего края.
func draw_front(c: CanvasItem) -> void:
	var k := K_FRONT
	var x0 := layer_x(k)
	var w := layer_w(k)
	if _tex.has("foreground"):
		var tex: Texture2D = _tex.foreground
		var h := w * tex.get_height() / tex.get_width()
		c.draw_texture_rect(tex, Rect2(x0, view.y - h + 10, w, h), false)
		return
	var i := 0
	var x := 0.0
	while x < w:
		var sx := x0 + x
		if sx > -80 and sx < view.x + 80:
			var dark := darkness(k, x)
			var col := Color(0.16, 0.22, 0.12).lerp(Color(0.09, 0.06, 0.09), dark)
			var sway := sin(t * 1.6 + i * 0.7) * 6.0
			for b in 5:
				var bx := sx + (b - 2) * 7.0
				var top := Vector2(bx + sway + (b - 2) * 4.0, view.y - 34 - 18 * ((i * 7 + b * 3) % 5) / 4.0)
				c.draw_line(Vector2(bx, view.y + 2), top, col, 4)
		x += 140.0 + 60.0 * ((i * 37) % 3)
		i += 1


# --- Слои ----------------------------------------------------------------

func _draw_sky(c: CanvasItem) -> void:
	var k := K_SKY
	if _tex.has("sky"):
		c.draw_texture_rect(_tex.sky, Rect2(layer_x(k), 0, layer_w(k), view.y), false)
		return
	var steps := 32
	var w := view.x / steps
	for i in steps:
		var lx := (i + 0.5) * w - layer_x(k)
		var horizon := SKY_LIGHT.lerp(SKY_DARK, darkness(k, lx))
		c.draw_rect(Rect2(i * w, 0, w + 1, ground_y * 0.35), SKY_TOP.lerp(horizon, 0.25))
		c.draw_rect(Rect2(i * w, ground_y * 0.35, w + 1, ground_y * 0.35), SKY_TOP.lerp(horizon, 0.6))
		c.draw_rect(Rect2(i * w, ground_y * 0.7, w + 1, ground_y * 0.3), SKY_TOP.lerp(horizon, 0.9))
	# Звёзды на тёмной стороне мерцают.
	for s in 60:
		var lx := float((s * 7919) % 1000) / 1000.0 * layer_w(k)
		var ly := float((s * 104729) % 1000) / 1000.0 * ground_y * 0.55
		var dark := darkness(k, lx)
		if dark < 0.45:
			continue
		var tw := 0.5 + 0.5 * sin(t * 2.0 + s * 1.3)
		c.draw_circle(Vector2(layer_x(k) + lx, ly), 1.2 + tw, Color(1, 0.95, 0.85, (dark - 0.45) * 1.6 * (0.4 + 0.6 * tw)))


func _draw_moon(c: CanvasItem) -> void:
	var k := K_MOON
	var pos := Vector2(layer_x(k) + layer_w(k) * 0.8, 215)
	var pulse := 0.5 + 0.5 * sin(t * 0.8)
	# Ореол.
	for i in 4:
		c.draw_circle(pos, 70.0 + i * 22.0 + pulse * 6.0, Color(0.95, 0.9, 1.0, 0.05))
	if _tex.has("moon"):
		var tex: Texture2D = _tex.moon
		var size := 150.0
		c.draw_texture_rect(tex, Rect2(pos - Vector2(size, size) / 2.0, Vector2(size, size)), false)
		return
	c.draw_circle(pos, 62, Color(0.96, 0.93, 0.84))
	c.draw_circle(pos + Vector2(-18, -14), 12, Color(0.86, 0.83, 0.76))
	c.draw_circle(pos + Vector2(20, 18), 9, Color(0.86, 0.83, 0.76))
	c.draw_circle(pos + Vector2(8, -28), 6, Color(0.86, 0.83, 0.76))


## Тучи плывут вправо (к тьме) и по кругу возвращаются.
func _draw_clouds(c: CanvasItem) -> void:
	var k := K_CLOUDS
	var w := layer_w(k)
	for i in 8:
		var speed := 8.0 + 5.0 * (i % 3)
		var span := w + 500.0
		var lx := fmod(i * span / 8.0 + t * speed, span) - 250.0
		var y := 50.0 + 34.0 * ((i * 5) % 7)
		var scale := 0.7 + 0.15 * (i % 4)
		var dark := darkness(k, lx)
		var pos := Vector2(layer_x(k) + lx, y)
		if not _clouds.is_empty():
			var tex := _clouds[i % _clouds.size()]
			var sz := Vector2(tex.get_width(), tex.get_height()) * scale * 0.5
			# Светлая сторона — тёплые тучи, тёмная — сизые.
			c.draw_texture_rect(tex, Rect2(pos - sz / 2.0, sz), false, Color(1, 0.92, 0.82).lerp(Color(0.55, 0.5, 0.65), dark))
			continue
		var col := Color(1.0, 0.86, 0.7, 0.75).lerp(Color(0.3, 0.24, 0.34, 0.85), dark)
		for b in 5:
			var off := Vector2((b - 2) * 34.0, -absf(b - 2.0) * -6.0 - (12.0 if b == 2 else 0.0)) * scale
			c.draw_circle(pos + off, (34.0 - absf(b - 2.0) * 6.0) * scale, col)


func _draw_mountains(c: CanvasItem) -> void:
	var k := K_MOUNTAINS
	var x0 := layer_x(k)
	var w := layer_w(k)
	if _tex.has("mountains"):
		_draw_strip(c, _tex.mountains, k, ground_y + 10)
		return
	var pts := PackedVector2Array([Vector2(x0, ground_y)])
	var x := 0.0
	while x <= w:
		var dark := darkness(k, x)
		# Слева пологие холмы, справа — острые пики.
		var soft := 90.0 + 35.0 * sin(x * 0.009) + 20.0 * sin(x * 0.023 + 1.1)
		var sharp := 150.0 + 70.0 * absf(sin(x * 0.012)) + 35.0 * absf(sin(x * 0.037 + 0.5))
		pts.append(Vector2(x0 + x, ground_y - lerpf(soft, sharp, smoothstep(0.35, 0.75, dark))))
		x += 16.0
	pts.append(Vector2(x0 + w, ground_y))
	var col := Color(0.42, 0.3, 0.32).lerp(Color(0.15, 0.1, 0.17), 0.5)
	c.draw_colored_polygon(pts, col)
	# Купола церкви на светлом холме и замок на тёмной скале.
	var church := Vector2(x0 + w * 0.12, ground_y - 112)
	c.draw_rect(Rect2(church + Vector2(-16, -30), Vector2(32, 30)), col.darkened(0.15))
	c.draw_circle(church + Vector2(0, -36), 13, col.darkened(0.15))
	c.draw_line(church + Vector2(0, -49), church + Vector2(0, -64), col.darkened(0.15), 3)
	var castle := Vector2(x0 + w * 0.86, ground_y - 190)
	for i in 3:
		var tx := castle.x + (i - 1) * 34.0
		var th := 60.0 + 25.0 * (i % 2)
		c.draw_rect(Rect2(tx - 10, castle.y - th, 20, th + 40), INK.lerp(col, 0.3))
		c.draw_colored_polygon(PackedVector2Array([Vector2(tx - 13, castle.y - th), Vector2(tx, castle.y - th - 26), Vector2(tx + 13, castle.y - th)]), INK.lerp(col, 0.3))
	c.draw_rect(Rect2(castle.x - 50, castle.y - 30, 100, 70), INK.lerp(col, 0.3))
	# Одно окно в замке горит.
	c.draw_rect(Rect2(castle.x + 30, castle.y - 60, 5, 8), Color(1, 0.75, 0.3, 0.6 + 0.4 * sin(t * 3.0)))


## Вороны кружат над лесом; часть летит в другую сторону.
func _draw_ravens(c: CanvasItem) -> void:
	var k := K_RAVENS
	var w := layer_w(k)
	for i in 5:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var speed := 55.0 + 18.0 * i
		var span := w + 400.0
		var lx := fmod(i * 431.0 + t * speed, span) - 200.0
		if dir < 0:
			lx = w - lx
		var y := 150.0 + 45.0 * i + sin(t * 1.3 + i) * 18.0
		var pos := Vector2(layer_x(k) + lx, y)
		var scale := 0.7 + 0.12 * (i % 3)
		if not _raven_frames.is_empty():
			var tex := _raven_frames[int(t * 10.0 + i * 2) % _raven_frames.size()]
			var sz := Vector2(tex.get_width(), tex.get_height()) * 0.18 * scale
			# Кадры нарисованы летящими вправо; летящих влево отражаем.
			c.draw_texture_rect(tex, Rect2(pos - Vector2(sz.x * dir, sz.y) / 2.0, Vector2(sz.x * dir, sz.y)), false)
			continue
		var flap := sin(t * 9.0 + i * 1.7)
		for side in [-1.0, 1.0]:
			var tip := pos + Vector2(side * 22.0, -16.0 * flap) * scale
			c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-4, 0) * scale, tip, pos + Vector2(4, 2) * scale]), INK)
		c.draw_circle(pos, 5.0 * scale, INK)
		c.draw_circle(pos + Vector2(dir * 6.0, -2.0) * scale, 3.5 * scale, INK)


func _draw_forest(c: CanvasItem) -> void:
	var k := K_FOREST
	var x0 := layer_x(k)
	var w := layer_w(k)
	if _tex.has("forest"):
		_draw_strip(c, _tex.forest, k, ground_y + 25)
		return
	var i := 0
	var x := 30.0
	while x < w:
		var dark := darkness(k, x)
		var base := Vector2(x0 + x, ground_y + 5)
		if base.x > -150 and base.x < view.x + 150:
			var hgt := 170.0 + 50.0 * ((i * 13) % 4)
			var sway := sin(t * 1.1 + i * 0.9) * 5.0
			if dark < 0.5:
				# Берёза: белый ствол, крона.
				var crown := Color(0.32, 0.42, 0.2).lerp(Color(0.5, 0.38, 0.2), 0.3)
				c.draw_line(base, base + Vector2(0, -hgt), Color(0.85, 0.82, 0.74), 9)
				for m in 4:
					c.draw_line(base + Vector2(-4, -30.0 - m * 32.0), base + Vector2(4, -34.0 - m * 32.0), INK, 3)
				for b in 4:
					var cp := base + Vector2(sway + (b - 1.5) * 22.0, -hgt + 10.0 + (b % 2) * 26.0)
					c.draw_circle(cp, 34, crown.darkened(0.08 * b))
			else:
				# Сухое кривое дерево.
				var col := Color(0.16, 0.1, 0.14)
				var top := base + Vector2(sway * 0.4, -hgt)
				c.draw_line(base, top, col, 10)
				for b in 4:
					var from := base.lerp(top, 0.45 + 0.15 * b)
					var side := -1.0 if b % 2 == 0 else 1.0
					var tip := from + Vector2(side * (40.0 - b * 6.0) + sway, -30.0 - b * 4.0)
					c.draw_line(from, tip, col, 5)
					c.draw_line(tip, tip + Vector2(side * 14.0, -12.0), col, 3)
		x += 150.0 + 70.0 * ((i * 29) % 3)
		i += 1


## Низкий туман у земли медленно ползёт.
func _draw_fog(c: CanvasItem) -> void:
	var k := K_FOG
	var w := layer_w(k)
	for i in 9:
		var lx := fmod(i * w / 9.0 + t * 12.0, w + 300.0) - 150.0
		var dark := darkness(k, lx)
		var col := Color(1, 0.9, 0.8, 0.07).lerp(Color(0.65, 0.6, 0.8, 0.12), dark)
		var pos := Vector2(layer_x(k) + lx, ground_y - 16)
		c.draw_set_transform(pos, 0, Vector2(1, 0.28))
		c.draw_circle(Vector2.ZERO, 160, col)
		c.draw_set_transform(Vector2.ZERO)


func _draw_ground(c: CanvasItem) -> void:
	var k := K_GROUND
	var x0 := layer_x(k)
	if _tex.has("ground"):
		var tex: Texture2D = _tex.ground
		var h := arena_w * tex.get_height() / tex.get_width()
		c.draw_texture_rect(tex, Rect2(x0, ground_y - 28, arena_w, h), false)
		return
	c.draw_rect(Rect2(0, ground_y, view.x, view.y - ground_y), Color(0.2, 0.17, 0.16))
	c.draw_line(Vector2(0, ground_y), Vector2(view.x, ground_y), Color(0.32, 0.28, 0.26), 3)
	# Колеи дороги и метки — видно движение камеры.
	var first := int(floor((cam_x - view.x / 2.0) / 100.0)) * 100
	for wx in range(first, int(cam_x + view.x / 2.0) + 100, 100):
		var p := Vector2(x0 + wx, ground_y)
		c.draw_line(p, p + Vector2(-30, 40), Color(0.32, 0.28, 0.26), 2)


## Камень на перепутье — в центре арены, на линии бойцов.
func _draw_stone(c: CanvasItem) -> void:
	var p := Vector2(layer_x(K_GROUND) + arena_w / 2.0, ground_y + 4)
	if _tex.has("stone"):
		var tex: Texture2D = _tex.stone
		var h := 170.0
		var w := h * tex.get_width() / tex.get_height()
		c.draw_texture_rect(tex, Rect2(p.x - w / 2.0, p.y - h, w, h), false)
		return
	var pts := PackedVector2Array([p + Vector2(-56, 0), p + Vector2(-50, -120), p + Vector2(-30, -150),
		p + Vector2(28, -152), p + Vector2(50, -126), p + Vector2(58, 0)])
	c.draw_colored_polygon(pts, Color(0.45, 0.43, 0.44))
	var outline := pts.duplicate()
	outline.append(pts[0])
	c.draw_polyline(outline, Color(0.25, 0.24, 0.26), 3)
	c.draw_circle(p + Vector2(-34, -20), 14, Color(0.3, 0.42, 0.22, 0.8))  # мох
	for i in 4:
		c.draw_line(p + Vector2(-30, -116 + i * 18), p + Vector2(30, -116 + i * 18), Color(0.28, 0.27, 0.29), 2)


## Слой-полоса: растянут по ширине слоя, низ — у bottom_y.
func _draw_strip(c: CanvasItem, tex: Texture2D, k: float, bottom_y: float) -> void:
	var w := layer_w(k)
	var h := w * tex.get_height() / tex.get_width()
	c.draw_texture_rect(tex, Rect2(layer_x(k), bottom_y - h, w, h), false)
