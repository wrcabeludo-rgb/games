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
const PING_PONG_MAX := 5    # до стольких кадров стойка идёт туда-обратно (1-2-3-2), больше — нарисован цикл

## id бойца → {анимация: {"tex": Array[Texture2D], "pivot": Array[Vector2]}}
var _bank := {}


func _init() -> void:
	for id in FighterData.CHARACTERS:
		_bank[id] = _load_character(id)


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
				"hit_end": clampi(hit_end, hit, n - 1), "reverse": bool(meta.get("reverse", false))}
	return out


func has_any(id: String) -> bool:
	return not _bank.get(id, {}).is_empty()


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
				return _pick(anims.walk_f, _cycle(f.state_frame, WALK_CYCLE, anims.walk_f.tex.size()))
		Fighter.State.WALK_B:
			# Шаг назад — кадры ходьбы в обратном порядке.
			var key := "walk_b" if anims.has("walk_b") else "walk_f"
			if anims.has(key):
				var n: int = anims[key].tex.size()
				# Лист шага вперёд (или помеченный reverse) — задом наперёд.
				var i := _cycle(f.state_frame, WALK_CYCLE, n)
				var reverse: bool = key == "walk_f" or anims[key].reverse
				return _pick(anims[key], n - 1 - i if reverse else i)
		Fighter.State.RUN:
			if anims.has("run"):
				return _pick(anims.run, _cycle(f.state_frame, RUN_CYCLE, anims.run.tex.size()))
		Fighter.State.CROUCH:
			if anims.has("crouch"):
				return _pick(anims.crouch, 0 if f.state_frame < 3 else anims.crouch.tex.size() - 1)
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			# Блок: 1-й кадр — стойка в блоке, 2-й — принял удар (оглушение в блоке).
			var key := "block_low" if f.low_pose else "block"
			if anims.has(key):
				var n: int = anims[key].tex.size()
				return _pick(anims[key], mini(1 if f.state == Fighter.State.BLOCKSTUN else 0, n - 1))
		Fighter.State.PREJUMP:
			if anims.has("jump"):
				return _pick(anims.jump, 0)
		Fighter.State.AIR:
			# Прыжок: взлёт → верх (сгруппировался) → падение. Удар в прыжке — пока заглушкой (нет кадров).
			if anims.has("jump") and f.move < 0:
				var n: int = anims.jump.tex.size()
				var i := 1
				if absi(f.vy) < 500:
					i = 2
				elif f.vy < 0:
					i = 3
				return _pick(anims.jump, mini(i, n - 1))
		Fighter.State.LAND:
			if anims.has("jump"):
				return _pick(anims.jump, anims.jump.tex.size() - 1)
		Fighter.State.BACKDASH:
			if anims.has("backdash"):
				var n: int = anims.backdash.tex.size()
				var moving: int = (f.data.backdash_v0 + f.data.backdash_decel - 1) / f.data.backdash_decel
				var i := 0 if f.state_frame < 3 else (1 if f.state_frame < moving else n - 1)
				return _pick(anims.backdash, mini(i, n - 1))
	match f.state:
		Fighter.State.STAND, Fighter.State.WALK_F, Fighter.State.WALK_B, Fighter.State.LAND, \
				Fighter.State.RUN_STOP, Fighter.State.PREJUMP, Fighter.State.RUN, Fighter.State.BACKDASH:
			if anims.has("idle"):
				var n: int = anims.idle.tex.size()
				if n <= PING_PONG_MAX:
					return _pick(anims.idle, _ping_pong(tick * (2 * n - 2) / IDLE_CYCLE, n))
				return _pick(anims.idle, _cycle(tick, IDLE_CYCLE, n))
	return []


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
