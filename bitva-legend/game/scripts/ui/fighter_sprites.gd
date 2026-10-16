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

## Одинаковые анимации (решение владельца): удары в прыжке рукой — одна на ЛР и СР, ногой — одна на ЛН и СН;
## удары ногой сидя — одна на ЛН и СН. Если у бойца нет своей анимации удара — берётся анимация-пара.
## Приёмы: одна анимация на обе версии (лёгкую и сильную).
const ANIM_ALIAS := {"j_hp": "j_lp", "j_lp": "j_hp", "j_hk": "j_lk", "j_lk": "j_hk", "cr_hk": "cr_lk", "cr_lk": "cr_hk",
	"sp_proj_h": "sp_proj_l", "sp_dd_h": "sp_dd_l", "sp_ff_h": "sp_ff_l", "sp_bb_h": "sp_bb_l"}
## Вставание из видео (много кадров) — дольше, чем из 4 нарисованных.
const GET_UP_TICKS_VIDEO := 28
## Прыжок из видео: столько последних кадров листа — приземление.
const JUMP_LAND_FRAMES := 4
## Удар о землю после полёта (кадры падения после воздушных) из видео — столько тиков.
const LAND_TICKS_VIDEO := 12

## id бойца → {анимация: {"tex": Array[Texture2D], "pivot": Array[Vector2]}}
var _bank := {}
## Боец → анимация последнего захвата (для доводки после броска, когда приём уже закончился).
var _last_grab := {}
## id бойца → во сколько раз его кадры крупнее обычных (у новых бойцов — 2: чётко на мониторах 2K/4K).
var _res := {}


## Кадр парной сцены → пятна теней фигур в нём: [[x0, x1, низ], …] (px листа от опорной точки, tools/add_feet.py).
static var _feet := {}


## Тени фигур кадра (парная сцена, добивание) или [] — у обычного кадра тень рисует бой.
static func feet_of(tex: Texture2D) -> Array:
	return _feet.get(tex, [])


## id бойца → {анимация: данные json} — всё, что нарисовано (текстуры грузятся по требованию: все кадры всех
## бойцов — несколько гигабайт).
var _meta := {}
## id бойца → загружены ли все обычные анимации (парные сцены, добивания, радость после выбора — отдельно).
var _full := {}


func _init() -> void:
	for id in FighterData.CHARACTERS:
		_meta[id] = _scan_character(id)
		_bank[id] = {}
		var idle: Dictionary = _meta[id].get("idle", {})
		_res[id] = float(idle.get("res", 1.0))


static func _scan_character(id: String) -> Dictionary:
	var out := {}
	var dir := DirAccess.open(ART_DIR + id)
	if dir == null:
		return out
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var meta = JSON.parse_string(FileAccess.get_file_as_string(ART_DIR + id + "/" + file))
		if meta is Dictionary:
			out[file.get_basename()] = meta
	return out


## Тяжёлые листы, которые нужны редко: парные сцены и добивания (только против своего соперника),
## радость после выбора (только в меню) — грузятся при первом обращении.
static func _deferred(name: String) -> bool:
	return name.begins_with("pair_") or name.begins_with("finisher_") or name.begins_with("select_win")


static func _load_anim(id: String, meta: Dictionary) -> Dictionary:
	var tex: Array[Texture2D] = []
	var pivots: Array[Vector2] = []
	for fr in meta.frames:
		var path: String = ART_DIR + id + "/" + fr.file
		if not ResourceLoader.exists(path):
			continue
		tex.append(load(path))
		pivots.append(Vector2(fr.pivot[0], fr.pivot[1]))
		var fi: int = tex.size() - 1
		if meta.has("feet") and fi < meta.feet.size():
			_feet[tex[fi]] = meta.feet[fi]
	if tex.is_empty():
		return {}
	# Ударные кадры (с 0); по умолчанию — 2-й из 3, предпоследний из 4+.
	var n := tex.size()
	var hit: int = int(meta.get("hit", 2 if n <= 3 else n - 1)) - 1
	var hit_end: int = int(meta.get("hit_end", hit + 1)) - 1
	return {"tex": tex, "pivot": pivots, "hit": clampi(hit, 0, n - 1),
		"hit_end": clampi(hit_end, hit, n - 1), "reverse": bool(meta.get("reverse", false)),
		"air": int(meta.get("air_frames", 1)), "res": float(meta.get("res", 1.0)),
		"bob": float(meta.get("bob", 0.0)), "stride": float(meta.get("stride", 0.0)),
		"cycle": int(meta.get("cycle", 0)), "release": int(meta.get("release", 0)),
		"lift": _lift_list(meta, n)}


