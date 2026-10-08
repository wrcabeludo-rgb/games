class_name Sim
extends RefCounted
## Детерминированная симуляция боя.
## Правила: только целые числа, никакого времени кадра, никакого рандома без сида.
## Всё состояние сохраняется и восстанавливается через save_state/load_state —
## это основа будущего rollback-онлайна.

const PLAYERS := 2
const HISTORY_LEN := 24
const MAX_HOLD_FRAMES := 999

const ARENA_WIDTH := 2000           # ширина арены, пикселей
const START_GAP := 440              # расстояние между бойцами в начале раунда
const MAX_SEPARATION := 1100        # дальше не разойтись: оба должны помещаться в кадр
const SUB := Fighter.SUB

var tick := 0
var inputs := PackedInt32Array([0, 0])
## История ввода по игрокам: записи [биты, сколько тиков удерживались], новые — первыми.
var history: Array = [[], []]
var fighters: Array[Fighter] = []


func _init() -> void:
	reset_round()


@warning_ignore("integer_division")
func reset_round() -> void:
	var center := ARENA_WIDTH / 2
	fighters = [
		Fighter.new("ilya", center - START_GAP / 2, 1),
		Fighter.new("dracula", center + START_GAP / 2, -1),
	]


func step(frame_inputs: PackedInt32Array) -> void:
	for p in PLAYERS:
		var bits := InputBits.clean_socd(frame_inputs[p])
		inputs[p] = bits
		_record_history(p, bits)

	var prev_x := PackedInt32Array([fighters[0].x, fighters[1].x])
	for p in PLAYERS:
		fighters[p].step(inputs[p])
	_resolve_push()
	_limit_separation(prev_x)
	_clamp_walls()
	_update_facing()
	tick += 1


func _record_history(p: int, bits: int) -> void:
	var h: Array = history[p]
	if h.is_empty() or h[0][0] != bits:
		h.push_front([bits, 1])
		if h.size() > HISTORY_LEN:
			h.pop_back()
	else:
		h[0][1] = mini(h[0][1] + 1, MAX_HOLD_FRAMES)


## Бойцы не проходят друг сквозь друга. На взлёте столкновения нет, а в воздухе
## «тело» ниже — так можно перепрыгнуть соперника (кросс-ап).
func _resolve_push() -> void:
	var a := fighters[0]
	var b := fighters[1]
	if a.is_rising() or b.is_rising():
		return
	var vertical := a.y < b.y + b.push_height() and b.y < a.y + a.push_height()
	if not vertical:
		return
	var overlap := a.push_half() + b.push_half() - absi(b.x - a.x)
	if overlap <= 0:
		return
	var s := signi(b.x - a.x)
	if s == 0:
		s = a.facing
	@warning_ignore("integer_division")
	var half := overlap / 2
	a.x -= half * s
	b.x += (overlap - half) * s
	# Если один упёрся в стену, отодвигаем второго.
	_clamp_walls()
	var rest := a.push_half() + b.push_half() - absi(b.x - a.x)
	if rest > 0:
		if _at_wall(a):
			b.x += rest * s
		else:
			a.x -= rest * s


## Нельзя разойтись дальше, чем помещается в кадр: отменяем шаг «наружу».
func _limit_separation(prev_x: PackedInt32Array) -> void:
	var sep := absi(fighters[1].x - fighters[0].x)
	var excess := sep - MAX_SEPARATION * SUB
	if excess <= 0:
		return
	var left := 0 if fighters[0].x < fighters[1].x else 1
	var right := 1 - left
	var left_out := maxi(prev_x[left] - fighters[left].x, 0)
	var right_out := maxi(fighters[right].x - prev_x[right], 0)
	var fix := mini(excess, left_out)
	fighters[left].x += fix
	excess -= fix
	fix = mini(excess, right_out)
	fighters[right].x -= fix


func _clamp_walls() -> void:
	for f in fighters:
		f.x = clampi(f.x, f.push_half(), ARENA_WIDTH * SUB - f.push_half())


func _at_wall(f: Fighter) -> bool:
	return f.x <= f.push_half() or f.x >= ARENA_WIDTH * SUB - f.push_half()


## Бойцы разворачиваются к сопернику, только стоя на земле.
func _update_facing() -> void:
	for p in PLAYERS:
		var f := fighters[p]
		var other := fighters[1 - p]
		if not (f.is_grounded_actionable() or f.state == Fighter.State.LAND):
			continue
		if other.x > f.x:
			f.facing = 1
		elif other.x < f.x:
			f.facing = -1


func save_state() -> Dictionary:
	return {
		"tick": tick,
		"inputs": inputs.duplicate(),
		"history": history.duplicate(true),
		"fighters": [fighters[0].save(), fighters[1].save()],
	}


func load_state(state: Dictionary) -> void:
	tick = state.tick
	inputs = state.inputs.duplicate()
	history = state.history.duplicate(true)
	for p in PLAYERS:
		fighters[p].load(state.fighters[p])


## Контрольная сумма состояния (FNV-1a по целым числам).
## Одинаковая на любых машинах — по ней будем ловить рассинхрон в онлайне.
func checksum() -> int:
	var h := 2166136261
	h = _mix(h, tick)
	for p in PLAYERS:
		h = _mix(h, inputs[p])
		for entry in history[p]:
			h = _mix(h, entry[0])
			h = _mix(h, entry[1])
		for v in fighters[p].save():
			h = _mix(h, v)
	return h


static func _mix(h: int, value: int) -> int:
	h = (h ^ (value & 0xFFFFFFFF)) & 0xFFFFFFFF
	return (h * 16777619) & 0xFFFFFFFF
