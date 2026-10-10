class_name FighterSprites
extends RefCounted
## Спрайты бойцов из game/art/fighters/<боец>/ (готовит tools/process_fighter_art.py, см. docs/ART_FIGHTERS.md).
## Для каждой анимации: <имя>.json (кадры и опорные точки) и <имя>_<N>.png.
## Если для состояния бойца анимации нет — возвращается пусто, и рисуется заглушка из фигур.

const ART_DIR := "res://art/fighters/"
const SCALE := 0.5          # кадры нарисованы для 1440p, игра считает в 720p
## Длительность цикла анимации, тиков: сколько бы кадров ни нарисовали (4 или 12),
## цикл идёт с той же скоростью — больше кадров = плавнее.
const IDLE_CYCLE := 96      # стойка (дыхание)
const WALK_CYCLE := 40      # шаг (полный цикл — два шага)
const RUN_CYCLE := 26       # бег
const BREATH_TICKS := 110  # один вдох-выдох в стойке (дыхание рисует игра, см. ArenaView._draw_breathing)
## Покачивание при ходьбе (bob в <анимация>.json — насколько оседает тело, доля роста): самая низкая точка —
## когда вес ложится на ногу (2-й и 6-й кадры из 8), самая высокая — нога проходит под телом (4-й и 8-й).
const WALK_LOW := 3.0 / 16.0
const WALK_SWAY := 0.4     # плечи подаются вперёд-назад — доля от покачивания вверх-вниз
const GET_UP_TICKS := 18   # вставание — последние столько тиков лежания
const PING_PONG_MAX := 5    # до стольких кадров стойка идёт туда-обратно (1-2-3-2), больше — нарисован цикл

## Стойка из кадра другой анимации: [анимация, кадр с 0] — временная мера, пока у бойца нарисованная
## стойка не совпадает с позой, из которой начинаются удары. Сейчас не нужна никому.
const IDLE_FROM := {}
## Прыжок из 4 кадров (присед, взлёт, верх, приземление): при падении держим кадр верхней точки,
## а кадр приземления — только у самой земли, px.
const JUMP_LAND_HEIGHT := 110

## id бойца → {анимация: {"tex": Array[Texture2D], "pivot": Array[Vector2]}}
var _bank := {}
## id бойца → во сколько раз его кадры крупнее обычных (у новых бойцов — 2: чётко на мониторах 2K/4K).
var _res := {}


func _init() -> void:
	for id in FighterData.CHARACTERS:
		_bank[id] = _load_character(id)
		var idle: Dictionary = _bank[id].get("idle", {})
		_res[id] = idle.get("res", 1.0)


static func _load_character(id: String) -> Dictionary:
	var out := {}
	var dir := DirAccess.open(ART_DIR + id)
	if dir == null:
		return out
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var meta = JSON.parse_string(FileAccess.get_file_as_string(ART_DIR + id + "/" + file))
		if not meta is Dictionary:
			continue
		var tex: Array[Texture2D] = []
		var pivots: Array[Vector2] = []
		for fr in meta.frames:
			var path: String = ART_DIR + id + "/" + fr.file
			if not ResourceLoader.exists(path):
				continue
			tex.append(load(path))
			pivots.append(Vector2(fr.pivot[0], fr.pivot[1]))
		if not tex.is_empty():
			# Ударные кадры (с 0); по умолчанию — 2-й из 3, предпоследний из 4+.
			var n := tex.size()
			var hit: int = int(meta.get("hit", 2 if n <= 3 else n - 1)) - 1
			var hit_end: int = int(meta.get("hit_end", hit + 1)) - 1
			out[file.get_basename()] = {"tex": tex, "pivot": pivots, "hit": clampi(hit, 0, n - 1),
				"hit_end": clampi(hit_end, hit, n - 1), "reverse": bool(meta.get("reverse", false)),
				"air": int(meta.get("air_frames", 1)), "res": float(meta.get("res", 1.0)),
				"bob": float(meta.get("bob", 0.0)), "stride": float(meta.get("stride", 0.0)),
				"cycle": int(meta.get("cycle", 0)), "release": int(meta.get("release", 0))}
	if IDLE_FROM.has(id) and out.has(IDLE_FROM[id][0]):
		var src: Dictionary = out[IDLE_FROM[id][0]]
		var k: int = IDLE_FROM[id][1]
		out["idle"] = {"tex": [src.tex[k]] as Array[Texture2D], "pivot": [src.pivot[k]] as Array[Vector2],
			"hit": 0, "hit_end": 0, "reverse": false, "air": 1, "bob": 0.0, "stride": 0.0, "cycle": 0, "release": 0}
	return out


