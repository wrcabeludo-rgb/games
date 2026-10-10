extends SceneTree
## Автотесты подэтапа 2.3: классические приёмы (подсечка, разворот, апперкот),
## бросок вплотную, вырывание, командные броски, выбор бойцов.

const SUB := Fighter.SUB
const S := Fighter.State
const R := InputBits.RIGHT
const L := InputBits.LEFT
const D := InputBits.DOWN
const LP := InputBits.LP
const LK := InputBits.LK
const HP := InputBits.HP
const HK := InputBits.HK
const BL := InputBits.BLOCK


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	ok = _check("назад + ЛН — подсечка: пробивает стоячий блок, сбивает с ног", _test_sweep()) and ok
	ok = _check("сбитый с ног неуязвим и встаёт", _test_knockdown_invul()) and ok
	ok = _check("назад + СН — удар с разворота: урон 120, сбивает", _test_roundhouse()) and ok
	ok = _check("вниз + СР — апперкот подбрасывает", _test_uppercut()) and ok
	ok = _check("апперкот Дракулы попадает по стоящему Илье на обычной дистанции", _test_drac_uppercut()) and ok
	ok = _check("апперкот Дракулы сбивает прыгнувшего Илью", _test_drac_uppercut_antiair()) and ok
	ok = _check("ЛР вплотную — бросок сквозь блок: урон 120", _test_throw_through_block()) and ok
	ok = _check("ЛР не вплотную — обычный удар", _test_throw_range()) and ok
	ok = _check("ЛР в ответ — вырвался из броска", _test_tech()) and ok
	ok = _check("в оглушении блока схватить нельзя", _test_no_throw_in_blockstun()) and ok
	ok = _check("Мельница: назад, назад + рука — урон 170, не вырваться", _test_windmill()) and ok
	ok = _check("Укус лечит Дракулу", _test_bite()) and ok
	ok = _check("зеркальный бой: два Дракулы, второй другим цветом", _test_mirror()) and ok
	ok = _check("Дракула за первого игрока против Ильи", _test_swapped()) and ok
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


## Сколько тиков подряд соперник лежал; заодно проверяем, что он встал.
func _watch_knockdown(sim: Sim, p1 := 0, p2 := 0) -> int:
	var lying := 0
	for i in 150:
		_run(sim, p1, p2)
		if sim.fighters[1].state == S.KNOCKDOWN:
			lying += 1
	return lying if sim.fighters[1].is_grounded_actionable() else -1


func _test_sweep() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, L | LK, BL)
	var name := _move_name(sim.fighters[0])
	var lying := _watch_knockdown(sim, 0, BL)
	return name == "st_sweep" and sim.fighters[1].hp == 1000 - 70 and lying >= Fighter.KNOCKDOWN_TICKS - 2


func _test_knockdown_invul() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, L | LK, 0)
	for i in 30:
		_run(sim, 0, 0)
	var down := sim.fighters[1].state == S.KNOCKDOWN
	var hp := sim.fighters[1].hp
	_run(sim, InputBits.HK, 0)  # бьём лежачего
	_run(sim, 0, 0, 20)
	return down and sim.fighters[1].hp == hp


func _test_roundhouse() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, L | HK, 0)
	var name := _move_name(sim.fighters[0])
	var lying := _watch_knockdown(sim)
	return name == "st_round" and sim.fighters[1].hp == 1000 - 120 and lying > 0


func _test_uppercut() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, D | HP, 0)
	var max_y := 0
	for i in 60:
		_run(sim, 0, 0)
		max_y = maxi(max_y, sim.fighters[1].y)
	return sim.fighters[1].hp == 1000 - 100 and max_y > 100 * SUB


func _test_throw_through_block() -> bool:
	var sim := _sim_at(900, 995)
	_run(sim, LP, BL)
	var name := _move_name(sim.fighters[0])
	_run(sim, 0, BL, 60)  # бросок Ильи держит 40 тиков (через плечо)
	return name == "throw" and sim.fighters[1].hp == 1000 - 120


