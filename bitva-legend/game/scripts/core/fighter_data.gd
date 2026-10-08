class_name FighterData
extends RefCounted
## Параметры бойцов. Размеры — в пикселях, скорости — в субпикселях за тик
## (1 пиксель = Fighter.SUB субпикселей), время — в тиках (60 тиков = 1 секунда).
##
## Удары: st_ — стоя, cr_ — в приседе, j_ — в прыжке; lp/lk/hp/hk — кнопки.
##   startup  — на каком тике после нажатия удар начинает бить
##   active   — сколько тиков бьёт
##   recovery — восстановление после (у ударов в прыжке нет: до приземления)
##   damage   — урон (здоровье бойца — 1000)
##   hitstun  — сколько тиков соперник оглушён после попадания
##   hitstop  — заморозка обоих бойцов при попадании (ощущение «веса»)
##   push     — сила отбрасывания соперника
##   box      — хитбокс [вперёд от центра, высота низа над ногами, ширина, высота], px
##   level    — high (по умолчанию), low (надо блокировать сидя), overhead (стоя) — для блока в 1.5
##
## Спецприёмы: sp_proj — «назад, вперёд», sp_dd — «вниз, вниз», sp_ff — «вперёд, вперёд».
##   У приёма одна версия (_l). Только у палицы versions: 2 — лёгкая (ЛР) и сильная (СР, _h).
##   proj — снаряд, выпускается на кадре startup:
##     x, y   — откуда вылетает (вперёд от центра, высота), px
##     vx, vy — скорость (вперёд, вверх), субпиксели за тик; gravity — гравитация
##     w, h   — размер хитбокса снаряда, px;  kind — вид для отрисовки (0 палица, 1 мыши)
##     damage, hitstun, hitstop, push — как у ударов; chip — урон сквозь блок
##   buttons — какими кнопками вызывается: punch (руки: ЛР/СР), kick (ноги: ЛН/СН), any
##   proj.level — high или low (волна по земле); proj.life — сколько тиков живёт (0 — пока не улетит)
##   lunge   — рывок вперёд в активной фазе, субпиксели за тик;  armor — сколько ударов выдерживает
##   teleport — туман: invul_from — с какого кадра неуязвим, offset — на сколько px за спину соперника
##   counter — контратака в активной фазе: stun — сколько тиков атакующий загипнотизирован
##
## Классика (у всех бойцов):
##   st_sweep — назад + ЛН (подсечка), st_round — назад + СН (с разворота),
##   cr_hp — вниз + СР (апперкот), throw — ЛР вплотную (бросок, проходит сквозь блок).
##   uppercut — апперкот: в активной фазе боец распрямляется, рука идёт снизу вверх
##   knockdown — сбивает с ног; launch — подброс [вперёд, вверх], субпиксели за тик; kick — рисовать ногой
##   grab — захват: range — дальность захвата (px между телами), hold — сколько тиков держит,
##     damage, launch — урон и полёт после броска, tech — можно вырваться (ЛР в первые 8 тиков),
##     heal — лечит бросающего, recovery — восстановление бросающего после броска
##
## Шкала силы (2.5):
##   ex — усиленная версия спецприёма (ввод с зажатым блоком, тратит секцию шкалы): поля, которые меняются.
##   super — суперприём (блок + СР + СН, вся шкала). Если удар попал — ролик:
##     cinema — hold (длительность ролика), damage, launch, heal, recovery, scaled (урон затухает в комбо)
##
## Строки (strings, как в Mortal Kombat): заданные цепочки ударов. Следующая кнопка нажимается,
## пока предыдущий удар бьёт или сразу после; направление не важно — удар берётся из строки.