## Одна анимация бойца (грузит, если ещё нет); {} — не нарисована.
func _one(id: String, name: String) -> Dictionary:
	var bank: Dictionary = _bank.get(id, {})
	if bank.has(name):
		return bank[name]
	var metas: Dictionary = _meta.get(id, {})
	if not metas.has(name):
		return {}
	var a := _load_anim(id, metas[name])
	if not a.is_empty():
		bank[name] = a
	return a


## Все обычные анимации бойца (загружаются при первом появлении бойца в бою).
func _char(id: String) -> Dictionary:
	if not _bank.has(id):
		return {}
	var out: Dictionary = _bank[id]
	if _full.get(id, false):
		return out
	_full[id] = true
	for name in _meta[id]:
		if not _deferred(name):
			_one(id, name)
	for a in ANIM_ALIAS:
		if not out.has(a) and out.has(ANIM_ALIAS[a]):
			out[a] = out[ANIM_ALIAS[a]]
	if IDLE_FROM.has(id) and out.has(IDLE_FROM[id][0]):
		var src: Dictionary = out[IDLE_FROM[id][0]]
		var k: int = IDLE_FROM[id][1]
		out["idle"] = {"tex": [src.tex[k]] as Array[Texture2D], "pivot": [src.pivot[k]] as Array[Vector2],
			"hit": 0, "hit_end": 0, "reverse": false, "air": 1, "bob": 0.0, "stride": 0.0, "cycle": 0, "release": 0,
			"lift": PackedFloat32Array()}
	return out


## Парные сцены и добивание бойца id против этого соперника (грузятся, когда они впервые встретились).
func _ensure_pairs(id: String, foe_id: String) -> void:
	for name in _meta.get(id, {}):
		if (name.begins_with("pair_") or name.begins_with("finisher_")) and String(name).ends_with("_" + foe_id):
			_one(id, name)


## Разрешение кадров бойца: 1 — обычное, 2 — двойное (рисовать с масштабом SCALE / res).
func res(id: String) -> float:
	return _res.get(id, 1.0)


func has_any(id: String) -> bool:
	return not _meta.get(id, {}).is_empty()


