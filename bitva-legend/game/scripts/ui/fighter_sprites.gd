class_name FighterSprites
extends RefCounted
## Спрайты бойцов из game/art/fighters/<боец>/ (готовит tools/process_fighter_art.py, см. docs/ART_FIGHTERS.md).
## Для каждой анимации: <имя>.json (кадры и опорные точки) и <имя>_<N>.png.
## Если для состояния бойца анимации нет — возвращается пусто, и рисуется заглушка из фигур.

const ART_DIR := "res://art/fighters/"
const SCALE := 0.5          # кадры нарисованы для 1440p, игра считает в 720p
const IDLE_TICKS := 9       # длительность кадра стойки, тиков

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
			out[file.get_basename()] = {"tex": tex, "pivot": pivots}
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
				return _pick(anims[name], _attack_index(f, anims[name].tex.size()))
		Fighter.State.STAND, Fighter.State.WALK_F, Fighter.State.WALK_B, Fighter.State.LAND, \
				Fighter.State.RUN_STOP, Fighter.State.PREJUMP:
			# Пока нет ходьбы — стойка (боец «скользит»; ходьба появится в 3.3).
			if anims.has("idle"):
				return _pick(anims.idle, (tick / IDLE_TICKS) % anims.idle.tex.size())
	return []


static func _pick(anim: Dictionary, i: int) -> Array:
	return [anim.tex[i], anim.pivot[i]]


## Ключевые кадры удара: до «ударного» кадра — подготовка, «ударный» (2-й) — активная фаза, после — возврат.
static func _attack_index(f: Fighter, n: int) -> int:
	if n <= 1:
		return 0
	var m := f.move_data()
	var hit := 1
	match f.move_phase():
		0:
			return clampi(f.move_frame * hit / maxi(m.startup, 1), 0, hit - 1)
		1:
			return hit
		_:
			var rest := n - 1 - hit
			if rest <= 0:
				return hit
			var rec: int = maxi(m.get("recovery", 1), 1)
			var t: int = f.move_frame - m.startup - m.active
			return hit + 1 + clampi(t * rest / rec, 0, rest - 1)
