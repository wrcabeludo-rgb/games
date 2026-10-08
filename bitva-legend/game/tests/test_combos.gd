extends SceneTree
## Автотесты подэтапа 2.4: строки ударов, отмена в спецприём, затухание урона, жонглирование.

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
	var ok := true
	ok = _check("затухание урона: 100% → 90% → … не меньше 30%", _test_scaling()) and ok
	ok = _check("строка Ильи ЛР, ЛР, СР — три удара подряд, урон с затуханием", _test_ilya_string()) and ok
	ok = _check("строка Дракулы ЛН, ЛН, СР — три удара подряд", _test_drac_string()) and ok
	ok = _check("строка Дракулы ЛР, ЛР, СН — три удара подряд", _test_drac_string2()) and ok
	ok = _check("строка в блоке: все удары выходят, урона нет", _test_string_blocked()) and ok
	ok = _check("строка выходит и при промахе (как в МК)", _test_string_whiff()) and ok
	ok = _check("кнопка не из строки — строка обрывается", _test_string_wrong_button()) and ok
	ok = _check("попавший удар отменяется в спецприём", _test_cancel_on_hit()) and ok
	ok = _check("удар в блок тоже отменяется в спецприём", _test_cancel_on_block()) and ok
	ok = _check("промах в спецприём не отменить", _test_no_cancel_on_whiff()) and ok
	ok = _check("жонглирование: апперкот Ильи → таран добивает в воздухе", _test_juggle_ram()) and ok
	ok = _check("жонглирование: апперкот Дракулы → мыши добивают в воздухе", _test_juggle_bats()) and ok
	ok = _check("жонглирование ограничено: после 3 добиваний неуязвим", _test_juggle_limit()) and ok
	ok = _check("после броска не добить", _test_no_juggle_after_throw()) and ok
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


## Подаёт игроку 1 нажатия по расписанию {тик: биты}, игроку 2 — p2 постоянно.
## Возвращает имена ударов игрока 1 по порядку (без повторов).
func _play(sim: Sim, script: Dictionary, p2 := 0, ticks := 90) -> Array:
	var seen := []
	var was_start := false
	for t in ticks:
		sim.step(PackedInt32Array([script.get(t, 0), p2]))
		var f := sim.fighters[0]
		# Удар начался — первый кадр; считаем один раз, даже если кадр держится несколько тиков.
		var at_start := f.state == S.ATTACK and f.move >= 0 and f.move_frame == 1
		if at_start and not was_start:
			seen.append(Fighter.MOVES[f.move])
		was_start = at_start
	return seen


func _test_scaling() -> bool:
	return Fighter.scaled_damage(100, 1) == 100 and Fighter.scaled_damage(100, 2) == 90 \
		and Fighter.scaled_damage(100, 5) == 60 and Fighter.scaled_damage(100, 8) == 30 \
		and Fighter.scaled_damage(100, 20) == 30


func _test_ilya_string() -> bool:
	var sim := _sim_at(900, 1040)
	var moves := _play(sim, {0: LP, 7: LP, 14: HP})
	var d := sim.fighters[1]
	var expected := 1000 - 40 - 36 - 88
	if moves != ["st_lp", "st_lp", "st_hp"] or d.hp != expected:
		print("    удары %s, здоровье %d (ждали %d)" % [moves, d.hp, expected])
		return false
	return true


func _test_drac_string() -> bool:
	var sim := _sim_at(900, 1040, PackedStringArray(["dracula", "ilya"]))
	var moves := _play(sim, {0: LK, 7: LK, 14: HP})
	var d := sim.fighters[1]
	var expected := 1000 - 35 - 31 - 64
	if moves != ["st_lk", "st_lk", "st_hp"] or d.hp != expected:
		print("    удары %s, здоровье %d (ждали %d)" % [moves, d.hp, expected])
		return false
	return true


func _test_drac_string2() -> bool:
	var sim := _sim_at(900, 1040, PackedStringArray(["dracula", "ilya"]))
	var moves := _play(sim, {0: LP, 6: LP, 12: HK})
	var d := sim.fighters[1]
	var expected := 1000 - 30 - 27 - 64
	if moves != ["st_lp", "st_lp", "st_hk"] or d.hp != expected:
		print("    удары %s, здоровье %d (ждали %d)" % [moves, d.hp, expected])
		return false
	return true


func _test_string_blocked() -> bool:
	var sim := _sim_at(900, 1040)
	var moves := _play(sim, {0: LP, 7: LP, 14: HP}, BL)
	return moves == ["st_lp", "st_lp", "st_hp"] and sim.fighters[1].hp == 1000


func _test_string_whiff() -> bool:
	var sim := _sim_at(700, 1400)
	var moves := _play(sim, {0: LP, 8: LP, 16: HP})
	return moves == ["st_lp", "st_lp", "st_hp"]


func _test_string_wrong_button() -> bool:
	var sim := _sim_at(900, 1040)
	var moves := _play(sim, {0: LP, 7: HK})
	return moves == ["st_lp"]


## Илья бьёт ЛР и сразу «назад, вперёд + ЛР» — палица вылетает раньше, чем закончился бы удар.
func _cancel_case(gap: int, p2: int) -> int:
	var sim := _sim_at(900, 900 + gap)
	var f := sim.fighters[0]
	var script := {0: LP, 3: L, 5: R | LP}
	for t in 40:
		sim.step(PackedInt32Array([script.get(t, 0), p2]))
		if f.state == S.ATTACK and Fighter.MOVES[f.move] == "sp_proj_l":
			return t
	return -1


func _natural_end() -> int:
	var m: Dictionary = FighterData.get_data("ilya").moves.st_lp
	return m.startup + m.active + m.recovery - 1


func _test_cancel_on_hit() -> bool:
	var t := _cancel_case(140, 0)
	return t >= 0 and t < _natural_end()


func _test_cancel_on_block() -> bool:
	var t := _cancel_case(140, BL)
	return t >= 0 and t < _natural_end()


func _test_no_cancel_on_whiff() -> bool:
	var t := _cancel_case(600, 0)
	return t < 0 or t >= _natural_end()


## Апперкот, затем спецприём по подброшенному. Возвращает [урон, был ли второй удар в воздухе].
func _juggle(chars: PackedStringArray, gap: int, special: Dictionary) -> Array:
	var sim := _sim_at(900, 900 + gap, chars)
	var d := sim.fighters[1]
	var script := {0: D | HP}
	for k in special:
		script[k] = special[k]
	var air_hits := 0
	var last_hp := d.hp
	for t in 120:
		sim.step(PackedInt32Array([script.get(t, 0), 0]))
		if d.hp < last_hp and d.state == S.AIR_HIT and d.juggle > 0:
			air_hits += 1
		last_hp = d.hp
	return [1000 - d.hp, air_hits]


func _test_juggle_ram() -> bool:
	# вниз+СР, затем «вперёд, вперёд + ЛР» — таран.
	var r := _juggle(PackedStringArray(["ilya", "dracula"]), 150, {10: R, 12: 0, 13: R | LP})
	if r[0] != 100 + 90 or r[1] != 1:
		print("    урон %d, добиваний %d" % r)
		return false
	return true


func _test_juggle_bats() -> bool:
	# вниз+СР, затем «назад, вперёд + ЛР» — мыши.
	var r := _juggle(PackedStringArray(["dracula", "ilya"]), 150, {9: L, 11: R | LP})
	if r[0] != 85 + 54 or r[1] != 1:
		print("    урон %d, добиваний %d" % r)
		return false
	return true


func _test_juggle_limit() -> bool:
	var sim := _sim_at(900, 1040)
	var d := sim.fighters[1]
	sim.step(PackedInt32Array([D | HP, 0]))
	for t in 20:
		sim.step(PackedInt32Array([0, 0]))
	var launched := d.state == S.AIR_HIT and d.is_juggleable() and not d.hurtboxes().is_empty()
	d.juggle = Fighter.JUGGLE_MAX
	return launched and not d.is_juggleable() and d.is_untouchable() and d.hurtboxes().is_empty()


func _test_no_juggle_after_throw() -> bool:
	var sim := _sim_at(900, 995)
	var d := sim.fighters[1]
	sim.step(PackedInt32Array([LP, 0]))
	for t in 40:
		sim.step(PackedInt32Array([0, 0]))
		if d.state == S.AIR_HIT:
			return d.is_untouchable()
	return false
