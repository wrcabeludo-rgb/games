extends SceneTree
## Автотесты матча (подэтап 1.6): раунды, таймер, нокаут, победа, реванш.

const SUB := Fighter.SUB
const P := Sim.Phase
const R := InputBits.RIGHT
const LP := InputBits.LP


func _init() -> void:
	var ok := true
	ok = _check("во вступлении бойцы не двигаются", _test_intro_frozen()) and ok
	ok = _check("после вступления — бой и таймер идёт", _test_timer_runs()) and ok
	ok = _check("в заморозке таймер стоит", _test_timer_hitstop()) and ok
	ok = _check("нокаут: конец раунда, победа, соперник лежит", _test_ko()) and ok
	ok = _check("следующий раунд: здоровье и позиции сброшены", _test_next_round()) and ok
	ok = _check("две победы — конец матча", _test_match_win()) and ok
	ok = _check("время вышло — побеждает тот, у кого больше здоровья", _test_timeout()) and ok
	ok = _check("время вышло при равном здоровье — ничья, победа обоим", _test_draw()) and ok
	ok = _check("двойной нокаут — ничья", _test_double_ko()) and ok
	ok = _check("реванш по кнопке удара после конца матча", _test_rematch()) and ok
	ok = _check("решающий нокаут: «ДОБИВАЙ!», команда вплотную — добивание, потом победа", _test_finisher()) and ok
	ok = _check("не добил за отведённое время — обычная победа, никто не застрял", _test_finish_timeout()) and ok
	ok = _check("ничья при счёте 1:1 — «Последний бой», а не ничья в матче", _test_last_bout()) and ok
	ok = _check("здоровье: Илья 1100, Дракула 950", _test_max_hp()) and ok
	ok = _check("меньше 30% здоровья — шкала копится в полтора раза быстрее", _test_comeback_meter()) and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed


func _run(sim: Sim, p1: int, p2: int, ticks := 1) -> void:
	for i in ticks:
		sim.step(PackedInt32Array([p1, p2]))


## Бой без вступления, бойцы вплотную; у Дракулы мало здоровья — Илья добивает ЛР.
func _ko_sim() -> Sim:
	var sim := Sim.new(false)
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 1040 * SUB
	sim.fighters[1].hp = 30
	return sim


func _ko(sim: Sim) -> void:
	_run(sim, LP, 0)
	_run(sim, 0, 0, 10)


func _test_intro_frozen() -> bool:
	var sim := Sim.new()
	var x0 := sim.fighters[0].x
	_run(sim, R, 0, Sim.INTRO_TICKS - 1)
	return sim.phase == P.INTRO and sim.fighters[0].x == x0 and sim.timer == Sim.ROUND_TICKS


func _test_timer_runs() -> bool:
	var sim := Sim.new()
	_run(sim, 0, 0, Sim.INTRO_TICKS)
	var fight := sim.phase == P.FIGHT
	_run(sim, 0, 0, 60)
	return fight and sim.timer == Sim.ROUND_TICKS - 60


func _test_timer_hitstop() -> bool:
	var sim := Sim.new(false)
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 1040 * SUB
	_run(sim, LP, 0)
	_run(sim, 0, 0, 4)  # попадание и начало заморозки (8 тиков)
	var t0 := sim.timer
	_run(sim, 0, 0, 8)
	return sim.hitstop == 0 and sim.timer == t0


func _test_ko() -> bool:
	var sim := _ko_sim()
	_ko(sim)
	var ended := sim.phase == P.ROUND_END and sim.end_reason == Sim.EndReason.KO \
		and sim.round_winner == 0 and sim.wins[0] == 1
	_run(sim, 0, 0, 120)
	return ended and sim.fighters[1].state == Fighter.State.DOWN


func _test_next_round() -> bool:
	var sim := _ko_sim()
	_ko(sim)
	_run(sim, 0, 0, Sim.ROUND_END_TICKS)
	var f := sim.fighters[1]
	return sim.phase == P.INTRO and sim.round_num == 2 and f.hp == f.max_hp \
		and f.state == Fighter.State.STAND and sim.timer == Sim.ROUND_TICKS and sim.wins[0] == 1


## До конца матча (после решающего нокаута идёт время на добивание).
func _to_match_end(sim: Sim) -> void:
	for i in 1000:
		if sim.phase == P.MATCH_END:
			return
		_run(sim, 0, 0)


