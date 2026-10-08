class_name AiController
extends RefCounted
## ИИ-соперник для тестов. Работает как «виртуальный геймпад»: смотрит на состояние боя
## и возвращает нажатые кнопки, как обычный игрок. Правила боя не нарушает.
## Видит соперника с задержкой (время реакции), поэтому его можно обмануть.

enum Level { OFF, EASY, MEDIUM, HARD }
const LEVEL_NAMES := ["выкл", "лёгкий", "средний", "сложный"]

## Параметры уровней.
##   reaction — через сколько тиков ИИ «замечает» действие соперника
##   block    — шанс заблокировать замеченный удар
##   anti_air — шанс сбить прыжок
##   think    — пауза между решениями, тиков [мин, макс]
##   punish   — шанс наказать удар в восстановлении
##   wary     — шанс за тик заранее поднять блок, когда стоит в досягаемости джеба соперника
##              (быстрые удары не успеть «увидеть» — опытный игрок вблизи держит блок)
const LEVELS := {
	Level.EASY: {"reaction": 24, "block": 0.25, "anti_air": 0.15, "think": [30, 55], "punish": 0.1, "wary": 0.0},
	Level.MEDIUM: {"reaction": 15, "block": 0.55, "anti_air": 0.45, "think": [14, 30], "punish": 0.45, "wary": 0.04},
	Level.HARD: {"reaction": 9, "block": 0.85, "anti_air": 0.8, "think": [6, 16], "punish": 0.85, "wary": 0.12},
}

const NEAR := 190       # близко: лёгкие удары и броски вплотную, px
const MID := 330        # средняя дистанция: дальние ноги и палица
const GUARD_RANGE := 330

var level := Level.OFF
var _rng := RandomNumberGenerator.new()
var _plan: Array = []           # очередь [биты, тиков]
var _cooldown := 0
var _seen: Array = []           # что ИИ «видел» о сопернике в прошлые тики
var _guarding := 0              # сколько ещё тиков держать блок


func _init(seed_value := 1) -> void:
	_rng.seed = seed_value


func next_level() -> void:
	level = ((level + 1) % LEVEL_NAMES.size()) as Level
	reset()


func reset() -> void:
	_plan.clear()
	_seen.clear()
	_cooldown = 30
	_guarding = 0


## Докуда достаёт лёгкий удар рукой соперника (между центрами бойцов), px.
static func _jab_reach(op: Fighter, me: Fighter) -> int:
	var box: Array = op.data.moves.st_lp.box
	return box[0] + box[2] + me.data.push_half + 10


func level_name() -> String:
	return LEVEL_NAMES[level]


## Кнопки ИИ на этот тик для игрока p.
func get_input(sim: Sim, p: int) -> int:
	if level == Level.OFF or sim.phase != Sim.Phase.FIGHT:
		_plan.clear()
		return 0
	var cfg: Dictionary = LEVELS[level]
	var me := sim.fighters[p]
	var op := sim.fighters[1 - p]
	_remember(op, me)
	var seen: Dictionary = _seen[0] if _seen.size() >= cfg.reaction else {}
	var fwd := InputBits.RIGHT if me.facing > 0 else InputBits.LEFT
	var back := InputBits.LEFT if me.facing > 0 else InputBits.RIGHT
	var dist := absi(op.x - me.x) / Sim.SUB

	# Защита важнее всего: если заметил удар — блок (нижний против низких).
	if _guarding > 0:
		_guarding -= 1
		if not seen.is_empty() and seen.attacking:
			_guarding = maxi(_guarding, 3)
		return InputBits.BLOCK | (InputBits.DOWN if seen.get("low", false) else 0)
	if me.is_grounded_actionable() and not seen.is_empty() and seen.attacking \
			and seen.dist < GUARD_RANGE and _rng.randf() < cfg.block:
		_plan.clear()
		_guarding = 12
		return InputBits.BLOCK | (InputBits.DOWN if seen.low else 0)

	# Вблизи от соперника — иногда заранее в блок.
	if me.is_grounded_actionable() and _plan.is_empty() and dist < _jab_reach(op, me) \
			and _rng.randf() < cfg.wary:
		_guarding = 10
		return InputBits.BLOCK

	# Сбить прыжок ударом снизу (у обоих бойцов вниз + СР бьёт вверх).
	if me.is_grounded_actionable() and op.is_airborne() and op.state == Fighter.State.AIR \
			and op.vy < 0 and dist < 230 and _cooldown <= 0:
		_cooldown = 25
		if _rng.randf() < cfg.anti_air:
			_plan = [[InputBits.DOWN | InputBits.HP, 1], [InputBits.DOWN, 20]]

	# Добить оглушённого или наказать удар в восстановлении.
	if _plan.is_empty() and me.is_grounded_actionable():
		if op.state == Fighter.State.HITSTUN and dist < NEAR + 20:
			_plan = [[InputBits.LP, 1], [0, 6]]
		elif op.state == Fighter.State.ATTACK and op.move_phase() == 2 and dist < NEAR + 40 \
				and _rng.randf() < cfg.punish:
			_plan = [[InputBits.LP, 1], [0, 4], [InputBits.LP, 1], [0, 6]]

	if _plan.is_empty():
		_cooldown -= 1
		if _cooldown <= 0 and me.is_grounded_actionable():
			_decide(dist, fwd, back, cfg, dist < _jab_reach(op, me))
			_cooldown = _rng.randi_range(cfg.think[0], cfg.think[1])
		elif me.is_grounded_actionable() and dist > MID:
			return fwd  # между решениями подходит ближе

	return _run_plan()


