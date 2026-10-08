class_name Fighter
extends RefCounted
## Один боец: позиция, скорость, состояние. Только целые числа.
## x — по горизонтали арены, y — высота над землёй (0 — на земле). Всё в субпикселях.

enum State {
	STAND, WALK_F, WALK_B, CROUCH, PREJUMP, AIR, LAND, RUN, RUN_STOP, BACKDASH,
	ATTACK, HITSTUN, AIR_HIT, BLOCK, BLOCKSTUN,
}
const STATE_NAMES := [
	"стойка", "шаг вперёд", "шаг назад", "присед", "подготовка прыжка", "в воздухе",
	"приземление", "бег", "торможение", "отскок", "удар", "оглушён", "отброшен", "блок", "в блоке",
]

## Удары по номерам: 0–3 стоя, 4–7 в приседе, 8–11 в прыжке; внутри — ЛР, ЛН, СР, СН.
const MOVES := [
	"st_lp", "st_lk", "st_hp", "st_hk",
	"cr_lp", "cr_lk", "cr_hp", "cr_hk",
	"j_lp", "j_lk", "j_hp", "j_hk",
]
const MOVE_LABELS := ["ЛР", "ЛН", "СР", "СН"]
const ATTACK_BITS := [InputBits.LP, InputBits.LK, InputBits.HP, InputBits.HK]

const SUB := 100            # субпикселей в пикселе
const AIR_PUSH_RATIO := 60  # в воздухе «тело» ниже, чтобы можно было перепрыгнуть соперника, %
const HURT_WIDTH_RATIO := 115  # уязвимое «тело» чуть шире, чем для столкновений, %
const DASH_WINDOW := 12     # за сколько тиков нужно нажать направление второй раз для бега/отскока
const BUFFER := 4           # нажатие кнопки удара «запоминается» на столько тиков
const TAP_TIMER_MAX := 99
const PUSHBACK_DECAY := 80  # отбрасывание затухает на 20% за тик
const AIR_HIT_VX := 350     # отброс при попадании в воздухе
const AIR_HIT_VY := 1100
const AIR_HIT_LANDING := 14 # приземление после отброса дольше обычного
const MAX_HP := 1000
const BLOCK_PUSH := 130     # в блоке отбрасывает сильнее, чем при попадании, %
const BLOCKSTUN_LESS := 2   # в блоке оглушение короче, чем при попадании, на столько тиков

var id := ""
var data: Dictionary
var x := 0
var y := 0
var vx := 0
var vy := 0
var facing := 1             # 1 — смотрит вправо, -1 — влево
var state := State.STAND
var state_frame := 0
var jump_dir := 0           # -1 назад, 0 вверх, 1 вперёд (относительно взгляда при отрыве)
var prev_bits := 0          # ввод прошлого тика — чтобы ловить нажатия
var fwd_tap_timer := TAP_TIMER_MAX   # тиков с прошлого нажатия «вперёд»
var back_tap_timer := TAP_TIMER_MAX  # тиков с прошлого нажатия «назад»
var run_speed := 0
var run_dir := 0            # направление бега по арене: 1 вправо, -1 влево
var from_run := 0           # 1, если прыжок начат с разбега
var hp := MAX_HP
var move := -1              # текущий удар (номер в MOVES) или -1
var move_frame := 0         # тик текущего удара, начиная с 1
var has_hit := 0            # удар уже попал (каждый удар попадает один раз)
var stun := 0               # оставшиеся тики оглушения
var pushback := 0           # скорость отбрасывания (по арене)
var low_pose := 0           # низкая стойка в оглушении или блоке (1 — сидя)
var combo := 0              # сколько ударов подряд пропущено
var landing_frames := 0     # длительность текущего приземления
var btn_timers := PackedInt32Array([TAP_TIMER_MAX, TAP_TIMER_MAX, TAP_TIMER_MAX, TAP_TIMER_MAX])


func _init(char_id: String, start_x_px: int, start_facing: int) -> void:
	id = char_id
	data = FighterData.get_data(char_id)
	x = start_x_px * SUB
	facing = start_facing


func save() -> PackedInt32Array:
	var s := PackedInt32Array([
		x, y, vx, vy, facing, state, state_frame, jump_dir,
		prev_bits, fwd_tap_timer, back_tap_timer, run_speed, run_dir, from_run,
		hp, move, move_frame, has_hit, stun, pushback, low_pose, combo, landing_frames,
	])
	s.append_array(btn_timers)
	return s


