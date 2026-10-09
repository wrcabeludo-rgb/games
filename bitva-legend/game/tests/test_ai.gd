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
	for id in FighterData.CHARACTERS:
		ok = _check("ИИ за %s применяет свои спецприёмы" % id, _test_uses_specials(id)) and ok
	ok = _check("манера: Дракула и Анубис держатся дальше, чем Геракл и Илья", _test_styles_distance()) and ok
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
	return sim.fighters[0].hp < sim.fighters[0].max_hp


## Илья на дистанции джеба раз за разом бьёт ЛР; считаем урон по ИИ за 20 секунд.
func _damage_taken(level: LV, seed_value := 7) -> int:
	var sim := Sim.new(false)
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 1040 * SUB
	var ai := _ai(level, seed_value)
	var total := 0
	var last_hp := sim.fighters[1].hp
	for i in 1200:
		# Держит дистанцию джеба: вплотную ЛР стал бы броском (он проходит сквозь блок и мешал бы замеру).
		# Подходит, только если далеко; «вперёд» зажат, пока подходит (повторные тапы — это парирование).
		var gap := absi(sim.fighters[1].x - sim.fighters[0].x) / SUB
		var p1 := (InputBits.RIGHT if gap > 190 else 0) | (InputBits.LP if i % 24 == 0 else 0)
		sim.step(PackedInt32Array([p1, ai.get_input(sim, 1)]))
		var hp := sim.fighters[1].hp
		if hp < last_hp:
			total += last_hp - hp
		last_hp = hp
		if sim.phase != Sim.Phase.FIGHT:
			break
	return total


## Сумма по пяти прогонам: в одном бою случайность ИИ может перевесить разницу уровней.
func _test_hard_blocks_more() -> bool:
	var easy := 0
	var hard := 0
	for s in [1, 2, 3, 4, 7]:
		easy += _damage_taken(LV.EASY, s)
		hard += _damage_taken(LV.HARD, s)
	return hard < easy


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


## Бой сложных ИИ: боец хоть раз начинает спецприём.
func _test_uses_specials(id: String) -> bool:
	var sim := Sim.new(false, PackedStringArray([id, "ilya"]))
	var a := _ai(LV.HARD, 3)
	var b := _ai(LV.MEDIUM, 4)
	for i in 3600:
		sim.step(PackedInt32Array([a.get_input(sim, 0), b.get_input(sim, 1)]))
		var f := sim.fighters[0]
		if f.state == Fighter.State.ATTACK and f.move >= Fighter.SPECIAL_BASE and f.move < Fighter.MOVE_SWEEP:
			return true
	return false


## Средняя дистанция до одного и того же соперника за минуту боя, px.
func _mean_distance(id: String) -> float:
	var total := 0.0
	var n := 0
	for seed_value in [1, 2]:
		var sim := Sim.new(false, PackedStringArray([id, "athena"]))
		var a := _ai(LV.HARD, seed_value)
		var b := _ai(LV.MEDIUM, seed_value + 10)
		for i in 3600:
			sim.step(PackedInt32Array([a.get_input(sim, 0), b.get_input(sim, 1)]))
			if sim.phase == Sim.Phase.FIGHT:
				total += absi(sim.fighters[0].x - sim.fighters[1].x) / float(SUB)
				n += 1
	return total / maxi(n, 1)


func _test_styles_distance() -> bool:
	var far := (_mean_distance("dracula") + _mean_distance("anubis")) / 2.0
	var near := (_mean_distance("hercules") + _mean_distance("ilya")) / 2.0
	print("    дистанция: дальние %d px, ближние %d px" % [far, near])
	return far > near + 30

