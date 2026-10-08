extends SceneTree
## Автотесты движения (подэтап 1.2).

const SUB := Fighter.SUB
const R := InputBits.RIGHT
const L := InputBits.LEFT
const U := InputBits.UP
const D := InputBits.DOWN


func _init() -> void:
	var ok := true
	ok = _check("ходьба вперёд: Илья 2.6 px/тик", _test_walk()) and ok
	ok = _check("ходьба назад медленнее, чем вперёд", _test_walk_back()) and ok
	ok = _check("прыжок вверх: высота и возврат на землю", _test_jump()) and ok
	ok = _check("присед, пока держишь вниз", _test_crouch()) and ok
	ok = _check("бойцы не проходят друг сквозь друга", _test_push()) and ok
	ok = _check("прыжок через соперника и разворот", _test_crossup()) and ok
	ok = _check("стена арены", _test_wall()) and ok
	ok = _check("нельзя разойтись дальше кадра", _test_separation()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _run(sim: Sim, p1: int, p2: int, ticks: int) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


func _test_walk() -> bool:
	var sim := Sim.new()
	var x0 := sim.fighters[0].x
	_run(sim, R, 0, 30)
	return sim.fighters[0].x - x0 == 30 * 260 and sim.fighters[0].state == Fighter.State.WALK_F


func _test_walk_back() -> bool:
	var sim := Sim.new()
	var x0 := sim.fighters[0].x
	_run(sim, L, 0, 30)
	var back := x0 - sim.fighters[0].x
	return back == 30 * 210 and sim.fighters[0].state == Fighter.State.WALK_B


func _test_jump() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	var apex := 0
	_run(sim, U, 0, 1)
	for i in 200:
		sim.step(PackedInt32Array([0, 0]))
		apex = maxi(apex, f.y)
		if f.state == Fighter.State.STAND:
			break
	var apex_px := apex / SUB
	return f.state == Fighter.State.STAND and f.y == 0 and apex_px >= 170 and apex_px <= 190


func _test_crouch() -> bool:
	var sim := Sim.new()
	_run(sim, D, 0, 10)
	var crouching := sim.fighters[0].state == Fighter.State.CROUCH
	_run(sim, 0, 0, 1)
	return crouching and sim.fighters[0].state == Fighter.State.STAND


func _test_push() -> bool:
	var sim := Sim.new()
	_run(sim, R, 0, 300)
	var a := sim.fighters[0]
	var b := sim.fighters[1]
	return b.x - a.x >= a.push_half() + b.push_half() and b.x > a.x


func _test_crossup() -> bool:
	var sim := Sim.new()
	var ilya := sim.fighters[0]
	var drac := sim.fighters[1]
	ilya.x = 900 * SUB
	drac.x = 990 * SUB
	_run(sim, D, L | U, 4)
	_run(sim, D, L, 80)
	return drac.x < ilya.x and drac.facing == 1 and ilya.facing == -1 \
		and absi(drac.x - ilya.x) >= ilya.push_half() + drac.push_half()


func _test_wall() -> bool:
	var sim := Sim.new()
	_run(sim, L, L, 1200)  # Дракула идёт следом и прижимает Илью к стене
	var a := sim.fighters[0]
	return a.x == a.push_half()


func _test_separation() -> bool:
	var sim := Sim.new()
	var max_sep := 0
	for i in 600:
		sim.step(PackedInt32Array([L, R]))
		max_sep = maxi(max_sep, absi(sim.fighters[1].x - sim.fighters[0].x))
	return max_sep <= Sim.MAX_SEPARATION * SUB and max_sep >= (Sim.MAX_SEPARATION - 5) * SUB