func load(s: PackedInt32Array) -> void:
	x = s[0]; y = s[1]; vx = s[2]; vy = s[3]
	facing = s[4]; state = s[5] as State; state_frame = s[6]; jump_dir = s[7]
	prev_bits = s[8]; fwd_tap_timer = s[9]; back_tap_timer = s[10]
	run_speed = s[11]; run_dir = s[12]; from_run = s[13]
	hp = s[14]; move = s[15]; move_frame = s[16]; has_hit = s[17]; stun = s[18]
	pushback = s[19]; low_pose = s[20]; combo = s[21]; landing_frames = s[22]
	btn_timers = s.slice(23, 27)


# --- Вопросы о состоянии --------------------------------------------------

func is_grounded_actionable() -> bool:
	return state == State.STAND or state == State.WALK_F or state == State.WALK_B \
		or state == State.CROUCH or state == State.BLOCK


func is_airborne() -> bool:
	return state == State.AIR or state == State.AIR_HIT


func is_rising() -> bool:
	return state == State.AIR and vy > 0


func is_stunned() -> bool:
	return state == State.HITSTUN or state == State.AIR_HIT


func is_crouching() -> bool:
	return state == State.CROUCH or (state == State.ATTACK and move >= 4 and move <= 7) \
		or ((state == State.HITSTUN or state == State.BLOCK or state == State.BLOCKSTUN) and low_pose == 1)


func move_data() -> Dictionary:
	return data.moves[MOVES[move]] if move >= 0 else {}


## Удар сейчас в активной фазе (может попасть).
func is_active() -> bool:
	if move < 0 or has_hit:
		return false
	var m := move_data()
	return move_frame >= m.startup and move_frame < m.startup + m.active


## Фаза удара для отрисовки: 0 — подготовка, 1 — бьёт, 2 — восстановление.
func move_phase() -> int:
	var m := move_data()
	if move_frame < m.startup:
		return 0
	if move_frame < m.startup + m.active:
		return 1
	return 2


func push_half() -> int:
	return data.push_half * SUB


## Высота «тела» для столкновений в текущем состоянии.
func push_height() -> int:
	if is_crouching():
		return data.crouch_height * SUB
	if is_airborne():
		return data.height * SUB * AIR_PUSH_RATIO / 100
	return data.height * SUB


## Хитбокс текущего удара в координатах арены: [x1, x2, y1, y2] (субпиксели).
func hitbox() -> PackedInt32Array:
	var b: Array = move_data().box
	return _box_world(b[0], b[1], b[2], b[3])


## Уязвимые зоны: тело и, во время удара, вытянутая рука или нога.
func hurtboxes() -> Array[PackedInt32Array]:
	var half: int = data.push_half * HURT_WIDTH_RATIO / 100 * SUB
	var h: int = data.crouch_height * SUB if is_crouching() else data.height * SUB
	if state == State.AIR:
		h = h * 80 / 100
	var boxes: Array[PackedInt32Array] = [PackedInt32Array([x - half, x + half, y, y + h])]
	if move >= 0 and move_phase() >= 1:
		var b: Array = move_data().box
		var shrink := 10
		if b[2] > shrink * 2 and b[3] > shrink * 2:
			boxes.append(_box_world(b[0] + shrink, b[1] + shrink, b[2] - shrink * 2, b[3] - shrink * 2))
	return boxes


func _box_world(fwd: int, bottom: int, w: int, h: int) -> PackedInt32Array:
	var x1 := x + facing * fwd * SUB
	var x2 := x + facing * (fwd + w) * SUB
	return PackedInt32Array([mini(x1, x2), maxi(x1, x2), y + bottom * SUB, y + (bottom + h) * SUB])


# --- События от симуляции ------------------------------------------------

## Соперник оказался за спиной во время бега — тормозим.
func stop_run() -> void:
	if state == State.RUN:
		_set_state(State.RUN_STOP)


## Попадание по этому бойцу. attacker_facing — куда смотрит атакующий (туда и отбрасывает).
func take_hit(m: Dictionary, attacker_facing: int) -> void:
	combo = combo + 1 if is_stunned() else 1
	hp = maxi(hp - m.damage, 0)
	var was_crouching := is_crouching()
	move = -1
	if is_airborne():
		vx = AIR_HIT_VX * attacker_facing
		vy = AIR_HIT_VY
		_set_state(State.AIR_HIT)
		state_frame = 0
		return
	low_pose = 1 if was_crouching else 0
	stun = m.hitstun
	pushback = m.push * attacker_facing
	vx = 0
	_set_state(State.HITSTUN)
	state_frame = 0


