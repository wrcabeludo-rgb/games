extends SceneTree
## Автотесты интерфейса: вибрация по событиям боя, сохранение настроек.


func _init() -> void:
	var ok := true
	ok = _check("вибрация: попадание и сбитие с ног — импульсы, выключена — ни одного", _test_rumble()) and ok
	ok = _check("настройки: сохраняются в файл и читаются обратно", _test_settings()) and ok
	ok = _check("управление: кнопка меняется местами с занятой, раскладка сохраняется", _test_controls()) and ok
	ok = _check("аркада: семь разных соперников, седьмой — соперник пары, потом Аватар и Скроллер", _test_arcade()) and ok
	ok = _check("аркада: эпилог у каждого бойца на двух языках", _test_endings()) and ok
	ok = _check("арены: у каждого бойца своя, у каждой пары свой шов, описание полное", _test_arenas()) and ok
	ok = _check("арены: выбор в бою и в аркаде", _test_arena_choice()) and ok
	ok = _check("реплики: у каждого героя по 3 общие до и после боя, у каждой встречи разных героев — по 2 диалога", _test_quotes_variety()) and ok
	ok = _check("реплики: на каждую победную фразу пары-соперников есть ответ проигравшего", _test_lose_quotes()) and ok
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


func _test_controls() -> bool:
	Settings.reset_controls()
	Settings.bind(Settings.pad_map, InputBits.LP, JOY_BUTTON_A)       # крест был у ЛН
	Settings.bind(Settings.key_map, InputBits.BLOCK, KEY_SPACE)
	var swapped: bool = Settings.pad_map[InputBits.LP] == JOY_BUTTON_A and Settings.pad_map[InputBits.LK] == JOY_BUTTON_X
	Settings.save_file()
	Settings.reset_controls()
	Settings.load_file()
	var ok: bool = swapped and Settings.pad_map[InputBits.LP] == JOY_BUTTON_A and Settings.key_map[InputBits.BLOCK] == KEY_SPACE
	Settings.reset_controls()
	Settings.save_file()
	return ok


func _test_arcade() -> bool:
	for id in MenuView.ROSTER:
		for seed_value in [1, 2, 3]:
			var run := Arcade.new(id, MenuView.ROSTER, seed_value)
			var uniq := {}
			for o in run.ladder:
				uniq[o] = true
			if run.ladder.size() != 9 or uniq.size() != 9 or uniq.has(id) or run.ladder[6] != Arcade.RIVALS[id] \
					or run.ladder[7] != Arcade.AVATAR or run.ladder[8] != Arcade.BOSS:
				print("  ", id, run.ladder)
				return false
			for i in 8:
				if run.advance():
					return false
			if not run.is_final() or not run.advance():
				return false
	return true


func _test_endings() -> bool:
	for id in MenuView.ROSTER:
		var rows: Array = Endings.ENDINGS.get(id, [])
		if rows.size() < 2:
			return false
		for row in rows:
			if row.size() != 2 or row[0] == "" or row[1] == "":
				return false
	return true


func _test_arenas() -> bool:
	for id in FighterData.CHARACTERS:
		if not Arenas.LIST.has(Arenas.home(id)) or Arenas.home(id) == Arenas.DEFAULT:
			return false
	for key in Arenas.SEAMS:
		if not Arenas.LIST.has(Arenas.SEAMS[key]):
			return false
	for id in Arenas.LIST:
		var d: Dictionary = Arenas.LIST[id]
		for field in ["name", "dir", "sky", "light", "hills", "shape", "marks", "trees", "ground", "birds"]:
			if not d.has(field):
				print("  у арены %s нет поля %s" % [id, field])
				return false
		if Loc.EN.get(d.name, "") == "":
			print("  нет перевода названия арены %s" % id)
			return false
	return true


func _test_arena_choice() -> bool:
	return Arenas.for_versus("ilya", "dracula", 0) == "crossroads" \
		and Arenas.for_versus("medusa", "athena", 1) == "coast" \
		and Arenas.for_versus("ilya", "ilya", 0) == "zastava" \
		and Arenas.for_versus("ilya", "medusa", 1) == "gorgon_isle" \
		and Arenas.for_versus("ilya", "medusa", 0) == "zastava" \
		and Arenas.for_arcade("ilya", "anubis") == "duat" \
		and Arenas.for_arcade("ilya", "dracula") == "crossroads" \
		and Arenas.for_arcade("ilya", "avatar") == "den" \
		and Arenas.for_arcade("ilya", "scroller") == "den"


func _test_quotes_variety() -> bool:
	var heroes: Array = MenuView.ROSTER
	for id in heroes + Arcade.FINALS:
		if Quotes.GENERIC_INTRO.get(id, []).size() < 3 or Quotes.GENERIC_WIN.get(id, []).size() < 3:
			print("  мало общих реплик: ", id)
			return false
	for a in heroes:
		for b in heroes + Arcade.FINALS:
			var ids := [a, b]
			ids.sort()
			var key := "%s|%s" % ids
			var need := 1 if a == b else 2
			var dialogs: Array = Quotes.INTRO.get(key, [])
			if dialogs.size() < need:
				print("  мало диалогов: ", key)
				return false
			for dlg in dialogs:
				for line in dlg:
					if not line[0] in ids or line[1] == "" or line[2] == "":
						print("  чужой или пустой голос в ", key)
						return false
	return true


func _test_lose_quotes() -> bool:
	for loser in Quotes.LOSE:
		for winner in Quotes.LOSE[loser]:
			var wins: Array = Quotes.WIN.get(winner, {}).get(loser, [])
			if wins.size() != Quotes.LOSE[loser][winner].size():
				print("  %s → %s: побед %d, ответов %d" % [winner, loser, wins.size(), Quotes.LOSE[loser][winner].size()])
				return false
	for winner in Quotes.WIN:
		for loser in Quotes.WIN[winner]:
			if Quotes.lose(loser, winner, 0) == "":
				print("  нет ответа: %s → %s" % [winner, loser])
				return false
	return true


func _check(name: String, passed: bool) -> bool:
	print(("  OK   " if passed else "  FAIL ") + name)
	return passed