## Анимация бойца по имени: {"tex", "pivot", …} или пусто, если её ещё не нарисовали.
func anim(id: String, name: String) -> Dictionary:
	if name == "idle" or not _meta.get(id, {}).has(name):
		return _char(id).get(name, {})  # стойка может собираться из другого листа, псевдонимы — тоже
	return _one(id, name)


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
func frame_for(f: Fighter, tick: int, foe: Fighter = null) -> Array:
	var anims: Dictionary = _char(f.id)
	if foe != null:
		_ensure_pairs(f.id, foe.id)
	if anims.is_empty():
		return []
	if anims.has("grabbed"):
		var pose := grab_pose(f, foe)
		if pose >= 0:
			return _pick(anims.grabbed, mini(pose, anims.grabbed.tex.size() - 1))
	match f.state:
		Fighter.State.ATTACK:
			var name: String = Fighter.MOVES[f.move]
			if f.alt_hand() and anims.has(name + "_b"):
				name += "_b"  # тот же удар подряд — другой рукой
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
				if anims[key].cycle > 0:
					# Блок из видео — цикл дыхания (держит блок и пропускает удары в нём же).
					return _pick(anims[key], _cycle(tick, anims[key].cycle, n))
				if n > 2 and f.state == Fighter.State.BLOCKSTUN:
					# Блок из видео: 1-й кадр — защита, остальные — принял удар и выровнялся (по ходу оглушения).
					return _pick(anims[key], 1 + _progress(f, n - 1))
				if f.state == Fighter.State.BLOCK:
					return [anims[key].tex[0], anims[key].pivot[0], true]  # держит блок и дышит
				return _pick(anims[key], mini(1, n - 1))
		Fighter.State.HITSTUN:
			# Получил удар: удар → откинулся → сильнее всего откинулся; в конце оглушения — приходит в себя.
			var key: String = "hit_low" if f.low_pose else HIT_KEYS[clampi(f.hit_kind, 0, 3)]
			if not anims.has(key):
				key = "hit_low" if f.low_pose else "hit_high"  # своей реакции ещё нет — общая
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
			var gkey := _grab_anim(anims, f)
			var pkey := pair_key(f, foe)
			if pkey != "" and anims.has(pkey):
				gkey = pkey  # парная сцена: оба бойца в одном ролике, соперник не рисуется
			if gkey != "" and gkey != "throw":
				# Захват из видео со своей анимацией (мельница, суперприём): по ходу удержания до release.
				_last_grab[f] = gkey
				var ga: Dictionary = anims[gkey]
				var gg: Dictionary = Sim.grab_of(f, foe.id if foe != null else "")
				var gt := clampf(1.0 - float(f.stun) / maxi(int(gg.get("hold", 30)), 1), 0.0, 1.0)
				var a0: int = ga.hit
				var rel: int = mini(ga.release - 1, ga.tex.size() - 1)
				return _pick(ga, a0 + roundi(gt * (rel - a0)))
			if anims.has("throw") and f.move >= 0:
				_last_grab[f] = "throw"
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
		Fighter.State.AIR_HIT when tumble_angle(f) != 0.0 and anims.has("grabbed") and anims.grabbed.tex.size() > 2:
			return _pick(anims.grabbed, 2)  # подброшен высоко — кувыркается (поза «летит», крутит игра)
		Fighter.State.AIR_HIT:
			# Полёт после удара: кадры полёта по очереди (откинуло → летит → почти лёг).
			if anims.has("fall"):
				if anims.fall.tex.size() > 8:
					return _pick(anims.fall, mini(f.state_frame / 3, anims.fall.air - 1))  # из видео: кадров больше
				return _pick(anims.fall, mini(f.state_frame / 6, anims.fall.air - 1))
		Fighter.State.KNOCKDOWN:
			# Удар о землю → подскок → лежит → встаёт (последние кадры).
			var up := Fighter.KNOCKDOWN_TICKS - f.state_frame
			var gu := GET_UP_TICKS_VIDEO if anims.has("get_up") and anims.get_up.tex.size() > 8 else GET_UP_TICKS
			if anims.has("get_up") and up <= gu:
				var n: int = anims.get_up.tex.size()
				return _pick(anims.get_up, clampi((gu - up) * n / gu, 0, n - 1))
			if anims.has("fall") and anims.fall.tex.size() > 8:
				# Из видео: удар о землю и подскок по кадрам, потом лежит (последний кадр).
				var nf: int = anims.fall.tex.size()
				var af: int = anims.fall.air
				return _pick(anims.fall, mini(af + f.state_frame * (nf - af) / LAND_TICKS_VIDEO, nf - 1))
			if anims.has("fall"):
				var n: int = anims.fall.tex.size()
				var air: int = anims.fall.air
				var i := air if f.state_frame < 5 else (air + 1 if f.state_frame < 10 else n - 2)
				return _pick(anims.fall, mini(i, n - 1))
		Fighter.State.DOWN:
			if anims.has("fall") and anims.fall.tex.size() > 8:
				return _pick(anims.fall, anims.fall.tex.size() - 1)  # из видео: лежит без сознания
			if anims.has("fall"):
				var n: int = anims.fall.tex.size()
				var air: int = anims.fall.air
				var i := air if f.state_frame < 5 else (air + 1 if f.state_frame < 10 else n - 2 + (tick / 40) % 2)
				return _pick(anims.fall, mini(i, n - 1))
		Fighter.State.PREJUMP:
			if anims.has("jump"):
				# Прыжок из 8 кадров: присед, потом толчок.
				var n0: int = anims.jump.tex.size()
				return _pick(anims.jump, 1 if n0 == 8 and f.state_frame * 2 >= f.data.prejump else 0)
		Fighter.State.AIR:
			# Удар в прыжке — свои кадры, если нарисованы.
			if f.move >= 0 and anims.has(Fighter.MOVES[f.move]):
				var air: Dictionary = anims[Fighter.MOVES[f.move]]
				return _pick(air, _attack_index(f, air))
			# Прыжок из видео (больше 8 кадров): 1-й — присед, последние JUMP_LAND_FRAMES — приземление,
			# между ними — полёт по ходу прыжка (от толчка до земли).
			if anims.has("jump") and f.move < 0 and anims.jump.tex.size() > 8:
				var nj: int = anims.jump.tex.size()
				var air_n: int = nj - 1 - JUMP_LAND_FRAMES
				var p := clampf((1.0 - float(f.vy) / f.data.jump_vy) * 0.5, 0.0, 1.0)
				if f.vx != 0:
					# Кувырок: до оборота — взлёт кадрами до «сгруппировался», весь оборот — сгруппированные
					# кадры (крутит игра), после — раскрывается к земле.
					var tk: Vector2i = _tuck(anims.jump)
					var j: float
					if p < FLIP_FROM:
						j = lerpf(1.0, tk.x, p / FLIP_FROM)
					elif p < FLIP_TO:
						j = lerpf(tk.x, tk.y, (p - FLIP_FROM) / (FLIP_TO - FLIP_FROM))
					else:
						j = lerpf(tk.y, air_n, (p - FLIP_TO) / (1.0 - FLIP_TO))
					return _pick(anims.jump, clampi(roundi(j), 1, air_n))
				return _pick(anims.jump, 1 + mini(int(p * air_n), air_n - 1))
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
				if flip_angle(f) != 0.0:
					i8 = 3  # кувырок — сгруппировался
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
		Fighter.State.LAND when f.throw_follow and anims.has(_last_grab.get(f, "throw")):
			# Только что бросил — доводит движение (у броска из видео — кадры после release, иначе последний).
			var ta: Dictionary = anims[_last_grab.get(f, "throw")]
			var nt: int = ta.tex.size()
			if ta.release > 0:
				var rel: int = mini(ta.release - 1, nt - 1)
				var rest: int = nt - 1 - rel
				return _pick(ta, rel + clampi(f.state_frame * rest / maxi(f.landing_frames, 1), 0, rest))
			return _pick(ta, nt - 1)
		Fighter.State.LAND:
			if anims.has("jump"):
				var nl: int = anims.jump.tex.size()
				if nl > 8:
					# Приземление из видео: последние кадры листа по ходу приземления.
					var k := clampi(f.state_frame * JUMP_LAND_FRAMES / maxi(f.landing_frames, 1), 0, JUMP_LAND_FRAMES - 1)
					return _pick(anims.jump, nl - JUMP_LAND_FRAMES + k)
				return _pick(anims.jump, nl - 1)
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