## Попробовать заблокировать удар. Стоя не держится низкий удар, сидя — удар сверху.
func try_block(m: Dictionary) -> bool:
	if state != State.BLOCK and state != State.BLOCKSTUN:
		return false
	var level: String = m.get("level", "high")
	if (level == "low" and low_pose == 0) or (level == "overhead" and low_pose == 1):
		return false
	return true


## Удар заблокирован: короткое оглушение в блоке и сильное отталкивание, без урона.
func take_block(m: Dictionary, attacker_facing: int) -> void:
	stun = m.get("blockstun", m.hitstun - BLOCKSTUN_LESS)
	pushback = m.push * BLOCK_PUSH / 100 * attacker_facing
	vx = 0
	_set_state(State.BLOCKSTUN)
	state_frame = 0


func mark_hit() -> void:
	has_hit = 1


# --- Ввод ----------------------------------------------------------------

## Обновляет таймеры нажатий. aging = false во время заморозки (hitstop):
## нажатия запоминаются, но не «протухают».
func read_input(bits: int, aging: bool) -> Dictionary:
	var fwd_bit := InputBits.RIGHT if facing > 0 else InputBits.LEFT
	var back_bit := InputBits.LEFT if facing > 0 else InputBits.RIGHT
	if aging:
		fwd_tap_timer = mini(fwd_tap_timer + 1, TAP_TIMER_MAX)
		back_tap_timer = mini(back_tap_timer + 1, TAP_TIMER_MAX)
		for i in 4:
			btn_timers[i] = mini(btn_timers[i] + 1, TAP_TIMER_MAX)
	var dash_fwd := false
	var dash_back := false
	if (bits & fwd_bit) != 0 and (prev_bits & fwd_bit) == 0:
		dash_fwd = fwd_tap_timer <= DASH_WINDOW
		fwd_tap_timer = 0
	if (bits & back_bit) != 0 and (prev_bits & back_bit) == 0:
		dash_back = back_tap_timer <= DASH_WINDOW
		back_tap_timer = 0
	for i in 4:
		if (bits & ATTACK_BITS[i]) != 0 and (prev_bits & ATTACK_BITS[i]) == 0:
			btn_timers[i] = 0
	prev_bits = bits
	return {
		"fwd": (bits & fwd_bit) != 0, "back": (bits & back_bit) != 0,
		"up": (bits & InputBits.UP) != 0, "down": (bits & InputBits.DOWN) != 0,
		"dash_fwd": dash_fwd, "dash_back": dash_back,
		"block": (bits & InputBits.BLOCK) != 0,
	}


## Самая свежая нажатая кнопка удара из буфера (0–3) или -1. Сильные — при равенстве.
func _buffered_button() -> int:
	var best := -1
	for i in [2, 3, 0, 1]:
		if btn_timers[i] <= BUFFER and (best < 0 or btn_timers[i] < btn_timers[best]):
			best = i
	return best


func _consume_button(i: int) -> void:
	btn_timers[i] = TAP_TIMER_MAX


# --- Тик -----------------------------------------------------------------

func step(bits: int) -> void:
	var inp := read_input(bits, true)
	state_frame += 1
	match state:
		State.PREJUMP:
			if state_frame >= data.prejump:
				_launch(inp.fwd, inp.back)
		State.AIR:
			_air_step()
		State.AIR_HIT:
			x += vx
			y += vy
			vy -= data.gravity
			if y <= 0:
				_land(AIR_HIT_LANDING)
		State.LAND:
			if state_frame >= landing_frames:
				_set_state(State.STAND)
				_ground_control(inp)
		State.RUN:
			_run_control(inp)
		State.RUN_STOP:
			# Скорость плавно падает до нуля за run_stop тиков.
			vx = run_speed * run_dir * maxi(data.run_stop - state_frame, 0) / data.run_stop
			x += vx
			if state_frame >= data.run_stop:
				vx = 0
				_set_state(State.STAND)
		State.BACKDASH:
			var speed := maxi(data.backdash_v0 - data.backdash_decel * (state_frame - 1), 0)
			vx = -speed * facing
			x += vx
			if speed == 0 and state_frame >= _backdash_moving_frames() + data.backdash_recovery:
				_set_state(State.STAND)
		State.ATTACK:
			move_frame += 1
			var m := move_data()
			if move_frame > m.startup + m.active - 1 + m.recovery:
				move = -1
				_set_state(State.STAND)
				_ground_control(inp)
		State.BLOCKSTUN:
			# Можно переключаться между верхним и нижним блоком прямо в блоке.
			low_pose = 1 if inp.down else 0
			x += pushback
			pushback = pushback * PUSHBACK_DECAY / 100
			stun -= 1
			if stun <= 0:
				pushback = 0
				_set_state(State.STAND)
				_ground_control(inp)
		State.HITSTUN:
			x += pushback
			pushback = pushback * PUSHBACK_DECAY / 100
			stun -= 1
			if stun <= 0:
				pushback = 0
				combo = 0
				_set_state(State.STAND)
				_ground_control(inp)
		_:
			_ground_control(inp)


