extends SceneTree
## Автотесты подэтапа 2.5: шкала силы, усиленные спецприёмы, суперприёмы.

const SUB := Fighter.SUB
const S := Fighter.State
const R := InputBits.RIGHT
const L := InputBits.LEFT
const LP := InputBits.LP
const HP := InputBits.HP
const HK := InputBits.HK
const BL := InputBits.BLOCK
const SUPER := BL | HP | HK


## Суперприём и встречный ЛР в один тик (баг 3.7: схваченный навсегда оставался в захвате).
func _test_super_vs_jab(chars: PackedStringArray, sup: int) -> bool:
	for delay in range(0, 12):
		var sim := Sim.new(false, chars)
		sim.fighters[0].x = 900 * SUB
		sim.fighters[1].x = 1150 * SUB
		sim.fighters[sup].meter = Fighter.METER_MAX
		for i in 400:
			var inp := PackedInt32Array([0, 0])
			if i == 5:
				inp[sup] = SUPER
			if i == 5 + delay:
				inp[1 - sup] |= LP
			sim.step(inp)
		for f in sim.fighters:
			if f.state == S.THROWN or f.state == S.THROWING:
				return false
	return true


## Суперприём поймал соперника в прыжке: тот не висит в воздухе весь ролик (баг 3.8).
func _test_super_air_catch() -> bool:
	var caught_in_air := 0
	for jump_at in range(0, 40, 2):
		for gap in [200, 260, 320]:
			var sim := Sim.new(false, PackedStringArray(["ilya", "dracula"]))
			sim.fighters[0].x = 900 * SUB
			sim.fighters[1].x = (900 + gap) * SUB
			sim.fighters[0].meter = Fighter.METER_MAX
			var held_air := 0
			for i in 300:
				var inp := PackedInt32Array([0, 0])
				if i == jump_at:
					inp[1] = InputBits.UP
				if i == 20:
					inp[0] = SUPER
				sim.step(inp)
				var d := sim.fighters[1]
				if d.state == S.THROWN and d.y > 0:
					held_air += 1
			if held_air > 0:
				caught_in_air += 1
			if held_air > 30:  # заморозка удара (12) + спуск; раньше висел весь ролик (100)
				return false
	return caught_in_air > 0


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	ok = _check("попадание: атакующему урон × 2, пропустившему — урон", _test_gain_hit()) and ok
	ok = _check("суперприём поймал в прыжке: схваченный опускается на землю, не висит", _test_super_air_catch()) and ok
	for who in [["dracula", "ilya"], ["ilya", "dracula"]]:
		for sup in [0, 1]:
			ok = _check("суперприём %s против ЛР в упор: никто не застревает в захвате" % who[sup],
				_test_super_vs_jab(PackedStringArray(who), sup)) and ok
	ok = _check("блок: атакующему — урон, защитнику ничего", _test_gain_block()) and ok
	ok = _check("шкала переходит в следующий раунд, в новом матче — с нуля", _test_carry()) and ok
	ok = _check("усиленные мыши (спецприём + блок): секция шкалы, урон 90", _test_ex_bats()) and ok
	ok = _check("без секции шкалы — обычные мыши", _test_ex_no_meter()) and ok
	ok = _check("усиленный таран сбивает с ног", _test_ex_ram()) and ok
	ok = _check("суперприём Ильи: пауза, ролик, урон 330, шкала пуста", _test_super_ilya()) and ok
	ok = _check("суперприём Дракулы: урон 300 и лечение", _test_super_drac()) and ok
	ok = _check("без полной шкалы суперприёма нет", _test_super_no_meter()) and ok
	ok = _check("суперприём в блок: только урон сквозь блок, наказуем", _test_super_blocked()) and ok
	ok = _check("суперприём из комбо: урон затухает", _test_super_combo()) and ok
	ok = _check("кнопки не совсем одновременно — всё равно суперприём", _test_super_kara()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _sim_at(p1_px: int, p2_px: int, chars := PackedStringArray(["ilya", "dracula"])) -> Sim:
	var sim := Sim.new(false, chars)
	sim.fighters[0].x = p1_px * SUB
	sim.fighters[1].x = p2_px * SUB
	return sim


## Игроку 1 — нажатия по расписанию {тик: биты}, игроку 2 — p2 постоянно.
func _play(sim: Sim, script: Dictionary, p2 := 0, ticks := 60) -> void:
	for t in ticks:
		sim.step(PackedInt32Array([script.get(t, 0), p2]))


func _test_gain_hit() -> bool:
	var sim := _sim_at(900, 1040)
	_play(sim, {0: LP})
	return sim.fighters[0].meter == 80 and sim.fighters[1].meter == 40


func _test_gain_block() -> bool:
	var sim := _sim_at(900, 1040)
	_play(sim, {0: LP}, BL)
	return sim.fighters[0].meter == 40 and sim.fighters[1].meter == 0


func _test_carry() -> bool:
	var sim := _sim_at(900, 1040)
	sim.fighters[0].meter = 1500
	sim.fighters[1].meter = 700
	sim._next_round()
	var kept := sim.fighters[0].meter == 1500 and sim.fighters[1].meter == 700
	sim._new_match()
	return kept and sim.fighters[0].meter == 0 and sim.fighters[1].meter == 0


## Дракула (игрок 1) выпускает мышей в Илью: «назад, вперёд + ЛР», блок — по желанию.
func _bats(meter: int, block: int) -> Array:
	var sim := _sim_at(900, 1300, PackedStringArray(["dracula", "ilya"]))
	var f := sim.fighters[0]
	f.meter = meter
	var was_ex := 0
	for t in 80:
		var bits := {0: L, 2: R | LP | block}.get(t, 0) as int
		sim.step(PackedInt32Array([bits, 0]))
		if f.move >= 0 and Fighter.MOVES[f.move] == "sp_proj_l":
			was_ex = maxi(was_ex, f.ex)
	return [was_ex, 1000 - sim.fighters[1].hp, f.meter]


func _test_ex_bats() -> bool:
	var r := _bats(1000, BL)
	if r != [1, 90, 180]:
		print("    усиление %d, урон %d, шкала %d" % r)
		return false
	return true


func _test_ex_no_meter() -> bool:
	var r := _bats(500, BL)
	if r != [0, 60, 500 + 120]:
		print("    усиление %d, урон %d, шкала %d" % r)
		return false
	return true


func _test_ex_ram() -> bool:
	var sim := _sim_at(900, 1150)
	sim.fighters[0].meter = 1000
	var knocked := false
	for t in 80:
		var bits := {0: R, 2: R | LP | BL}.get(t, 0) as int
		sim.step(PackedInt32Array([bits, 0]))
		knocked = knocked or sim.fighters[1].state == S.KNOCKDOWN
	return knocked and sim.fighters[1].hp == 1000 - 140


func _super(chars: PackedStringArray, p2 := 0) -> Dictionary:
	var sim := _sim_at(900, 1060, chars)
	var a := sim.fighters[0]
	a.meter = Fighter.METER_MAX
	var froze := false
	var cinema := false
	for t in 220:
		sim.step(PackedInt32Array([SUPER if t == 0 else 0, p2]))
		if t == 1:
			froze = sim.hitstop >= Sim.SUPER_FLASH - 2 and a.is_super()
		cinema = cinema or a.state == S.THROWING
	return {"froze": froze, "cinema": cinema, "dmg": 1000 - sim.fighters[1].hp, "a_hp": a.hp, "meter": a.meter}


func _test_super_ilya() -> bool:
	var r := _super(PackedStringArray(["ilya", "dracula"]))
	if not (r.froze and r.cinema and r.dmg == 330 and r.meter == 0):
		print("    %s" % r)
		return false
	return true


func _test_super_drac() -> bool:
	var sim_hp := 600
	var sim := _sim_at(900, 1060, PackedStringArray(["dracula", "ilya"]))
	sim.fighters[0].meter = Fighter.METER_MAX
	sim.fighters[0].hp = sim_hp
	for t in 220:
		sim.step(PackedInt32Array([SUPER if t == 0 else 0, 0]))
	return sim.fighters[1].hp == 1000 - 300 and sim.fighters[0].hp == sim_hp + 80


func _test_super_no_meter() -> bool:
	var sim := _sim_at(900, 1060)
	var a := sim.fighters[0]
	a.meter = Fighter.METER_MAX - 1
	sim.step(PackedInt32Array([SUPER, 0]))
	return a.state == S.ATTACK and not a.is_super() and a.meter == Fighter.METER_MAX - 1


func _test_super_blocked() -> bool:
	var sim := _sim_at(900, 1060)
	var a := sim.fighters[0]
	var d := sim.fighters[1]
	a.meter = Fighter.METER_MAX
	var d_free := -1
	var a_free := -1
	for t in 150:
		sim.step(PackedInt32Array([SUPER if t == 0 else 0, BL]))
		if d_free < 0 and t > 40 and d.state == S.BLOCK:
			d_free = t
		if a_free < 0 and t > 2 and a.state != S.ATTACK:
			a_free = t
	if d.hp != 1000 - 45 or a.state == S.THROWING or a_free - d_free < 20:
		print("    здоровье %d, защитник свободен на %d, атакующий на %d" % [d.hp, d_free, a_free])
		return false
	return true


func _test_super_combo() -> bool:
	var sim := _sim_at(900, 1040)
	sim.fighters[0].meter = Fighter.METER_MAX
	_play(sim, {0: LP, 10: SUPER}, 0, 220)
	var expected := 1000 - 40 - Fighter.scaled_damage(330, 2)
	if sim.fighters[1].hp != expected:
		print("    здоровье %d (ждали %d)" % [sim.fighters[1].hp, expected])
		return false
	return true


func _test_super_kara() -> bool:
	var sim := _sim_at(900, 1060)
	var a := sim.fighters[0]
	a.meter = Fighter.METER_MAX
	sim.step(PackedInt32Array([BL | HP, 0]))
	var heavy_first := a.state == S.ATTACK and not a.is_super()
	sim.step(PackedInt32Array([SUPER, 0]))
	return heavy_first and a.is_super()
