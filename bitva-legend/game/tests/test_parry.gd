extends SceneTree
## Автотесты подэтапа 2.6: парирование (тап «вперёд» в момент удара).

const SUB := Fighter.SUB
const S := Fighter.State
const L := InputBits.LEFT
const R := InputBits.RIGHT
const D := InputBits.DOWN
const LP := InputBits.LP
const LK := InputBits.LK
const HP := InputBits.HP
const BL := InputBits.BLOCK


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	ok = _check("тап «вперёд» в момент удара — парирование: урона нет, атакующий ошеломлён", _test_parry_basic()) and ok
	ok = _check("окно — до 6 кадров до удара: раньше — уже поздно", _test_window()) and ok
	ok = _check("просто держать «вперёд» — не парирование", _test_hold()) and ok
	ok = _check("долбить «вперёд» нельзя: попытка не чаще раза в 20 кадров", _test_mash()) and ok
	ok = _check("после парирования успевает полное комбо (строка НР, НР, ВН)", _test_punish()) and ok
	ok = _check("парируется и низкий удар (подсечка)", _test_parry_low()) and ok
	ok = _check("снаряд парируется: гаснет, бросивший не ошеломлён", _test_parry_projectile()) and ok
	ok = _check("в оглушении блока парировать нельзя", _test_no_parry_in_blockstun()) and ok
	ok = _check("парирование даёт шкалу", _test_meter()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _sim_at(p1_px: int, p2_px: int) -> Sim:
	var sim := Sim.new(false)
	sim.fighters[0].x = p1_px * SUB
	sim.fighters[1].x = p2_px * SUB
	return sim


## Илья бьёт ВР в тик 0 (попадает на 12-м кадре — тик 11), Дракула (смотрит влево, «вперёд» — L)
## подаёт свои нажатия по расписанию. Возвращает sim после 40 тиков.
func _heavy_vs(drac: Dictionary, ilya_move := HP, gap := 150) -> Sim:
	var sim := _sim_at(900, 900 + gap)
	for t in 40:
		sim.step(PackedInt32Array([ilya_move if t == 0 else 0, drac.get(t, 0)]))
		if sim.fighters[0].staggered:
			break
	return sim


func _hit_tick(ilya_move := HP, gap := 150) -> int:
	var sim := _sim_at(900, 900 + gap)
	for t in 40:
		sim.step(PackedInt32Array([ilya_move if t == 0 else 0, 0]))
		if sim.fighters[1].hp < 1000:
			return t
	return -1


func _test_parry_basic() -> bool:
	var hit := _hit_tick()
	var sim := _heavy_vs({hit - 3: L})
	var a := sim.fighters[0]
	if sim.fighters[1].hp != 1000 or not a.staggered or a.state != S.HITSTUN:
		print("    удар на тике %d, здоровье %d, ошеломлён %d" % [hit, sim.fighters[1].hp, a.staggered])
		return false
	return true


func _test_window() -> bool:
	var hit := _hit_tick()
	var in_window := _heavy_vs({hit - Fighter.PARRY_WINDOW: L}).fighters[1].hp == 1000
	var too_early := _heavy_vs({hit - Fighter.PARRY_WINDOW - 1: L}).fighters[1].hp < 1000
	return in_window and too_early


func _test_hold() -> bool:
	var hold := {}
	for t in 40:
		hold[t] = L
	return _heavy_vs(hold).fighters[1].hp < 1000


func _test_mash() -> bool:
	# Тапы каждые 4 тика: засчитывается только первый, остальные попадают в блокировку.
	var hit := _hit_tick()
	var mash := {}
	var t := hit - 14
	while t <= hit:
		mash[t] = L
		t += 4
	return _heavy_vs(mash).fighters[1].hp < 1000


func _test_punish() -> bool:
	var hit := _hit_tick()
	var sim := _sim_at(900, 1050)
	var d := sim.fighters[1]
	var a := sim.fighters[0]
	var parried_at := -1
	for t in 120:
		var p2 := L if t == hit - 3 else 0
		if parried_at >= 0:
			var k := t - parried_at
			p2 = {1: LP, 7: LP, 13: InputBits.HK}.get(k, 0)
		sim.step(PackedInt32Array([HP if t == 0 else 0, p2]))
		if parried_at < 0 and a.staggered and sim.hitstop == 0:
			parried_at = t  # пауза парирования кончилась — начинаем комбо
	return d.hp == 1000 and a.hp < 1000 - 100 and a.combo >= 0 and parried_at >= 0


func _test_parry_low() -> bool:
	var hit := _hit_tick(L | LK, 140)
	var sim := _heavy_vs({hit - 2: L}, L | LK, 140)
	return hit >= 0 and sim.fighters[1].hp == 1000 and sim.fighters[0].staggered == 1


func _test_parry_projectile() -> bool:
	# Дракула пускает мышей («назад, вперёд + НР»), Илья вдалеке тапает «вперёд» в момент попадания.
	var chars := PackedStringArray(["dracula", "ilya"])
	var script := {0: L, 2: R | LP}
	var hit := -1
	var sim := Sim.new(false, chars)
	sim.fighters[0].x = 700 * SUB
	sim.fighters[1].x = 1150 * SUB
	for t in 120:
		sim.step(PackedInt32Array([script.get(t, 0), 0]))
		if sim.fighters[1].hp < 1000:
			hit = t
			break
	if hit < 0:
		return false
	sim = Sim.new(false, chars)
	sim.fighters[0].x = 700 * SUB
	sim.fighters[1].x = 1150 * SUB
	for t in 120:
		sim.step(PackedInt32Array([script.get(t, 0), L if t == hit - 2 else 0]))
	return sim.fighters[1].hp == 1000 and sim.fighters[0].staggered == 0 and sim.projectiles.is_empty()


func _test_no_parry_in_blockstun() -> bool:
	var sim := _sim_at(900, 1040)
	var d := sim.fighters[1]
	d.state = S.BLOCKSTUN
	d.stun = 30
	d.parry_timer = 0
	return not d.can_parry()


func _test_meter() -> bool:
	var hit := _hit_tick()
	var sim := _heavy_vs({hit - 3: L})
	return sim.fighters[1].meter == Sim.PARRY_METER