## Разрешение кадров бойца: 1 — обычное, 2 — двойное (рисовать с масштабом SCALE / res).
func res(id: String) -> float:
	return _res.get(id, 1.0)


func has_any(id: String) -> bool:
	return not _bank.get(id, {}).is_empty()


## Анимация бойца по имени: {"tex", "pivot", …} или пусто, если её ещё не нарисовали.
func anim(id: String, name: String) -> Dictionary:
	return _bank.get(id, {}).get(name, {})


## Дыхание: один кадр, натянутый на сетку; грудь, плечи и голова плавно поднимаются,
## ноги стоят на месте. Без смены кадров — никакой «рваности». Координаты — в пикселях кадра,
## phase — 0 (выдох) … 1 (вдох), body_h — рост в пикселях кадра.
static func draw_breathing(c: CanvasItem, tex: Texture2D, pivot: Vector2, tint: Color, body_h: float,
		phase: float, lift := 7.0) -> void:
	draw_flexed(c, tex, pivot, tint, body_h, lift * phase, 0.0)


## Кадр на сетке: верх тела (от пояса) поднят на lift и сдвинут вперёд на shift пикселей кадра, ноги на месте.
static func draw_flexed(c: CanvasItem, tex: Texture2D, pivot: Vector2, tint: Color, body_h: float,
		lift: float, shift: float) -> void:
	const ROWS := 12
	var size := tex.get_size()
	var colors := PackedColorArray([tint, tint, tint, tint])
	for j in ROWS:
		var v0 := float(j) / ROWS
		var v1 := float(j + 1) / ROWS
		var k0 := _lift(v0 * size.y, pivot.y, body_h)
		var k1 := _lift(v1 * size.y, pivot.y, body_h)
		var y0 := v0 * size.y - pivot.y - k0 * lift
		var y1 := v1 * size.y - pivot.y - k1 * lift
		var pts := PackedVector2Array([Vector2(-pivot.x + k0 * shift, y0), Vector2(size.x - pivot.x + k0 * shift, y0),
			Vector2(size.x - pivot.x + k1 * shift, y1), Vector2(-pivot.x + k1 * shift, y1)])
		var uvs := PackedVector2Array([Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1)])
		c.draw_polygon(pts, colors, uvs, tex)


## Покачивание в шаге: [насколько поднять верх тела, насколько подать вперёд] в долях роста; phase — 0…1 цикла.
static func walk_flex(bob: float, phase: float) -> Vector2:
	var a := TAU * 2.0 * (phase - WALK_LOW)  # два шага за цикл
	return Vector2(-bob * cos(a), -bob * WALK_SWAY * sin(a))


## Насколько поднимается точка кадра на вдохе: ноги — 0, от пояса растёт, грудь и выше — полностью.
static func _lift(y: float, feet_y: float, body_h: float) -> float:
	var h := clampf((feet_y - y) / body_h, 0.0, 1.0)
	return smoothstep(0.35, 0.7, h)


