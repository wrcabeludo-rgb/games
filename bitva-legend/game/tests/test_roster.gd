extends SceneTree
## Автотесты состава: каждый боец из сетки выбора может драться с каждым.


func _init() -> void:
	var ok := true
	var ids: Array = FighterData.CHARACTERS.keys()
	for a in ids:
		for b in ids:
			ok = _check("%s против %s: бой ИИ против ИИ без ошибок, удары проходят" % [a, b], _test_pair(a, b)) and ok
	for id in MenuView.ROSTER:
		if id != "":
			ok = _check("%s есть в данных бойцов" % id, FighterData.CHARACTERS.has(id)) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _test_pair(a: String, b: String) -> bool:
	var sim := Sim.new(false, PackedStringArray([a, b]))
	var ai0 := AiController.new(1)
	var ai1 := AiController.new(2)
	ai0.level = AiController.Level.HARD
	ai1.level = AiController.Level.HARD
	for i in 1800:
		sim.step(PackedInt32Array([ai0.get_input(sim, 0), ai1.get_input(sim, 1)]))
	var hurt := sim.fighters[0].hp < sim.fighters[0].max_hp or sim.fighters[1].hp < sim.fighters[1].max_hp \
		or sim.phase != Sim.Phase.FIGHT
	return hurt


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed
