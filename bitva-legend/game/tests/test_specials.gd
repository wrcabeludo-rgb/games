extends SceneTree
## Автотесты спецприёмов и снарядов (подэтап 2.1).

const SUB := Fighter.SUB
const S := Fighter.State
const R := InputBits.RIGHT
const L := InputBits.LEFT
const D := InputBits.DOWN
const LP := InputBits.LP
const HP := InputBits.HP
const BL := InputBits.BLOCK


func _init() -> void:
	var ok := true
	ok = _check("назад, вперёд + ЛР → снаряд Дракулы (лёгкий)", _test_recognized()) and ok
	ok = _check("у мышей одна версия: и СР даёт тот же приём", _test_heavy_version()) and ok
	ok = _check("снаряд появляется на 12-м кадре", _test_spawn_frame()) and ok
	ok = _check("мыши попадают издалека: урон 60", _test_hits()) and ok
	ok = _check("в блоке — 6 урона сквозь блок", _test_chip()) and ok
	ok = _check("мыши бьют и присевшего", _test_duck()) and ok
	ok = _check("пока снаряд летит, второй не выпустить (выходит обычный удар)", _test_one_projectile()) and ok
	ok = _check("встречные снаряды гасят друг друга", _test_clash()) and ok
	ok = _check("палица падает на землю и исчезает", _test_mace_lands()) and ok
	ok = _check("вперёд, назад + удар — обычный удар", _test_wrong_order()) and ok
	ok = _check("слишком медленный ввод — обычный удар", _test_too_slow()) and ok
	ok = _check("урон сквозь блок может добить", _test_chip_ko()) and ok
	ok = _check("палица — только руками: назад, вперёд + ЛН — обычный удар ногой", _test_mace_punch_only()) and ok
	ok = _check("назад, вперёд + СР у Ильи — сильная палица", _test_mace_heavy_punch()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _sim_at(ilya_px: int, drac_px: int) -> Sim:
	var sim := Sim.new(false)
	sim.fighters[0].x = ilya_px * SUB
	sim.fighters[1].x = drac_px * SUB
	return sim


func _run(sim: Sim, p1: int, p2: int, ticks := 1) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


## Дракула смотрит влево: «назад» — вправо, «вперёд» — влево.
func _drac_fireball(sim: Sim, button: int, p1 := 0) -> void:
	_run(sim, p1, R, 2)
	_run(sim, p1, L | button)


func _move_name(f: Fighter) -> String:
	return Fighter.MOVES[f.move] if f.move >= 0 else ""


func _test_recognized() -> bool:
	var sim := _sim_at(600, 1100)
	_drac_fireball(sim, LP)
	var d := sim.fighters[1]
	return d.state == S.ATTACK and _move_name(d) == "sp_proj_l"


func _test_heavy_version() -> bool:
	var sim := _sim_at(600, 1100)
	_drac_fireball(sim, HP)
	return _move_name(sim.fighters[1]) == "sp_proj_l"


func _test_spawn_frame() -> bool:
	var sim := _sim_at(600, 1100)
	_drac_fireball(sim, LP)
	_run(sim, 0, 0, 10)
	var before := sim.projectiles.size()
	_run(sim, 0, 0)
	return before == 0 and sim.projectiles.size() == 1


func _test_hits() -> bool:
	var sim := _sim_at(600, 1100)
	_drac_fireball(sim, LP)
	_run(sim, 0, 0, 90)
	return sim.fighters[0].hp == 1000 - 60 and sim.projectiles.is_empty()


func _test_chip() -> bool:
	var sim := _sim_at(600, 1100)
	_drac_fireball(sim, LP, BL)
	var blocked := false
	for i in 90:
		_run(sim, BL, 0)
		blocked = blocked or sim.fighters[0].state == S.BLOCKSTUN
	return blocked and sim.fighters[0].hp == 1000 - 6


func _duck_damage(button: int) -> int:
	var sim := _sim_at(600, 1100)
	_drac_fireball(sim, button, D)
	_run(sim, D, 0, 120)
	return 1000 - sim.fighters[0].hp


func _test_duck() -> bool:
	return _duck_damage(HP) == 60 and _duck_damage(LP) == 60


func _test_one_projectile() -> bool:
	var sim := _sim_at(200, 1290)
	var d := sim.fighters[1]
	_drac_fireball(sim, LP)
	_run(sim, 0, 0, 36)  # первый спецприём закончился, мыши ещё летят
	var flying := sim.projectiles.size() == 1
	_drac_fireball(sim, LP)
	return flying and d.state == S.ATTACK and _move_name(d) == "st_lp"


func _test_clash() -> bool:
	var sim := _sim_at(300, 1700)
	# Два встречных снаряда на одной высоте посреди арены.
	for p in 2:
		var pr := PackedInt32Array()
		pr.resize(Sim.Proj.SIZE)
		pr[Sim.Proj.OWNER] = p
		pr[Sim.Proj.X] = (900 if p == 0 else 1100) * SUB
		pr[Sim.Proj.Y] = 150 * SUB
		pr[Sim.Proj.VX] = 800 if p == 0 else -800
		pr[Sim.Proj.HW] = 30 * SUB
		pr[Sim.Proj.HH] = 20 * SUB
		pr[Sim.Proj.DMG] = 50
		sim.projectiles.append(pr)
	_run(sim, 0, 0, 30)
	return sim.projectiles.is_empty() and sim.fighters[0].hp == 1000 and sim.fighters[1].hp == 1000


func _test_mace_lands() -> bool:
	var sim := _sim_at(300, 1300)
	_run(sim, L, 0, 2)
	_run(sim, R | LP, 0)
	_run(sim, 0, 0, 20)
	var flying := sim.projectiles.size() == 1
	_run(sim, 0, 0, 60)
	return flying and sim.projectiles.is_empty() and sim.fighters[1].hp == 1000


func _test_wrong_order() -> bool:
	var sim := _sim_at(600, 1100)
	_run(sim, 0, L, 2)
	_run(sim, 0, R | LP)
	return _move_name(sim.fighters[1]) == "st_lp"


func _test_too_slow() -> bool:
	var sim := _sim_at(600, 1100)
	_run(sim, 0, R, 2)
	_run(sim, 0, 0, 16)
	_run(sim, 0, L | LP)
	return _move_name(sim.fighters[1]) == "st_lp"


func _test_chip_ko() -> bool:
	var sim := _sim_at(600, 1100)
	sim.fighters[0].hp = 5
	_drac_fireball(sim, LP, BL)
	_run(sim, BL, 0, 90)
	return sim.fighters[0].hp == 0 and sim.phase == Sim.Phase.ROUND_END


func _test_mace_punch_only() -> bool:
	var sim := _sim_at(600, 1100)
	var f := sim.fighters[0]
	_run(sim, L, 0, 2)
	_run(sim, R | InputBits.LK, 0)
	_run(sim, 0, 0, 30)
	return sim.projectiles.is_empty() and sim.fighters[1].hp == 1000 \
		and (f.move < 0 or _move_name(f) == "st_lk")


func _test_mace_heavy_punch() -> bool:
	var sim := _sim_at(600, 1100)
	_run(sim, L, 0, 2)
	_run(sim, R | HP, 0)
	return _move_name(sim.fighters[0]) == "sp_proj_h"
