extends SceneTree
## Автотесты блока (подэтап 1.5).

const SUB := Fighter.SUB
const S := Fighter.State
const L := InputBits.LEFT
const U := InputBits.UP
const D := InputBits.DOWN
const LP := InputBits.LP
const LK := InputBits.LK
const HP := InputBits.HP
const HK := InputBits.HK
const BL := InputBits.BLOCK


func _init() -> void:
	var ok := true
	ok = _check("стоячий блок держит ЛР: урона нет, оглушение в блоке", _test_block_basic()) and ok
	ok = _check("после блока, пока держишь кнопку, — снова блок", _test_block_return()) and ok
	ok = _check("низкий удар пробивает стоячий блок", _test_low_vs_stand()) and ok
	ok = _check("нижний блок держит низкий удар", _test_low_vs_crouch()) and ok
	ok = _check("удар в прыжке: стоячий блок держит, нижний — нет", _test_overhead()) and ok
	ok = _check("в блоке отбрасывает дальше, чем при попадании", _test_block_push()) and ok
	ok = _check("в блоке нельзя ходить", _test_no_walk()) and ok
	ok = _check("из блока можно сразу ударить", _test_attack_from_block()) and ok
	ok = _check("палица Ильи в блоке — в минусе (защитник свободен раньше)", _test_heavy_unsafe()) and ok
	ok = _check("ЛР Ильи в блоке — в плюсе", _test_light_safe()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _sim_at(ilya_px: int, drac_px: int) -> Sim:
	var sim := Sim.new()
	sim.fighters[0].x = ilya_px * SUB
	sim.fighters[1].x = drac_px * SUB
	return sim


func _run(sim: Sim, p1: int, p2: int, ticks := 1) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


func _test_block_basic() -> bool:
	var sim := _sim_at(900, 1000)
	var d := sim.fighters[1]
	_run(sim, LP, BL)
	_run(sim, 0, BL, 4)
	return d.hp == 1000 and d.state == S.BLOCKSTUN and d.stun == 15 - Fighter.BLOCKSTUN_LESS


func _test_block_return() -> bool:
	var sim := _sim_at(900, 1000)
	var d := sim.fighters[1]
	_run(sim, LP, BL)
	_run(sim, 0, BL, 30)
	return d.state == S.BLOCK and d.hp == 1000


func _test_low_vs_stand() -> bool:
	var sim := _sim_at(900, 1000)
	_run(sim, D | LK, BL)
	_run(sim, D, BL, 20)
	return sim.fighters[1].hp == 1000 - 35


func _test_low_vs_crouch() -> bool:
	var sim := _sim_at(900, 1000)
	_run(sim, D | LK, D | BL)
	_run(sim, D, D | BL, 20)
	return sim.fighters[1].hp == 1000 and sim.fighters[1].low_pose == 1


## Дракула прыгает на Илью и бьёт ЛН на снижении. Возвращает здоровье Ильи.
func _jump_in(ilya_input: int) -> int:
	var sim := _sim_at(900, 1150)
	_run(sim, ilya_input, L | U)
	_run(sim, ilya_input, L, 26)
	_run(sim, ilya_input, L | LK)
	_run(sim, ilya_input, 0, 40)
	return sim.fighters[0].hp


func _test_overhead() -> bool:
	var no_guard := _jump_in(D)
	var stand_block := _jump_in(BL)
	var crouch_block := _jump_in(D | BL)
	return no_guard == 1000 - 35 and stand_block == 1000 and crouch_block == 1000 - 35


func _push_distance(defender_input: int) -> int:
	var sim := _sim_at(900, 1000)
	var d := sim.fighters[1]
	var x0 := d.x
	_run(sim, HK, defender_input)
	_run(sim, 0, defender_input, 40)
	return d.x - x0


func _test_block_push() -> bool:
	return _push_distance(BL) > _push_distance(0)


func _test_no_walk() -> bool:
	var sim := _sim_at(900, 1300)
	var f := sim.fighters[0]
	var x0 := f.x
	_run(sim, BL | InputBits.RIGHT, 0, 30)
	return f.x == x0 and f.state == S.BLOCK


func _test_attack_from_block() -> bool:
	var sim := _sim_at(900, 1300)
	var f := sim.fighters[0]
	_run(sim, BL, 0, 5)
	_run(sim, BL | LP, 0)
	return f.state == S.ATTACK and Fighter.MOVES[f.move] == "st_lp"


## Преимущество после блока: на сколько тиков защитник освободился раньше атакующего.
func _block_advantage(button: int, gap_px: int) -> int:
	var sim := _sim_at(900, 900 + gap_px)
	var a := sim.fighters[0]
	var d := sim.fighters[1]
	var a_free := -1
	var d_free := -1
	_run(sim, button, BL)
	for t in range(1, 120):
		_run(sim, 0, BL)
		if d_free < 0 and d.state == S.BLOCK and t > 3:
			d_free = t
		if a_free < 0 and a.state != S.ATTACK:
			a_free = t
	return a_free - d_free


func _test_heavy_unsafe() -> bool:
	return _block_advantage(HP, 150) >= 3


func _test_light_safe() -> bool:
	return _block_advantage(LP, 100) < 0
