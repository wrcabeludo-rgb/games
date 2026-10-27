extends SceneTree
## Перепрыгивание соперника (3.17.56) и нокаут парной сценой (соперник сразу лежит, без полёта нокаута).

const SUB := Fighter.SUB
const S := Fighter.State
const R := InputBits.RIGHT
const UP := InputBits.UP
const LP := InputBits.LP
const BL := InputBits.BLOCK


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	ok = _check("прыжок вперёд вплотную — перелетает через соперника", _test_cross(["ilya", "dracula"])) and ok
	ok = _check("Дракула тоже перепрыгивает Илью", _test_cross(["dracula", "ilya"])) and ok
	ok = _check("прыжок на месте вплотную — остаётся со своей стороны", _test_straight_up()) and ok
	ok = _check("на земле сквозь соперника не пройти", _test_no_walk_through()) and ok
	ok = _check("нокаут броском-сценой: соперник лежит на земле, не летит", _test_pair_ko()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _sim_at(pair: Array, a_px: int, b_px: int) -> Sim:
	var sim := Sim.new(false, PackedStringArray(pair))
	sim.fighters[0].x = a_px * SUB
	sim.fighters[1].x = b_px * SUB
	return sim


func _run(sim: Sim, p1: int, p2: int, ticks := 1) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


func _touching(sim: Sim) -> int:
	return (sim.fighters[0].push_half() + sim.fighters[1].push_half()) / SUB


func _test_cross(pair: Array) -> bool:
	var sim := _sim_at(pair, 900, 900)
	sim.fighters[1].x = sim.fighters[0].x + _touching(sim) * SUB
	_run(sim, UP | R, 0)
	_run(sim, R, 0, 90)
	var a := sim.fighters[0]
	var b := sim.fighters[1]
	return a.x > b.x and a.y == 0 and absi(a.x - b.x) >= a.push_half() + b.push_half() - SUB


func _test_straight_up() -> bool:
	var sim := _sim_at(["ilya", "dracula"], 900, 900)
	sim.fighters[1].x = sim.fighters[0].x + _touching(sim) * SUB
	_run(sim, UP, 0)
	_run(sim, 0, 0, 90)
	return sim.fighters[0].x < sim.fighters[1].x and sim.fighters[0].y == 0


func _test_no_walk_through() -> bool:
	var sim := _sim_at(["ilya", "dracula"], 900, 1000)
	_run(sim, R, 0, 120)
	return sim.fighters[0].x < sim.fighters[1].x


func _test_pair_ko() -> bool:
	var sim := _sim_at(["ilya", "dracula"], 900, 995)
	sim.fighters[1].hp = 20
	_run(sim, LP, BL)
	var throwing := false
	var down := 0
	for i in 100:
		_run(sim, 0, 0)
		throwing = throwing or sim.fighters[0].state == S.THROWING
		var d := sim.fighters[1]
		if d.hp == 0:
			if d.state != S.DOWN or d.y != 0:
				return false  # нокаут — сразу лежит на земле
			down += 1
	return throwing and down > 20
