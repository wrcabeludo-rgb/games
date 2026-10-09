class_name ArenaScenery
extends RefCounted
## Фон арены: слои с параллаксом и анимацией. Какая арена — Arenas (у каждой своя папка арта).
## Первая арена, «Перепутье»: слева светлая Русь (закат, берёзы, холмы с куполами), справа тёмные Карпаты
## (луна, звёзды, сухие деревья, замок), посередине — камень на перепутье.
##
## Если в папке арены лежит картинка слоя — рисуется она (см. docs/ART_ARENA.md),
## иначе — заглушка из фигур по описанию арены (Arenas.LIST). В симуляции боя не участвует.
##
## Параллакс: слой с коэффициентом k сдвигается на k от движения камеры.
## k = 0 — неподвижен (небо), k = 1 — вместе с бойцами (земля), k > 1 — передний план.

const K_SKY := 0.04
const K_MOON := 0.07
const K_CLOUDS := 0.14
const K_MOUNTAINS := 0.1
const K_RAVENS := 0.2
const K_FOREST := 0.3
const K_FOG := 0.8
const K_GROUND := 1.0
const K_FRONT := 1.3

const GROUND_WIDE := 1.3      # земля из трёх панелей: ширина рисунка — столько ширин арены
const GROUND_SQUASH := 0.8  # картинку земли сжимаем по высоте
const GROUND_RISE := 148.0  # бойцы стоят на дороге: полоса травы и кустов — выше их ступней, px
const FOREST_HEIGHT := 270.0  # высота полосы леса на экране, px (ширина — по пропорциям картинки)
const K_STONE := 0.85
const STONE_H := 260.0       # высота камня с надписью (боец — 300)
const STONE_BACK := 26.0    # насколько выше линии бойцов стоит камень (дальше от зрителя), px
const STONE_SINK := 16.0    # камень утоплен в землю, px
const FRONT_RISE := 95.0    # передний план поднимается над линией земли, px

const INK := Color(0.1, 0.06, 0.1)

## Какая арена и её описание (цвета заглушки, ориентиры, деревья).
var id := Arenas.DEFAULT
var _d: Dictionary = Arenas.data(Arenas.DEFAULT)
var _sky_top := Color(0.08, 0.07, 0.15)
var _sky_light := Color(0.98, 0.74, 0.4)     # горизонт слева
var _sky_dark := Color(0.3, 0.07, 0.17)      # горизонт справа

var ground_y := 620.0
var view := Vector2(1280, 720)
var arena_w := 2000.0
var cam_x := 640.0
var shake := Vector2.ZERO
var t := 0.0                # время в секундах (по тикам боя — скриншоты повторяемы)

var _tex := {}
var _clouds: Array[Texture2D] = []
var _raven_frames: Array[Texture2D] = []
## Ореол луны: свет плавно гаснет от края диска к краю текстуры.
var _halo := _make_halo()


func _init(arena_id := Arenas.DEFAULT) -> void:
	id = arena_id if Arenas.LIST.has(arena_id) else Arenas.DEFAULT
	_d = Arenas.data(id)
	_sky_top = _d.sky[0]
	_sky_light = _d.sky[1]
	_sky_dark = _d.sky[2]
	for name in ["sky", "moon", "mountains", "forest", "stone", "ground", "foreground"]:
		var tex := _load(name)
		if tex != null:
			_tex[name] = tex
	for i in range(1, 9):
		var c := _load("cloud_%d" % i)
		if c != null:
			_clouds.append(c)
	for i in range(1, 17):
		var r := _load("raven_%d" % i)
		if r != null:
			_raven_frames.append(r)


