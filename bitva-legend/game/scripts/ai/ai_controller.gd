class_name AiController
extends RefCounted
## ИИ-соперник. Работает как «виртуальный геймпад»: смотрит на состояние боя
## и возвращает нажатые кнопки, как обычный игрок. Правила боя не нарушает.
## Видит соперника с задержкой (время реакции), поэтому его можно обмануть.
## У каждого бойца своя манера (STYLES): любимая дистанция, напор, прыжки, снаряды, спецприёмы.
## Роли спецприёмов (снаряд, рывок, захват, взлёт, контратака, телепорт) ИИ узнаёт по данным приёма.

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
	Level.HARD: {"reaction": 9, "block": 0.85, "anti_air": 0.8, "think": [6, 16], "punish": 0.85, "wary": 0.16},
}

## Манера бойцов:
##   ideal   — любимая дистанция, px (дальше — подходит или стреляет, ближе — отходит, если любит дистанцию)
##   aggro   — напор: как часто атакует, а не ждёт
##   jump    — как часто прыгает с ударом
##   zone    — как часто бросает снаряд издалека
##   special — как часто вообще использует спецприёмы
const STYLES := {
	"ilya": {"ideal": 260, "aggro": 0.6, "jump": 0.15, "zone": 0.35, "special": 0.35},      # давит, таран
	"dracula": {"ideal": 420, "aggro": 0.4, "jump": 0.2, "zone": 0.6, "special": 0.45},     # мыши издалека, туман
	"koschei": {"ideal": 330, "aggro": 0.35, "jump": 0.1, "zone": 0.45, "special": 0.45},   # осторожный хитрец, ловит на контратаку
	"hercules": {"ideal": 150, "aggro": 0.7, "jump": 0.15, "zone": 0.25, "special": 0.35},  # лезет вплотную, хватает
	"athena": {"ideal": 380, "aggro": 0.4, "jump": 0.05, "zone": 0.55, "special": 0.45},    # стена: копьё, сова против прыжков
	"medusa": {"ideal": 360, "aggro": 0.45, "jump": 0.1, "zone": 0.5, "special": 0.45},     # контроль: яд, взгляд
	"sunwukong": {"ideal": 230, "aggro": 0.65, "jump": 0.4, "zone": 0.3, "special": 0.4},   # прыгает, дразнит, посох
	"anubis": {"ideal": 400, "aggro": 0.35, "jump": 0.05, "zone": 0.55, "special": 0.4},    # терпеливый: скарабеи, смерч
	"lenta": {"ideal": 300, "aggro": 0.65, "jump": 0.2, "zone": 0.5, "special": 0.6},       # босс: всё сразу и без пауз
}
const DEFAULT_STYLE := {"ideal": 300, "aggro": 0.5, "jump": 0.15, "zone": 0.35, "special": 0.3}
## Насколько часто уровень пользуется спецприёмами и суперприёмом.
const LEVEL_SPECIALS := {Level.EASY: 0.4, Level.MEDIUM: 0.8, Level.HARD: 1.0}

const NEAR := 190       # близко: лёгкие удары и броски вплотную, px
const MID := 330        # средняя дистанция: дальние ноги и палица
const GUARD_RANGE := 330

