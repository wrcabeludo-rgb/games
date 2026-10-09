class_name Fighter
extends RefCounted
## Один боец: позиция, скорость, состояние. Только целые числа.
## x — по горизонтали арены, y — высота над землёй (0 — на земле). Всё в субпикселях.

enum State {
	STAND, WALK_F, WALK_B, CROUCH, PREJUMP, AIR, LAND, RUN, RUN_STOP, BACKDASH,
	ATTACK, HITSTUN, AIR_HIT, BLOCK, BLOCKSTUN, DOWN, KNOCKDOWN, THROWING, THROWN,
}
const STATE_NAMES := [
	"стойка", "шаг вперёд", "шаг назад", "присед", "подготовка прыжка", "в воздухе",
	"приземление", "бег", "торможение", "отскок", "удар", "оглушён", "отброшен", "блок", "в блоке", "повержен",
	"сбит с ног", "бросает", "в захвате",
]

## Удары по номерам: 0–3 стоя, 4–7 в приседе, 8–11 в прыжке; внутри — ЛР, ЛН, СР, СН.
const MOVES := [
	"st_lp", "st_lk", "st_hp", "st_hk",
	"cr_lp", "cr_lk", "cr_hp", "cr_hk",
	"j_lp", "j_lk", "j_hp", "j_hk",
	"sp_proj_l", "sp_proj_h",
	"sp_dd_l", "sp_dd_h",
	"sp_ff_l", "sp_ff_h",
	"sp_bb_l", "sp_bb_h",
	"st_sweep", "st_round", "throw", "super",
]
const MOVE_SWEEP := 20      # назад + ЛН — подсечка
const MOVE_ROUND := 21      # назад + СН — удар ногой с разворота
const MOVE_THROW := 22      # ЛР вплотную — бросок
const MOVE_SUPER := 23      # блок + СР + СН — суперприём (вся шкала)
## Спецприёмы: номер → ввод. Удар по номеру: SPECIAL_BASE + номер * 2 + сила (0 лёгкий, 1 сильный).
const SPECIAL_BASE := 12
const SPECIAL_PROJ := 0     # «назад, вперёд + удар»
const SPECIAL_DD := 1       # «вниз, вниз + удар»
const SPECIAL_FF := 2       # «вперёд, вперёд + удар»
const SPECIAL_BB := 3       # «назад, назад + удар» — командные броски
## Коды нажатий направлений (относительно взгляда бойца).
const TAP_BACK := 1
const TAP_FWD := 2
const TAP_DOWN := 3
const TAP_UP := 4
const TAP_WINDOW := 14      # между нажатиями направлений в спецприёме, тиков
const BUTTON_WINDOW := 10   # от последнего направления до кнопки удара, тиков
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
const KO_VX := 520          # нокаут: отлёт назад и вверх
const KO_VY := 1500
const DOWN_HEIGHT := 50     # высота лежащего бойца, px
const BLOCK_PUSH := 130     # в блоке отбрасывает сильнее, чем при попадании, %
const BLOCKSTUN_LESS := 2   # в блоке оглушение короче, чем при попадании, на столько тиков
const KNOCKDOWN_TICKS := 45 # сбитый с ног лежит (неуязвим) и встаёт
const KNOCK_LAUNCH := [200, 600]   # подброс по умолчанию у ударов, сбивающих с ног
const BACKDASH_CANCEL := 3  # в первые кадры отскока ещё можно начать «назад, назад + удар»
## Комбо (2.4).
const CHAIN_MAX := 4        # самая длинная строка ударов
const CHAIN_LATE := 10      # строку можно продолжить ещё столько тиков после активной фазы
const CANCEL_LATE := 12     # попавший удар можно отменить в спецприём ещё столько тиков после активной фазы
const COMBO_SCALE := 10     # каждый следующий удар в комбо слабее на 10%…
const COMBO_MIN := 30       # …но не слабее 30% от полного урона
const JUGGLE_MAX := 3       # сколько ударов можно добавить подброшенному сопернику
const JUGGLE_DECAY := 250   # каждый удар в воздухе подбрасывает слабее
const JUGGLE_MIN_VY := 500
const BUTTON_OF := {"lp": 0, "lk": 1, "hp": 2, "hk": 3}
## Шкала силы (2.5): 3 секции.
const METER_SECTION := 1000
const METER_MAX := 3 * METER_SECTION
## Парирование (2.6): тап «вперёд» не раньше PARRY_WINDOW тиков до попадания.
const PARRY_WINDOW := 6
const PARRY_LOCK := 20      # следующая попытка — не раньше, чем через столько тиков (нельзя долбить)
const PARRY_STAGGER := 32   # парированный атакующий ошеломлён (хватает на комбо)
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
var max_hp := MAX_HP        # у каждого бойца своё (FighterData "max_hp")
## Тесты урона: у всех бойцов одинаковое здоровье (они проверяют арифметику урона, а не запас здоровья).
static var test_max_hp := 0
var move := -1              # текущий удар (номер в MOVES) или -1
var move_frame := 0         # тик текущего удара, начиная с 1
var has_hit := 0            # удар уже попал (каждый удар попадает один раз)
var stun := 0               # оставшиеся тики оглушения
var pushback := 0           # скорость отбрасывания (по арене)
var low_pose := 0           # низкая стойка в оглушении или блоке (1 — сидя)
var combo := 0              # сколько ударов подряд пропущено
var landing_frames := 0     # длительность текущего приземления
var btn_timers := PackedInt32Array([TAP_TIMER_MAX, TAP_TIMER_MAX, TAP_TIMER_MAX, TAP_TIMER_MAX])
## Три последних нажатия направлений: [код, тиков назад] × 3, новые — первыми.
var tap_log := PackedInt32Array([0, TAP_TIMER_MAX, 0, TAP_TIMER_MAX, 0, TAP_TIMER_MAX])
var special_buf := -1       # распознанный спецприём, ждущий исполнения
var special_strength := 0
var special_timer := TAP_TIMER_MAX
## Выставляет симуляция перед тиком: свой снаряд ещё летит (второй выпустить нельзя).
var projectile_alive := false
## Удар дошёл до кадра выпуска снаряда — симуляция создаст снаряд в этот же тик.
var spawn_request := 0
## Туманный рывок дошёл до кадра появления — симуляция переставит бойца за спину сопернику.
var teleport_request := 0
var armor := 0              # сколько ударов ещё выдержит броня текущего приёма
var hypnotized := 0         # 1 — оглушён гипнозом, 2 — окаменел, 3 — прилип к жвачке (для отрисовки)
var inverted := 0           # тиков до конца «перехвата»: лево и право поменялись местами
var knock_on_land := 0      # приземлится — будет лежать (сбит с ног)
var parry_timer := TAP_TIMER_MAX  # тиков с последней засчитанной попытки парирования
var parry_cool := 0         # тиков до следующей возможной попытки
var staggered := 0          # 1 — ошеломлён парированием (для отрисовки)
## Выставляет симуляция перед тиком: ниже этого здоровья не опустить (в тренировке — 1, нокаута нет).
var min_hp := 0
## Удары текущей строки (номера в MOVES), -1 — пусто.
var chain := PackedInt32Array([-1, -1, -1, -1])
var juggle := 0             # сколько раз добит в воздухе за этот полёт
var combo_damage := 0       # урон текущего комбо (для счётчика)
var meter := 0              # шкала силы, 0…METER_MAX
var ex := 0                 # 1 — текущий спецприём усиленный
var special_ex := 0         # спецприём введён с зажатым блоком
var super_timer := TAP_TIMER_MAX  # тиков с ввода суперприёма
## Удар дошёл до первого кадра суперприёма — симуляция включит затемнение и паузу.
var flash_request := 0
## Усиленные версии спецприёмов (данные приёма + поле "ex"); не состояние — считаются из данных.
var ex_moves := {}
## Выставляет симуляция перед тиком: соперник вплотную и его можно бросить (ЛР станет броском).
var throw_ok := false
## Удар дошёл до кадра захвата — симуляция проверит, схвачен ли соперник.
var grab_request := 0
## Нажата ЛР в этот тик (в захвате — попытка вырваться).
var tech_press := 0
## Второй боец того же персонажа — рисуется другим цветом.
var alt := false


func _init(char_id: String, start_x_px: int, start_facing: int) -> void:
	id = char_id
	data = FighterData.get_data(char_id)
	for key in data.moves:
		if data.moves[key].has("ex"):
			ex_moves[key] = _merged(data.moves[key], data.moves[key].ex)
	x = start_x_px * SUB
	facing = start_facing
	max_hp = test_max_hp if test_max_hp > 0 else data.get("max_hp", MAX_HP)
	hp = max_hp


func save() -> PackedInt32Array:
	var s := PackedInt32Array([
		x, y, vx, vy, facing, state, state_frame, jump_dir,
		prev_bits, fwd_tap_timer, back_tap_timer, run_speed, run_dir, from_run,
		hp, move, move_frame, has_hit, stun, pushback, low_pose, combo, landing_frames,
	])
	s.append_array(btn_timers)
	s.append_array(tap_log)
	s.append_array(PackedInt32Array([special_buf, special_strength, special_timer, armor, hypnotized, knock_on_land]))
	s.append_array(chain)
	s.append_array(PackedInt32Array([juggle, combo_damage, meter, ex, special_ex, super_timer,
		parry_timer, parry_cool, staggered, inverted]))
	return s


func load(s: PackedInt32Array) -> void:
	x = s[0]; y = s[1]; vx = s[2]; vy = s[3]
	facing = s[4]; state = s[5] as State; state_frame = s[6]; jump_dir = s[7]
	prev_bits = s[8]; fwd_tap_timer = s[9]; back_tap_timer = s[10]
	run_speed = s[11]; run_dir = s[12]; from_run = s[13]
	hp = s[14]; move = s[15]; move_frame = s[16]; has_hit = s[17]; stun = s[18]
	pushback = s[19]; low_pose = s[20]; combo = s[21]; landing_frames = s[22]
	btn_timers = s.slice(23, 27)
	tap_log = s.slice(27, 33)
	special_buf = s[33]; special_strength = s[34]; special_timer = s[35]
	armor = s[36]; hypnotized = s[37]; knock_on_land = s[38]
	chain = s.slice(39, 43)
	juggle = s[43]; combo_damage = s[44]
	meter = s[45]; ex = s[46]; special_ex = s[47]; super_timer = s[48]
	parry_timer = s[49]; parry_cool = s[50]; staggered = s[51]; inverted = s[52]


