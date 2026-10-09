extends SceneTree
## Автотесты спецприёмов шести новых бойцов (Кощей, Геракл, Афина, Медуза, Сунь Укун, Анубис)
## и новых механик: неуязвимый взлёт, каменный взгляд, кража шкалы.

const SUB := Fighter.SUB
const R := InputBits.RIGHT
const L := InputBits.LEFT
const D := InputBits.DOWN
const LP := InputBits.LP
const LK := InputBits.LK
const HP := InputBits.HP
const HK := InputBits.HK
const BL := InputBits.BLOCK
const NEW := ["koschei", "hercules", "athena", "medusa", "sunwukong", "anubis"]


func _init() -> void:
	Fighter.test_max_hp = 1000
	var ok := true
	for id in NEW:
		ok = _check("%s: у всех четырёх спецприёмов и суперприёма есть данные" % id, _test_has_moves(id)) and ok
		for sp in ["sp_proj_l", "sp_dd_l", "sp_ff_l", "sp_bb_l"]:
			ok = _check("%s: %s вводится и попадает" % [id, sp], _test_special_hits(id, sp)) and ok
		ok = _check("%s: суперприём попадает и бьёт больно" % id, _test_super(id)) and ok
	ok = _check("Сова Паллады: на взлёте удар проходит мимо Афины", _test_invul()) and ok
	ok = _check("Каменный взгляд: попавший соперник каменеет", _test_petrify()) and ok
	ok = _check("Похищение Кощея крадёт шкалу силы", _test_drain()) and ok
	ok = _check("Бессмертие Кощея ловит удар: ударивший застыл", _test_counter()) and ok
	ok = _check("Облако: Сунь Укун за спиной соперника", _test_cloud()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _sim(id: String, gap_px: int) -> Sim:
	var sim := Sim.new(false, PackedStringArray([id, "ilya"]))
	sim.fighters[0].x = 700 * SUB
	sim.fighters[1].x = (700 + gap_px) * SUB
	return sim


func _run(sim: Sim, p1: int, p2: int, ticks := 1) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


func _move_name(f: Fighter) -> String:
	return Fighter.MOVES[f.move] if f.move >= 0 else ""


## Ввод спецприёма первым игроком (смотрит вправо).
func _input(sim: Sim, sp: String, p2 := 0) -> void:
	var button := LK if sp == "sp_dd_l" else LP
	match sp:
		"sp_proj_l":
			_run(sim, L, p2, 2)
			_run(sim, R | button, p2)
		"sp_dd_l":
			_run(sim, D, p2, 2)
			_run(sim, 0, p2, 2)
			_run(sim, D | button, p2)
		"sp_ff_l":
			_run(sim, R, p2, 2)
			_run(sim, 0, p2, 2)
			_run(sim, R | button, p2)
		"sp_bb_l":
			_run(sim, L, p2, 2)
			_run(sim, 0, p2, 2)
			_run(sim, L | button, p2)


func _test_has_moves(id: String) -> bool:
	var moves: Dictionary = FighterData.get_data(id).moves
	for key in ["sp_proj_l", "sp_dd_l", "sp_ff_l", "sp_bb_l", "super"]:
		if not moves.has(key):
			return false
	return true


## Приём узнаётся по вводу и хоть с какой-то дистанции попадает по стоящему.
## Контратака и телепорт ничего не бьют сами — для них только распознавание.
func _test_special_hits(id: String, sp: String) -> bool:
	var m: Dictionary = FighterData.get_data(id).moves[sp]
	for gap in [110, 160, 230, 320, 450, 600]:
		var sim := _sim(id, gap)
		_input(sim, sp)
		if _move_name(sim.fighters[0]) != sp:
			return false
		if m.has("counter") or m.has("teleport"):
			return true
		_run(sim, 0, 0, 150)
		if sim.fighters[1].hp < 1000:
			return true
	return false


func _test_super(id: String) -> bool:
	var sim := _sim(id, 200)
	sim.fighters[0].meter = Fighter.METER_MAX
	_run(sim, BL | HP | HK, 0)
	_run(sim, 0, 0, 220)
	return 1000 - sim.fighters[1].hp >= 250


func _test_invul() -> bool:
	var sim := _sim("athena", 150)
	_run(sim, R, 0, 2)
	_run(sim, 0, 0, 2)
	_run(sim, R | LP, LP)   # Илья бьёт джебом в тот же тик
	var invul := false
	for i in 10:
		invul = invul or sim.fighters[0].is_invulnerable()
		_run(sim, 0, 0)
	_run(sim, 0, 0, 60)
	return invul and sim.fighters[0].hp == 1000 and sim.fighters[1].hp < 1000


func _test_petrify() -> bool:
	var sim := _sim("medusa", 300)
	_input(sim, "sp_dd_l")
	for i in 60:
		_run(sim, 0, 0)
		if sim.fighters[1].hypnotized == 2:
			return true
	return false


func _test_drain() -> bool:
	var sim := _sim("koschei", 130)
	sim.fighters[1].meter = 800
	_input(sim, "sp_bb_l")
	_run(sim, 0, 0, 80)
	return sim.fighters[1].hp < 1000 and sim.fighters[0].meter >= 500 and sim.fighters[1].meter < 800


func _test_counter() -> bool:
	var sim := _sim("koschei", 170)
	_input(sim, "sp_dd_l")
	_run(sim, 0, 0, 2)
	_run(sim, 0, HP)
	for i in 30:
		_run(sim, 0, 0)
		if sim.fighters[1].hypnotized == 1:
			return sim.fighters[0].hp == 1000
	return false


func _test_cloud() -> bool:
	var sim := _sim("sunwukong", 300)
	_input(sim, "sp_dd_l")
	_run(sim, 0, 0, 40)
	return sim.fighters[0].x > sim.fighters[1].x