var level := Level.OFF
var _rng := RandomNumberGenerator.new()
var _plan: Array = []           # очередь [биты, тиков]
var _cooldown := 0
var _seen: Array = []           # что ИИ «видел» о сопернике в прошлые тики
var _guarding := 0              # сколько ещё тиков держать блок
var _roles := {}                # боец → роли его спецприёмов (кэш)


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

	var style: Dictionary = STYLES.get(me.id, DEFAULT_STYLE)
	var roles := _roles_of(me)
	var sp_chance: float = style.special * LEVEL_SPECIALS[level]

	# Сбить прыжок: взлётом (если есть), иначе ударом снизу (у всех вниз + СР бьёт вверх).
	if me.is_grounded_actionable() and op.is_airborne() and op.state == Fighter.State.AIR \
			and op.vy < 0 and dist < 260 and _cooldown <= 0:
		_cooldown = 25
		if _rng.randf() < cfg.anti_air:
			if roles.has("anti_air") and _rng.randf() < sp_chance * 1.5:
				_plan = _special_plan(roles.anti_air, fwd, back)
			else:
				_plan = [[InputBits.DOWN | InputBits.HP, 1], [InputBits.DOWN, 20]]

	# Суперприём: шкала полна, соперник рядом и открыт.
	if _plan.is_empty() and me.is_grounded_actionable() and me.meter >= Fighter.METER_MAX \
			and me.data.moves.has("super") and dist < 280 and _rng.randf() < 0.04 * LEVEL_SPECIALS[level]:
		_plan = [[InputBits.BLOCK | InputBits.HP | InputBits.HK, 1], [0, 50]]

	# Соперник стреляет — телепорт за спину (если умеет).
	if _plan.is_empty() and me.is_grounded_actionable() and roles.has("teleport") and sim.has_projectile(1 - p) \
			and dist > NEAR and _rng.randf() < sp_chance * 0.15:
		_plan = _special_plan(roles.teleport, fwd, back)

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
			# В досягаемости джеба опытный ИИ сначала думает о защите (общая логика), а не о манере.
			var cautious: bool = dist < _jab_reach(op, me) and _rng.randf() < cfg.wary * 5.0
			if cautious:
				_plan = [[InputBits.BLOCK, _rng.randi_range(15, 28)]]
			elif not _decide_style(sim, p, dist, fwd, back, style, roles, sp_chance):
				_decide(dist, fwd, back, cfg, dist < _jab_reach(op, me))
			_cooldown = _rng.randi_range(cfg.think[0], cfg.think[1])
		elif me.is_grounded_actionable() and dist > maxi(MID, int(style.ideal) + 60):
			return fwd  # между решениями подходит ближе

	return _run_plan()


## Решение «в характере»: держать любимую дистанцию, стрелять, прыгать, применять спецприёмы.
## false — пусть решает общая логика (_decide).
func _decide_style(sim: Sim, p: int, dist: int, fwd: int, back: int, style: Dictionary, roles: Dictionary,
		sp_chance: float) -> bool:
	var ideal: int = style.ideal
	var r := _rng.randf()
	# Далеко от любимой дистанции: снаряд, прыжок или подход.
	if dist > ideal + 90:
		if roles.has("proj") and not sim.has_projectile(p) and r < style.zone * LEVEL_SPECIALS[level]:
			_plan = _special_plan(_zone_entry(roles), fwd, back, dist)
			return true
		if r < style.zone + style.jump and dist < ideal + 330:
			_plan = [[InputBits.UP | fwd, 1], [fwd, 15], [InputBits.HK if _rng.randf() < 0.5 else InputBits.HP, 1], [0, 25]]
			return true
		if roles.has("rush") and dist < 420 and _rng.randf() < sp_chance * 0.2:
			_plan = _special_plan(roles.rush, fwd, back)
			return true
		return false
	# Слишком близко для любителя дистанции — отходит (чем меньше напор, тем чаще).
	if dist < ideal - 110 and ideal >= 330 and r < 1.0 - style.aggro:
		if _rng.randf() < 0.5:
			_plan = [[back, 2], [0, 2], [back, 1], [0, 12]]  # отскок
		else:
			_plan = [[back, _rng.randi_range(14, 26)]]
		return true
	# Любитель дистанции на своей дистанции не лезет вперёд: обстреливает или выжидает.
	if ideal > MID and dist > MID - 40 and r < 1.0 - style.aggro * 0.5:
		if roles.has("proj") and not sim.has_projectile(p) and _rng.randf() < style.zone * LEVEL_SPECIALS[level]:
			_plan = _special_plan(_zone_entry(roles), fwd, back, dist)
		elif _rng.randf() < 0.4:
			_plan = [[back, _rng.randi_range(6, 14)], [0, 6]]
		else:
			_plan = [[0, _rng.randi_range(10, 24)]]
		return true
	# На своей дистанции — спецприёмы по ситуации.
	if _rng.randf() < sp_chance:
		if roles.has("grab") and dist < roles.grab_reach and _rng.randf() < 0.6:
			_plan = _special_plan(roles.grab, fwd, back)
			return true
		if roles.has("counter") and dist < 300 and _rng.randf() < 0.35:
			_plan = _special_plan(roles.counter, fwd, back)
			return true
		if roles.has("rush") and dist > NEAR - 40 and dist < 420 and _rng.randf() < 0.35:
			_plan = _special_plan(roles.rush, fwd, back)
			return true
		if roles.has("proj") and not sim.has_projectile(p) and dist > NEAR:
			_plan = _special_plan(_zone_entry(roles), fwd, back, dist)
			return true
		if roles.has("teleport") and _rng.randf() < 0.3:
			_plan = _special_plan(roles.teleport, fwd, back)
			return true
	# Обезьяна дразнится: прыжки на месте и отскоки.
	if style.jump >= 0.3 and _rng.randf() < style.jump * 0.4:
		_plan = [[InputBits.UP, 1], [0, 40]] if _rng.randf() < 0.5 else [[back, 2], [0, 2], [back, 1], [0, 10]]
		return true
	# Нет напора — чаще ждёт в блоке.
	if _rng.randf() > style.aggro + 0.3:
		_plan = [[InputBits.BLOCK, _rng.randi_range(12, 26)]]
		return true
	return false


