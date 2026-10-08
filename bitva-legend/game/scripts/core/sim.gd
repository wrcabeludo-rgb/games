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
enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END }
enum EndReason { NONE, KO, TIME, DOUBLE_KO }
const INTRO_TICKS := 80             # «РАУНД N» — бойцы ещё не двигаются
const ROUND_TICKS := 60 * 60        # таймер раунда: 60 секунд
const ROUND_END_TICKS := 200        # пауза после конца раунда
const REMATCH_DELAY := 60           # после конца матча кнопки работают не сразу
const KO_FREEZE := 40               # драматичная заморозка на нокауте
const WINS_NEEDED := 2
const ATTACK_MASK := InputBits.LP | InputBits.LK | InputBits.HP | InputBits.HK

var tick := 0
var inputs := PackedInt32Array([0, 0])
## История ввода по игрокам: записи [биты, сколько тиков удерживались], новые — первыми.
var history: Array = [[], []]
var fighters: Array[Fighter] = []
## Заморозка после попадания: пока > 0, бойцы стоят, но нажатия запоминаются.
var hitstop := 0
var hitstop_total := 0              # длительность текущей заморозки (для тряски камеры)
## Последнее попадание каждого игрока (для искр): [тик, x, y, вид: 0 лёгкий, 1 сильный, 2 блок].
var sparks := PackedInt32Array([-999, 0, 0, 0, -999, 0, 0, 0])

var phase := Phase.INTRO
var phase_frame := 0
var round_num := 1
var wins := PackedInt32Array([0, 0])
var timer := ROUND_TICKS
var round_winner := -1              # -1 ещё нет, 0/1 — игрок, 2 — ничья
var end_reason := EndReason.NONE
var prev_inputs := PackedInt32Array([0, 0])


## with_intro = false — сразу бой (для тестов и тренировки).
func _init(with_intro := true) -> void:
	_reset_fighters()
	if not with_intro:
		phase = Phase.FIGHT


@warning_ignore("integer_division")
func _reset_fighters() -> void:
	var center := ARENA_WIDTH / 2
	fighters = [
		Fighter.new("ilya", center - START_GAP / 2, 1),
		Fighter.new("dracula", center + START_GAP / 2, -1),
	]
	hitstop = 0
	hitstop_total = 0


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
		Phase.MATCH_END:
			_combat_step(idle, false)
			if phase_frame >= REMATCH_DELAY and _any_attack_pressed():
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
	for p in PLAYERS:
		fighters[p].step(inp[p])
	_wall_pushback()
	_resolve_push()
	_limit_separation(prev_x)
	_clamp_walls()
	if hits:
		_check_hits()
	_update_facing()


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
		var h0 := fighters[0].hp
		var h1 := fighters[1].hp
		_end_round(2 if h0 == h1 else (0 if h0 > h1 else 1), EndReason.TIME)


func _end_round(winner: int, reason: EndReason) -> void:
	round_winner = winner
	end_reason = reason
	if winner == 2:
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
	wins = PackedInt32Array([0, 0])
	_start_round()


func _start_round() -> void:
	_reset_fighters()
	timer = ROUND_TICKS
	round_winner = -1
	end_reason = EndReason.NONE
	_set_phase(Phase.INTRO)


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
		if not a.is_active() or d.state == Fighter.State.AIR_HIT or d.state == Fighter.State.DOWN:
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
		a.mark_hit()
		var blocked := d.try_block(m)
		var stop: int = m.hitstop
		if blocked:
			d.take_block(m, a.facing)
			stop = maxi(m.hitstop * 2 / 3, 4)  # блок «легче» попадания
		else:
			d.take_hit(m, a.facing)
		if stop > hitstop:
			hitstop = stop
			hitstop_total = stop
		# Искра — в точке, где хитбокс заходит в тело соперника.
		var spark_x := (maxi(hb[0], d.x - d.push_half()) + mini(hb[1], d.x + d.push_half())) / 2
		var spark_y := (hb[2] + hb[3]) / 2
		var base := p * 4
		sparks[base] = tick
		sparks[base + 1] = spark_x
		sparks[base + 2] = spark_y
		sparks[base + 3] = 2 if blocked else (1 if m.hitstop >= 11 else 0)


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
	if a.is_rising() or b.is_rising():
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
			round_winner, end_reason, prev_inputs[0], prev_inputs[1]]),
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


## Контрольная сумма состояния (FNV-1a по целым числам).
## Одинаковая на любых машинах — по ней будем ловить рассинхрон в онлайне.
func checksum() -> int:
	var h := 2166136261
	h = _mix(h, tick)
	h = _mix(h, hitstop)
	h = _mix(h, hitstop_total)
	for v in sparks:
		h = _mix(h, v)
	for v in [phase, phase_frame, round_num, wins[0], wins[1], timer, round_winner, end_reason]:
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
