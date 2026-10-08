class_name Fighter
extends RefCounted
## Один боец: позиция, скорость, состояние. Только целые числа.
## x — по горизонтали арены, y — высота над землёй (0 — на земле). Всё в субпикселях.

enum State { STAND, WALK_F, WALK_B, CROUCH, PREJUMP, AIR, LAND }
const STATE_NAMES := ["стойка", "шаг вперёд", "шаг назад", "присед", "подготовка прыжка", "в воздухе", "приземление"]

const SUB := 100            # субпикселей в пикселе
const AIR_PUSH_RATIO := 60  # в воздухе «тело» ниже, чтобы можно было перепрыгнуть соперника, %

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


func _init(char_id: String, start_x_px: int, start_facing: int) -> void:
	id = char_id
	data = FighterData.get_data(char_id)
	x = start_x_px * SUB
	facing = start_facing


func save() -> PackedInt32Array:
	return PackedInt32Array([x, y, vx, vy, facing, state, state_frame, jump_dir])


func load(s: PackedInt32Array) -> void:
	x = s[0]; y = s[1]; vx = s[2]; vy = s[3]
	facing = s[4]; state = s[5] as State; state_frame = s[6]; jump_dir = s[7]


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


func step(bits: int) -> void:
	var fwd_bit := InputBits.RIGHT if facing > 0 else InputBits.LEFT
	var back_bit := InputBits.LEFT if facing > 0 else InputBits.RIGHT
	var hold_fwd := (bits & fwd_bit) != 0
	var hold_back := (bits & back_bit) != 0
	var hold_up := (bits & InputBits.UP) != 0
	var hold_down := (bits & InputBits.DOWN) != 0

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
				_ground_control(hold_fwd, hold_back, hold_up, hold_down)
		_:
			_ground_control(hold_fwd, hold_back, hold_up, hold_down)


func _ground_control(hold_fwd: bool, hold_back: bool, hold_up: bool, hold_down: bool) -> void:
	if hold_up:
		vx = 0
		_set_state(State.PREJUMP)
	elif hold_down:
		vx = 0
		_set_state(State.CROUCH)
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


## Направление прыжка берётся в момент отрыва — как в Street Fighter.
func _launch(hold_fwd: bool, hold_back: bool) -> void:
	jump_dir = 1 if hold_fwd else (-1 if hold_back else 0)
	match jump_dir:
		1: vx = data.jump_vx_f * facing
		-1: vx = -data.jump_vx_b * facing
		_: vx = 0
	vy = data.jump_vy
	_set_state(State.AIR)


func _set_state(s: State) -> void:
	if s != state:
		state = s
		state_frame = 0
