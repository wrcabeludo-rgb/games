extends SceneTree
## Автотесты звука: музыка и диктор срабатывают по событиям, а не каждый тик.


func _init() -> void:
	var ok := true
	ok = _check("начало боя: трек включается один раз, «Round 1» и «Fight» — по разу", _test_round_start()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _test_round_start() -> bool:
	var sound := SoundDirector.new()
	root.add_child(sound)
	sound.menu()
	var starts := sound.music_starts
	var sim := Sim.new(true)
	for i in Sim.INTRO_TICKS + 30:
		sim.step(PackedInt32Array([0, 0]))
		sound.update(sim, false)
	var ok := sound.music_starts == starts + 1 and sound.voice_lines == 2
	sound.queue_free()
	return ok


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed
