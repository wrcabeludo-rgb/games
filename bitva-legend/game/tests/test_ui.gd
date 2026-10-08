extends SceneTree
## Автотесты интерфейса: вибрация по событиям боя, сохранение настроек.


func _init() -> void:
	var ok := true
	ok = _check("вибрация: попадание и сбитие с ног — импульсы, выключена — ни одного", _test_rumble()) and ok
	ok = _check("настройки: сохраняются в файл и читаются обратно", _test_settings()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


## Илья подходит и бьёт СН с разворота (сбивает с ног); считаем импульсы.
func _pulses(level: int) -> int:
	Settings.rumble = level
	var sim := Sim.new(false)
	sim.fighters[0].x = 900 * Fighter.SUB
	sim.fighters[1].x = 1080 * Fighter.SUB
	var reader := InputReader.new()
	var rumble := Rumble.new()
	for i in 120:
		var bits := InputBits.LEFT | InputBits.HK if i == 2 else 0
		sim.step(PackedInt32Array([bits, 0]))
		rumble.update(sim, reader)
	return rumble.pulses


func _test_rumble() -> bool:
	var on := _pulses(1)
	var off := _pulses(0)
	Settings.rumble = 1
	return on >= 2 and off == 0


func _test_settings() -> bool:
	var keep := [Settings.music, Settings.rumble, Settings.hints]
	Settings.music = 3
	Settings.rumble = 2
	Settings.hints = true
	Settings.save_file()
	Settings.music = 9
	Settings.rumble = 0
	Settings.hints = false
	Settings.load_file()
	var ok := Settings.music == 3 and Settings.rumble == 2 and Settings.hints
	Settings.music = keep[0]
	Settings.rumble = keep[1]
	Settings.hints = keep[2]
	Settings.save_file()
	return ok


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed
