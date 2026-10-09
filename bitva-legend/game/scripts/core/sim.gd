class_name Sim
extends RefCounted
## Детерминированная симуляция боя.
## Правила: только целые числа, никакого времени кадра, никакого рандома без сида.
## Всё состояние сохраняется и восстанавливается через save_state/load_state —
## это основа будущего rollback-онлайна.

const PLAYERS := 2
const HISTORY_LEN := 24
const MAX_HOLD_FRAMES := 999

const ARENA_WIDTH := 2000           # ширина арены, пикселей
const START_GAP := 440              # расстояние между бойцами в начале раунда
const MAX_SEPARATION := 1100        # дальше не разойтись: оба должны помещаться в кадр
const SUB := Fighter.SUB

## Фазы матча.
enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END, FINISH, FINISHER }
enum EndReason { NONE, KO, TIME, DOUBLE_KO }
const INTRO_TICKS := 80             # «РАУНД N» — бойцы ещё не двигаются
const ROUND_TICKS := 60 * 60        # таймер раунда: 60 секунд
const ROUND_END_TICKS := 200        # пауза после конца раунда
const REMATCH_DELAY := 60           # после конца матча кнопки работают не сразу
const KO_FREEZE := 40               # драматичная заморозка на нокауте
const WINS_NEEDED := 2
## Добивание: после решающего нокаута проигравший встаёт оглушённым, у победителя есть время
## ввести «вперёд, назад + СР» вплотную. Сами добивания — заглушка, будут переписаны.
const FINISH_DELAY := 110           # тиков после нокаута до «ДОБИВАЙ!»
const FINISH_TICKS := 180           # время на команду
const FINISH_STEP := 30             # между нажатиями команды — не дольше
const FINISH_RANGE := 420           # дистанция удара: не дальше, px между бойцами
const FINISHER_TICKS := 160         # ролик добивания
const ATTACK_MASK := InputBits.LP | InputBits.LK | InputBits.HP | InputBits.HK

## Поля снаряда (PackedInt32Array): владелец, позиция, скорость, гравитация, размер,
## урон и прочее из данных спецприёма, вид для отрисовки, возраст.
enum Proj { OWNER, X, Y, VX, VY, GRAV, HW, HH, DMG, STUN, STOP, PUSH, CHIP, KIND, AGE, LOW, LIFE, SIZE }
const TECH_WINDOW := 8              # вырваться из броска: ЛР в первые тики захвата
const THROW_HITSTOP := 12
const ARMOR_HITSTOP := 6            # короткая заморозка, когда удар принят бронёй
const COUNTER_HITSTOP := 24         # драматичная пауза при удачной контратаке
const PROJ_MARGIN := 150            # снаряд исчезает за краем арены на столько пикселей
## Тренировка (2.7): без таймера и раундов, нокаута нет, здоровье восстанавливается
## через REFILL_DELAY тиков после конца комбо, шкала всегда полная.
const REFILL_DELAY := 45
const PARRY_HITSTOP := 16          # парирование: короткая пауза с синей вспышкой
const PARRY_METER := 60
const SUPER_FLASH := 30             # суперприём: пауза с затемнением перед ударом
## Шкала силы: за попадание атакующему — урон × 2, за блок — урон; пропустившему удар — урон.
const METER_HIT := 2
const METER_BLOCK := 1
const METER_TAKEN := 1

var tick := 0
var inputs := PackedInt32Array([0, 0])
## История ввода по игрокам: записи [биты, сколько тиков удерживались], новые — первыми.
var history: Array = [[], []]
var fighters: Array[Fighter] = []
## Заморозка после попадания: пока > 0, бойцы стоят, но нажатия запоминаются.
var hitstop := 0
var hitstop_total := 0              # длительность текущей заморозки (для тряски камеры)
## Последнее попадание каждого игрока (для искр): [тик, x, y, вид]:
## 0 лёгкий, 1 сильный, 2 блок, 3 удар в броню, 4 контратака-гипноз, 5 парирование (p — парировавший).
var sparks := PackedInt32Array([-999, 0, 0, 0, -999, 0, 0, 0])

var phase := Phase.INTRO
var phase_frame := 0
var round_num := 1
var wins := PackedInt32Array([0, 0])
var timer := ROUND_TICKS
var round_winner := -1              # -1 ещё нет, 0/1 — игрок, 2 — ничья
var end_reason := EndReason.NONE
var prev_inputs := PackedInt32Array([0, 0])
var projectiles: Array[PackedInt32Array] = []
var training := false
## После конца матча удар начинает реванш. В аркаде выключено: что дальше, решает main.
var auto_rematch := true
## Ничья в решающем раунде (1:1): следующий — «Последний бой», пока кто-то не победит.
var last_bout := false
## Добивание: этап ввода команды (0 — ждём «вперёд», 1 — «назад», 2 — СР), сколько ждать, было ли.
var finish_step := 0
var finish_wait := 0
var finished := false
var refill_wait := PackedInt32Array([0, 0])


## Персонажи игроков (id из FighterData). Можно выбрать одинаковых.
var chars := PackedStringArray(["ilya", "dracula"])


## with_intro = false — сразу бой (для тестов и тренировки).
func _init(with_intro := true, characters := PackedStringArray(["ilya", "dracula"])) -> void:
	chars = characters
	_reset_fighters(false)
	if not with_intro:
		phase = Phase.FIGHT


@warning_ignore("integer_division")
func _reset_fighters(keep_meter := true) -> void:
	var meters := PackedInt32Array([0, 0])
	if keep_meter:
		meters = PackedInt32Array([fighters[0].meter, fighters[1].meter])
	var center := ARENA_WIDTH / 2
	fighters = [
		Fighter.new(chars[0], center - START_GAP / 2, 1),
		Fighter.new(chars[1], center + START_GAP / 2, -1),
	]
	fighters[1].alt = chars[0] == chars[1]
	# Шкала силы переходит в следующий раунд (новый матч — с нуля).
	fighters[0].meter = meters[0]
	fighters[1].meter = meters[1]
	hitstop = 0
	hitstop_total = 0
	projectiles = []


func step(frame_inputs: PackedInt32Array) -> void:
	for p in PLAYERS:
		var bits := InputBits.clean_socd(frame_inputs[p])
		prev_inputs[p] = inputs[p]
		inputs[p] = bits
		_record_history(p, bits)

	var idle := PackedInt32Array([0, 0])
	phase_frame += 1
	match phase:
		Phase.INTRO:
			_combat_step(idle, false)
			if phase_frame >= INTRO_TICKS:
				_set_phase(Phase.FIGHT)
		Phase.FIGHT:
			var frozen := hitstop > 0
			_combat_step(inputs, true)
			if training:
				_training_upkeep()
			else:
				if not frozen:
					timer = maxi(timer - 1, 0)
				_check_round_end()
		Phase.ROUND_END:
			_combat_step(idle, false)
			if phase_frame >= ROUND_END_TICKS:
				if wins[0] >= WINS_NEEDED or wins[1] >= WINS_NEEDED:
					_set_phase(Phase.MATCH_END)
				else:
					_next_round()
			elif phase_frame == FINISH_DELAY and _finish_allowed():
				_start_finish()
		Phase.FINISH:
			var w := round_winner
			var inp := PackedInt32Array([0, 0])
			inp[w] = inputs[w]
			_combat_step(inp, false)
			if _finish_input(w):
				_start_finisher(w)
			elif phase_frame >= FINISH_TICKS:
				fighters[1 - w].finisher_launch(0)  # не добил — падает
				fighters[1 - w].vx = 0
				fighters[1 - w].vy = 0
				_set_phase(Phase.MATCH_END)
		Phase.FINISHER:
			_combat_step(PackedInt32Array([0, 0]), false)
			if phase_frame >= FINISHER_TICKS:
				_set_phase(Phase.MATCH_END)
		Phase.MATCH_END:
			_combat_step(idle, false)
			if auto_rematch and phase_frame >= REMATCH_DELAY and _any_attack_pressed():
				_new_match()
	tick += 1


## Один тик боя. hits = false — удары не попадают (вне фазы боя).
func _combat_step(inp: PackedInt32Array, hits: bool) -> void:
	if hitstop > 0:
		for p in PLAYERS:
			fighters[p].read_input(inp[p], false)
		hitstop -= 1
		return
	var prev_x := PackedInt32Array([fighters[0].x, fighters[1].x])
	for f in fighters:
		f.min_hp = 1 if training else 0
	for p in PLAYERS:
		fighters[p].projectile_alive = has_projectile(p)
		fighters[p].throw_ok = hits and _can_throw(p)
		fighters[p].step(inp[p])
	_super_flash()
	_wall_pushback()
	_resolve_push()
	_limit_separation(prev_x)
	_clamp_walls()
	_teleports()
	_process_grabs()
	_hold_throws()
	_release_orphans()
	_move_projectiles()
	_spawn_projectiles()
	if hits:
		_check_hits()
		_check_projectiles()
	_update_facing()
	for f in fighters:
		f.tech_press = 0


## Начало суперприёма: всё замирает, экран темнеет (рисует отрисовка по SUPER_FLASH).
func _super_flash() -> void:
	for f in fighters:
		if f.flash_request:
			f.flash_request = 0
			hitstop = maxi(hitstop, SUPER_FLASH)
			hitstop_total = 0  # без тряски


func _throw_gap(a: Fighter, d: Fighter) -> int:
	return absi(d.x - a.x) - a.push_half() - d.push_half()


## ЛР станет броском, если соперник вплотную и его можно схватить.
func _can_throw(p: int) -> bool:
	var a := fighters[p]
	var d := fighters[1 - p]
	if not a.data.moves.has("throw") or a.y != 0 or not d.is_throwable():
		return false
	return _throw_gap(a, d) <= a.data.moves.throw.grab.range * SUB


## Кадр захвата: схватил, если соперник в досягаемости и его можно бросить; иначе — промах.
func _process_grabs() -> void:
	for p in PLAYERS:
		var a := fighters[p]
		if a.grab_request == 0:
			continue
		a.grab_request = 0
		var d := fighters[1 - p]
		if a.state != Fighter.State.ATTACK or not d.is_throwable():
			continue
		var g: Dictionary = a.move_data().grab
		if _throw_gap(a, d) > g.range * SUB:
			continue
		a.stun = g.hold
		a.vx = 0
		a.state = Fighter.State.THROWING
		a.state_frame = 0
		d.become_thrown()
		_hold_position(a, d)


const HOLD_DROP := 40               # схваченный в прыжке (суперприём) опускается на землю, px за тик


func _hold_position(a: Fighter, d: Fighter) -> void:
	d.x = a.x + a.facing * (a.push_half() + d.push_half())
	d.y = maxi(d.y - HOLD_DROP * SUB, 0)
	d.x = clampi(d.x, d.push_half(), ARENA_WIDTH * SUB - d.push_half())


## Удержание в захвате: можно вырваться (ЛР в первые TECH_WINDOW тиков), иначе — бросок.
func _hold_throws() -> void:
	for p in PLAYERS:
		var a := fighters[p]
		if a.state != Fighter.State.THROWING:
			continue
		var d := fighters[1 - p]
		var m := a.move_data()
		var g: Dictionary = m.grab if m.has("grab") else m.cinema
		_hold_position(a, d)
		if g.tech and d.tech_press and d.state_frame <= TECH_WINDOW:
			a.throw_break(-a.facing)
			d.throw_break(a.facing)
			hitstop = 8
			hitstop_total = 8
			_set_spark(1 - p, (a.x + d.x) / 2, a.data.height * SUB / 2, 2)
			continue
		a.stun -= 1
		if a.stun > 0:
			continue
		d.take_throw(g, a.facing)
		if not g.has("scaled"):
			a.add_meter(g.damage * METER_HIT)
			d.add_meter(g.damage * METER_TAKEN)
		if g.has("heal"):
			a.hp = mini(a.hp + g.heal, a.max_hp)
		a.finish_throw(g.recovery)
		hitstop = THROW_HITSTOP
		hitstop_total = THROW_HITSTOP
		_set_spark(p, d.x, d.data.height * SUB / 2, 1)


## Страховка: схваченный, которого никто не держит (бросающего сбили), освобождается.
## Иначе он навсегда остался бы в захвате — неуязвимым и неподвижным.
func _release_orphans() -> void:
	for p in PLAYERS:
		if fighters[p].state == Fighter.State.THROWN and fighters[1 - p].state != Fighter.State.THROWING:
			fighters[p].release_grab()


func has_projectile(owner: int) -> bool:
	for pr in projectiles:
		if pr[Proj.OWNER] == owner:
			return true
	return false


func _spawn_projectiles() -> void:
	for p in PLAYERS:
		var f := fighters[p]
		if f.spawn_request == 0:
			continue
		f.spawn_request = 0
		var d: Dictionary = f.move_data().proj
		var pr := PackedInt32Array()
		pr.resize(Proj.SIZE)
		pr[Proj.OWNER] = p
		pr[Proj.X] = f.x + f.facing * d.x * SUB
		pr[Proj.Y] = f.y + d.y * SUB
		pr[Proj.VX] = d.vx * f.facing
		pr[Proj.VY] = d.vy
		pr[Proj.GRAV] = d.gravity
		pr[Proj.HW] = d.w * SUB / 2
		pr[Proj.HH] = d.h * SUB / 2
		pr[Proj.DMG] = d.damage
		pr[Proj.STUN] = d.hitstun
		pr[Proj.STOP] = d.hitstop
		pr[Proj.PUSH] = d.push
		pr[Proj.CHIP] = d.chip
		pr[Proj.KIND] = d.kind
		pr[Proj.AGE] = 0
		pr[Proj.LOW] = 1 if d.get("level", "high") == "low" else 0
		pr[Proj.LIFE] = d.get("life", 0)
		projectiles.append(pr)


## Туманный рывок: появляется за спиной соперника и разворачивается к нему.
func _teleports() -> void:
	for p in PLAYERS:
		var f := fighters[p]
		if f.teleport_request == 0:
			continue
		f.teleport_request = 0
		var other := fighters[1 - p]
		var dir := signi(other.x - f.x)
		if dir == 0:
			dir = f.facing
		f.x = other.x + dir * f.move_data().teleport.offset * SUB
		f.x = clampi(f.x, f.push_half(), ARENA_WIDTH * SUB - f.push_half())
		f.facing = -dir


func _move_projectiles() -> void:
	var alive: Array[PackedInt32Array] = []
	for pr in projectiles:
		pr[Proj.X] += pr[Proj.VX]
		pr[Proj.Y] += pr[Proj.VY]
		pr[Proj.VY] -= pr[Proj.GRAV]
		pr[Proj.AGE] += 1
		var out := pr[Proj.X] < -PROJ_MARGIN * SUB or pr[Proj.X] > (ARENA_WIDTH + PROJ_MARGIN) * SUB
		var landed := pr[Proj.Y] <= 0
		var expired := pr[Proj.LIFE] > 0 and pr[Proj.AGE] >= pr[Proj.LIFE]
		if not out and not landed and not expired:
			alive.append(pr)
	projectiles = alive


static func _proj_box(pr: PackedInt32Array) -> PackedInt32Array:
	return PackedInt32Array([pr[Proj.X] - pr[Proj.HW], pr[Proj.X] + pr[Proj.HW],
		pr[Proj.Y] - pr[Proj.HH], pr[Proj.Y] + pr[Proj.HH]])


## Снаряды: встречные гасят друг друга; попавший в соперника исчезает.
func _check_projectiles() -> void:
	var removed := {}
	for i in projectiles.size():
		for j in range(i + 1, projectiles.size()):
			var a := projectiles[i]
			var b := projectiles[j]
			if a[Proj.OWNER] != b[Proj.OWNER] and _overlap(_proj_box(a), _proj_box(b)):
				removed[i] = true
				removed[j] = true
				_set_spark(a[Proj.OWNER], (a[Proj.X] + b[Proj.X]) / 2, (a[Proj.Y] + b[Proj.Y]) / 2, 0)
	for i in projectiles.size():
		if removed.has(i):
			continue
		var pr := projectiles[i]
		var p: int = pr[Proj.OWNER]
		var d := fighters[1 - p]
		if d.is_untouchable():
			continue
		var box := _proj_box(pr)
		for hurt in d.hurtboxes():
			if _overlap(box, hurt):
				var m := {"damage": pr[Proj.DMG], "hitstun": pr[Proj.STUN], "hitstop": pr[Proj.STOP],
					"push": pr[Proj.PUSH], "chip": pr[Proj.CHIP], "level": "low" if pr[Proj.LOW] else "high"}
				_apply_hit(p, m, signi(pr[Proj.VX]), pr[Proj.X], pr[Proj.Y])
				removed[i] = true
				break
	if removed.is_empty():
		return
	var alive: Array[PackedInt32Array] = []
	for i in projectiles.size():
		if not removed.has(i):
			alive.append(projectiles[i])
	projectiles = alive


## Включить/выключить тренировку: бой начинается заново, сразу без вступления.
func set_training(on: bool) -> void:
	training = on
	round_num = 1
	wins = PackedInt32Array([0, 0])
	_reset_fighters(false)
	timer = ROUND_TICKS
	round_winner = -1
	end_reason = EndReason.NONE
	refill_wait = PackedInt32Array([0, 0])
	_set_phase(Phase.FIGHT)
	if on:
		for f in fighters:
			f.meter = Fighter.METER_MAX


## Тренировка: шкала полная, здоровье восстанавливается, когда боец пришёл в себя после комбо.
func _training_upkeep() -> void:
	for p in PLAYERS:
		var f := fighters[p]
		f.meter = Fighter.METER_MAX
		var recovered := not (f.is_stunned() or f.is_untouchable() or f.state == Fighter.State.BLOCKSTUN)
		if f.hp < f.max_hp and recovered:
			refill_wait[p] += 1
			if refill_wait[p] >= REFILL_DELAY:
				f.hp = f.max_hp
				refill_wait[p] = 0
		else:
			refill_wait[p] = 0


func _check_round_end() -> void:
	var ko0 := fighters[0].hp == 0
	var ko1 := fighters[1].hp == 0
	if ko0 or ko1:
		if ko0 and ko1:
			_end_round(2, EndReason.DOUBLE_KO)
		else:
			_end_round(1 if ko0 else 0, EndReason.KO)
		hitstop = KO_FREEZE
		hitstop_total = KO_FREEZE
	elif timer == 0:
		# Здоровье у бойцов разное — сравниваем долю от полного.
		var h0 := fighters[0].hp * fighters[1].max_hp
		var h1 := fighters[1].hp * fighters[0].max_hp
		_end_round(2 if h0 == h1 else (0 if h0 > h1 else 1), EndReason.TIME)


func _end_round(winner: int, reason: EndReason) -> void:
	round_winner = winner
	end_reason = reason
	if winner == 2 and wins[0] == WINS_NEEDED - 1 and wins[1] == WINS_NEEDED - 1:
		last_bout = true  # без ничьей в матче: следующий раунд — «Последний бой»
	elif winner == 2:
		wins[0] += 1
		wins[1] += 1
	else:
		wins[winner] += 1
	_set_phase(Phase.ROUND_END)


func _next_round() -> void:
	round_num += 1
	_start_round()


func _new_match() -> void:
	round_num = 1
	last_bout = false
	finished = false
	wins = PackedInt32Array([0, 0])
	_start_round()
	for f in fighters:
		f.meter = 0


func _start_round() -> void:
	_reset_fighters()
	timer = ROUND_TICKS
	round_winner = -1
	end_reason = EndReason.NONE
	_set_phase(Phase.INTRO)


## Победитель стоит достаточно близко для добивания.
func finish_in_range() -> bool:
	if round_winner < 0 or round_winner > 1:
		return false
	return absi(fighters[0].x - fighters[1].x) <= FINISH_RANGE * SUB


## Добивание возможно: нокаут решил матч.
func _finish_allowed() -> bool:
	return not training and end_reason == EndReason.KO and round_winner < 2 \
		and wins[round_winner] >= WINS_NEEDED


func _start_finish() -> void:
	finish_step = 0
	finish_wait = 0
	var w := fighters[round_winner]
	w.hp = maxi(w.hp, 1)
	fighters[1 - round_winner].daze(FINISH_TICKS + FINISHER_TICKS)
	_set_phase(Phase.FINISH)


## «Вперёд, назад + СР» вплотную; направления — относительно взгляда победителя.
func _finish_input(w: int) -> bool:
	var a := fighters[w]
	var press := inputs[w] & ~prev_inputs[w]
	var fwd := InputBits.RIGHT if a.facing > 0 else InputBits.LEFT
	var back := InputBits.LEFT if a.facing > 0 else InputBits.RIGHT
	if finish_wait > 0:
		finish_wait -= 1
		if finish_wait == 0:
			finish_step = 0
	if press & fwd:
		finish_step = 1
		finish_wait = FINISH_STEP
	elif press & back and finish_step == 1:
		finish_step = 2
		finish_wait = FINISH_STEP
	elif press & InputBits.HP and finish_step == 2:
		if finish_in_range():
			finish_step = 0
			return true
		finish_wait = FINISH_STEP  # далеко — команда не теряется: подойди и нажми СР ещё раз
	return false


func _start_finisher(w: int) -> void:
	finished = true
	fighters[1 - w].finisher_launch(fighters[w].facing)
	hitstop = SUPER_FLASH
	hitstop_total = 0
	_set_spark(w, fighters[1 - w].x, fighters[1 - w].data.height * SUB / 2, 1)
	_set_phase(Phase.FINISHER)


func _set_phase(p: Phase) -> void:
	phase = p
	phase_frame = 0


func _any_attack_pressed() -> bool:
	for p in PLAYERS:
		if (inputs[p] & ATTACK_MASK & ~prev_inputs[p]) != 0:
			return true
	return false


## Победитель матча: 0/1, 2 — ничья, -1 — матч не окончен.
func match_winner() -> int:
	if phase != Phase.MATCH_END:
		return -1
	if wins[0] == wins[1]:
		return 2
	return 0 if wins[0] > wins[1] else 1


## Отбросило в стену — значит, отбрасывает самого атакующего (как в Street Fighter).
func _wall_pushback() -> void:
	for p in PLAYERS:
		var f := fighters[p]
		if f.state != Fighter.State.HITSTUN and f.state != Fighter.State.BLOCKSTUN:
			continue
		var other := fighters[1 - p]
		var hi := ARENA_WIDTH * SUB - f.push_half()
		if f.x > hi:
			other.x -= f.x - hi
		elif f.x < f.push_half():
			other.x += f.push_half() - f.x


## Попадания проверяются для обоих сразу, поэтому возможны размены ударами.
func _check_hits() -> void:
	var hits: Array = []
	for p in PLAYERS:
		var a := fighters[p]
		var d := fighters[1 - p]
		if not a.is_active() or d.is_untouchable():
			continue
		var hb := a.hitbox()
		for hurt in d.hurtboxes():
			if _overlap(hb, hurt):
				hits.append([p, a.move_data(), hb])
				break
	for hit in hits:
		var p: int = hit[0]
		var m: Dictionary = hit[1]
		var hb: PackedInt32Array = hit[2]
		var a := fighters[p]
		var d := fighters[1 - p]
		# Соперник в этот же тик схватил атакующего суперприёмом — удар атакующего не выходит.
		if a.state == Fighter.State.THROWN:
			continue
		a.mark_hit()
		# Искра — в точке, где хитбокс заходит в тело соперника.
		var spark_x := (maxi(hb[0], d.x - d.push_half()) + mini(hb[1], d.x + d.push_half())) / 2
		_apply_hit(p, m, a.facing, spark_x, (hb[2] + hb[3]) / 2, true)


## Попадание или блок от игрока p (удар или снаряд); direction — куда отбрасывать.
## melee — удар рукой или ногой (его можно поймать контратакой).
func _apply_hit(p: int, m: Dictionary, direction: int, spark_x: int, spark_y: int, melee := false) -> void:
	var d := fighters[1 - p]
	if d.can_parry():
		# Парирование: урона нет; атакующий врукопашную ошеломлён, снаряд просто гаснет.
		d.parry_success()
		d.add_meter(PARRY_METER)
		if melee:
			fighters[p].take_stagger()
		hitstop = maxi(hitstop, PARRY_HITSTOP)
		hitstop_total = 0
		_set_spark(1 - p, spark_x, spark_y, 5)
		return
	if melee and d.is_countering():
		# Гипнотический взгляд: атакующий застывает, защитник свободен.
		fighters[p].take_hypnosis(d.move_data().counter.stun)
		d.counter_success()
		hitstop = COUNTER_HITSTOP
		hitstop_total = COUNTER_HITSTOP
		_set_spark(1 - p, d.x + d.facing * 40 * SUB, d.y + d.data.height * SUB * 85 / 100, 4)
		return
	if d.has_armor():
		d.absorb_hit(m, direction)
		if ARMOR_HITSTOP > hitstop:
			hitstop = ARMOR_HITSTOP
			hitstop_total = ARMOR_HITSTOP
		_set_spark(p, spark_x, spark_y, 3)
		return
	var blocked := d.try_block(m)
	var stop: int = m.hitstop
	var a := fighters[p]
	if blocked:
		d.take_block(m, direction)
		stop = maxi(m.hitstop * 2 / 3, 4)  # блок «легче» попадания
		if not a.is_super():
			a.add_meter(m.damage * METER_BLOCK)
	elif m.has("cinema") and melee and a.state == Fighter.State.ATTACK:
		# (если атакующего в этот же тик сбили — размен: суперприём бьёт как обычный удар)
		# Суперприём попал: ролик — соперник схвачен, серия ударов, в конце урон (_hold_throws).
		if not d.is_stunned():
			d.combo = 0
		a.stun = m.cinema.hold
		a.vx = 0
		a.state = Fighter.State.THROWING
		a.state_frame = 0
		d.become_thrown()
		_hold_position(a, d)
	else:
		d.take_hit(m, direction)
		if not a.is_super():
			a.add_meter(m.damage * METER_HIT)
			d.add_meter(m.damage * METER_TAKEN)
	if stop > hitstop:
		hitstop = stop
		hitstop_total = stop
	_set_spark(p, spark_x, spark_y, 2 if blocked else (1 if m.hitstop >= 11 else 0))


func _set_spark(p: int, x: int, y: int, kind: int) -> void:
	var base := p * 4
	sparks[base] = tick
	sparks[base + 1] = x
	sparks[base + 2] = y
	sparks[base + 3] = kind


static func _overlap(a: PackedInt32Array, b: PackedInt32Array) -> bool:
	return a[0] < b[1] and b[0] < a[1] and a[2] < b[3] and b[2] < a[3]


func _record_history(p: int, bits: int) -> void:
	var h: Array = history[p]
	if h.is_empty() or h[0][0] != bits:
		h.push_front([bits, 1])
		if h.size() > HISTORY_LEN:
			h.pop_back()
	else:
		h[0][1] = mini(h[0][1] + 1, MAX_HOLD_FRAMES)


## Бойцы не проходят друг сквозь друга. На взлёте столкновения нет, а в воздухе
## «тело» ниже — так можно перепрыгнуть соперника (кросс-ап).
func _resolve_push() -> void:
	var a := fighters[0]
	var b := fighters[1]
	if a.is_rising() or b.is_rising() or a.is_intangible() or b.is_intangible():
		return
	for f in fighters:
		if f.state == Fighter.State.THROWING or f.state == Fighter.State.THROWN:
			return
	var vertical := a.y < b.y + b.push_height() and b.y < a.y + a.push_height()
	if not vertical:
		return
	var overlap := a.push_half() + b.push_half() - absi(b.x - a.x)
	if overlap <= 0:
		return
	var s := signi(b.x - a.x)
	if s == 0:
		s = a.facing
	@warning_ignore("integer_division")
	var half := overlap / 2
	a.x -= half * s
	b.x += (overlap - half) * s
	# Если один упёрся в стену, отодвигаем второго.
	_clamp_walls()
	var rest := a.push_half() + b.push_half() - absi(b.x - a.x)
	if rest > 0:
		if _at_wall(a):
			b.x += rest * s
		else:
			a.x -= rest * s


## Нельзя разойтись дальше, чем помещается в кадр: отменяем шаг «наружу».
func _limit_separation(prev_x: PackedInt32Array) -> void:
	var sep := absi(fighters[1].x - fighters[0].x)
	var excess := sep - MAX_SEPARATION * SUB
	if excess <= 0:
		return
	var left := 0 if fighters[0].x < fighters[1].x else 1
	var right := 1 - left
	var left_out := maxi(prev_x[left] - fighters[left].x, 0)
	var right_out := maxi(fighters[right].x - prev_x[right], 0)
	var fix := mini(excess, left_out)
	fighters[left].x += fix
	excess -= fix
	fix = mini(excess, right_out)
	fighters[right].x -= fix


func _clamp_walls() -> void:
	for f in fighters:
		f.x = clampi(f.x, f.push_half(), ARENA_WIDTH * SUB - f.push_half())


func _at_wall(f: Fighter) -> bool:
	return f.x <= f.push_half() or f.x >= ARENA_WIDTH * SUB - f.push_half()


## Бойцы разворачиваются к сопернику, только стоя на земле.
func _update_facing() -> void:
	for p in PLAYERS:
		var f := fighters[p]
		var other := fighters[1 - p]
		if f.state == Fighter.State.RUN and (other.x - f.x) * f.run_dir < 0:
			f.stop_run()
		if not (f.is_grounded_actionable() or f.state == Fighter.State.LAND):
			continue
		if other.x > f.x:
			f.facing = 1
		elif other.x < f.x:
			f.facing = -1


func save_state() -> Dictionary:
	return {
		"tick": tick,
		"inputs": inputs.duplicate(),
		"history": history.duplicate(true),
		"fighters": [fighters[0].save(), fighters[1].save()],
		"hitstop": hitstop,
		"hitstop_total": hitstop_total,
		"sparks": sparks.duplicate(),
		"match": PackedInt32Array([phase, phase_frame, round_num, wins[0], wins[1], timer,
			round_winner, end_reason, prev_inputs[0], prev_inputs[1],
			1 if training else 0, refill_wait[0], refill_wait[1],
			1 if last_bout else 0, finish_step, finish_wait, 1 if finished else 0]),
		"projectiles": projectiles.duplicate(true),
	}


func load_state(state: Dictionary) -> void:
	tick = state.tick
	inputs = state.inputs.duplicate()
	history = state.history.duplicate(true)
	for p in PLAYERS:
		fighters[p].load(state.fighters[p])
	hitstop = state.hitstop
	hitstop_total = state.hitstop_total
	sparks = state.sparks.duplicate()
	var m: PackedInt32Array = state.match
	phase = m[0] as Phase; phase_frame = m[1]; round_num = m[2]
	wins = PackedInt32Array([m[3], m[4]]); timer = m[5]
	round_winner = m[6]; end_reason = m[7] as EndReason
	prev_inputs = PackedInt32Array([m[8], m[9]])
	training = m[10] == 1
	refill_wait = PackedInt32Array([m[11], m[12]])
	last_bout = m[13] == 1; finish_step = m[14]; finish_wait = m[15]; finished = m[16] == 1
	projectiles.clear()
	for pr in state.projectiles:
		projectiles.append((pr as PackedInt32Array).duplicate())


## Контрольная сумма состояния (FNV-1a по целым числам).
## Одинаковая на любых машинах — по ней будем ловить рассинхрон в онлайне.
func checksum() -> int:
	var h := 2166136261
	h = _mix(h, tick)
	h = _mix(h, hitstop)
	h = _mix(h, hitstop_total)
	for v in sparks:
		h = _mix(h, v)
	for v in [phase, phase_frame, round_num, wins[0], wins[1], timer, round_winner, end_reason,
			1 if training else 0, refill_wait[0], refill_wait[1],
			1 if last_bout else 0, finish_step, finish_wait, 1 if finished else 0]:
		h = _mix(h, v)
	for pr in projectiles:
		for v in pr:
			h = _mix(h, v)
	for p in PLAYERS:
		h = _mix(h, inputs[p])
		for entry in history[p]:
			h = _mix(h, entry[0])
			h = _mix(h, entry[1])
		for v in fighters[p].save():
			h = _mix(h, v)
	return h


static func _mix(h: int, value: int) -> int:
	h = (h ^ (value & 0xFFFFFFFF)) & 0xFFFFFFFF
	return (h * 16777619) & 0xFFFFFFFF
