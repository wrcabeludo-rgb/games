extends SceneTree
## Автотесты ИИ-соперника.

const SUB := Fighter.SUB
const LV := AiController.Level


func _init() -> void:
	var ok := true
	for lv in [LV.EASY, LV.MEDIUM, LV.HARD]:
		ok = _check("ИИ (%s) наносит урон стоящему игроку" % AiController.LEVEL_NAMES[lv], _test_deals_damage(lv)) and ok
	ok = _check("сложный ИИ пропускает меньше ударов, чем лёгкий", _test_hard_blocks_more()) and ok
	ok = _check("бой двух ИИ доходит до конца матча", _test_ai_vs_ai()) and ok
	ok = _check("ИИ с одинаковым зерном играет одинаково", _test_ai_deterministic()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _ai(level: LV, seed_value := 7) -> AiController:
	var ai := AiController.new(seed_value)
	ai.level = level
	ai.reset()
	return ai


func _test_deals_damage(level: LV) -> bool:
	var sim := Sim.new(false)
	var ai := _ai(level)
	for i in 1800:
		sim.step(PackedInt32Array([0, ai.get_input(sim, 1)]))
	return sim.fighters[0].hp < Fighter.MAX_HP


## Илья вплотную раз за разом бьёт ЛР; считаем урон по ИИ за 20 секунд.
func _damage_taken(level: LV) -> int:
	var sim := Sim.new(false)
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 1000 * SUB
	var ai := _ai(level)
	var total := 0
	var last_hp := sim.fighters[1].hp
	for i in 1200:
		var p1 := InputBits.LP if i % 24 == 0 else (InputBits.RIGHT if i % 24 > 12 else 0)
		sim.step(PackedInt32Array([p1, ai.get_input(sim, 1)]))
		var hp := sim.fighters[1].hp
		if hp < last_hp:
			total += last_hp - hp
		last_hp = hp
		if sim.phase != Sim.Phase.FIGHT:
			break
	return total


func _test_hard_blocks_more() -> bool:
	return _damage_taken(LV.HARD) < _damage_taken(LV.EASY)


func _test_ai_vs_ai() -> bool:
	var sim := Sim.new()
	var a := _ai(LV.MEDIUM, 1)
	var b := _ai(LV.HARD, 2)
	for i in 60 * 60 * 6:
		sim.step(PackedInt32Array([a.get_input(sim, 0), b.get_input(sim, 1)]))
		if sim.phase == Sim.Phase.MATCH_END:
			return true
	return false


func _test_ai_deterministic() -> bool:
	var sums := []
	for run in 2:
		var sim := Sim.new(false)
		var a := _ai(LV.MEDIUM, 11)
		var b := _ai(LV.MEDIUM, 12)
		for i in 1500:
			sim.step(PackedInt32Array([a.get_input(sim, 0), b.get_input(sim, 1)]))
		sums.append(sim.checksum())
	return sums[0] == sums[1]