func _test_match_win() -> bool:
	var sim := _ko_sim()
	sim.wins[0] = 1
	_ko(sim)
	_to_match_end(sim)
	return sim.phase == P.MATCH_END and sim.match_winner() == 0


func _test_timeout() -> bool:
	var sim := Sim.new(false)
	sim.fighters[0].hp = 400
	sim.timer = 2
	_run(sim, 0, 0, 2)
	return sim.phase == P.ROUND_END and sim.end_reason == Sim.EndReason.TIME and sim.round_winner == 1


func _test_draw() -> bool:
	var sim := Sim.new(false)
	sim.timer = 1
	_run(sim, 0, 0)
	return sim.round_winner == 2 and sim.wins[0] == 1 and sim.wins[1] == 1


func _test_double_ko() -> bool:
	var sim := Sim.new(false)
	sim.fighters[0].x = 900 * SUB
	sim.fighters[1].x = 990 * SUB
	sim.fighters[0].hp = 10
	sim.fighters[1].hp = 10
	# Ноги Ильи (7 кадров) и Дракулы (5 кадров) — Дракула быстрее, поэтому Илья бьёт на 2 тика раньше.
	_run(sim, InputBits.LK, 0, 1)
	_run(sim, 0, 0, 1)
	_run(sim, 0, InputBits.LK, 1)
	_run(sim, 0, 0, 10)
	return sim.end_reason == Sim.EndReason.DOUBLE_KO and sim.round_winner == 2


func _test_rematch() -> bool:
	var sim := _ko_sim()
	sim.wins[0] = 1
	_ko(sim)
	_to_match_end(sim)
	_run(sim, 0, LP)  # слишком рано — игнорируется
	var early_ignored := sim.phase == P.MATCH_END
	_run(sim, 0, 0, Sim.REMATCH_DELAY)
	_run(sim, 0, LP)
	return early_ignored and sim.phase == P.INTRO and sim.round_num == 1 and sim.wins[0] == 0


## Решающий нокаут и ожидание фазы добивания.
func _to_finish() -> Sim:
	var sim := _ko_sim()
	sim.wins[0] = 1
	_ko(sim)
	for i in 400:
		if sim.phase == P.FINISH:
			break
		_run(sim, 0, 0)
	return sim


func _test_finisher() -> bool:
	var sim := _to_finish()
	if sim.phase != P.FINISH or sim.fighters[1].state != Fighter.State.HITSTUN or sim.fighters[1].staggered != 1:
		return false
	# Подойти вплотную.
	for i in 120:
		if absi(sim.fighters[1].x - sim.fighters[0].x) <= 220 * SUB:
			break
		_run(sim, R, 0)
	_run(sim, 0, 0, 2)
	_run(sim, R, 0)
	_run(sim, 0, 0, 2)
	_run(sim, InputBits.LEFT, 0)
	_run(sim, 0, 0, 2)
	_run(sim, InputBits.HP, 0)
	var started := sim.phase == P.FINISHER and sim.finished
	_to_match_end(sim)
	return started and sim.match_winner() == 0


func _test_finish_timeout() -> bool:
	var sim := _to_finish()
	var was_finish := sim.phase == P.FINISH
	_to_match_end(sim)
	_run(sim, 0, 0, 120)
	var d := sim.fighters[1]
	return was_finish and not sim.finished and sim.match_winner() == 0 \
		and d.state != Fighter.State.HITSTUN and d.y == 0


func _test_last_bout() -> bool:
	var sim := Sim.new(false)
	sim.wins = PackedInt32Array([1, 1])
	sim.timer = 1
	_run(sim, 0, 0)
	var held := sim.round_winner == 2 and sim.wins[0] == 1 and sim.wins[1] == 1 and sim.last_bout
	_run(sim, 0, 0, Sim.ROUND_END_TICKS)
	return held and sim.phase == P.INTRO and sim.match_winner() == -1


func _test_max_hp() -> bool:
	var sim := Sim.new(false, PackedStringArray(["ilya", "dracula"]))
	return sim.fighters[0].hp == 1100 and sim.fighters[0].max_hp == 1100 and sim.fighters[1].hp == 950


func _test_comeback_meter() -> bool:
	var sim := Sim.new(false)
	var f := sim.fighters[0]
	f.add_meter(100)
	var normal := f.meter
	f.meter = 0
	f.hp = f.max_hp / 4
	f.add_meter(100)
	return normal == 100 and f.meter == 150