## Подъём кадров (sheets.json "lift": боец в ролике улетает вверх), px игры по кадрам; пусто — подъёма нет.
static func _lift_list(meta: Dictionary, n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if not meta.has("lift"):
		return out
	out.resize(n)
	var k := SCALE / float(meta.get("res", 1.0))
	for key in meta.lift:
		var i := int(key) - 1
		if i >= 0 and i < n:
			out[i] = float(meta.lift[key]) * k
	return out


## На сколько px игры захват из видео (суперприём) поднял бойца на текущем кадре — схваченного держат на той же высоте.
func visual_lift(f: Fighter) -> float:
	if f.state != Fighter.State.THROWING:
		return 0.0
	var anims: Dictionary = _char(f.id)
	var gkey := _grab_anim(anims, f)
	if gkey == "" or not anims.has(gkey) or anims[gkey].lift.is_empty():
		return 0.0
	var ga: Dictionary = anims[gkey]
	var gm := f.move_data()
	var gg: Dictionary = gm.grab if gm.has("grab") else gm.get("cinema", {"hold": 30})
	var gt := clampf(1.0 - float(f.stun) / maxi(int(gg.hold), 1), 0.0, 1.0)
	var rel: int = mini(ga.release - 1, ga.tex.size() - 1)
	var i: int = ga.hit + roundi(gt * (rel - ga.hit))
	return ga.lift[clampi(i, 0, ga.lift.size() - 1)]


## Кувырок в прыжке вперёд/назад (рисует игра: кадр «сгруппировался» крутится на полный оборот вокруг
## середины тела): угол поворота по ходу полёта, по часовой — вперёд; 0 — не кувыркается.
const FLIP_FROM := 0.2    # доля полёта, где начинается оборот…
const FLIP_TO := 0.8      # …и где заканчивается (дальше — раскрылся к приземлению)
static func flip_angle(f: Fighter) -> float:
	if f.state != Fighter.State.AIR or f.move >= 0 or f.vx == 0 or f.data.jump_vy <= 0:
		return 0.0
	var p := clampf((1.0 - float(f.vy) / f.data.jump_vy) * 0.5, 0.0, 1.0)
	if p <= FLIP_FROM or p >= FLIP_TO:
		return 0.0
	var t := smoothstep(FLIP_FROM, FLIP_TO, p)
	var forward := signi(f.vx) == f.facing
	return TAU * t * (1.0 if forward else -1.0)


## Сгруппированные кадры прыжка из видео (самые низкие по высоте рисунка в середине полёта): [первый, последний].
func _tuck(a: Dictionary) -> Vector2i:
	if a.has("tuck"):
		return a.tuck
	var n: int = a.tex.size() - JUMP_LAND_FRAMES
	var lo := 1
	for i in range(1, n):
		if a.tex[i].get_height() < a.tex[lo].get_height():
			lo = i
	var limit: float = a.tex[lo].get_height() * 1.08
	var first := lo
	var last := lo
	while first > 1 and a.tex[first - 1].get_height() <= limit:
		first -= 1
	while last < n - 1 and a.tex[last + 1].get_height() <= limit:
		last += 1
	a["tuck"] = Vector2i(first, last)
	return a.tuck


## Реакции на удар стоя по hit_kind: голова, голова сильно, корпус, ноги (нет листа — общая hit_high).
const HIT_KEYS := ["hit_high", "hit_heavy", "hit_body", "hit_legs"]
## Подброшен высоко (апперкот, жонглирование): кувыркается назад через голову на полный оборот за полёт.
const TUMBLE_VY := 1300
static func tumble_angle(f: Fighter) -> float:
	if f.state != Fighter.State.AIR_HIT or f.thrown_air or f.hp <= 0:
		return 0.0
	var g: int = f.data.gravity
	var v0: int = f.vy + g * f.state_frame  # скорость подброса
	if v0 < TUMBLE_VY or g <= 0:
		return 0.0
	var t := float(f.state_frame) / (2.0 * v0 / g * 0.8)
	if t >= 1.0:
		return 0.0
	return -TAU * smoothstep(0.0, 1.0, t)


## Лист парной сцены захвата: суперприём — pair_<соперник>, бросок — pair_throw_<соперник>,
## приём-захват — pair_<приём>_<соперник>; "" — нет.
static func pair_key(f: Fighter, foe: Fighter) -> String:
	if foe == null or f.move < 0:
		return ""
	if f.move == Fighter.MOVE_SUPER:
		return "pair_" + foe.id
	if f.move == Fighter.MOVE_THROW:
		return "pair_throw_" + foe.id
	if f.move_data().has("grab"):
		# Приём-захват (мельница): pair_sp_ff_l_<id>, у сильной версии — тот же лист.
		return "pair_%s_%s" % [String(Fighter.MOVES[f.move]).replace("_h", "_l"), foe.id]
	return ""


## Соперника f сейчас рисует парная сцена того, кто его держит (лист pair_<id> / pair_throw_<id>): во время
## захвата и пока бросивший доигрывает ролик после броска (соперник в ролике летит и падает).
func in_pair_scene(f: Fighter, foe: Fighter) -> bool:
	if foe == null:
		return false
	if f.state == Fighter.State.THROWN and foe.state == Fighter.State.THROWING:
		_ensure_pairs(foe.id, f.id)
		return _char(foe.id).has(pair_key(foe, f))
	return foe.state == Fighter.State.LAND and foe.throw_follow \
			and String(_last_grab.get(foe, "")).begins_with("pair_")


## Анимация, которую боец доигрывает после броска (кадры после release), или "" — не доигрывает.
func follow_anim(f: Fighter) -> String:
	if f.state != Fighter.State.LAND or not f.throw_follow:
		return ""
	return String(_last_grab.get(f, ""))


## Реакция на захват (лист grabbed: 0 — схвачен за плечи, 1 — вниз головой за лодыжку, 2 — летит после броска,
## 3 — обмяк после укуса) или -1. Поза — по приёму того, кто держит: укус (захват с лечением) — схвачен, потом
## обмяк; мельница (захват-приём без лечения) — вниз головой; бросок — схвачен, через плечо — летит; суперприём
## с укусом — как укус, иначе — схвачен.
static func grab_pose(f: Fighter, foe: Fighter) -> int:
	if f.state == Fighter.State.AIR_HIT and f.thrown_air:
		return 2
	if f.state != Fighter.State.THROWN or foe == null or foe.state != Fighter.State.THROWING or foe.move < 0:
		return -1
	var m := foe.move_data()
	var g: Dictionary = m.grab if m.has("grab") else m.get("cinema", {})
	var t := Sim.throw_progress(foe)
	if g.has("heal"):
		if foe.move == Fighter.MOVE_SUPER:
			return 0 if foe.state_frame < 40 else 3
		return 0 if t < 0.4 else 3
	if foe.move == Fighter.MOVE_THROW:
		return 2 if g.get("over", 0) and t > Sim.THROW_GRIP else 0
	if foe.move != Fighter.MOVE_SUPER and m.has("grab"):
		return 1
	return 0


## Анимация захвата бойца: своя у приёма (мельница), у суперприёма — super_cinema, иначе обычный бросок.
static func _grab_anim(anims: Dictionary, f: Fighter) -> String:
	if f.move < 0:
		return ""
	var name: String = Fighter.MOVES[f.move]
	if f.move == Fighter.MOVE_SUPER and anims.has("super_cinema"):
		return "super_cinema"
	if anims.has(name) and anims[name].release > 0:
		return name
	return "throw" if anims.has("throw") else ""


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