# --- Вопросы о состоянии --------------------------------------------------

## Цвет бойца; второй боец того же персонажа — холоднее, чтобы их не путать.
func color() -> Color:
	var c: Color = data.color
	return c.lerp(Color(0.35, 0.55, 1.0), 0.5) if alt else c


## Парирует ли боец удар, который попадает прямо сейчас: недавно тапнул «вперёд» и стоит на земле свободно.
func can_parry() -> bool:
	return parry_timer <= PARRY_WINDOW and y == 0 and (is_grounded_actionable() or state == State.LAND)


## Удачное парирование: сразу свободен.
func parry_success() -> void:
	parry_timer = TAP_TIMER_MAX
	move = -1
	vx = 0
	_set_state(State.STAND)


## Удар парировали — ошеломлён.
func take_stagger() -> void:
	move = -1
	stun = PARRY_STAGGER
	pushback = 0
	low_pose = 0
	staggered = 1
	vx = 0
	_set_state(State.HITSTUN)
	state_frame = 0


func is_grounded_actionable() -> bool:
	return state == State.STAND or state == State.WALK_F or state == State.WALK_B \
		or state == State.CROUCH or state == State.BLOCK


## Сбит с ног, захвачен или бросает — по нему нельзя попасть.
func is_untouchable() -> bool:
	return state == State.KNOCKDOWN or state == State.THROWING or state == State.THROWN \
		or state == State.DOWN or (state == State.AIR_HIT and not is_juggleable())


## Подброшенного можно добить в воздухе, но не больше JUGGLE_MAX раз за полёт.
func is_juggleable() -> bool:
	return state == State.AIR_HIT and hp > 0 and juggle < JUGGLE_MAX


## Урон с учётом затухания в комбо: combo — номер удара в комбо (1 — первый).
static func scaled_damage(damage: int, combo_hits: int) -> int:
	return damage * maxi(100 - COMBO_SCALE * (combo_hits - 1), COMBO_MIN) / 100


## Можно ли схватить: на земле и не в оглушении/блоке (защита от бросков, как в Street Fighter).
func is_throwable() -> bool:
	if y != 0 or is_untouchable() or is_intangible() or is_invulnerable():
		return false
	return state != State.HITSTUN and state != State.BLOCKSTUN and state != State.AIR \
		and state != State.LAND


func is_airborne() -> bool:
	return state == State.AIR or state == State.AIR_HIT


func is_rising() -> bool:
	return state == State.AIR and vy > 0


func is_stunned() -> bool:
	return state == State.HITSTUN or state == State.AIR_HIT


func is_crouching() -> bool:
	if state == State.ATTACK and move >= 4 and move <= 7 and move_phase() >= 1 and move_data().get("uppercut", 0):
		return false  # апперкот: распрямился
	return state == State.CROUCH or (state == State.ATTACK and move >= 4 and move <= 7) \
		or ((state == State.HITSTUN or state == State.BLOCK or state == State.BLOCKSTUN) and low_pose == 1)


## Туманный рывок: в тумане боец неуязвим и проходит сквозь соперника.
func is_intangible() -> bool:
	if move < 0 or state != State.ATTACK:
		return false
	var m := move_data()
	return m.has("teleport") and move_frame >= m.teleport.invul_from and move_frame < m.startup


## Неуязвимый старт приёма (взлёт против прыжков): удары, снаряды и броски проходят мимо.
func is_invulnerable() -> bool:
	if move < 0 or state != State.ATTACK:
		return false
	var m := move_data()
	return m.has("invul") and move_frame >= m.invul[0] and move_frame < m.invul[1]


## Гипнотический взгляд: окно контратаки.
func is_countering() -> bool:
	if move < 0 or state != State.ATTACK:
		return false
	var m := move_data()
	return m.has("counter") and move_frame >= m.startup and move_frame < m.startup + m.active


## Броня держит удары в подготовке и активной фазе приёма.
func has_armor() -> bool:
	return armor > 0 and state == State.ATTACK and move >= 0 and move_phase() <= 1


func move_data() -> Dictionary:
	if move < 0:
		return {}
	var key: String = MOVES[move]
	if ex and ex_moves.has(key):
		return ex_moves[key]
	return data.moves[key]