## Роли спецприёмов бойца: роль → [номер приёма (Fighter.SPECIAL_*), кнопка]. Определяются по данным.
func _roles_of(f: Fighter) -> Dictionary:
	if _roles.has(f.id):
		return _roles[f.id]
	var roles := {}
	var specials := [Fighter.SPECIAL_PROJ, Fighter.SPECIAL_DD, Fighter.SPECIAL_FF, Fighter.SPECIAL_BB]
	for sp in specials:
		var key: String = Fighter.MOVES[Fighter.SPECIAL_BASE + sp * 2]
		if not f.data.moves.has(key):
			continue
		var m: Dictionary = f.data.moves[key]
		var button := InputBits.LK if m.get("buttons", "any") == "kick" else InputBits.LP
		var entry := [sp, button]
		if m.has("proj"):
			var rising: bool = m.proj.vy > 0 and m.proj.gravity == 0
			# Второй снаряд (волна Ильи, землетрясение Геракла) — запасной вариант обстрела.
			roles["anti_air" if rising else ("proj2" if roles.has("proj") else "proj")] = entry
		elif m.has("invul"):
			roles["anti_air"] = entry
		elif m.has("grab"):
			roles["grab"] = entry
			roles["grab_reach"] = int(m.grab.range) + f.data.push_half * 2 + 30
		elif m.has("counter"):
			roles["counter"] = entry
		elif m.has("teleport"):
			roles["teleport"] = entry
		elif m.has("lunge") or m.has("box"):
			roles["rush"] = entry
	_roles[f.id] = roles
	return roles


## Снаряд для обстрела: основной или (если есть) второй.
func _zone_entry(roles: Dictionary) -> Array:
	if roles.has("proj2") and _rng.randf() < 0.4:
		return roles.proj2
	return roles.proj


## Ввод спецприёма: направления относительно взгляда, кнопка, потом ожидание конца приёма.
## Палица Ильи: издалека — сильный бросок (дальше).
func _special_plan(entry: Array, fwd: int, back: int, dist := 0) -> Array:
	var sp: int = entry[0]
	var button: int = entry[1]
	if sp == Fighter.SPECIAL_PROJ and dist > 450 and button == InputBits.LP:
		button = InputBits.HP
	match sp:
		Fighter.SPECIAL_PROJ:
			return [[back, 2], [fwd | button, 1], [0, 30]]
		Fighter.SPECIAL_DD:
			return [[InputBits.DOWN, 2], [0, 2], [InputBits.DOWN | button, 1], [0, 30]]
		Fighter.SPECIAL_FF:
			return [[fwd, 2], [0, 2], [fwd | button, 1], [0, 34]]
	return [[back, 2], [0, 2], [back | button, 1], [0, 34]]


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