static func _make_halo() -> Texture2D:
	var g := Gradient.new()
	var glow := Color(0.95, 0.9, 1.0)
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.45, 0.65, 1.0])
	g.colors = PackedColorArray([Color(glow, 0.42), Color(glow, 0.3), Color(glow, 0.15), Color(glow, 0.05), Color(glow, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex


func _load(name: String) -> Texture2D:
	var path: String = _d.dir + name + ".png"
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
		# Верх растений чуть выше линии земли: кончики травы перед ногами бойцов, остальное ниже.
		var h := w * tex.get_height() / tex.get_width()
		# Низ травы — у нижнего края экрана (без полосы голой земли под ней).
		var top := maxf(ground_y - FRONT_RISE, view.y - h + 4.0)
		_draw_swaying(c, tex, Rect2(x0, top, w, h), Color(0.78, 0.76, 0.8), 7.0, 1.9)
		return
	if _d.get("glitch", false):
		_draw_glitch_front(c)
		return
	if _d.get("indoor", false):
		return
	var grass: Color = (_d.ground as Color).lerp(Color(0.16, 0.24, 0.1), 0.6).darkened(0.3)
	var i := 0
	var x := 0.0
	while x < w:
		var sx := x0 + x
		if sx > -80 and sx < view.x + 80:
			var dark := darkness(k, x)
			var col := grass.lerp(grass.darkened(0.4), dark)
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
		# Низ неба (горизонт с солнцем) — чуть выше земли, лишнее сверху уходит за экран.
		var tex: Texture2D = _tex.sky
		var h := maxf(layer_w(k) * tex.get_height() / tex.get_width(), ground_y)
		c.draw_texture_rect(tex, Rect2(layer_x(k), ground_y - h, layer_w(k), h), false)
		return
	var steps := 32
	var w := view.x / steps
	for i in steps:
		var lx := (i + 0.5) * w - layer_x(k)
		var horizon := _sky_light.lerp(_sky_dark, darkness(k, lx))
		c.draw_rect(Rect2(i * w, 0, w + 1, ground_y * 0.35), _sky_top.lerp(horizon, 0.25))
		c.draw_rect(Rect2(i * w, ground_y * 0.35, w + 1, ground_y * 0.35), _sky_top.lerp(horizon, 0.6))
		c.draw_rect(Rect2(i * w, ground_y * 0.7, w + 1, ground_y * 0.3), _sky_top.lerp(horizon, 0.9))
	if _d.get("indoor", false):
		_draw_hall_wall(c)
		return
	# Звёзды на тёмной стороне мерцают.
	for s in (60 if _d.stars else 0):
		var lx := float((s * 7919) % 1000) / 1000.0 * layer_w(k)
		var ly := float((s * 104729) % 1000) / 1000.0 * ground_y * 0.55
		var dark := darkness(k, lx)
		if dark < 0.45:
			continue
		var tw := 0.5 + 0.5 * sin(t * 2.0 + s * 1.3)
		c.draw_circle(Vector2(layer_x(k) + lx, ly), 1.2 + tw, Color(1, 0.95, 0.85, (dark - 0.45) * 1.6 * (0.4 + 0.6 * tw)))


func _draw_moon(c: CanvasItem) -> void:
	var k := K_MOON
	var kind: String = _d.light[0]
	if kind == "none" or (_d.get("indoor", false) and not _tex.has("moon")):
		return
	var pos := Vector2(layer_x(k) + layer_w(k) * float(_d.light[1]), 215)
	if kind == "sun" and not _tex.has("moon"):
		var glow := Color(1.0, 0.9, 0.65)
		c.draw_texture_rect(_halo, Rect2(pos - Vector2(260, 260), Vector2(520, 520)), false, Color(glow, 0.9))
		c.draw_circle(pos, 58, Color(1.0, 0.93, 0.7))
		return
	var pulse := 0.5 + 0.5 * sin(t * 0.8)
	# Ореол: мягкий радиальный градиент (без ступенек), слегка дышит.
	var r := 230.0 + pulse * 12.0
	c.draw_texture_rect(_halo, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, 0.85 + 0.15 * pulse))
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
	if _d.get("indoor", false) or _d.get("glitch", false):
		return
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
		# Дальний план из панелей (широкий): поднят, чтобы холмы, деревни и замок были видны над лесом.
		var wide: bool = float(_tex.mountains.get_width()) / _tex.mountains.get_height() > 5.0
		_draw_strip(c, _tex.mountains, k, ground_y - 95 if wide else ground_y + 70)
		return
	var col: Color = _d.hills
	if not _d.get("indoor", false):
		var pts := PackedVector2Array([Vector2(x0, ground_y)])
		var x := 0.0
		while x <= w:
			var dark := darkness(k, x)
			var left := _hill_height(_d.shape[0], x)
			var right := _hill_height(_d.shape[1], x)
			pts.append(Vector2(x0 + x, ground_y - lerpf(left, right, smoothstep(0.35, 0.75, dark))))
			x += 16.0
		pts.append(Vector2(x0 + w, ground_y))
		c.draw_colored_polygon(pts, col)
		# Море: блики на воде.
		for side in 2:
			if _d.shape[side] == "sea":
				for i in 14:
					var wx := x0 + w * (0.04 + 0.03 * i + 0.55 * side)
					var wy := ground_y - 30.0 - 12.0 * (i % 3)
					c.draw_line(Vector2(wx + sin(t + i) * 6, wy), Vector2(wx + 26 + sin(t + i) * 6, wy), Color(1, 1, 1, 0.35), 2)
	for m in _d.marks:
		_draw_mark(c, m[0], Vector2(x0 + w * float(m[1]), ground_y), float(m[2]), col.darkened(0.25))


## Высота дальнего плана заглушки в точке x слоя для вида рельефа.
func _hill_height(shape: String, x: float) -> float:
	match shape:
		"sharp":
			return 150.0 + 70.0 * absf(sin(x * 0.012)) + 35.0 * absf(sin(x * 0.037 + 0.5))
		"flat":
			return 40.0 + 6.0 * sin(x * 0.01)
		"dunes":
			return 70.0 + 30.0 * sin(x * 0.006) + 12.0 * sin(x * 0.019 + 1.3)
		"sea":
			return 55.0 + 3.0 * sin(x * 0.05 + t)
	return 90.0 + 35.0 * sin(x * 0.009) + 20.0 * sin(x * 0.023 + 1.1)


## Ориентир дальнего плана (силуэт): p — точка на линии земли.
func _draw_mark(c: CanvasItem, kind: String, p: Vector2, k: float, col: Color) -> void:
	var dark := INK.lerp(col, 0.4)
	match kind:
		"church":
			var church := p + Vector2(0, -112)
			c.draw_rect(Rect2(church + Vector2(-16, -30), Vector2(32, 30)), col.darkened(0.15))
			c.draw_circle(church + Vector2(0, -36), 13, col.darkened(0.15))
			c.draw_line(church + Vector2(0, -49), church + Vector2(0, -64), col.darkened(0.15), 3)
		"castle":
			_draw_castle(c, p + Vector2(0, -190))
		"temple", "ruins":
			var base := p + Vector2(0, -60 * k)
			var wdt := 150.0 * k
			c.draw_rect(Rect2(base + Vector2(-wdt / 2, 0), Vector2(wdt, 12 * k)), col.lightened(0.35))
			for i in 6:
				var cx := base.x - wdt / 2 + 10 * k + i * (wdt - 20 * k) / 5.0
				var hgt := 90.0 * k * (1.0 if kind == "temple" or i % 2 == 0 else 0.5)
				c.draw_rect(Rect2(cx - 5 * k, base.y - hgt, 10 * k, hgt), col.lightened(0.35))
			if kind == "temple":
				c.draw_colored_polygon(PackedVector2Array([base + Vector2(-wdt / 2 - 8, -90 * k), base + Vector2(0, -130 * k),
					base + Vector2(wdt / 2 + 8, -90 * k)]), col.lightened(0.3))
		"rocks":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-90, 0) * k, p + Vector2(-40, -170) * k, p + Vector2(10, -120) * k,
				p + Vector2(60, -200) * k, p + Vector2(110, 0) * k]), dark)
		"tower":
			c.draw_rect(Rect2(p + Vector2(-18, -260) * k, Vector2(36, 260) * k), dark)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-26, -260) * k, p + Vector2(0, -330) * k, p + Vector2(26, -260) * k]), dark)
			c.draw_rect(Rect2(p + Vector2(-4, -220) * k, Vector2(8, 12) * k), Color(0.6, 1.0, 0.5, 0.5 + 0.4 * sin(t * 2.0)))
		"pyramid":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-150, 0) * k, p + Vector2(0, -170) * k, p + Vector2(150, 0) * k]),
				col.darkened(0.1))
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -170) * k, p + Vector2(150, 0) * k, p + Vector2(30, 0) * k]),
				col.darkened(0.3))
		"cloud_palace":
			var cp := p + Vector2(0, -330)
			for i in 5:
				c.draw_circle(cp + Vector2((i - 2) * 40, 10 + absf(i - 2.0) * 6), 34, Color(1, 1, 1, 0.7))
			c.draw_rect(Rect2(cp + Vector2(-40, -50), Vector2(80, 40)), Color(0.85, 0.3, 0.2))
			c.draw_colored_polygon(PackedVector2Array([cp + Vector2(-62, -48), cp + Vector2(0, -82), cp + Vector2(62, -48)]), Color(0.95, 0.75, 0.3))
		"fort":
			for i in 14:
				var px := p.x + (i - 7) * 22.0 * k
				c.draw_colored_polygon(PackedVector2Array([Vector2(px - 10 * k, p.y), Vector2(px - 10 * k, p.y - 80 * k),
					Vector2(px, p.y - 96 * k), Vector2(px + 10 * k, p.y - 80 * k), Vector2(px + 10 * k, p.y)]), Color(0.42, 0.3, 0.2))
			c.draw_rect(Rect2(p + Vector2(-30, -190) * k, Vector2(60, 110) * k), Color(0.38, 0.26, 0.18))
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-42, -190) * k, p + Vector2(0, -235) * k, p + Vector2(42, -190) * k]), Color(0.3, 0.2, 0.14))
		"window":
			var wc := p + Vector2(0, -330)
			c.draw_rect(Rect2(wc + Vector2(-45, 0), Vector2(90, 170)), Color(0.15, 0.12, 0.3))
			c.draw_circle(wc, 45, Color(0.15, 0.12, 0.3))
			c.draw_circle(wc + Vector2(10, 40), 22, Color(0.9, 0.88, 0.8, 0.9))
			c.draw_line(wc + Vector2(0, -45), wc + Vector2(0, 170), dark, 5)
		"throne":
			c.draw_rect(Rect2(p + Vector2(-40, -170), Vector2(80, 170)), Color(0.4, 0.06, 0.1))
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-40, -170), p + Vector2(0, -230), p + Vector2(40, -170)]), Color(0.4, 0.06, 0.1))
		"statue":
			c.draw_rect(Rect2(p + Vector2(-30, -40) * k, Vector2(60, 40) * k), col.lightened(0.2))
			c.draw_rect(Rect2(p + Vector2(-16, -170) * k, Vector2(32, 130) * k), col.lightened(0.3))
			c.draw_circle(p + Vector2(0, -186) * k, 18 * k, col.lightened(0.3))
		"cave":
			c.draw_circle(p + Vector2(0, -60), 120, dark)
			c.draw_circle(p + Vector2(0, -40), 80, Color(0.03, 0.05, 0.05))
		"giant":
			c.draw_rect(Rect2(p + Vector2(-30, -220), Vector2(60, 220)), col.darkened(0.2))
			c.draw_circle(p + Vector2(0, -320), 90, Color(0.35, 0.45, 0.7, 0.8))
		"gold":
			for i in 7:
				c.draw_circle(p + Vector2((i - 3) * 22, -12 - (3 - absi(i - 3)) * 14), 18, Color(0.9, 0.72, 0.2))
		"waterfall":
			c.draw_rect(Rect2(p + Vector2(-40, -380), Vector2(80, 380)), Color(0.6, 0.85, 1.0, 0.75))
			for i in 6:
				var yy := fmod(t * 120.0 + i * 60.0, 380.0)
				c.draw_line(p + Vector2(-30 + i * 12, -380 + yy), p + Vector2(-30 + i * 12, -350 + yy), Color(1, 1, 1, 0.6), 3)
		"scales":
			var top := p + Vector2(0, -300) * k
			c.draw_line(p, top, Color(0.85, 0.7, 0.3), 8)
			var tilt := sin(t * 0.7) * 10.0
			c.draw_line(top + Vector2(-110, tilt) * k, top + Vector2(110, -tilt) * k, Color(0.85, 0.7, 0.3), 6)
			for side in [-1.0, 1.0]:
				var pan := top + Vector2(side * 110, -side * tilt + 70) * k
				c.draw_line(top + Vector2(side * 110, -side * tilt) * k, pan, Color(0.85, 0.7, 0.3), 2)
				c.draw_colored_polygon(PackedVector2Array([pan + Vector2(-34, 0) * k, pan + Vector2(34, 0) * k, pan + Vector2(0, 20) * k]), Color(0.85, 0.7, 0.3))
		"screens":
			for i in 9:
				var r := Rect2(p + Vector2((i % 3 - 1) * 70 - 28, -110 - (i / 3) * 120) * k, Vector2(56, 100) * k)
				var flick := 0.5 + 0.5 * sin(t * 3.0 + i * 1.7)
				c.draw_rect(r, Color(0.05, 0.05, 0.1))
				c.draw_rect(r.grow(-4), Color(0.2, 0.75, 0.95, 0.3 + 0.5 * flick))