func _test_throw_range() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, LP, 0)
	return _move_name(sim.fighters[0]) == "st_lp"


func _test_tech() -> bool:
	var sim := _sim_at(900, 995)
	_run(sim, LP, 0)
	_run(sim, 0, 0, 5)  # захват на 4-м кадре
	var grabbed := sim.fighters[1].state == S.THROWN
	_run(sim, 0, LP)    # Дракула вырывается
	_run(sim, 0, 0, 30)
	var gap := absi(sim.fighters[1].x - sim.fighters[0].x) / SUB
	return grabbed and sim.fighters[1].hp == 1000 and sim.fighters[0].hp == 1000 and gap > 120


func _test_no_throw_in_blockstun() -> bool:
	var sim := _sim_at(900, 995)
	var d := sim.fighters[1]
	d.state = S.BLOCKSTUN
	d.stun = 20
	_run(sim, LP, BL)
	return _move_name(sim.fighters[0]) == "st_lp"


func _test_windmill() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, L, 0, 2)
	_run(sim, 0, 0, 2)
	_run(sim, L | LP, 0)
	var name := _move_name(sim.fighters[0])
	_run(sim, 0, 0, 8)
	_run(sim, 0, LP)  # пытается вырваться — у Мельницы нельзя
	_run(sim, 0, 0, 60)
	return name == "sp_bb_l" and sim.fighters[1].hp == 1000 - 170


func _test_bite() -> bool:
	var sim := _sim_at(900, 1040)
	sim.fighters[1].hp = 500
	_run(sim, 0, R, 2)
	_run(sim, 0, 0, 2)
	_run(sim, 0, R | LP)
	var name := _move_name(sim.fighters[1])
	_run(sim, 0, 0, 60)
	return name == "sp_bb_l" and sim.fighters[0].hp == 1000 - 110 and sim.fighters[1].hp == 560


func _test_mirror() -> bool:
	var sim := Sim.new(false, PackedStringArray(["dracula", "dracula"]))
	for i in 300:
		sim.step(PackedInt32Array([R if i % 40 < 20 else LP, L]))
	return sim.fighters[0].id == "dracula" and sim.fighters[1].id == "dracula" \
		and sim.fighters[1].alt and not sim.fighters[0].alt and sim.fighters[0].color() != sim.fighters[1].color()


func _test_swapped() -> bool:
	var sim := Sim.new(false, PackedStringArray(["dracula", "ilya"]))
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 1040 * SUB
	_run(sim, R, 0, 2)
	_run(sim, 0, 0, 2)
	_run(sim, R | LP, 0)  # у Дракулы «вперёд, вперёд + рука» — гипнотический взгляд
	return sim.fighters[0].id == "dracula" and _move_name(sim.fighters[0]) == "sp_ff_l"


func _test_drac_uppercut() -> bool:
	var sim := _sim_at(900, 1060)
	_run(sim, 0, D | HP)
	var name := _move_name(sim.fighters[1])
	var max_y := 0
	for i in 60:
		_run(sim, 0, 0)
		max_y = maxi(max_y, sim.fighters[0].y)
	return name == "cr_hp" and sim.fighters[0].hp == 1000 - 85 and max_y > 100 * SUB


## Илья прыгает вперёд на Дракулу; ищем момент, когда апперкот его сбивает (как игрок, ловящий прыжок).
func _test_drac_uppercut_antiair() -> bool:
	for press in range(5, 45):
		var sim := _sim_at(820, 1080)
		_run(sim, R | InputBits.UP, 0)
		var flew := false
		for i in 70:
			_run(sim, R, D | HP if i == press else 0)
			flew = flew or sim.fighters[0].state == S.AIR_HIT
		if flew and sim.fighters[0].hp == 1000 - 85 and sim.fighters[1].hp == 1000:
			return true
	return false
