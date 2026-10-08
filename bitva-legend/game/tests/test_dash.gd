extends SceneTree
## Автотесты бега и отскока (подэтап 1.3).

const SUB := Fighter.SUB
const R := InputBits.RIGHT
const L := InputBits.LEFT
const U := InputBits.UP
const S := Fighter.State


func _init() -> void:
	var ok := true
	ok = _check("двойное «вперёд» → бег, скорость растёт до максимума", _test_run()) and ok
	ok = _check("медленное двойное нажатие → обычный шаг", _test_slow_tap()) and ok
	ok = _check("отпустил «вперёд» → торможение и стойка", _test_run_stop()) and ok
	ok = _check("двойное «назад» → отскок ~96 px, потом стойка", _test_backdash()) and ok
	ok = _check("во время отскока нельзя идти", _test_backdash_commit()) and ok
	ok = _check("прыжок с разбега дальше обычного", _test_run_jump()) and ok
	ok = _check("соперник за спиной → бег прерывается", _test_run_side_switch()) and ok
	ok = _check("Дракула бегает быстрее Ильи", _test_dracula_faster()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


## Подаёт игроку 1 последовательность [биты, тиков]; игрок 2 стоит.
func _play(sim: Sim, seq: Array) -> void:
	for step in seq:
		for i in step[1]:
			sim.step(PackedInt32Array([step[0], 0]))


func _test_run() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	f.x = 300 * SUB  # подальше от соперника
	_play(sim, [[R, 2], [0, 2], [R, 1]])
	var started := f.state == S.RUN
	_play(sim, [[R, 20]])
	return started and f.state == S.RUN and f.run_speed == f.data.run_speed


func _test_slow_tap() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	_play(sim, [[R, 2], [0, 20], [R, 3]])
	return f.state == S.WALK_F


func _test_run_stop() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	f.x = 300 * SUB
	_play(sim, [[R, 2], [0, 2], [R, 15], [0, 1]])
	var stopping := f.state == S.RUN_STOP
	_play(sim, [[0, f.data.run_stop]])
	return stopping and f.state == S.STAND and f.vx == 0


func _test_backdash() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	var x0 := f.x
	_play(sim, [[L, 2], [0, 2], [L, 1]])
	var started := f.state == S.BACKDASH
	_play(sim, [[0, 40]])
	var dist := (x0 - f.x) / SUB
	return started and f.state == S.STAND and dist >= 90 and dist <= 100


func _test_backdash_commit() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	_play(sim, [[L, 2], [0, 2], [L, 1], [R, 10]])
	return f.state == S.BACKDASH and f.vx < 0


func _jump_distance(run_first: bool) -> int:
	var sim := Sim.new()
	var f := sim.fighters[0]
	f.x = 200 * SUB
	sim.fighters[1].x = 1800 * SUB
	if run_first:
		_play(sim, [[R, 2], [0, 2], [R, 12]])
	var x0 := f.x
	_play(sim, [[R | U, 1]])
	for i in 200:
		_play(sim, [[R, 1]])
		if f.state == S.LAND:
			break
	return f.x - x0


func _test_run_jump() -> bool:
	return _jump_distance(true) > _jump_distance(false) + 30 * SUB


func _test_run_side_switch() -> bool:
	var sim := Sim.new()
	var f := sim.fighters[0]
	_play(sim, [[R, 2], [0, 2], [R, 3]])
	sim.fighters[1].x = f.x - 300 * SUB  # соперник внезапно оказался сзади
	_play(sim, [[R, 1]])
	return f.state == S.RUN_STOP


func _test_dracula_faster() -> bool:
	var ilya := FighterData.get_data("ilya")
	var drac := FighterData.get_data("dracula")
	return drac.run_speed > ilya.run_speed and drac.run_accel > ilya.run_accel
