extends SceneTree
## Автотесты подэтапа 2.7: режим тренировки.

const SUB := Fighter.SUB
const LP := InputBits.LP
const HP := InputBits.HP


func _init() -> void:
	var ok := true
	ok = _check("в тренировке таймер стоит, бой сразу начат", _test_timer()) and ok
	ok = _check("нокаута нет: здоровье не ниже 1, раунд не кончается", _test_no_ko()) and ok
	ok = _check("здоровье восстанавливается после конца комбо", _test_refill()) and ok
	ok = _check("во время комбо здоровье не восстанавливается", _test_no_refill_in_combo()) and ok
	ok = _check("шкала всегда полная: суперприём сколько угодно раз", _test_meter()) and ok
	ok = _check("выключение тренировки — обычный бой", _test_off()) and ok
	ok = _check("тренировка сохраняется и восстанавливается (для отката)", _test_save_load()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _training(p1_px := 900, p2_px := 1040) -> Sim:
	var sim := Sim.new(true)
	sim.set_training(true)
	sim.fighters[0].x = p1_px * SUB
	sim.fighters[1].x = p2_px * SUB
	return sim


func _test_timer() -> bool:
	var sim := _training()
	var started := sim.phase == Sim.Phase.FIGHT
	for t in 600:
		sim.step(PackedInt32Array([0, 0]))
	return started and sim.timer == Sim.ROUND_TICKS and sim.phase == Sim.Phase.FIGHT


func _test_no_ko() -> bool:
	var sim := _training()
	sim.fighters[1].hp = 50
	for t in 40:
		sim.step(PackedInt32Array([HP if t == 0 else 0, 0]))
	return sim.fighters[1].hp == 1 and sim.phase == Sim.Phase.FIGHT


func _test_refill() -> bool:
	var sim := _training()
	sim.step(PackedInt32Array([HP, 0]))
	var hurt := false
	for t in 200:
		sim.step(PackedInt32Array([0, 0]))
		hurt = hurt or sim.fighters[1].hp < Fighter.MAX_HP
	return hurt and sim.fighters[1].hp == Fighter.MAX_HP


func _test_no_refill_in_combo() -> bool:
	var sim := _training()
	var d := sim.fighters[1]
	d.hp = 500
	d.state = Fighter.State.HITSTUN
	d.stun = 200
	for t in 100:
		sim.step(PackedInt32Array([0, 0]))
	return d.hp == 500


func _test_meter() -> bool:
	var sim := _training(900, 1060)
	var supers := 0
	for t in 600:
		var p1 := InputBits.BLOCK | HP | InputBits.HK if t % 200 == 0 else 0
		sim.step(PackedInt32Array([p1, 0]))
		if sim.fighters[0].is_super() and sim.fighters[0].move_frame == 1 and sim.hitstop == Sim.SUPER_FLASH - 1:
			supers += 1
	return supers == 3 and sim.fighters[0].meter == Fighter.METER_MAX


func _test_off() -> bool:
	var sim := _training()
	sim.set_training(false)
	sim.fighters[1].hp = 50
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 1040 * SUB
	for t in 40:
		sim.step(PackedInt32Array([HP if t == 0 else 0, 0]))
	return sim.fighters[1].hp == 0 and sim.phase == Sim.Phase.ROUND_END and sim.fighters[0].meter < Fighter.METER_MAX


func _test_save_load() -> bool:
	var sim := _training()
	sim.step(PackedInt32Array([HP, 0]))
	for t in 20:
		sim.step(PackedInt32Array([0, 0]))
	var state := sim.save_state()
	var sum := sim.checksum()
	var other := Sim.new(true)
	other.load_state(state)
	return other.training and other.checksum() == sum
