extends SceneTree
## Автотесты спецприёмов подэтапа 2.2: удар оземь, таран, туманный рывок, гипнотический взгляд.

const SUB := Fighter.SUB
const S := Fighter.State
const R := InputBits.RIGHT
const L := InputBits.LEFT
const D := InputBits.DOWN
const LP := InputBits.LP
const LK := InputBits.LK
const HK := InputBits.HK
const BL := InputBits.BLOCK


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	ok = _check("вниз, вниз + ЛН → удар оземь Ильи", _test_stomp_recognized()) and ok
	ok = _check("вниз, вниз + рука — обычный удар в приседе", _test_stomp_punch()) and ok
	ok = _check("волна бьёт стоящего: урон 80", _test_wave_hits()) and ok
	ok = _check("волна пробивает стоячий блок", _test_wave_vs_stand_block()) and ok
	ok = _check("нижний блок держит волну (8 сквозь блок)", _test_wave_vs_crouch_block()) and ok
	ok = _check("волна исчезает, не долетев до дальнего соперника", _test_wave_life()) and ok
	ok = _check("вперёд, вперёд + ЛР → таран: рывок и урон 100", _test_ram()) and ok
	ok = _check("броня тарана выдерживает удар", _test_ram_armor()) and ok
	ok = _check("вниз, вниз + ЛН → Дракула за спиной у Ильи", _test_teleport()) and ok
	ok = _check("в тумане Дракула неуязвим", _test_mist_intangible()) and ok
	ok = _check("гипнотический взгляд ловит удар: Илья застыл", _test_counter()) and ok
	ok = _check("взгляд впустую — Дракула открыт до конца приёма", _test_counter_whiff()) and ok
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


func _move_name(f: Fighter) -> String:
	return Fighter.MOVES[f.move] if f.move >= 0 else ""


## Илья: вниз, вниз + кнопка; p2 — что всё это время держит Дракула.
func _ilya_dd(sim: Sim, button: int, p2 := 0) -> void:
	_run(sim, D, p2, 2)
	_run(sim, 0, p2, 2)
	_run(sim, D | button, p2)


func _test_stomp_recognized() -> bool:
	var sim := _sim_at(800, 1100)
	_ilya_dd(sim, LK)
	return _move_name(sim.fighters[0]) == "sp_dd_l"


func _test_stomp_punch() -> bool:
	var sim := _sim_at(800, 1100)
	_ilya_dd(sim, LP)
	return _move_name(sim.fighters[0]) == "cr_lp"


func _wave_damage(guard: int) -> int:
	var sim := _sim_at(800, 1100)
	_ilya_dd(sim, LK, guard)
	_run(sim, 0, guard, 70)
	return 1000 - sim.fighters[1].hp


func _test_wave_hits() -> bool:
	return _wave_damage(0) == 80


func _test_wave_vs_stand_block() -> bool:
	return _wave_damage(BL) == 80


func _test_wave_vs_crouch_block() -> bool:
	return _wave_damage(D | BL) == 8


func _test_wave_life() -> bool:
	var sim := _sim_at(600, 1600)
	_ilya_dd(sim, LK)
	_run(sim, 0, 0, 25)
	var flying := sim.projectiles.size() == 1
	_run(sim, 0, 0, 40)
	return flying and sim.projectiles.is_empty() and sim.fighters[1].hp == 1000


func _test_ram() -> bool:
	var sim := _sim_at(800, 1100)
	var ilya := sim.fighters[0]
	var x0 := ilya.x
	_run(sim, R, 0, 2)
	_run(sim, 0, 0, 2)
	_run(sim, R | LP, 0)
	var started := _move_name(ilya) == "sp_ff_l"
	_run(sim, 0, 0, 40)
	return started and sim.fighters[1].hp == 900 and ilya.x > x0 + 50 * SUB


func _test_ram_armor() -> bool:
	var sim := _sim_at(900, 1040)
	var ilya := sim.fighters[0]
	_run(sim, R, 0, 2)
	_run(sim, 0, 0, 2)
	_run(sim, R | LP, LP)  # Дракула бьёт ЛР одновременно с началом тарана
	_run(sim, 0, 0, 40)
	return ilya.hp == 1000 - 30 and sim.fighters[1].hp == 900


func _drac_dd(sim: Sim, button: int, p1 := 0) -> void:
	_run(sim, p1, D, 2)
	_run(sim, p1, 0, 2)
	_run(sim, p1, D | button)


func _test_teleport() -> bool:
	var sim := _sim_at(900, 1100)
	_drac_dd(sim, LK)
	var started := _move_name(sim.fighters[1]) == "sp_dd_l"
	_run(sim, 0, 0, 20)
	var drac := sim.fighters[1]
	return started and drac.x < sim.fighters[0].x and drac.facing == 1 and sim.fighters[0].facing == -1


func _test_mist_intangible() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, 0, D, 2)
	_run(sim, 0, 0, 2)
	_run(sim, HK, D | LK)  # Илья бьёт ногой, а Дракула уходит в туман
	_run(sim, 0, 0, 40)
	return sim.fighters[1].hp == 1000


## Дракула смотрит влево: «вперёд» — влево.
func _drac_ff(sim: Sim) -> void:
	_run(sim, 0, L, 2)
	_run(sim, 0, 0, 2)
	_run(sim, 0, L | LP)


func _test_counter() -> bool:
	var sim := _sim_at(900, 1040)
	_drac_ff(sim)
	_run(sim, 0, 0, 2)
	_run(sim, LP, 0)  # Илья бьёт в окно взгляда
	var hypnotized := false
	for i in 30:
		_run(sim, 0, 0)
		hypnotized = hypnotized or sim.fighters[0].hypnotized == 1
	return hypnotized and sim.fighters[1].hp == 1000 and sim.fighters[0].state == S.HITSTUN


func _test_counter_whiff() -> bool:
	var sim := _sim_at(700, 1100)
	_drac_ff(sim)
	_run(sim, 0, 0, 30)
	return sim.fighters[1].state == S.ATTACK and _move_name(sim.fighters[1]) == "sp_ff_l"