const CHARACTERS := {
	"ilya": {
		"name": "ИЛЬЯ МУРОМЕЦ",
		"color": Color(0.85, 0.66, 0.32),
		"height": 300,          # рост стоя
		"crouch_height": 190,   # рост в приседе
		"push_half": 55,        # половина ширины «тела» для столкновений
		"walk_f": 260,          # ходьба вперёд
		"walk_b": 210,          # ходьба назад
		"prejump": 5,           # подготовка к прыжку (на земле, уязвим)
		"jump_vy": 1800,        # начальная скорость прыжка вверх
		"gravity": 90,          # гравитация
		"jump_vx_f": 380,       # скорость прыжка вперёд по горизонтали
		"jump_vx_b": 320,       # скорость прыжка назад
		"landing": 4,           # приземление (нельзя действовать)
		"run_speed": 560,       # бег: максимальная скорость
		"run_accel": 30,        # бег: разгон за тик (Илья разгоняется тяжело)
		"run_stop": 8,          # торможение после бега, тиков
		"run_jump_bonus": 140,  # прыжок с разбега: прибавка к скорости вперёд
		"backdash_v0": 1000,    # отскок: начальная скорость
		"backdash_decel": 55,   # отскок: замедление за тик (~96 px за 19 тиков)
		"backdash_recovery": 8, # после отскока нельзя действовать, тиков
		"strings": [
			{"name": "Кулачный бой", "moves": ["st_lp", "st_lp", "st_hp"]},
			{"name": "Богатырский пинок", "moves": ["st_lk", "st_hk"]},
			{"name": "Сверху и снизу", "moves": ["st_lp", "st_lk", "cr_hk"]},
		],
		"moves": {
			# Кулаки и ноги Ильи медленнее, зато палица (сильные удары рукой) бьёт далеко.
			"st_lp": {"startup": 5, "active": 3, "recovery": 8, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 700, "box": [40, 180, 90, 40]},
			"st_lk": {"startup": 7, "active": 3, "recovery": 11, "damage": 50, "hitstun": 16, "hitstop": 8, "push": 800, "box": [40, 85, 105, 40]},
			"st_hp": {"startup": 12, "active": 4, "recovery": 20, "damage": 110, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [40, 120, 155, 140]},
			"st_hk": {"startup": 10, "active": 4, "recovery": 18, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 140, 130, 45]},
			"cr_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [45, 110, 85, 35]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [40, 0, 110, 30], "level": "low"},
			# Апперкот (вниз + СР): удар снизу вверх, распрямляется из приседа, подбрасывает.
			"cr_hp": {"startup": 8, "active": 5, "recovery": 24, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 900, "box": [20, 40, 110, 260], "knockdown": 1, "launch": [250, 1700], "uppercut": 1},
			"cr_hk": {"startup": 11, "active": 4, "recovery": 24, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 0, 165, 30], "level": "low"},
			"j_lp": {"startup": 5, "active": 6, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 600, "box": [30, 70, 85, 50], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 8, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 600, "box": [30, 10, 95, 50], "level": "overhead"},
			"j_hp": {"startup": 9, "active": 5, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 800, "box": [25, -15, 125, 95], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 6, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 800, "box": [30, 15, 125, 50], "level": "overhead"},
			# Бросок палицы (только руками): летит по дуге и падает. Медленный, но мощный.
			"sp_proj_l": {"buttons": "punch", "versions": 2, "startup": 16, "active": 1, "recovery": 20, "proj": {"x": 60, "y": 200, "vx": 650, "vy": 1100, "gravity": 70, "w": 54, "h": 54, "kind": 0, "damage": 90, "hitstun": 22, "hitstop": 12, "push": 900, "chip": 9}, "ex": {"startup": 12, "proj": {"vx": 900, "vy": 1000, "damage": 140, "hitstun": 26, "chip": 16, "kind": 3}}},
			"sp_proj_h": {"buttons": "punch", "startup": 20, "active": 1, "recovery": 22, "proj": {"x": 60, "y": 200, "vx": 950, "vy": 900, "gravity": 70, "w": 54, "h": 54, "kind": 0, "damage": 110, "hitstun": 24, "hitstop": 13, "push": 1000, "chip": 11}, "ex": {"startup": 14, "proj": {"vx": 1250, "vy": 850, "damage": 150, "hitstun": 26, "chip": 18, "kind": 3}}},
			# Удар оземь (вниз, вниз + нога): волна по земле, низкий удар — блокировать сидя или перепрыгнуть.
			"sp_dd_l": {"buttons": "kick", "startup": 18, "active": 1, "recovery": 24, "proj": {"x": 70, "y": 22, "vx": 900, "vy": 0, "gravity": 0, "w": 70, "h": 44, "kind": 2, "level": "low", "life": 34, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 900, "chip": 8}, "ex": {"startup": 14, "proj": {"life": 70, "vx": 1000, "w": 90, "h": 70, "damage": 120, "hitstun": 26, "chip": 14, "kind": 5}}},
			# Богатырский таран с палицей (вперёд, вперёд + рука): рывок вперёд, выдерживает один удар.
			"sp_ff_l": {"buttons": "punch", "startup": 10, "active": 16, "recovery": 20, "lunge": 900, "armor": 1, "damage": 100, "hitstun": 24, "hitstop": 13, "push": 1400, "chip": 10, "box": [30, 60, 110, 200], "ex": {"armor": 2, "lunge": 1150, "damage": 140, "chip": 16, "knockdown": 1, "launch": [400, 1500]}},
			# Мельница (назад, назад + рука): дальний захват, раскручивает и швыряет. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 6, "active": 2, "recovery": 30, "grab": {"range": 90, "hold": 40, "damage": 170, "launch": [900, 1300], "tech": 0, "recovery": 12}, "ex": {"grab": {"range": 130, "damage": 240}}},
			# Классика.
			"st_sweep": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 20, "hitstop": 11, "push": 600, "box": [40, 0, 150, 30], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 14, "active": 4, "recovery": 24, "damage": 120, "hitstun": 22, "hitstop": 14, "push": 1200, "box": [40, 150, 150, 60], "knockdown": 1, "launch": [650, 950], "kick": 1},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 26, "damage": 120, "launch": [500, 1000], "tech": 1, "recovery": 10}},
			# «Удар с небес» (блок + СР + СН): рывок с палицей; попал — небо разверзается, молнии и удар сверху.
			"super": {"name": "УДАР С НЕБЕС", "startup": 8, "active": 8, "recovery": 45, "lunge": 700, "damage": 60, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 45, "box": [25, 40, 140, 240], "cinema": {"hold": 100, "damage": 330, "launch": [700, 1700], "tech": 0, "recovery": 20, "scaled": 1}},
		},
	},
	"dracula": {
		"name": "ДРАКУЛА",
		"color": Color(0.72, 0.16, 0.24),
		"height": 270,
		"crouch_height": 165,
		"push_half": 40,
		"walk_f": 360,
		"walk_b": 300,
		"prejump": 3,
		"jump_vy": 2220,
		"gravity": 123,
		"jump_vx_f": 480,
		"jump_vx_b": 420,
		"landing": 2,
		"run_speed": 820,
		"run_accel": 280,
		"run_stop": 3,
		"run_jump_bonus": 220,
		"backdash_v0": 1700,
		"backdash_decel": 120,
		"backdash_recovery": 3,
		"strings": [
			{"name": "Когти ночи", "moves": ["st_lp", "st_lp", "st_hk"]},
			{"name": "Взмах плаща", "moves": ["st_lk", "st_lk", "st_hp"]},
			{"name": "Вальс", "moves": ["st_hp", "st_hk"]},
		],
		"moves": {
			# Дракула быстрее и бьёт чаще, но слабее; ноги длиннее рук.
			"st_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [32, 165, 72, 35]},
			"st_lk": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 700, "box": [30, 80, 95, 35]},
			"st_hp": {"startup": 8, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 950, "box": [32, 150, 115, 50]},
			"st_hk": {"startup": 9, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [32, 115, 135, 45]},
			"cr_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 25, "hitstun": 13, "hitstop": 6, "push": 600, "box": [35, 100, 72, 30]},
			"cr_lk": {"startup": 5, "active": 2, "recovery": 9, "damage": 30, "hitstun": 13, "hitstop": 6, "push": 600, "box": [30, 0, 105, 28], "level": "low"},
			# Апперкот (вниз + СР): удар снизу вверх, распрямляется из приседа, подбрасывает.
			"cr_hp": {"startup": 7, "active": 4, "recovery": 20, "damage": 85, "hitstun": 20, "hitstop": 12, "push": 850, "box": [18, 30, 100, 250], "knockdown": 1, "launch": [200, 1600], "uppercut": 1},
			"cr_hk": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [35, 0, 145, 28], "level": "low"},
			"j_lp": {"startup": 4, "active": 5, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 550, "box": [25, 60, 72, 45], "level": "overhead"},
			"j_lk": {"startup": 5, "active": 7, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 550, "box": [25, 10, 85, 45], "level": "overhead"},
			"j_hp": {"startup": 7, "active": 4, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 750, "box": [25, 0, 105, 80], "level": "overhead"},
			"j_hk": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 750, "box": [25, 20, 115, 45], "level": "overhead"},
			# Стая летучих мышей (назад, вперёд + рука): летит прямо на уровне груди, бьёт и сидящего.
			"sp_proj_l": {"buttons": "punch", "startup": 12, "active": 1, "recovery": 22, "proj": {"x": 50, "y": 150, "vx": 1000, "vy": 0, "gravity": 0, "w": 68, "h": 44, "kind": 1, "damage": 60, "hitstun": 18, "hitstop": 9, "push": 700, "chip": 6}, "ex": {"startup": 9, "proj": {"vx": 1400, "damage": 90, "hitstun": 26, "chip": 10, "h": 70, "kind": 4}}},
			# Туманный рывок (вниз, вниз + нога): растворяется в тумане и появляется за спиной соперника.
			"sp_dd_l": {"buttons": "kick", "startup": 16, "active": 1, "recovery": 14, "teleport": {"invul_from": 4, "offset": 110}, "ex": {"startup": 10, "recovery": 6, "teleport": {"invul_from": 2}}},
			# Гипнотический взгляд (вперёд, вперёд + рука): если соперник ударит в окно — застынет.
			"sp_ff_l": {"buttons": "punch", "startup": 4, "active": 16, "recovery": 18, "counter": {"stun": 55}, "ex": {"active": 28, "counter": {"stun": 90}}},
			# Укус (назад, назад + рука): захват, кусает и лечится. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 5, "active": 2, "recovery": 28, "grab": {"range": 70, "hold": 40, "damage": 110, "heal": 60, "launch": [300, 600], "tech": 0, "recovery": 10}, "ex": {"grab": {"range": 100, "damage": 150, "heal": 120}}},
			# Классика.
			"st_sweep": {"startup": 8, "active": 3, "recovery": 18, "damage": 60, "hitstun": 20, "hitstop": 10, "push": 600, "box": [30, 0, 140, 28], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 12, "active": 4, "recovery": 20, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [30, 140, 145, 55], "knockdown": 1, "launch": [600, 900], "kick": 1},
			"throw": {"startup": 3, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 22, "damage": 100, "launch": [450, 900], "tech": 1, "recovery": 10}},
			# «Кровавая луна» (блок + СР + СН): бросок вперёд; попал — восходит кровавая луна, стая и укус.
			"super": {"name": "КРОВАВАЯ ЛУНА", "startup": 6, "active": 8, "recovery": 40, "lunge": 950, "damage": 50, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 40, "box": [20, 40, 120, 220], "cinema": {"hold": 100, "damage": 300, "heal": 80, "launch": [600, 1500], "tech": 0, "recovery": 18, "scaled": 1}},
		},
	},
}


static func get_data(id: String) -> Dictionary:
	return CHARACTERS[id]