func _air_step() -> void:
	if move < 0 and has_hit == 0:
		var b := _buffered_button()
		if b >= 0:
			_consume_button(b)
			move = 8 + b
			move_frame = 0
	if move >= 0:
		move_frame += 1
	x += vx
	y += vy
	vy -= data.gravity
	if y <= 0:
		_land(data.landing)


func _land(frames: int) -> void:
	y = 0
	vx = 0
	vy = 0
	move = -1
	has_hit = 0
	combo = 0
	landing_frames = frames
	_set_state(State.LAND)


func _ground_control(inp: Dictionary) -> void:
	var b := _buffered_button()
	if b >= 0:
		_start_attack(b, inp.down)
	elif inp.block:
		# Блок держится, пока нажата кнопка; вниз — нижний блок. Ходить в блоке нельзя.
		vx = 0
		low_pose = 1 if inp.down else 0
		_set_state(State.BLOCK)
	elif inp.up:
		vx = 0
		from_run = 0
		has_hit = 0
		_set_state(State.PREJUMP)
	elif inp.down:
		vx = 0
		_set_state(State.CROUCH)
	elif inp.dash_fwd:
		run_speed = data.walk_f
		run_dir = facing
		vx = run_speed * run_dir
		_set_state(State.RUN)
		x += vx
	elif inp.dash_back:
		vx = 0
		_set_state(State.BACKDASH)
	elif inp.fwd:
		vx = data.walk_f * facing
		_set_state(State.WALK_F)
		x += vx
	elif inp.back:
		vx = -data.walk_b * facing
		_set_state(State.WALK_B)
		x += vx
	else:
		vx = 0
		_set_state(State.STAND)


func _start_attack(button: int, crouching: bool) -> void:
	_consume_button(button)
	move = (4 if crouching else 0) + button
	move_frame = 1  # тик нажатия — первый кадр удара (как во фреймдате Street Fighter)
	has_hit = 0
	vx = 0
	_set_state(State.ATTACK)
	state_frame = 0


## Бег продолжается, пока держишь «вперёд»; скорость растёт до run_speed.
## Из бега можно сразу ударить.
func _run_control(inp: Dictionary) -> void:
	var b := _buffered_button()
	if b >= 0:
		_start_attack(b, inp.down)
	elif inp.up:
		vx = 0
		from_run = 1
		has_hit = 0
		_set_state(State.PREJUMP)
	elif inp.down:
		vx = 0
		_set_state(State.CROUCH)
	elif inp.fwd:
		run_speed = mini(run_speed + data.run_accel, data.run_speed)
		vx = run_speed * run_dir
		x += vx
	else:
		_set_state(State.RUN_STOP)


func _backdash_moving_frames() -> int:
	return (data.backdash_v0 + data.backdash_decel - 1) / data.backdash_decel


## Направление прыжка берётся в момент отрыва — как в Street Fighter.
## Прыжок вперёд с разбега летит дальше.
func _launch(hold_fwd: bool, hold_back: bool) -> void:
	jump_dir = 1 if hold_fwd else (-1 if hold_back else 0)
	match jump_dir:
		1: vx = (data.jump_vx_f + (data.run_jump_bonus if from_run else 0)) * facing
		-1: vx = -data.jump_vx_b * facing
		_: vx = 0
	vy = data.jump_vy
	move = -1
	has_hit = 0
	_set_state(State.AIR)


func _set_state(s: State) -> void:
	if s != state:
		state = s
		state_frame = 0
