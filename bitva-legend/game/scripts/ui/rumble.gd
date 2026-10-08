class_name Rumble
extends RefCounted
## Вибрация геймпадов. Как и звук, только читает состояние Sim и по изменениям между тиками
## понимает, что случилось: кого ударили, кто поставил блок, кого сбили с ног.
## Сила умножается на настройку «Вибрация» (Settings.rumble).

## [слабый мотор, сильный мотор, секунды] для каждого события.
const HIT_LIGHT := [0.35, 0.15, 0.10]
const HIT_HEAVY := [0.55, 0.65, 0.20]
const BLOCK := [0.30, 0.0, 0.08]
const PARRY := [0.0, 0.0, 0.0]         # парирование — тишина (на нём и так пауза со вспышкой)
const PARRIED := [0.6, 0.3, 0.25]      # тебя парировали — ошеломлён
const ATTACKER := [0.15, 0.0, 0.06]    # «отдача» в руку атакующему
const KNOCKDOWN := [0.4, 0.8, 0.30]
const THROWN := [0.3, 0.6, 0.25]
const SUPER := [0.5, 0.5, 0.45]
const KO := [0.8, 1.0, 0.70]

## Сколько раз включалась вибрация (для тестов).
var pulses := 0
var _last_tick := -1
var _last_spark := PackedInt32Array([-999, -999])
var _last_state := PackedInt32Array([-1, -1])
var _last_phase := -1
var _last_flash := 0


## Каждый тик боя. reader — чтобы знать, у кого какой геймпад.
func update(sim: Sim, reader: InputReader) -> void:
	if sim.tick == _last_tick:
		return
	var fresh := _last_tick < 0 or sim.tick < _last_tick
	_last_tick = sim.tick
	if fresh:
		_last_spark = PackedInt32Array([sim.sparks[0], sim.sparks[4]])
		_last_state = PackedInt32Array([sim.fighters[0].state, sim.fighters[1].state])
		_last_phase = sim.phase
		return
	for p in 2:
		var t := sim.sparks[p * 4]
		if t != _last_spark[p]:
			_on_spark(p, sim.sparks[p * 4 + 3], reader)
		_last_spark[p] = t
	for p in 2:
		var st := sim.fighters[p].state
		if st != _last_state[p]:
			if st == Fighter.State.KNOCKDOWN:
				_pulse(p, KNOCKDOWN, reader)
			elif st == Fighter.State.THROWN:
				_pulse(p, THROWN, reader)
		_last_state[p] = st
	# Суперприём: пауза с затемнением — дрожат оба.
	if sim.hitstop >= Sim.SUPER_FLASH - 1 and sim.hitstop_total == 0 and _last_flash != sim.tick - 1:
		for p in 2:
			_pulse(p, SUPER, reader)
		_last_flash = sim.tick
	if sim.phase != _last_phase:
		if sim.phase == Sim.Phase.ROUND_END and sim.end_reason == Sim.EndReason.KO:
			for p in 2:
				_pulse(p, KO, reader)
		_last_phase = sim.phase


## Искра игрока p: p — тот, кто ударил (kind 0–1 попадание, 2 блок, 3 броня),
## или защитник для парирования (5) и контратаки (4): в этих случаях Sim пишет искру защитнику.
func _on_spark(p: int, kind: int, reader: InputReader) -> void:
	match kind:
		0:
			_pulse(1 - p, HIT_LIGHT, reader)
			_pulse(p, ATTACKER, reader)
		1:
			_pulse(1 - p, HIT_HEAVY, reader)
			_pulse(p, ATTACKER, reader)
		2, 3:
			_pulse(1 - p, BLOCK, reader)
		4, 5:
			_pulse(1 - p, PARRIED, reader)


func _pulse(p: int, motors: Array, reader: InputReader) -> void:
	var k: float = Settings.RUMBLE_SCALE[Settings.rumble]
	if k <= 0.0 or motors[2] <= 0.0:
		return
	pulses += 1
	for pad in _pads(p, reader):
		Input.start_joy_vibration(pad, minf(motors[0] * k, 1.0), minf(motors[1] * k, 1.0), motors[2])


## Геймпады игрока: против ИИ первым управляет любой геймпад — вибрируют все.
static func _pads(p: int, reader: InputReader) -> Array:
	if reader.single_player:
		return Input.get_connected_joypads() if p == 0 else []
	var pad := reader.pad_for(p)
	return [pad] if pad >= 0 else []
