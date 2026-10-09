extends SceneTree
## Автотесты ударов (подэтап 1.4).

const SUB := Fighter.SUB
const S := Fighter.State
const R := InputBits.RIGHT
const L := InputBits.LEFT
const U := InputBits.UP
const D := InputBits.DOWN
const LP := InputBits.LP
const LK := InputBits.LK
const HP := InputBits.HP
const HK := InputBits.HK


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	ok = _check("ЛР Ильи попадает ровно на 5-м тике, урон 40", _test_startup_and_damage()) and ok
	ok = _check("промах издалека: урона нет, возврат в стойку", _test_whiff()) and ok
	ok = _check("заморозка: бойцы стоят 8 тиков после попадания", _test_hitstop()) and ok
	ok = _check("удар попадает только один раз", _test_single_hit()) and ok
	ok = _check("буфер: нажатие за 3 тика до конца удара срабатывает", _test_buffer()) and ok
	ok = _check("буфер: нажатие за 7 тиков до конца — нет", _test_buffer_expired()) and ok
	ok = _check("вниз + ЛН → удар в приседе", _test_crouch_attack()) and ok
	ok = _check("удар в прыжке попадает по стоящему", _test_air_attack()) and ok
	ok = _check("размен: быстрый удар Дракулы прерывает Илью", _test_trade()) and ok
	ok = _check("у стены отбрасывает атакующего", _test_wall_pushback()) and ok
	ok = _check("удар по оглушённому — комбо 2", _test_combo()) and ok
	ok = _check("попадание в воздухе → отброс и приземление", _test_air_hit()) and ok
	ok = _check("джеб Ильи достаёт, докуда кулак на спрайте (190 px), но не дальше (300 px)", _test_jab_reach()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


## Новый бой с бойцами на заданных позициях (в пикселях).
func _sim_at(ilya_px: int, drac_px: int) -> Sim:
	var sim := Sim.new(false)
	sim.fighters[0].x = ilya_px * SUB
	sim.fighters[1].x = drac_px * SUB
	return sim


func _run(sim: Sim, p1: int, p2: int, ticks := 1) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


func _test_startup_and_damage() -> bool:
	var sim := _sim_at(900, 1040)
	var d := sim.fighters[1]
	_run(sim, LP, 0)
	_run(sim, 0, 0, 3)
	var before := d.hp
	_run(sim, 0, 0)
	return before == 1000 and d.hp == 960 and d.state == S.HITSTUN and sim.hitstop == 8


func _test_whiff() -> bool:
	var sim := _sim_at(900, 1300)
	_run(sim, LP, 0)
	_run(sim, 0, 0, 20)
	return sim.fighters[1].hp == 1000 and sim.fighters[0].state == S.STAND


func _test_hitstop() -> bool:
	var sim := _sim_at(900, 1040)
	var d := sim.fighters[1]
	_run(sim, LP, 0)
	_run(sim, 0, 0, 4)
	var x_hit := d.x
	_run(sim, 0, 0, 8)
	var frozen := d.x == x_hit
	_run(sim, 0, 0, 2)
	return frozen and d.x > x_hit


func _test_single_hit() -> bool:
	var sim := _sim_at(900, 1010)
	_run(sim, HK, 0)
	_run(sim, 0, 0, 40)
	return sim.fighters[1].hp == 1000 - 90


## Удар Ильи ЛР длится 15 тиков (5 + 3 − 1 + 8). Второе нажатие — на тике press_at.
## ЛР, потом СН (не продолжение строки — значит, выйдет только после конца ЛР, из буфера).
func _second_attack_started(press_at: int) -> bool:
	var sim := _sim_at(600, 1400)
	var f := sim.fighters[0]
	_run(sim, LP, 0)
	for t in range(1, 16):
		_run(sim, HK if t == press_at else 0, 0)
	return f.state == S.ATTACK and f.move == 3 and f.move_frame == 1


func _test_buffer() -> bool:
	return _second_attack_started(12)


func _test_buffer_expired() -> bool:
	return not _second_attack_started(8)


func _test_crouch_attack() -> bool:
	var sim := _sim_at(900, 1040)
	var f := sim.fighters[0]
	_run(sim, D, 0, 3)
	_run(sim, D | LK, 0)
	return f.state == S.ATTACK and Fighter.MOVES[f.move] == "cr_lk" and f.is_crouching()


func _test_air_attack() -> bool:
	var sim := _sim_at(900, 1150)
	var ilya := sim.fighters[0]
	_run(sim, 0, L | U)
	_run(sim, 0, L, 12)
	_run(sim, 0, L | HK)
	for i in 60:
		_run(sim, 0, 0)
		if ilya.hp < 1000:
			return ilya.hp == 1000 - 75
	return false


func _test_trade() -> bool:
	var sim := _sim_at(900, 1040)
	_run(sim, LP, LP)
	_run(sim, 0, 0, 20)
	return sim.fighters[0].hp == 1000 - 30 and sim.fighters[1].hp == 1000


func _test_wall_pushback() -> bool:
	var sim := _sim_at(55, 175)
	var drac := sim.fighters[1]
	var x0 := drac.x
	_run(sim, 0, HP)
	_run(sim, 0, 0, 40)
	return sim.fighters[0].hp < 1000 and drac.x > x0 + 10 * SUB \
		and sim.fighters[0].x == sim.fighters[0].push_half()


func _test_combo() -> bool:
	var sim := _sim_at(900, 1040)
	var d := sim.fighters[1]
	_run(sim, LP, 0)
	_run(sim, 0, 0, 4)
	d.stun = 60  # искусственно удлиняем оглушение, чтобы второй удар успел
	_run(sim, 0, 0, 20)  # 8 тиков заморозки + конец первого удара
	_run(sim, LP, 0)
	_run(sim, 0, 0, 20)
	return d.combo == 2 and d.hp == 1000 - 40 - 36  # второй удар — 90%


func _test_air_hit() -> bool:
	var sim := _sim_at(900, 1040)
	var d := sim.fighters[1]
	_run(sim, 0, U)
	_run(sim, 0, 0, 3)
	_run(sim, D | HP, 0)  # Илья — палица вверх из приседа (анти-эйр)
	var flew := false
	for i in 120:
		_run(sim, D, 0)
		if d.state == S.AIR_HIT:
			flew = true
		if flew and d.state == S.STAND:
			break
	return flew and d.state == S.STAND and d.hp == 1000 - 100


func _test_jab_reach() -> bool:
	var near := _sim_at(900, 1090)
	near.step(PackedInt32Array([LP, 0]))
	for t in 20:
		near.step(PackedInt32Array([0, 0]))
	var far := _sim_at(900, 1200)
	far.step(PackedInt32Array([LP, 0]))
	for t in 20:
		far.step(PackedInt32Array([0, 0]))
	return near.fighters[1].hp == 1000 - 40 and far.fighters[1].hp == 1000