## Кадр для текущего состояния бойца: [текстура, опорная точка] или [] (нет анимации — рисовать заглушку).
func frame_for(f: Fighter, tick: int) -> Array:
	var anims: Dictionary = _bank.get(f.id, {})
	if anims.is_empty():
		return []
	match f.state:
		Fighter.State.ATTACK:
			var name: String = Fighter.MOVES[f.move]
			if anims.has(name):
				return _pick(anims[name], _attack_index(f, anims[name]))
		Fighter.State.WALK_F:
			if anims.has("walk_f"):
				var cycle := _walk_cycle(anims.walk_f, f.data.walk_f)
				return _walk(anims.walk_f, _cycle(f.state_frame, cycle, anims.walk_f.tex.size()),
					float(f.state_frame % cycle) / cycle)
		Fighter.State.WALK_B:
			# Шаг назад — кадры ходьбы в обратном порядке.
			var key := "walk_b" if anims.has("walk_b") else "walk_f"
			if anims.has(key):
				var n: int = anims[key].tex.size()
				# Лист шага вперёд (или помеченный reverse) — задом наперёд.
				var cycle := _walk_cycle(anims[key], f.data.walk_b)
				var i := _cycle(f.state_frame, cycle, n)
				var reverse: bool = key == "walk_f" or anims[key].reverse
				var phase := float(f.state_frame % cycle) / cycle
				return _walk(anims[key], n - 1 - i if reverse else i, 1.0 - phase if reverse else phase)
		Fighter.State.RUN:
			if anims.has("run"):
				var cycle := _walk_cycle(anims.run, f.data.run_speed, RUN_CYCLE)
				return _pick(anims.run, _cycle(f.state_frame, cycle, anims.run.tex.size()))
		Fighter.State.CROUCH:
			if anims.has("crouch"):
				if anims.crouch.cycle > 0:
					# Присед из видео — цикл дыхания (как стойка).
					return _pick(anims.crouch, _cycle(f.state_frame, anims.crouch.cycle, anims.crouch.tex.size()))
				return _pick(anims.crouch, 0 if f.state_frame < 3 else anims.crouch.tex.size() - 1)
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			# Блок: 1-й кадр — стойка в блоке, 2-й — принял удар (оглушение в блоке).
			var key := "block_low" if f.low_pose else "block"
			if anims.has(key):
				var n: int = anims[key].tex.size()
				if n > 2 and f.state == Fighter.State.BLOCKSTUN:
					# Блок из видео: 1-й кадр — защита, остальные — принял удар и выровнялся (по ходу оглушения).
					return _pick(anims[key], 1 + _progress(f, n - 1))
				return _pick(anims[key], mini(1 if f.state == Fighter.State.BLOCKSTUN else 0, n - 1))
		Fighter.State.HITSTUN:
			# Получил удар: удар → откинулся → сильнее всего откинулся; в конце оглушения — приходит в себя.
			var key := "hit_low" if f.low_pose else "hit_high"
			if anims.has(key):
				var n: int = anims[key].tex.size()
				if n > 4:
					# Из видео: откинуло → пришёл в себя, по ходу оглушения.
					return _pick(anims[key], _progress(f, n))
				if f.stun <= 4:
					return _pick(anims[key], n - 1)
				return _pick(anims[key], mini(f.state_frame / 4, n - 2))
		Fighter.State.THROWING:
			# Бросает: держит → поднял → швыряет (по ходу удержания).
			if anims.has("throw") and f.move >= 0:
				# Единый сценарий (Sim.throw_progress): держит за ворот → поднимает над головой → бросает.
				var n: int = anims.throw.tex.size()
				var m := f.move_data()
				var g: Dictionary = m.grab if m.has("grab") else m.get("cinema", {"hold": 30})
				var hold: int = maxi(int(g.hold), 1)
				var t := clampf(1.0 - float(f.stun) / hold, 0.0, 1.0)
				if anims.throw.release > 0:
					# Бросок из видео: от захвата (hit) до кадра, где соперник брошен (release), по ходу удержания.
					var a0: int = anims.throw.hit
					var rel: int = mini(anims.throw.release - 1, n - 1)
					return _pick(anims.throw, a0 + roundi(t * (rel - a0)))
				var i := 1 if t < Sim.THROW_GRIP else (2 if t < 0.92 else 3)
				return _pick(anims.throw, mini(i, n - 1))
		Fighter.State.THROWN:
			if anims.has("thrown"):
				# Схвачен за ворот (на земле) → поднят над землёй.
				var n: int = anims.thrown.tex.size()
				return _pick(anims.thrown, mini(0 if f.y < 20 * Fighter.SUB else 1, n - 1))
		Fighter.State.AIR_HIT when f.thrown_air and anims.has("thrown") and anims.thrown.tex.size() >= 4:
			# Летит после броска: кувырок → вниз головой у земли.
			return _pick(anims.thrown, 2 if f.vy > 0 or f.y > 140 * Fighter.SUB else 3)
		Fighter.State.AIR_HIT:
			# Полёт после удара: кадры полёта по очереди (откинуло → летит → почти лёг).
			if anims.has("fall"):
				return _pick(anims.fall, mini(f.state_frame / 6, anims.fall.air - 1))
		Fighter.State.KNOCKDOWN:
			# Удар о землю → подскок → лежит → встаёт (последние кадры).
			var up := Fighter.KNOCKDOWN_TICKS - f.state_frame
			if anims.has("get_up") and up <= GET_UP_TICKS:
				var n: int = anims.get_up.tex.size()
				return _pick(anims.get_up, clampi((GET_UP_TICKS - up) * n / GET_UP_TICKS, 0, n - 1))
			if anims.has("fall"):
				var n: int = anims.fall.tex.size()
				var air: int = anims.fall.air
				var i := air if f.state_frame < 5 else (air + 1 if f.state_frame < 10 else n - 2)
				return _pick(anims.fall, mini(i, n - 1))
		Fighter.State.DOWN:
			if anims.has("fall"):
				var n: int = anims.fall.tex.size()
				var air: int = anims.fall.air
				var i := air if f.state_frame < 5 else (air + 1 if f.state_frame < 10 else n - 2 + (tick / 40) % 2)
				return _pick(anims.fall, mini(i, n - 1))
		Fighter.State.PREJUMP:
			if anims.has("jump"):
				# Прыжок из 8 кадров: присед, потом толчок.
				var n0: int = anims.jump.tex.size()
				return _pick(anims.jump, 1 if n0 >= 8 and f.state_frame * 2 >= f.data.prejump else 0)
		Fighter.State.AIR:
			# Удар в прыжке — свои кадры, если нарисованы.
			if f.move >= 0 and anims.has(Fighter.MOVES[f.move]):
				var air: Dictionary = anims[Fighter.MOVES[f.move]]
				return _pick(air, _attack_index(f, air))
			# Прыжок: взлёт → верх (сгруппировался) → падение.
			if anims.has("jump") and f.move < 0 and anims.jump.tex.size() >= 8:
				# 8 кадров: 2 взлёт, 3 группировка, 4 верх, 5 раскрылся, 6 падает, (7 приземление — в LAND).
				var up: float = float(f.vy) / f.data.jump_vy
				var i8 := 2
				if up < 0.55:
					i8 = 3
				if up < 0.2:
					i8 = 4
				if up < -0.2:
					i8 = 5
				if up < -0.5 or (f.vy < 0 and f.y < JUMP_LAND_HEIGHT * Fighter.SUB):
					i8 = 6
				return _pick(anims.jump, i8)
			if anims.has("jump") and f.move < 0:
				var n: int = anims.jump.tex.size()
				var i := 1
				if absi(f.vy) < 500:
					i = 2
				elif f.vy < 0:
					# Падение: в листе из 4 кадров последний — приземление, его показываем у самой земли.
					i = 3 if n > 4 or f.y < JUMP_LAND_HEIGHT * Fighter.SUB else 2
				return _pick(anims.jump, mini(i, n - 1))
		Fighter.State.LAND when f.throw_follow and anims.has("throw"):
			# Только что бросил — доводит движение (у броска из видео — кадры после release, иначе последний).
			var nt: int = anims.throw.tex.size()
			if anims.throw.release > 0:
				var rel: int = mini(anims.throw.release - 1, nt - 1)
				var rest: int = nt - 1 - rel
				return _pick(anims.throw, rel + clampi(f.state_frame * rest / maxi(f.landing_frames, 1), 0, rest))
			return _pick(anims.throw, nt - 1)
		Fighter.State.LAND:
			if anims.has("jump"):
				return _pick(anims.jump, anims.jump.tex.size() - 1)
		Fighter.State.BACKDASH:
			if anims.has("backdash"):
				var n: int = anims.backdash.tex.size()
				var moving: int = (f.data.backdash_v0 + f.data.backdash_decel - 1) / f.data.backdash_decel
				if n > 3:
					# Отскок из видео: все кадры на весь отскок (полёт и приземление).
					var total: int = moving + f.data.backdash_recovery
					return _pick(anims.backdash, clampi(f.state_frame * n / maxi(total, 1), 0, n - 1))
				var i := 0 if f.state_frame < 3 else (1 if f.state_frame < moving else n - 1)
				return _pick(anims.backdash, mini(i, n - 1))
	match f.state:
		Fighter.State.STAND, Fighter.State.WALK_F, Fighter.State.WALK_B, Fighter.State.LAND, \
				Fighter.State.RUN_STOP, Fighter.State.PREJUMP, Fighter.State.RUN, Fighter.State.BACKDASH:
			if anims.has("idle"):
				# Стойка из видео (задан cycle) — цикл кадров; иначе один чистый кадр, дыхание делает игра.
				if anims.idle.cycle > 0:
					return _pick(anims.idle, _cycle(tick, anims.idle.cycle, anims.idle.tex.size()))
				return [anims.idle.tex[0], anims.idle.pivot[0], true]
				var n: int = anims.idle.tex.size()
				if n <= PING_PONG_MAX:
					return _pick(anims.idle, _ping_pong(tick * (2 * n - 2) / IDLE_CYCLE, n))
				return _pick(anims.idle, _cycle(tick, IDLE_CYCLE, n))
	# Для состояния ещё нет кадров (лист не нарисован) — стойка, а не заглушка из фигур.
	if anims.has("idle"):
		return _pick(anims.idle, 0)
	return []