## Новое решение в зависимости от дистанции.
func _decide(dist: int, fwd: int, back: int, cfg: Dictionary, in_jab_range: bool) -> void:
	var r := _rng.randf()
	# В досягаемости джеба соперника опытный ИИ чаще встаёт в блок, чем лезет с медленным ударом.
	if in_jab_range and _rng.randf() < cfg.wary * 5.0:
		_plan = [[InputBits.BLOCK, _rng.randi_range(15, 28)]]
		return
	if dist > MID:
		if r < 0.45:
			_plan = [[fwd, _rng.randi_range(15, 35)]]
		elif r < 0.7:
			_plan = [[fwd, 2], [0, 2], [fwd, _rng.randi_range(10, 22)]]  # разбег
		elif r < 0.9:
			_plan = [[InputBits.UP | fwd, 1], [fwd, 16], [InputBits.HK, 1], [0, 25]]  # прыжок с ударом
		else:
			_plan = [[0, 20]]
	elif dist > NEAR:
		if r < 0.35:
			_plan = [[InputBits.HK, 1], [0, 18]]
		elif r < 0.6:
			_plan = [[InputBits.DOWN | InputBits.HK, 1], [InputBits.DOWN, 22]]  # подсечка
		elif r < 0.75:
			_plan = [[InputBits.UP | fwd, 1], [fwd, 12], [InputBits.HP, 1], [0, 25]]
		elif r < 0.9:
			_plan = [[fwd, _rng.randi_range(8, 18)]]
		else:
			_plan = [[back, _rng.randi_range(10, 20)]]
	else:
		if r < 0.3:
			_plan = [[InputBits.LP, 1], [0, 5], [InputBits.LP, 1], [0, 8]]
		elif r < 0.5:
			_plan = [[InputBits.DOWN | InputBits.LK, 1], [InputBits.DOWN, 8], [InputBits.DOWN | InputBits.LP, 1], [0, 10]]
		elif r < 0.65:
			_plan = [[InputBits.HP, 1], [0, 20]]
		elif r < 0.8:
			_plan = [[back, 2], [0, 2], [back, 1], [0, 15]]  # отскок
		else:
			_plan = [[InputBits.BLOCK, _rng.randi_range(10, 25)]]


func _run_plan() -> int:
	if _plan.is_empty():
		return 0
	var step: Array = _plan[0]
	var bits: int = step[0]
	step[1] -= 1
	if step[1] <= 0:
		_plan.pop_front()
	return bits


## Запоминает, что делает соперник; ИИ «видит» это с задержкой.
func _remember(op: Fighter, me: Fighter) -> void:
	var low := false
	if op.move >= 0:
		low = op.move_data().get("level", "high") == "low"
	_seen.append({
		"attacking": op.move >= 0 and op.move_phase() <= 1,
		"low": low,
		"dist": absi(op.x - me.x) / Sim.SUB,
	})
	var cfg: Dictionary = LEVELS[level]
	while _seen.size() > cfg.reaction:
		_seen.pop_front()