## Данные приёма с заменой полей (вложенные словари — тоже по полям).
static func _merged(base: Dictionary, over: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	out.erase("ex")
	for k in over:
		if out.has(k) and out[k] is Dictionary and over[k] is Dictionary:
			out[k] = _merged(out[k], over[k])
		else:
			out[k] = over[k]
	return out


func add_meter(amount: int) -> void:
	# Помощь проигрывающему: при здоровье ниже 30% шкала копится в полтора раза быстрее.
	if amount > 0 and hp * 10 < max_hp * 3:
		amount = amount * 3 / 2
	meter = clampi(meter + amount, 0, METER_MAX)


func is_super() -> bool:
	return move == MOVE_SUPER


## Удар сейчас в активной фазе (может попасть).
func is_active() -> bool:
	if move < 0 or has_hit:
		return false
	var m := move_data()
	if not m.has("box"):
		return false
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
	if state == State.DOWN or state == State.KNOCKDOWN:
		return DOWN_HEIGHT * SUB
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
	if is_intangible() or is_untouchable():
		return []
	var half: int = data.push_half * HURT_WIDTH_RATIO / 100 * SUB
	var h: int = data.crouch_height * SUB if is_crouching() else data.height * SUB
	if state == State.AIR:
		h = h * 80 / 100
	var boxes: Array[PackedInt32Array] = [PackedInt32Array([x - half, x + half, y, y + h])]
	if move >= 0 and move_phase() >= 1 and move_data().has("box"):
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
	var in_combo := is_stunned()
	combo = combo + 1 if in_combo else 1
	var dmg := scaled_damage(m.damage, combo)
	combo_damage = combo_damage + dmg if in_combo else dmg
	hp = maxi(hp - dmg, min_hp)
	var was_crouching := is_crouching()
	var juggled := state == State.AIR_HIT
	move = -1
	chain = PackedInt32Array([-1, -1, -1, -1])
	if hp == 0:
		# Нокаут: отлетает в любом положении и падает.
		vx = KO_VX * attacker_facing
		vy = KO_VY
		y = maxi(y, 1)
		_set_state(State.AIR_HIT)
		state_frame = 0
		return
	if is_airborne():
		# В воздухе: отбрасывает; добивание подброшенного (жонглирование) — каждый раз ниже.
		var launch: Array = m.get("launch", KNOCK_LAUNCH) if m.get("knockdown", 0) else [AIR_HIT_VX, AIR_HIT_VY]
		juggle = juggle + 1 if juggled else 0
		vx = launch[0] * attacker_facing
		vy = maxi(launch[1] - juggle * JUGGLE_DECAY, JUGGLE_MIN_VY)
		y = maxi(y, 1)
		knock_on_land = 1 if m.get("knockdown", 0) or (juggled and knock_on_land) else 0
		_set_state(State.AIR_HIT)
		state_frame = 0
		return
	if m.get("knockdown", 0):
		# Подсечка, разворот, апперкот: подбрасывает, соперник падает и лежит.
		var launch: Array = m.get("launch", KNOCK_LAUNCH)
		_launch_knockdown(launch, attacker_facing)
		return
	low_pose = 1 if was_crouching else 0
	stun = m.hitstun
	pushback = m.push * attacker_facing
	vx = 0
	_set_state(State.HITSTUN)
	state_frame = 0


func _launch_knockdown(launch: Array, direction: int) -> void:
	vx = launch[0] * direction
	vy = launch[1]
	y = maxi(y, 1)
	knock_on_land = 1
	juggle = 0
	move = -1
	_set_state(State.AIR_HIT)
	state_frame = 0


## Схвачен: стоит в захвате, пока симуляция не завершит бросок.
func become_thrown() -> void:
	move = -1
	vx = 0
	_set_state(State.THROWN)
	state_frame = 0


## Добивание: проигравший стоит оглушённым (звёзды над головой), пока победитель вводит команду.
func daze(ticks: int) -> void:
	move = -1
	x = clampi(x, push_half(), Sim.ARENA_WIDTH * SUB - push_half())
	y = 0
	vx = 0
	vy = 0
	pushback = 0
	low_pose = 0
	staggered = 1
	stun = ticks
	_set_state(State.HITSTUN)
	state_frame = 0


## Добивание: улетает «за горизонт» (заглушка, пока нет своих анимаций).
func finisher_launch(direction: int) -> void:
	staggered = 0
	_launch_knockdown([700, 3400], direction)


## Отпустили из захвата без броска: в воздухе — падает, на земле — сразу свободен.
func release_grab() -> void:
	if y > 0:
		_launch_knockdown([0, 0], facing)
	else:
		_set_state(State.STAND)
		state_frame = 0


## Бросок завершён: урон и полёт в сторону direction, потом лежит.
func take_throw(grab: Dictionary, direction: int) -> void:
	var dmg: int = scaled_damage(grab.damage, combo + 1) if grab.get("scaled", 0) else grab.damage
	combo = 0
	hp = maxi(hp - dmg, min_hp)
	if hp == 0:
		vx = KO_VX * direction
		vy = KO_VY
		y = maxi(y, 1)
		_set_state(State.AIR_HIT)
		state_frame = 0
		return
	_launch_knockdown(grab.launch, direction)
	juggle = JUGGLE_MAX  # после броска не добить


## Вырвался из захвата (или бросающий, у которого вырвались): разлёт в стороны.
func throw_break(direction: int) -> void:
	move = -1
	stun = 14
	pushback = 1100 * direction
	_set_state(State.BLOCKSTUN)
	state_frame = 0


## Бросающий закончил бросок — короткое восстановление.
func finish_throw(recovery: int) -> void:
	move = -1
	landing_frames = recovery
	_set_state(State.LAND)


## Попробовать заблокировать удар. Стоя не держится низкий удар, сидя — удар сверху.
func try_block(m: Dictionary) -> bool:
	if state != State.BLOCK and state != State.BLOCKSTUN:
		return false
	var level: String = m.get("level", "high")
	if (level == "low" and low_pose == 0) or (level == "overhead" and low_pose == 1):
		return false
	return true


## Удар заблокирован: короткое оглушение в блоке и сильное отталкивание.
## Обычные удары урона не наносят, спецприёмы снимают немного сквозь блок (chip).
func take_block(m: Dictionary, attacker_facing: int) -> void:
	var chip: int = m.get("chip", 0)
	if chip > 0:
		if hp <= chip:
			take_hit(m, attacker_facing)  # урон сквозь блок может добить
			return
		hp -= chip
	stun = m.get("blockstun", m.hitstun - BLOCKSTUN_LESS)
	pushback = m.push * BLOCK_PUSH / 100 * attacker_facing
	vx = 0
	_set_state(State.BLOCKSTUN)
	state_frame = 0


## Удар пришёлся в броню: урон проходит, но приём не прерывается.
func absorb_hit(m: Dictionary, attacker_facing: int) -> void:
	if hp <= m.damage:
		take_hit(m, attacker_facing)
		return
	hp -= m.damage
	armor -= 1


## Атаковал в гипнотический взгляд — застыл.
func take_hypnosis(frames: int) -> void:
	move = -1
	stun = frames
	pushback = 0
	low_pose = 0
	hypnotized = 1
	vx = 0
	_set_state(State.HITSTUN)
	state_frame = 0


## Контратака сработала — Дракула сразу свободен.
func counter_success() -> void:
	move = -1
	_set_state(State.STAND)


func mark_hit() -> void:
	has_hit = 1


# --- Ввод ----------------------------------------------------------------

## Обновляет таймеры нажатий. aging = false во время заморозки (hitstop):
## нажатия запоминаются, но не «протухают».
func read_input(bits: int, aging: bool) -> Dictionary:
	if inverted > 0 and (bits & (InputBits.LEFT | InputBits.RIGHT)) != 0 \
			and (bits & (InputBits.LEFT | InputBits.RIGHT)) != (InputBits.LEFT | InputBits.RIGHT):
		bits ^= InputBits.LEFT | InputBits.RIGHT  # перехват: нажал вправо — пошёл влево
	var fwd_bit := InputBits.RIGHT if facing > 0 else InputBits.LEFT
	var back_bit := InputBits.LEFT if facing > 0 else InputBits.RIGHT
	if aging:
		fwd_tap_timer = mini(fwd_tap_timer + 1, TAP_TIMER_MAX)
		parry_timer = mini(parry_timer + 1, TAP_TIMER_MAX)
		parry_cool = maxi(parry_cool - 1, 0)
		back_tap_timer = mini(back_tap_timer + 1, TAP_TIMER_MAX)
		special_timer = mini(special_timer + 1, TAP_TIMER_MAX)
		super_timer = mini(super_timer + 1, TAP_TIMER_MAX)
		for i in 4:
			btn_timers[i] = mini(btn_timers[i] + 1, TAP_TIMER_MAX)
		for i in 3:
			tap_log[i * 2 + 1] = mini(tap_log[i * 2 + 1] + 1, TAP_TIMER_MAX)
	# Журнал нажатий направлений — по нему узнаются спецприёмы.
	for pair in [[back_bit, TAP_BACK], [fwd_bit, TAP_FWD], [InputBits.DOWN, TAP_DOWN], [InputBits.UP, TAP_UP]]:
		if (bits & pair[0]) != 0 and (prev_bits & pair[0]) == 0:
			_push_tap(pair[1])
	var dash_fwd := false
	var dash_back := false
	if (bits & fwd_bit) != 0 and (prev_bits & fwd_bit) == 0:
		dash_fwd = fwd_tap_timer <= DASH_WINDOW
		fwd_tap_timer = 0
		if parry_cool == 0:
			parry_timer = 0
			parry_cool = PARRY_LOCK
	if (bits & back_bit) != 0 and (prev_bits & back_bit) == 0:
		dash_back = back_tap_timer <= DASH_WINDOW
		back_tap_timer = 0
	for i in 4:
		if (bits & ATTACK_BITS[i]) != 0 and (prev_bits & ATTACK_BITS[i]) == 0:
			btn_timers[i] = 0
			if i == 0:
				tech_press = 1
			special_ex = 1 if bits & InputBits.BLOCK else 0
			_check_special(i)
	# Суперприём: блок + СР + СН (вторая из сильных нажата, пока первая держится).
	var heavy := InputBits.HP | InputBits.HK
	if (bits & InputBits.BLOCK) and (bits & heavy) == heavy and (prev_bits & heavy) != heavy:
		super_timer = 0
	prev_bits = bits
	return {
		"fwd": (bits & fwd_bit) != 0, "back": (bits & back_bit) != 0,
		"up": (bits & InputBits.UP) != 0, "down": (bits & InputBits.DOWN) != 0,
		"dash_fwd": dash_fwd, "dash_back": dash_back,
		"block": (bits & InputBits.BLOCK) != 0,
	}


func _push_tap(code: int) -> void:
	for i in [2, 1]:
		tap_log[i * 2] = tap_log[(i - 1) * 2]
		tap_log[i * 2 + 1] = tap_log[(i - 1) * 2 + 1]
	tap_log[0] = code
	tap_log[1] = 0


## Нажата кнопка удара: не завершает ли она ввод спецприёма?
## «Назад, вперёд + удар»: вперёд не раньше BUTTON_WINDOW тиков до кнопки,
## назад — не раньше TAP_WINDOW тиков до «вперёд».
func _check_special(button: int) -> void:
	if tap_log[0] == TAP_FWD and tap_log[2] == TAP_BACK and tap_log[1] <= BUTTON_WINDOW \
			and tap_log[3] - tap_log[1] <= TAP_WINDOW:
		_queue_special(SPECIAL_PROJ, button)
	elif tap_log[0] == TAP_FWD and tap_log[2] == TAP_FWD and tap_log[1] <= BUTTON_WINDOW \
			and tap_log[3] - tap_log[1] <= TAP_WINDOW:
		_queue_special(SPECIAL_FF, button)
	elif tap_log[0] == TAP_DOWN and tap_log[2] == TAP_DOWN and tap_log[1] <= BUTTON_WINDOW \
			and tap_log[3] - tap_log[1] <= TAP_WINDOW:
		_queue_special(SPECIAL_DD, button)
	elif tap_log[0] == TAP_BACK and tap_log[2] == TAP_BACK and tap_log[1] <= BUTTON_WINDOW \
			and tap_log[3] - tap_log[1] <= TAP_WINDOW:
		_queue_special(SPECIAL_BB, button)


## Спецприём узнан по направлениям; проверяем, подходит ли кнопка (руки, ноги или любая).
func _queue_special(special: int, button: int) -> void:
	var key: String = MOVES[SPECIAL_BASE + special * 2]
	if not data.moves.has(key):
		return
	var m: Dictionary = data.moves[key]
	var kind: String = m.get("buttons", "any")
	var is_punch := button == 0 or button == 2
	if (kind == "punch" and not is_punch) or (kind == "kick" and is_punch):
		return
	special_buf = special
	# У большинства приёмов одна версия; у палицы — лёгкая и сильная.
	special_strength = (1 if button >= 2 else 0) if m.get("versions", 1) == 2 else 0
	special_timer = 0


## Готов ли спецприём из буфера к исполнению (и разрешён ли он сейчас).
func _super_ready() -> bool:
	return super_timer <= BUFFER and meter >= METER_MAX and data.moves.has("super")


func _start_super() -> void:
	for i in 4:
		_consume_button(i)
	super_timer = TAP_TIMER_MAX
	special_buf = -1
	meter -= METER_MAX
	move = MOVE_SUPER
	chain = PackedInt32Array([-1, -1, -1, -1])
	_begin_move()
	flash_request = 1


func _special_ready() -> bool:
	if special_buf < 0 or special_timer > BUFFER:
		return false
	var m: Dictionary = data.moves[MOVES[SPECIAL_BASE + special_buf * 2]]
	if m.has("proj") and projectile_alive:
		return false
	return true


func _start_special() -> void:
	for i in 4:
		if btn_timers[i] <= BUFFER:
			_consume_button(i)  # чтобы вслед не вышел ещё и обычный удар
	move = SPECIAL_BASE + special_buf * 2 + special_strength
	# Усиленный: спецприём введён с зажатым блоком и есть секция шкалы.
	ex = 1 if special_ex and meter >= METER_SECTION and ex_moves.has(MOVES[move]) else 0
	if ex:
		meter -= METER_SECTION
	armor = move_data().get("armor", 0)
	special_buf = -1
	special_timer = TAP_TIMER_MAX
	chain = PackedInt32Array([-1, -1, -1, -1])
	move_frame = 1
	has_hit = 0
	vx = 0
	_set_state(State.ATTACK)
	state_frame = 0


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
	inverted = maxi(inverted - 1, 0)
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
				if hp == 0:
					y = 0
					vx = 0
					vy = 0
					_set_state(State.DOWN)
				elif knock_on_land:
					y = 0
					vx = 0
					vy = 0
					knock_on_land = 0
					_set_state(State.KNOCKDOWN)
				else:
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
			if state_frame <= BACKDASH_CANCEL and _special_ready():
				_start_special()
				return
			var speed := maxi(data.backdash_v0 - data.backdash_decel * (state_frame - 1), 0)
			vx = -speed * facing
			x += vx
			if speed == 0 and state_frame >= _backdash_moving_frames() + data.backdash_recovery:
				_set_state(State.STAND)
		State.DOWN, State.THROWING, State.THROWN:
			pass  # управляет симуляция
		State.KNOCKDOWN:
			if state_frame >= KNOCKDOWN_TICKS:
				_set_state(State.STAND)
				_ground_control(inp)
		State.ATTACK:
			if _try_cancel():
				return
			move_frame += 1
			var m := move_data()
			if m.has("proj") and move_frame == m.startup:
				spawn_request = 1
			if m.has("teleport") and move_frame == m.startup:
				teleport_request = 1
			if m.has("grab") and move_frame == m.startup:
				grab_request = 1
			# Многократный удар (лента Аватара): каждые rehit тиков активной фазы бьёт снова.
			if m.has("rehit") and has_hit and move_frame > m.startup and move_frame < m.startup + m.active \
					and (move_frame - m.startup) % int(m.rehit) == 0:
				has_hit = 0
			# Рывок вперёд в активной фазе (таран), пока не попал.
			if m.has("lunge") and has_hit == 0 and move_frame >= m.startup and move_frame < m.startup + m.active:
				x += m.lunge * facing
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
				hypnotized = 0
				staggered = 0
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
	if _super_ready():
		_start_super()
	elif _special_ready():
		_start_special()
	elif b >= 0:
		_start_attack(b, inp.down, inp.back)
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


func _start_attack(button: int, crouching: bool, back := false) -> void:
	_consume_button(button)
	move = (4 if crouching else 0) + button
	if not crouching:
		if button == 0 and throw_ok and data.moves.has("throw"):
			move = MOVE_THROW
		elif back and button == 1 and data.moves.has("st_sweep"):
			move = MOVE_SWEEP
		elif back and button == 3 and data.moves.has("st_round"):
			move = MOVE_ROUND
	chain = PackedInt32Array([move if move <= 7 else -1, -1, -1, -1])
	_begin_move()


func _begin_move() -> void:
	ex = 0
	move_frame = 1  # тик нажатия — первый кадр удара (как во фреймдате Street Fighter)
	has_hit = 0
	vx = 0
	_set_state(State.ATTACK)
	state_frame = 0


## Обычный удар на земле: его можно продолжить строкой или отменить в спецприём.
func _is_ground_normal() -> bool:
	return move >= 0 and (move <= 7 or move == MOVE_SWEEP or move == MOVE_ROUND)


## Во время удара: отмена в спецприём (только если удар коснулся — попал или в блок)
## или следующий удар строки (как в Mortal Kombat — выходит и при промахе).
func _try_cancel() -> bool:
	if not _is_ground_normal():
		return false
	# Блок + СР + СН нажаты не совсем одновременно: сильный удар в первые кадры превращается в суперприём.
	if move_frame <= 3 and _super_ready():
		_start_super()
		return true
	var m := move_data()
	var after: int = move_frame - (m.startup + m.active - 1)  # > 0 — уже восстановление
	if has_hit and after <= CANCEL_LATE and _super_ready():
		_start_super()
		return true
	if has_hit and after <= CANCEL_LATE and _special_ready():
		_start_special()
		return true
	if (has_hit or after >= 0) and after <= CHAIN_LATE:
		var b := _buffered_button()
		if b < 0:
			return false
		var n := chain.find(-1)
		var next := _next_in_string(b, n)
		if next < 0:
			return false
		_consume_button(b)
		chain[n] = next
		move = next
		_begin_move()
		return true
	return false


## Следующий удар строки для кнопки button, если строка сейчас на шаге n; иначе -1.
func _next_in_string(button: int, n: int) -> int:
	if n <= 0:
		return -1
	for s in data.get("strings", []):
		var keys: Array = s.moves
		if keys.size() <= n:
			continue
		var same := true
		for i in n:
			if keys[i] != MOVES[chain[i]]:
				same = false
				break
		if same and BUTTON_OF[(keys[n] as String).right(2)] == button:
			return MOVES.find(keys[n])
	return -1


## Бег продолжается, пока держишь «вперёд»; скорость растёт до run_speed.
## Из бега можно сразу ударить.
func _run_control(inp: Dictionary) -> void:
	var b := _buffered_button()
	if _super_ready():
		_start_super()
	elif _special_ready():
		_start_special()
	elif b >= 0:
		_start_attack(b, inp.down, inp.back)
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