## Цикл шага, тиков: если у листа задано stride (px за цикл) — под скорость бойца, чтобы ступни не скользили.
static func _walk_cycle(anim: Dictionary, speed: int, fallback := WALK_CYCLE) -> int:
	if anim.stride <= 0.0 or speed <= 0:
		return fallback
	return maxi(int(round(anim.stride * Fighter.SUB / speed)), 1)


## Кадр 0…n-1 по ходу оглушения (удар или блок): прошло state_frame из state_frame + stun тиков.
static func _progress(f: Fighter, n: int) -> int:
	return clampi(f.state_frame * n / maxi(f.state_frame + f.stun, 1), 0, n - 1)


## Кадр цикла длиной cycle тиков из n кадров.
static func _cycle(t: int, cycle: int, n: int) -> int:
	return (t % cycle) * n / cycle


## 0,1,2,3,2,1,0,1… — дыхание без рывка с последнего кадра на первый.
static func _ping_pong(i: int, n: int) -> int:
	if n <= 2:
		return i % n
	var period := 2 * n - 2
	var k := i % period
	return k if k < n else period - k


static func _pick(anim: Dictionary, i: int) -> Array:
	return [anim.tex[i], anim.pivot[i]]


## Кадр ходьбы; если у анимации задано покачивание — третьим элементом [подъём, сдвиг] в долях роста.
static func _walk(anim: Dictionary, i: int, phase: float) -> Array:
	if anim.bob <= 0.0:
		return _pick(anim, i)
	return [anim.tex[i], anim.pivot[i], walk_flex(anim.bob, phase)]


## Кадр удара по фазе: замах — кадры до ударных, активная фаза — ударные (hit…hit_end), возврат — остальные.
static func _attack_index(f: Fighter, anim: Dictionary) -> int:
	var n: int = anim.tex.size()
	if n <= 1:
		return 0
	var m := f.move_data()
	var hit: int = anim.hit
	var hit_end: int = anim.hit_end
	match f.move_phase():
		0:
			if hit <= 0:
				return 0
			return clampi((f.move_frame - 1) * hit / maxi(m.startup - 1, 1), 0, hit - 1)
		1:
			var span := hit_end - hit + 1
			return hit + clampi((f.move_frame - m.startup) * span / maxi(m.active, 1), 0, span - 1)
		_:
			var rest := n - 1 - hit_end
			if rest <= 0:
				return hit_end
			var rec: int = maxi(m.get("recovery", 1), 1)
			var t: int = f.move_frame - m.startup - m.active
			return hit_end + 1 + clampi(t * rest / rec, 0, rest - 1)
