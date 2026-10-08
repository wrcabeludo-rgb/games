class_name Sim
extends RefCounted
## Детерминированная симуляция боя.
## Правила: только целые числа, никакого времени кадра, никакого рандома без сида.
## Всё состояние сохраняется и восстанавливается через save_state/load_state —
## это основа будущего rollback-онлайна.

const PLAYERS := 2
const HISTORY_LEN := 24
const MAX_HOLD_FRAMES := 999

var tick := 0
var inputs := PackedInt32Array([0, 0])
## История ввода по игрокам: записи [биты, сколько тиков удерживались], новые — первыми.
var history: Array = [[], []]


func step(frame_inputs: PackedInt32Array) -> void:
	for p in PLAYERS:
		var bits := InputBits.clean_socd(frame_inputs[p])
		inputs[p] = bits
		var h: Array = history[p]
		if h.is_empty() or h[0][0] != bits:
			h.push_front([bits, 1])
			if h.size() > HISTORY_LEN:
				h.pop_back()
		else:
			h[0][1] = mini(h[0][1] + 1, MAX_HOLD_FRAMES)
	tick += 1


func save_state() -> Dictionary:
	return {
		"tick": tick,
		"inputs": inputs.duplicate(),
		"history": history.duplicate(true),
	}


func load_state(state: Dictionary) -> void:
	tick = state.tick
	inputs = state.inputs.duplicate()
	history = state.history.duplicate(true)


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
	return h


static func _mix(h: int, value: int) -> int:
	h = (h ^ (value & 0xFFFFFFFF)) & 0xFFFFFFFF
	return (h * 16777619) & 0xFFFFFFFF