func _draw_castle(c: CanvasItem, castle: Vector2) -> void:
	var col := Color(0.42, 0.3, 0.32).lerp(Color(0.15, 0.1, 0.17), 0.5)
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
	var birds: String = _d.birds
	if birds == "none":
		return
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
		if birds == "gulls":
			# Чайки: светлая «галочка», медленный взмах.
			var fl := sin(t * 4.0 + i * 1.3)
			for side in [-1.0, 1.0]:
				c.draw_line(pos, pos + Vector2(side * 18.0, -8.0 * fl - 4.0) * scale, Color(0.95, 0.95, 0.92), 3)
			continue
		if birds == "bats":
			var fb := sin(t * 14.0 + i * 1.7)
			for side in [-1.0, 1.0]:
				c.draw_colored_polygon(PackedVector2Array([pos, pos + Vector2(side * 16, -10 * fb) * scale, pos + Vector2(side * 6, 6) * scale]), INK)
			continue
		if not _raven_frames.is_empty():
			var tex := _raven_frames[int(t * 1.6 * _raven_frames.size() + i * 2) % _raven_frames.size()]  # взмах ≈ 0,6 с при любом числе кадров
			var sz := Vector2(tex.get_width(), tex.get_height()) * 0.24 * scale
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
		# Нижняя часть леса уходит за землю; чуть приглушён, чтобы бойцы читались.
		# Лес из панелей шире слоя: рисуем заданной высоты по центру слоя, края уходят за кадр.
		var tex: Texture2D = _tex.forest
		var fh := FOREST_HEIGHT
		var fw := fh * tex.get_width() / tex.get_height()
		var fx := layer_x(k) + (layer_w(k) - fw) / 2.0
		_draw_swaying(c, tex, Rect2(fx, ground_y + 30 - fh, fw, fh), Color(0.82, 0.8, 0.88), 0.0 if _d.get("still", false) else 5.0, 1.1)
		return
	var i := 0
	var x := 30.0
	while x < w:
		var dark := darkness(k, x)
		var base := Vector2(x0 + x, ground_y + 5)
		if base.x > -150 and base.x < view.x + 150:
			var hgt := 170.0 + 50.0 * ((i * 13) % 4)
			var sway := sin(t * 1.1 + i * 0.9) * 5.0
			var kind: String = _d.trees[0] if dark < 0.5 else _d.trees[1]
			if kind != "birch" and kind != "dead":
				_draw_tree(c, kind, base, hgt, sway, i)
			elif kind == "birch":
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
	if _d.get("glitch", false):
		return
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
		# Дорога сжата по высоте (вид сбоку, земля «уходит» вдаль); бойцы стоят чуть ниже травы.
		# Земля из панелей шире арены: рисуем в своих пропорциях по центру, края уходят за кадр
		# (перекрёсток — посередине). Старая земля одной картинкой — сжата по высоте.
		var w := arena_w
		var h := arena_w * tex.get_height() / tex.get_width() * GROUND_SQUASH
		if float(tex.get_width()) / tex.get_height() > 6.0:
			w = arena_w * GROUND_WIDE
			h = w * tex.get_height() / tex.get_width()
		c.draw_texture_rect(tex, Rect2(x0 + (arena_w - w) / 2.0, ground_y - GROUND_RISE, w, h), false)
		# Ниже картинки — та же тёмная земля до края экрана.
		var bottom := ground_y - GROUND_RISE + h - 2
		if bottom < view.y:
			c.draw_rect(Rect2(0, bottom, view.x, view.y - bottom + 1), Color(0.15, 0.12, 0.1))
		return
	var gcol: Color = _d.ground
	c.draw_rect(Rect2(0, ground_y, view.x, view.y - ground_y), gcol)
	c.draw_line(Vector2(0, ground_y), Vector2(view.x, ground_y), gcol.lightened(0.2), 3)
	if _d.get("glitch", false):
		# Пол Ленты: светящаяся сетка, уходящая вдаль.
		for gx in range(-10, 30):
			var px := x0 + gx * 120.0
			c.draw_line(Vector2(px, ground_y), Vector2(px - 60, view.y), Color(0.2, 0.75, 0.95, 0.35), 2)
		for gy in 4:
			var py := ground_y + 12.0 + gy * gy * 10.0
			c.draw_line(Vector2(0, py), Vector2(view.x, py), Color(0.2, 0.75, 0.95, 0.25), 2)
		return
	# Колеи дороги и метки — видно движение камеры.
	var first := int(floor((cam_x - view.x / 2.0) / 100.0)) * 100
	for wx in range(first, int(cam_x + view.x / 2.0) + 100, 100):
		var p := Vector2(x0 + wx, ground_y)
		c.draw_line(p, p + Vector2(-30, 40), Color(0.32, 0.28, 0.26), 2)


