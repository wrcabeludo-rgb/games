class_name Fighter
extends RefCounted
## Один боец: позиция, скорость, состояние. Только целые числа.
## x — по горизонтали арены, y — высота над землёй (0 — на земле). Всё в субпикселях.

enum State { STAND, WALK_F, WALK_B, CROUCH, PREJUMP, AIR, LAND, RUN, RUN_STOP, BACKDASH }
const STATE_NAMES := [
	"стойка", "шаг вперёд", "шаг назад", "присед", "подготовка прыжка", "в воздухе",
	"приземление", "бег", "торможение", "отскок",
]

const SUB := 100            # субпикселей в пикселе
const AIR_PUSH_RATIO := 60  # в воздухе «тело» ниже, чтобы можно было перепрыгнуть соперника, %
const DASH_WINDOW := 12     # за сколько тиков нужно нажать направление второй раз для бега/отскока
const TAP_TIMER_MAX := 99

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


func _init(char_id: String, start_x_px: int, start_facing: int) -> void:
	id = char_id
	data = FighterData.get_data(char_id)
	x = start_x_px * SUB
	facing = start_facing


func save() -> PackedInt32Array:
	return PackedInt32Array([
		x, y, vx, vy, facing, state, state_frame, jump_dir,
		prev_bits, fwd_tap_timer, back_tap_timer, run_speed, run_dir, from_run,
	])


func load(s: PackedInt32Array) -> void:
	x = s[0]; y = s[1]; vx = s[2]; vy = s[3]
	facing = s[4]; state = s[5] as State; state_frame = s[6]; jump_dir = s[7]
	prev_bits = s[8]; fwd_tap_timer = s[9]; back_tap_timer = s[10]
	run_speed = s[11]; run_dir = s[12]; from_run = s[13]


func is_grounded_actionable() -> bool:
	return state == State.STAND or state == State.WALK_F or state == State.WALK_B or state == State.CROUCH


func is_airborne() -> bool:
	return state == State.AIR


func is_rising() -> bool:
	return state == State.AIR and vy > 0


func push_half() -> int:
	return data.push_half * SUB


## Высота «тела» для столкновений в текущем состоянии.
func push_height() -> int:
	match state:
		State.CROUCH:
			return data.crouch_height * SUB
		State.AIR:
			return data.height * SUB * AIR_PUSH_RATIO / 100
		_:
			return data.height * SUB


## Соперник оказался за спиной во время бега — тормозим.
func stop_run() -> void:
	if state == State.RUN:
		_set_state(State.RUN_STOP)


func step(bits: int) -> void:
	var fwd_bit := InputBits.RIGHT if facing > 0 else InputBits.LEFT
	var back_bit := InputBits.LEFT if facing > 0 else InputBits.RIGHT
	var hold_fwd := (bits & fwd_bit) != 0
	var hold_back := (bits & back_bit) != 0
	var hold_up := (bits & InputBits.UP) != 0
	var hold_down := (bits & InputBits.DOWN) != 0

	# Двойное нажатие: второе нажатие пришло не позже DASH_WINDOW тиков после первого.
	fwd_tap_timer = mini(fwd_tap_timer + 1, TAP_TIMER_MAX)
	back_tap_timer = mini(back_tap_timer + 1, TAP_TIMER_MAX)
	var dash_fwd := false
	var dash_back := false
	if hold_fwd and (prev_bits & fwd_bit) == 0:
		dash_fwd = fwd_tap_timer <= DASH_WINDOW
		fwd_tap_timer = 0
	if hold_back and (prev_bits & back_bit) == 0:
		dash_back = back_tap_timer <= DASH_WINDOW
		back_tap_timer = 0
	prev_bits = bits

	state_frame += 1
	match state:
		State.PREJUMP:
			if state_frame >= data.prejump:
				_launch(hold_fwd, hold_back)
		State.AIR:
			x += vx
			y += vy
			vy -= data.gravity
			if y <= 0:
				y = 0
				vx = 0
				vy = 0
				_set_state(State.LAND)
		State.LAND:
			if state_frame >= data.landing:
				_set_state(State.STAND)
				_ground_control(hold_fwd, hold_back, hold_up, hold_down, dash_fwd, dash_back)
		State.RUN:
			_run_control(hold_fwd, hold_up, hold_down)
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
		_:
			_ground_control(hold_fwd, hold_back, hold_up, hold_down, dash_fwd, dash_back)


func _ground_control(hold_fwd: bool, hold_back: bool, hold_up: bool, hold_down: bool,
		dash_fwd: bool, dash_back: bool) -> void:
	if hold_up:
		vx = 0
		from_run = 0
		_set_state(State.PREJUMP)
	elif hold_down:
		vx = 0
		_set_state(State.CROUCH)
	elif dash_fwd:
		run_speed = data.walk_f
		run_dir = facing
		vx = run_speed * run_dir
		_set_state(State.RUN)
		x += vx
	elif dash_back:
		vx = 0
		_set_state(State.BACKDASH)
	elif hold_fwd:
		vx = data.walk_f * facing
		_set_state(State.WALK_F)
		x += vx
	elif hold_back:
		vx = -data.walk_b * facing
		_set_state(State.WALK_B)
		x += vx
	else:
		vx = 0
		_set_state(State.STAND)


## Бег продолжается, пока держишь «вперёд»; скорость растёт до run_speed.
func _run_control(hold_fwd: bool, hold_up: bool, hold_down: bool) -> void:
	if hold_up:
		vx = 0
		from_run = 1
		_set_state(State.PREJUMP)
	elif hold_down:
		vx = 0
		_set_state(State.CROUCH)
	elif hold_fwd:
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
	_set_state(State.AIR)


func _set_state(s: State) -> void:
	if s != state:
		state = s
		state_frame = 0
