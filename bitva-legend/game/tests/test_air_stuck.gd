extends SceneTree
## Боец не должен «зависать» над землёй в наземном состоянии (стойка, оглушение, блок…).
## Случайные бои; среди них — найденный случай: парирован удар в прыжке (Дракула завис оглушённым).

const S := Fighter.State
const DIRS := [0, 1, 2, 4, 8, 1 | 8, 1 | 4, 2 | 8, 2 | 4]
const BTN := [0, 0, 0, 16, 32, 64, 128, 256]


func _init() -> void:
	var ok := true
	ok = _check("парированный в прыжке падает, а не висит в воздухе", _run_fuzz(["dracula", "ilya"], [43])) and ok
	ok = _check("случайные бои: никто не стоит в воздухе", _run_fuzz(["ilya", "koschei"], [1, 2, 3, 4]) and _run_fuzz(["dracula", "ilya"], [5, 6, 7])) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _run_fuzz(pair: Array, seeds: Array) -> bool:
	var rng := RandomNumberGenerator.new()
	for seed in seeds:
		rng.seed = seed * 7919 + 13
		var sim := Sim.new(true, PackedStringArray(pair))
		sim.set_training(true)
		var bits := [0, 0]
		for t in 2000:
			for p in 2:
				if rng.randi() % 5 == 0:
					bits[p] = DIRS[rng.randi() % DIRS.size()] | BTN[rng.randi() % BTN.size()]
			sim.step(PackedInt32Array([bits[0], bits[1]]))
			for f in sim.fighters:
				if f.y > 0 and not (f.state in [S.AIR, S.AIR_HIT, S.THROWN, S.ATTACK]) and f.state_frame > 25:
					print("  завис: ", pair, " seed ", seed, " тик ", t, " ", S.keys()[f.state], " y ", f.y / Fighter.SUB)
					return false
	return true


func _check(name: String, ok: bool) -> bool:
	print(("  OK   " if ok else "  FAIL ") + name)
	return ok