## Камень на перепутье — в центре арены, на линии бойцов.
func _draw_stone(c: CanvasItem) -> void:
	if not _d.get("stone", false):
		return
	# Камень дальше, за спиной бойцов: свой параллакс, стоит выше по дороге, чуть меньше и в дымке.
	var p := Vector2(layer_x(K_STONE) + layer_w(K_STONE) / 2.0, ground_y - STONE_BACK)
	if _tex.has("stone"):
		var tex: Texture2D = _tex.stone
		# Основание (трава и камешки) утоплено в дорогу, под ним — тень: камень стоит, а не висит.
		var h := STONE_H
		var w := h * tex.get_width() / tex.get_height()
		var foot := p + Vector2(0, STONE_SINK)
		c.draw_set_transform(foot + Vector2(0, -4), 0, Vector2(1, 0.2))
		c.draw_circle(Vector2.ZERO, w * 0.55, Color(0.05, 0.03, 0.05, 0.55))
		c.draw_set_transform(Vector2.ZERO)
		c.draw_texture_rect(tex, Rect2(foot.x - w / 2.0, foot.y - h, w, h), false, Color(0.94, 0.93, 0.95))  # дальше — чуть в дымке (надпись должна читаться)
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


## Дерево заглушки по виду (кроме берёзы и сухого дерева — они рисуются на месте).
func _draw_tree(c: CanvasItem, kind: String, base: Vector2, hgt: float, sway: float, i: int) -> void:
	match kind:
		"cypress", "pine":
			var col := Color(0.12, 0.22, 0.14) if kind == "cypress" else Color(0.1, 0.2, 0.16)
			c.draw_line(base, base + Vector2(0, -30), Color(0.25, 0.16, 0.1), 8)
			var wdt := 26.0 if kind == "cypress" else 60.0
			c.draw_colored_polygon(PackedVector2Array([base + Vector2(-wdt, -20), base + Vector2(sway, -hgt - 20), base + Vector2(wdt, -20)]), col)
		"olive", "apple", "peach":
			var crown := {"olive": Color(0.45, 0.5, 0.35), "apple": Color(0.25, 0.42, 0.18), "peach": Color(0.3, 0.45, 0.2)}[kind] as Color
			c.draw_line(base, base + Vector2(sway * 0.3 + (8 if kind == "olive" else 0), -hgt * 0.6), Color(0.35, 0.25, 0.18), 10)
			for b in 4:
				c.draw_circle(base + Vector2(sway + (b - 1.5) * 26.0, -hgt * 0.65 - (b % 2) * 24.0), 36, crown.darkened(0.06 * b))
			if kind != "olive":
				var fruit := Color(1.0, 0.8, 0.2) if kind == "apple" else Color(1.0, 0.6, 0.35)
				for f in 5:
					c.draw_circle(base + Vector2(sway + (f - 2) * 20.0, -hgt * 0.62 - (f % 3) * 16.0), 6, fruit)
		"palm":
			var top := base + Vector2(sway + 20, -hgt)
			c.draw_line(base, top, Color(0.5, 0.36, 0.22), 9)
			for b in 5:
				var a := PI + PI * b / 4.0
				c.draw_line(top, top + Vector2.from_angle(a) * 60.0 + Vector2(0, 20), Color(0.25, 0.45, 0.2), 6)
		"column":
			var col := (_d.hills as Color).lightened(0.25)
			c.draw_rect(Rect2(base + Vector2(-22, -hgt - 120), Vector2(44, hgt + 120)), col)
			c.draw_rect(Rect2(base + Vector2(-30, -hgt - 130), Vector2(60, 14)), col.lightened(0.1))
			for f in 3:
				c.draw_line(base + Vector2(-12 + f * 12, -hgt - 116), base + Vector2(-12 + f * 12, 0), col.darkened(0.15), 2)
		"screen":
			var r := Rect2(base + Vector2(-30, -hgt), Vector2(60, hgt * 0.8))
			var flick := 0.5 + 0.5 * sin(t * 4.0 + i)
			c.draw_rect(r, Color(0.05, 0.05, 0.1))
			c.draw_rect(r.grow(-5), Color(0.2, 0.75, 0.95, 0.2 + 0.4 * flick))


## Зал (храм, замок, Дуат): вместо неба — стена с мягким светом сверху.
func _draw_hall_wall(c: CanvasItem) -> void:
	var steps := 12
	for i in steps:
		var y0 := ground_y * i / steps
		c.draw_rect(Rect2(0, y0, view.x, ground_y / steps + 1), _sky_top.lerp(_sky_light, float(i) / steps))
	# Кладка — сдвигается с параллаксом стены.
	var x0 := layer_x(K_MOUNTAINS)
	for row in 10:
		var y := ground_y - 60.0 - row * 56.0
		c.draw_line(Vector2(0, y), Vector2(view.x, y), Color(0, 0, 0, 0.12), 2)
		var off := fmod(x0 + (row % 2) * 70.0, 140.0)
		var x := off - 140.0
		while x < view.x:
			c.draw_line(Vector2(x, y), Vector2(x, y + 56), Color(0, 0, 0, 0.1), 2)
			x += 140.0


## Лента: поверх бойцов — бегущие строки помех и поднимающаяся пиксельная пыль (мир рассыпается).
func _draw_glitch_front(c: CanvasItem) -> void:
	for i in 40:
		var px := fmod(i * 97.0 + sin(i) * 300.0, view.x)
		var py := view.y - fmod(t * (40.0 + i % 7 * 12.0) + i * 53.0, view.y)
		var sz := 4.0 + (i % 4) * 3.0
		var col := [Color(0.2, 0.75, 0.95, 0.6), Color(1, 0.25, 0.35, 0.5), Color(0.95, 0.95, 1, 0.45)][i % 3] as Color
		c.draw_rect(Rect2(px, py, sz, sz), col)
	var band := fmod(t * 160.0, view.y + 60.0) - 30.0
	c.draw_rect(Rect2(0, band, view.x, 3), Color(1, 1, 1, 0.08))


## Слой-полоса: растянут по ширине слоя, низ — у bottom_y.
func _draw_strip(c: CanvasItem, tex: Texture2D, k: float, bottom_y: float, tint := Color.WHITE) -> void:
	var w := layer_w(k)
	var h := w * tex.get_height() / tex.get_width()
	c.draw_texture_rect(tex, Rect2(layer_x(k), bottom_y - h, w, h), false, tint)


## Слой на ветру: картинка натянута на сетку, верх сетки качается сильнее низа (низ стоит на месте),
## волна бежит вдоль слоя, иногда налетает порыв. Рисуется только видимая часть.
func _draw_swaying(c: CanvasItem, tex: Texture2D, rect: Rect2, tint: Color, amp: float, speed: float) -> void:
	const COLS_PER_SCREEN := 24
	const ROWS := 6
	var step := view.x / COLS_PER_SCREEN
	var first := maxi(int(floor((0.0 - rect.position.x) / step)) - 1, 0)
	var last := mini(int(ceil((view.x - rect.position.x) / step)) + 1, int(ceil(rect.size.x / step)))
	var gust := 1.0 + 0.6 * maxf(sin(t * 0.37), 0.0)
	var colors := PackedColorArray([tint, tint, tint, tint])
	for i in range(first, last):
		var u0 := minf(i * step / rect.size.x, 1.0)
		var u1 := minf((i + 1) * step / rect.size.x, 1.0)
		for j in ROWS:
			var v0 := float(j) / ROWS
			var v1 := float(j + 1) / ROWS
			var pts := PackedVector2Array([
				_sway_point(rect, u0, v0, amp * gust, speed),
				_sway_point(rect, u1, v0, amp * gust, speed),
				_sway_point(rect, u1, v1, amp * gust, speed),
				_sway_point(rect, u0, v1, amp * gust, speed),
			])
			var uvs := PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)])
			c.draw_polygon(pts, colors, uvs, tex)


func _sway_point(rect: Rect2, u: float, v: float, amp: float, speed: float) -> Vector2:
	var p := rect.position + Vector2(u * rect.size.x, v * rect.size.y)
	var lift := (1.0 - v) * (1.0 - v)  # верх качается, низ (корни) неподвижен
	var wx := u * rect.size.x
	var dx := amp * lift * (sin(t * speed + wx * 0.006) + 0.35 * sin(t * speed * 2.3 + wx * 0.017))
	return p + Vector2(dx, 0)
