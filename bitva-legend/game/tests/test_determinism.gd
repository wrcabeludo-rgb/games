extends SceneTree
## Автотест детерминизма. Запуск: tools/build.sh или
## godot --headless --path game --script res://tests/test_determinism.gd

const TICKS := 3000
const SEED := 20261008


func _init() -> void:
	var ok := true
	ok = _check("одинаковый ввод → одинаковое состояние", _test_same_inputs()) and ok
	ok = _check("откат и повтор → то же состояние", _test_rollback()) and ok
	ok = _check("влево+вправо = нейтраль", _test_socd()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _random_inputs() -> Array[PackedInt32Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var frames: Array[PackedInt32Array] = []
	var held := PackedInt32Array([0, 0])
	for i in TICKS:
		for p in Sim.PLAYERS:
			if rng.randi_range(0, 5) == 0:
				held[p] = rng.randi_range(0, 1023)
		frames.append(held.duplicate())
	return frames


func _test_same_inputs() -> bool:
	var frames := _random_inputs()
	var a := Sim.new()
	var b := Sim.new()
	for f in frames:
		a.step(f)
		b.step(f)
		if a.checksum() != b.checksum():
			return false
	return a.tick == TICKS


func _test_rollback() -> bool:
	var frames := _random_inputs()
	var sim := Sim.new()
	var reference := Sim.new()
	for f in frames:
		reference.step(f)
	# Каждые 100 тиков откатываемся на 8 тиков назад и пересчитываем — как будет в онлайне.
	var snapshots := {}
	var i := 0
	while i < frames.size():
		snapshots[i] = sim.save_state()
		sim.step(frames[i])
		i += 1
		if i % 100 == 0 and i >= 8:
			sim.load_state(snapshots[i - 8])
			i -= 8
			for k in 8:
				sim.step(frames[i])
				i += 1
	return sim.checksum() == reference.checksum()


func _test_socd() -> bool:
	var sim := Sim.new()
	sim.step(PackedInt32Array([InputBits.LEFT | InputBits.RIGHT | InputBits.LP, 0]))
	return sim.inputs[0] == InputBits.LP
