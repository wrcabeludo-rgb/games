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
##   invul   — [с какого, до какого кадра] неуязвим к ударам, снарядам и броскам (взлёты против прыжков)
##   proj.petrify — попавший снаряд обращает соперника в камень на столько тиков (каменный взгляд)
##   grab.drain   — захват забирает столько шкалы силы у соперника себе
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
		"max_hp": 1100,         # тяжеловес держит удар
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
			# Хитбоксы ударов стоя — по спрайтам (докуда достают кулак, сапог, палица от центра бойца).
			"st_lp": {"startup": 5, "active": 3, "recovery": 8, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 700, "box": [80, 190, 150, 50]},
			"st_lk": {"startup": 7, "active": 3, "recovery": 11, "damage": 50, "hitstun": 16, "hitstop": 8, "push": 800, "box": [60, 130, 115, 60]},
			"st_hp": {"startup": 12, "active": 4, "recovery": 20, "damage": 110, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [80, 110, 190, 140]},
			"st_hk": {"startup": 10, "active": 4, "recovery": 18, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 150, 130, 90]},
			"cr_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [70, 125, 125, 45]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [60, 0, 130, 45], "level": "low"},
			# Апперкот (вниз + СР): удар снизу вверх, распрямляется из приседа, подбрасывает.
			"cr_hp": {"startup": 8, "active": 5, "recovery": 24, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 900, "box": [20, 50, 150, 260], "knockdown": 1, "launch": [250, 1700], "uppercut": 1},
			"cr_hk": {"startup": 11, "active": 4, "recovery": 24, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 0, 140, 35], "level": "low"},
			"j_lp": {"startup": 5, "active": 6, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 600, "box": [60, 140, 120, 55], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 8, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 600, "box": [60, 70, 115, 65], "level": "overhead"},
			"j_hp": {"startup": 9, "active": 5, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 800, "box": [40, 0, 110, 130], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 6, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 800, "box": [60, 100, 100, 100], "level": "overhead"},
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
			"st_sweep": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 20, "hitstop": 11, "push": 600, "box": [30, 0, 125, 40], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 14, "active": 4, "recovery": 24, "damage": 120, "hitstun": 22, "hitstop": 14, "push": 1200, "box": [30, 160, 130, 130], "knockdown": 1, "launch": [650, 950], "kick": 1},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 26, "damage": 120, "launch": [500, 1000], "tech": 1, "recovery": 10}},
			# «Удар с небес» (блок + СР + СН): рывок с палицей; попал — небо разверзается, молнии и удар сверху.
			"super": {"name": "УДАР С НЕБЕС", "startup": 8, "active": 8, "recovery": 45, "lunge": 700, "damage": 60, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 45, "box": [25, 40, 140, 240], "cinema": {"hold": 100, "damage": 330, "launch": [700, 1700], "tech": 0, "recovery": 20, "scaled": 1}},
		},
	},
	"dracula": {
		"name": "ДРАКУЛА",
		"color": Color(0.72, 0.16, 0.24),
		"max_hp": 950,          # лечится укусом и суперприёмом
		"height": 310,
		"crouch_height": 190,
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
			"st_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [90, 215, 135, 45]},
			"st_lk": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 700, "box": [40, 85, 100, 40]},
			"st_hp": {"startup": 8, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 950, "box": [50, 100, 200, 80]},
			"st_hk": {"startup": 9, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 140, 105, 110]},
			"cr_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 25, "hitstun": 13, "hitstop": 6, "push": 600, "box": [60, 105, 115, 45]},
			"cr_lk": {"startup": 5, "active": 2, "recovery": 9, "damage": 30, "hitstun": 13, "hitstop": 6, "push": 600, "box": [50, 0, 155, 40], "level": "low"},
			# Апперкот (вниз + СР): удар снизу вверх, распрямляется из приседа, подбрасывает.
			"cr_hp": {"startup": 7, "active": 4, "recovery": 20, "damage": 85, "hitstun": 20, "hitstop": 12, "push": 850, "box": [20, 60, 105, 240], "knockdown": 1, "launch": [200, 1600], "uppercut": 1},
			"cr_hk": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [50, 0, 210, 40], "level": "low"},
			"j_lp": {"startup": 4, "active": 5, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 550, "box": [25, 60, 95, 45], "level": "overhead"},
			"j_lk": {"startup": 5, "active": 7, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 550, "box": [25, 0, 150, 50], "level": "overhead"},
			"j_hp": {"startup": 7, "active": 4, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 750, "box": [25, 0, 105, 80], "level": "overhead"},
			"j_hk": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 750, "box": [25, 0, 150, 50], "level": "overhead"},
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
			"st_round": {"startup": 12, "active": 4, "recovery": 20, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [20, 160, 110, 90], "knockdown": 1, "launch": [600, 900], "kick": 1},
			"throw": {"startup": 3, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 22, "damage": 100, "launch": [450, 900], "tech": 1, "recovery": 10}},
			# «Кровавая луна» (блок + СР + СН): бросок вперёд; попал — восходит кровавая луна, стая и укус.
			"super": {"name": "КРОВАВАЯ ЛУНА", "startup": 6, "active": 8, "recovery": 40, "lunge": 950, "damage": 50, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 40, "box": [20, 40, 120, 220], "cinema": {"hold": 100, "damage": 300, "heal": 80, "launch": [600, 1500], "tech": 0, "recovery": 18, "scaled": 1}},
		},
	},
	"koschei": {
		# Кощей Бессмертный: высокий костлявый чародей с мечом-кладенцом. Хитрец: длинные тычки мечом,
		# быстрые костлявые удары; здоровья меньше всех (его «бессмертие» — будущий спецприём).
		"name": "КОЩЕЙ",
		"color": Color(0.45, 0.62, 0.42),
		"max_hp": 900,
		"height": 320,
		"crouch_height": 195,
		"push_half": 38,
		"walk_f": 300,
		"walk_b": 260,
		"prejump": 4,
		"jump_vy": 2000,
		"gravity": 110,
		"jump_vx_f": 420,
		"jump_vx_b": 380,
		"landing": 3,
		"run_speed": 700,
		"run_accel": 120,
		"run_stop": 5,
		"run_jump_bonus": 180,
		"backdash_v0": 1500,
		"backdash_decel": 105,
		"backdash_recovery": 5,
		"strings": [
			{"name": "Костяная пляска", "moves": ["st_lp", "st_lp", "st_lk"]},
			{"name": "Меч-кладенец", "moves": ["st_hp", "st_hk"]},
			{"name": "Злая сила", "moves": ["st_lk", "st_hp", "cr_hk"]},
		],
		"moves": {
			# Руки короткие и быстрые, меч (сильный удар рукой) достаёт дальше всех.
			"st_lp": {"startup": 5, "active": 2, "recovery": 8, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [60, 200, 140, 40]},
			"st_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 700, "box": [40, 70, 120, 40]},
			"st_hp": {"startup": 11, "active": 4, "recovery": 20, "damage": 95, "hitstun": 21, "hitstop": 12, "push": 1050, "box": [70, 120, 230, 90]},
			"st_hk": {"startup": 10, "active": 3, "recovery": 18, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 150, 140, 90]},
			"cr_lp": {"startup": 5, "active": 2, "recovery": 8, "damage": 25, "hitstun": 13, "hitstop": 6, "push": 600, "box": [60, 100, 120, 40]},
			"cr_lk": {"startup": 5, "active": 3, "recovery": 9, "damage": 30, "hitstun": 13, "hitstop": 6, "push": 600, "box": [50, 0, 145, 35], "level": "low"},
			# Апперкот мечом снизу вверх.
			"cr_hp": {"startup": 9, "active": 4, "recovery": 22, "damage": 90, "hitstun": 21, "hitstop": 12, "push": 900, "box": [20, 60, 140, 250], "knockdown": 1, "launch": [220, 1650], "uppercut": 1},
			# Меч по земле — самая длинная низкая атака.
			"cr_hk": {"startup": 10, "active": 3, "recovery": 22, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [50, 0, 220, 35], "level": "low"},
			"j_lp": {"startup": 5, "active": 5, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 550, "box": [40, 80, 110, 50], "level": "overhead"},
			"j_lk": {"startup": 5, "active": 7, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 550, "box": [30, 10, 130, 55], "level": "overhead"},
			"j_hp": {"startup": 8, "active": 4, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 750, "box": [30, 0, 150, 100], "level": "overhead"},
			"j_hk": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 750, "box": [30, 10, 135, 60], "level": "overhead"},
			# Классика.
			"st_sweep": {"startup": 8, "active": 3, "recovery": 19, "damage": 60, "hitstun": 20, "hitstop": 10, "push": 600, "box": [30, 0, 150, 30], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 13, "active": 4, "recovery": 22, "damage": 105, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [25, 160, 125, 100], "knockdown": 1, "launch": [600, 900], "kick": 1},
			# Кощеева игла (назад, вперёд + рука): быстрый тонкий снаряд.
			"sp_proj_l": {"buttons": "punch", "startup": 11, "active": 1, "recovery": 18, "proj": {"x": 60, "y": 200, "vx": 1300, "vy": 0, "gravity": 0, "w": 70, "h": 20, "kind": 6, "damage": 50, "hitstun": 16, "hitstop": 8, "push": 600, "chip": 5}, "ex": {"startup": 8, "proj": {"vx": 1700, "damage": 80, "hitstun": 24, "chip": 9, "kind": 106}}},
			# Бессмертие (вниз, вниз + нога): удар проходит сквозь кости — ударивший застывает.
			"sp_dd_l": {"buttons": "kick", "startup": 3, "active": 18, "recovery": 20, "counter": {"stun": 50}, "ex": {"active": 30, "counter": {"stun": 85}}},
			# Удар кладенцом (вперёд, вперёд + рука): выпад мечом с шагом вперёд.
			"sp_ff_l": {"buttons": "punch", "startup": 12, "active": 6, "recovery": 22, "lunge": 700, "damage": 100, "hitstun": 22, "hitstop": 12, "push": 1200, "chip": 10, "box": [40, 120, 200, 90], "ex": {"lunge": 950, "damage": 140, "chip": 16, "knockdown": 1, "launch": [500, 1200]}},
			# Похищение (назад, назад + рука): захват, крадёт шкалу силы. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 6, "active": 2, "recovery": 30, "grab": {"range": 85, "hold": 36, "damage": 110, "drain": 500, "launch": [400, 800], "tech": 0, "recovery": 12}, "ex": {"grab": {"range": 120, "damage": 150, "drain": 1000}}},
			# «Смерть в игле» (блок + СР + СН): выпад; попал — игла ломается, и смерть достаётся сопернику.
			"super": {"name": "СМЕРТЬ В ИГЛЕ", "startup": 7, "active": 8, "recovery": 42, "lunge": 850, "damage": 50, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 40, "box": [25, 40, 150, 230], "cinema": {"hold": 100, "damage": 310, "launch": [650, 1600], "tech": 0, "recovery": 20, "scaled": 1}},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 24, "damage": 100, "launch": [450, 900], "tech": 1, "recovery": 10}},
		},
	},
	"hercules": {
		# Геракл: силач-борец в шкуре Немейского льва, с дубиной. Сильные удары и лучший бросок,
		# средняя скорость — между Ильёй и Дракулой.
		"name": "ГЕРАКЛ",
		"color": Color(0.78, 0.46, 0.22),
		"max_hp": 1050,
		"height": 305,
		"crouch_height": 195,
		"push_half": 52,
		"walk_f": 290,
		"walk_b": 230,
		"prejump": 4,
		"jump_vy": 1950,
		"gravity": 100,
		"jump_vx_f": 420,
		"jump_vx_b": 350,
		"landing": 3,
		"run_speed": 650,
		"run_accel": 80,
		"run_stop": 6,
		"run_jump_bonus": 160,
		"backdash_v0": 1200,
		"backdash_decel": 70,
		"backdash_recovery": 6,
		"strings": [
			{"name": "Немейский лев", "moves": ["st_lp", "st_lp", "st_hk"]},
			{"name": "Дубина", "moves": ["st_lk", "st_hp"]},
			{"name": "Подвиг", "moves": ["st_lp", "st_lk", "st_hp"]},
		],
		"moves": {
			"st_lp": {"startup": 5, "active": 3, "recovery": 8, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 700, "box": [70, 190, 140, 45]},
			"st_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 750, "box": [50, 120, 120, 50]},
			# Сильный удар рукой — дубиной сверху.
			"st_hp": {"startup": 10, "active": 4, "recovery": 18, "damage": 105, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [70, 130, 170, 100]},
			"st_hk": {"startup": 9, "active": 4, "recovery": 17, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 150, 135, 85]},
			"cr_lp": {"startup": 5, "active": 3, "recovery": 8, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [65, 120, 120, 45]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [55, 0, 130, 40], "level": "low"},
			"cr_hp": {"startup": 8, "active": 5, "recovery": 22, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 900, "box": [20, 50, 140, 260], "knockdown": 1, "launch": [250, 1750], "uppercut": 1},
			"cr_hk": {"startup": 10, "active": 4, "recovery": 22, "damage": 75, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 0, 150, 35], "level": "low"},
			"j_lp": {"startup": 5, "active": 6, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 600, "box": [60, 130, 115, 55], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 7, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 600, "box": [55, 60, 115, 65], "level": "overhead"},
			"j_hp": {"startup": 9, "active": 5, "damage": 95, "hitstun": 21, "hitstop": 12, "push": 800, "box": [40, 0, 115, 120], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 6, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 800, "box": [55, 90, 105, 100], "level": "overhead"},
			# Классика; бросок борца — дальше и больнее, чем у остальных.
			"st_sweep": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 20, "hitstop": 11, "push": 600, "box": [30, 0, 130, 40], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 13, "active": 4, "recovery": 23, "damage": 115, "hitstun": 22, "hitstop": 14, "push": 1200, "box": [30, 160, 130, 120], "knockdown": 1, "launch": [650, 950], "kick": 1},
			# Валун (назад, вперёд + рука): тяжёлый камень по дуге.
			"sp_proj_l": {"buttons": "punch", "startup": 20, "active": 1, "recovery": 24, "proj": {"x": 50, "y": 230, "vx": 600, "vy": 1200, "gravity": 75, "w": 70, "h": 70, "kind": 7, "damage": 120, "hitstun": 24, "hitstop": 14, "push": 1100, "chip": 12}, "ex": {"startup": 15, "proj": {"vx": 850, "damage": 160, "hitstun": 28, "chip": 18, "kind": 107}}},
			# Землетрясение (вниз, вниз + нога): волна по земле — блок сидя или прыжок.
			"sp_dd_l": {"buttons": "kick", "startup": 20, "active": 1, "recovery": 26, "proj": {"x": 60, "y": 22, "vx": 800, "vy": 0, "gravity": 0, "w": 90, "h": 44, "kind": 2, "level": "low", "life": 40, "damage": 90, "hitstun": 22, "hitstop": 12, "push": 900, "chip": 9}, "ex": {"startup": 15, "proj": {"life": 80, "w": 120, "h": 70, "damage": 130, "kind": 5}}},
			# Немейский натиск (вперёд, вперёд + рука): рывок львом, держит два удара.
			"sp_ff_l": {"buttons": "punch", "startup": 12, "active": 16, "recovery": 24, "lunge": 850, "armor": 2, "damage": 110, "hitstun": 24, "hitstop": 13, "push": 1400, "chip": 10, "box": [30, 60, 120, 210], "ex": {"armor": 3, "lunge": 1100, "damage": 150, "chip": 16, "knockdown": 1, "launch": [450, 1500]}},
			# Объятия Антея (назад, назад + рука): отрывает от земли и сжимает. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 6, "active": 2, "recovery": 32, "grab": {"range": 80, "hold": 50, "damage": 200, "launch": [800, 1400], "tech": 0, "recovery": 14}, "ex": {"grab": {"range": 120, "damage": 270}}},
			# «Двенадцать подвигов» (блок + СР + СН): рывок; попал — двенадцать ударов, по одному за подвиг.
			"super": {"name": "ДВЕНАДЦАТЬ ПОДВИГОВ", "startup": 8, "active": 8, "recovery": 45, "lunge": 750, "damage": 60, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 45, "box": [25, 40, 140, 240], "cinema": {"hold": 110, "damage": 340, "launch": [700, 1700], "tech": 0, "recovery": 20, "scaled": 1}},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 40, "hold": 30, "damage": 150, "launch": [600, 1100], "tech": 1, "recovery": 10}},
		},
	},
	"athena": {
		# Афина Паллада: копьё и щит-эгида. «Стена»: самые длинные тычки копьём, крепкая середина.
		"name": "АФИНА",
		"color": Color(0.72, 0.8, 0.92),
		"max_hp": 1000,
		"height": 305,
		"crouch_height": 195,
		"push_half": 45,
		"walk_f": 280,
		"walk_b": 240,
		"prejump": 4,
		"jump_vy": 1950,
		"gravity": 105,
		"jump_vx_f": 400,
		"jump_vx_b": 360,
		"landing": 3,
		"run_speed": 680,
		"run_accel": 100,
		"run_stop": 5,
		"run_jump_bonus": 160,
		"backdash_v0": 1400,
		"backdash_decel": 95,
		"backdash_recovery": 5,
		"strings": [
			{"name": "Копьё Паллады", "moves": ["st_lp", "st_lp", "st_hp"]},
			{"name": "Эгида", "moves": ["st_lk", "st_hp"]},
			{"name": "Стратегия", "moves": ["st_lp", "st_lk", "cr_hk"]},
		],
		"moves": {
			"st_lp": {"startup": 5, "active": 3, "recovery": 8, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 700, "box": [70, 195, 150, 40]},
			"st_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 750, "box": [45, 110, 120, 45]},
			# Тычок копьём — самый дальний обычный удар.
			"st_hp": {"startup": 11, "active": 4, "recovery": 19, "damage": 95, "hitstun": 21, "hitstop": 12, "push": 1100, "box": [80, 165, 245, 45]},
			"st_hk": {"startup": 10, "active": 4, "recovery": 18, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 145, 135, 90]},
			"cr_lp": {"startup": 5, "active": 2, "recovery": 8, "damage": 28, "hitstun": 13, "hitstop": 6, "push": 600, "box": [60, 110, 120, 40]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 9, "damage": 32, "hitstun": 13, "hitstop": 6, "push": 600, "box": [50, 0, 140, 38], "level": "low"},
			# Щитом снизу вверх.
			"cr_hp": {"startup": 8, "active": 5, "recovery": 22, "damage": 90, "hitstun": 21, "hitstop": 12, "push": 900, "box": [20, 60, 130, 245], "knockdown": 1, "launch": [230, 1650], "uppercut": 1},
			# Копьё по ногам.
			"cr_hk": {"startup": 10, "active": 3, "recovery": 22, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [50, 0, 215, 35], "level": "low"},
			"j_lp": {"startup": 5, "active": 5, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 550, "box": [50, 110, 115, 50], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 7, "damage": 40, "hitstun": 15, "hitstop": 7, "push": 550, "box": [40, 30, 125, 60], "level": "overhead"},
			"j_hp": {"startup": 8, "active": 5, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 750, "box": [40, 0, 150, 80], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 5, "damage": 80, "hitstun": 19, "hitstop": 10, "push": 750, "box": [45, 70, 110, 90], "level": "overhead"},
			"st_sweep": {"startup": 9, "active": 3, "recovery": 20, "damage": 65, "hitstun": 20, "hitstop": 10, "push": 600, "box": [30, 0, 140, 35], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 13, "active": 4, "recovery": 22, "damage": 105, "hitstun": 22, "hitstop": 13, "push": 1150, "box": [30, 160, 125, 110], "knockdown": 1, "launch": [620, 920], "kick": 1},
			# Копьё Паллады (назад, вперёд + рука): метает копьё — быстро и далеко.
			"sp_proj_l": {"buttons": "punch", "startup": 14, "active": 1, "recovery": 22, "proj": {"x": 70, "y": 190, "vx": 1500, "vy": 0, "gravity": 0, "w": 110, "h": 24, "kind": 8, "damage": 75, "hitstun": 20, "hitstop": 10, "push": 900, "chip": 8}, "ex": {"startup": 10, "proj": {"vx": 1900, "damage": 110, "hitstun": 28, "chip": 12, "kind": 108}}},
			# Эгида (вниз, вниз + нога): удар щитом с шагом, держит два удара, сильно отбрасывает.
			"sp_dd_l": {"buttons": "kick", "startup": 8, "active": 10, "recovery": 20, "lunge": 400, "armor": 2, "damage": 70, "hitstun": 20, "hitstop": 11, "push": 1600, "chip": 8, "box": [30, 40, 90, 230], "ex": {"armor": 3, "damage": 100, "knockdown": 1, "launch": [700, 900]}},
			# Сова Паллады (вперёд, вперёд + рука): взлёт с копьём, неуязвима на старте — против прыжков.
			"sp_ff_l": {"buttons": "punch", "startup": 6, "active": 6, "recovery": 28, "invul": [1, 10], "damage": 110, "hitstun": 24, "hitstop": 13, "push": 800, "box": [10, 80, 120, 320], "knockdown": 1, "launch": [300, 1800], "uppercut": 1, "ex": {"invul": [1, 14], "damage": 150, "launch": [350, 2000]}},
			# Суд мудрости (назад, назад + рука): захват и бросок через плечо. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 6, "active": 2, "recovery": 30, "grab": {"range": 70, "hold": 34, "damage": 150, "launch": [700, 1200], "tech": 0, "recovery": 12}, "ex": {"grab": {"range": 110, "damage": 210}}},
			# «Гнев Олимпа» (блок + СР + СН): выпад копьём; попал — молнии Зевса и удар эгидой.
			"super": {"name": "ГНЕВ ОЛИМПА", "startup": 7, "active": 8, "recovery": 42, "lunge": 850, "damage": 55, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 42, "box": [25, 40, 160, 230], "cinema": {"hold": 100, "damage": 320, "launch": [700, 1650], "tech": 0, "recovery": 20, "scaled": 1}},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 24, "damage": 110, "launch": [480, 950], "tech": 1, "recovery": 10}},
		},
	},
	"medusa": {
		# Медуза Горгона: змеи вместо волос, бронзовые когти. Контроль: быстрые хлёсткие удары змеями
		# средней дальности; окаменяющий взгляд — будущий спецприём.
		"name": "МЕДУЗА",
		"color": Color(0.22, 0.6, 0.58),
		"max_hp": 950,
		"height": 300,
		"crouch_height": 190,
		"push_half": 40,
		"walk_f": 320,
		"walk_b": 280,
		"prejump": 3,
		"jump_vy": 2050,
		"gravity": 112,
		"jump_vx_f": 440,
		"jump_vx_b": 390,
		"landing": 2,
		"run_speed": 760,
		"run_accel": 200,
		"run_stop": 4,
		"run_jump_bonus": 190,
		"backdash_v0": 1550,
		"backdash_decel": 110,
		"backdash_recovery": 4,
		"strings": [
			{"name": "Змеиный шёпот", "moves": ["st_lp", "st_lp", "st_lk"]},
			{"name": "Клубок", "moves": ["st_lk", "st_lk", "st_hk"]},
			{"name": "Каменное сердце", "moves": ["st_hp", "st_hk"]},
		],
		"moves": {
			"st_lp": {"startup": 4, "active": 3, "recovery": 8, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [70, 200, 145, 45]},
			"st_lk": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 700, "box": [45, 90, 115, 45]},
			# Змеи с головы хлещут вперёд.
			"st_hp": {"startup": 9, "active": 4, "recovery": 17, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 950, "box": [60, 200, 195, 70]},
			"st_hk": {"startup": 9, "active": 3, "recovery": 17, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 140, 130, 100]},
			"cr_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 25, "hitstun": 13, "hitstop": 6, "push": 600, "box": [60, 100, 115, 40]},
			"cr_lk": {"startup": 5, "active": 2, "recovery": 9, "damage": 30, "hitstun": 13, "hitstop": 6, "push": 600, "box": [50, 0, 150, 38], "level": "low"},
			"cr_hp": {"startup": 8, "active": 4, "recovery": 21, "damage": 85, "hitstun": 20, "hitstop": 12, "push": 850, "box": [20, 60, 120, 240], "knockdown": 1, "launch": [210, 1600], "uppercut": 1},
			"cr_hk": {"startup": 9, "active": 3, "recovery": 21, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [50, 0, 190, 38], "level": "low"},
			"j_lp": {"startup": 4, "active": 5, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 550, "box": [35, 80, 110, 50], "level": "overhead"},
			"j_lk": {"startup": 5, "active": 7, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 550, "box": [30, 10, 140, 55], "level": "overhead"},
			"j_hp": {"startup": 7, "active": 5, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 750, "box": [30, 0, 140, 100], "level": "overhead"},
			"j_hk": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 750, "box": [30, 10, 145, 55], "level": "overhead"},
			"st_sweep": {"startup": 8, "active": 3, "recovery": 18, "damage": 60, "hitstun": 20, "hitstop": 10, "push": 600, "box": [30, 0, 145, 30], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 12, "active": 4, "recovery": 21, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [25, 160, 115, 95], "knockdown": 1, "launch": [600, 900], "kick": 1},
			# Яд (назад, вперёд + рука): змеи плюют ядом по дуге.
			"sp_proj_l": {"buttons": "punch", "startup": 13, "active": 1, "recovery": 20, "proj": {"x": 50, "y": 210, "vx": 750, "vy": 700, "gravity": 45, "w": 50, "h": 40, "kind": 9, "damage": 70, "hitstun": 20, "hitstop": 10, "push": 700, "chip": 10}, "ex": {"startup": 10, "proj": {"vx": 950, "damage": 100, "chip": 16, "kind": 109}}},
			# Каменный взгляд (вниз, вниз + нога): короткий луч; попал — соперник каменеет.
			"sp_dd_l": {"buttons": "kick", "startup": 16, "active": 1, "recovery": 26, "proj": {"x": 40, "y": 230, "vx": 1100, "vy": 0, "gravity": 0, "w": 120, "h": 90, "kind": 10, "life": 22, "damage": 20, "hitstun": 14, "hitstop": 10, "push": 200, "chip": 0, "petrify": 60}, "ex": {"startup": 12, "proj": {"life": 34, "petrify": 90, "kind": 110}}},
			# Хвост змеи (вперёд, вперёд + рука): скользит вперёд и подсекает — блок сидя.
			"sp_ff_l": {"buttons": "punch", "startup": 9, "active": 10, "recovery": 24, "lunge": 650, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 800, "chip": 8, "box": [30, 0, 170, 50], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1, "ex": {"lunge": 900, "damage": 120, "chip": 12}},
			# Змеиные объятия (назад, назад + рука): змеи жалят схваченного, Медуза лечится. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 5, "active": 2, "recovery": 28, "grab": {"range": 70, "hold": 44, "damage": 120, "heal": 40, "launch": [350, 700], "tech": 0, "recovery": 10}, "ex": {"grab": {"range": 105, "damage": 160, "heal": 80}}},
			# «Взгляд Горгоны» (блок + СР + СН): бросок вперёд; попал — Медуза снимает повязку.
			"super": {"name": "ВЗГЛЯД ГОРГОНЫ", "startup": 6, "active": 8, "recovery": 40, "lunge": 900, "damage": 50, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 40, "box": [20, 40, 130, 220], "cinema": {"hold": 100, "damage": 300, "heal": 50, "launch": [600, 1500], "tech": 0, "recovery": 18, "scaled": 1}},
			"throw": {"startup": 3, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 22, "damage": 100, "launch": [450, 900], "tech": 1, "recovery": 10}},
		},
	},
	"sunwukong": {
		# Сунь Укун, Царь обезьян: маленький, быстрый, высоко прыгает; посох достаёт далеко.
		"name": "СУНЬ УКУН",
		"color": Color(0.96, 0.78, 0.2),
		"max_hp": 900,
		"height": 265,
		"crouch_height": 170,
		"push_half": 36,
		"walk_f": 380,
		"walk_b": 320,
		"prejump": 2,
		"jump_vy": 2300,
		"gravity": 118,
		"jump_vx_f": 520,
		"jump_vx_b": 440,
		"landing": 2,
		"run_speed": 900,
		"run_accel": 300,
		"run_stop": 3,
		"run_jump_bonus": 240,
		"backdash_v0": 1700,
		"backdash_decel": 120,
		"backdash_recovery": 3,
		"strings": [
			{"name": "Посох Жуи", "moves": ["st_lp", "st_lp", "st_hp"]},
			{"name": "Облако", "moves": ["st_lk", "st_lk", "st_hk"]},
			{"name": "Проделка", "moves": ["st_lp", "st_lk", "cr_hk"]},
		],
		"moves": {
			"st_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 28, "hitstun": 13, "hitstop": 6, "push": 600, "box": [55, 160, 120, 40]},
			"st_lk": {"startup": 4, "active": 3, "recovery": 8, "damage": 32, "hitstun": 14, "hitstop": 7, "push": 650, "box": [40, 80, 110, 45]},
			# Посох — длинный удар с размаха.
			"st_hp": {"startup": 9, "active": 4, "recovery": 17, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [60, 120, 215, 60]},
			"st_hk": {"startup": 8, "active": 3, "recovery": 15, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 950, "box": [35, 120, 125, 90]},
			"cr_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 22, "hitstun": 12, "hitstop": 6, "push": 550, "box": [55, 85, 110, 40]},
			"cr_lk": {"startup": 4, "active": 2, "recovery": 8, "damage": 28, "hitstun": 12, "hitstop": 6, "push": 550, "box": [45, 0, 140, 35], "level": "low"},
			"cr_hp": {"startup": 7, "active": 4, "recovery": 20, "damage": 80, "hitstun": 20, "hitstop": 12, "push": 850, "box": [20, 50, 140, 260], "knockdown": 1, "launch": [220, 1750], "uppercut": 1},
			"cr_hk": {"startup": 8, "active": 3, "recovery": 20, "damage": 65, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [45, 0, 200, 35], "level": "low"},
			"j_lp": {"startup": 4, "active": 5, "damage": 28, "hitstun": 13, "hitstop": 6, "push": 500, "box": [35, 60, 105, 50], "level": "overhead"},
			"j_lk": {"startup": 4, "active": 7, "damage": 32, "hitstun": 14, "hitstop": 7, "push": 500, "box": [30, 0, 130, 55], "level": "overhead"},
			"j_hp": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 700, "box": [35, 0, 160, 90], "level": "overhead"},
			"j_hk": {"startup": 6, "active": 5, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 700, "box": [30, 0, 140, 60], "level": "overhead"},
			"st_sweep": {"startup": 7, "active": 3, "recovery": 17, "damage": 55, "hitstun": 20, "hitstop": 10, "push": 600, "box": [30, 0, 150, 30], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 11, "active": 4, "recovery": 20, "damage": 95, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [20, 130, 115, 100], "knockdown": 1, "launch": [600, 900], "kick": 1},
			# Обезьянки из волосков (назад, вперёд + рука): сдувает волоски — стайка обезьянок.
			"sp_proj_l": {"buttons": "punch", "startup": 12, "active": 1, "recovery": 20, "proj": {"x": 50, "y": 140, "vx": 1100, "vy": 0, "gravity": 0, "w": 80, "h": 50, "kind": 11, "damage": 55, "hitstun": 18, "hitstop": 9, "push": 700, "chip": 6}, "ex": {"startup": 9, "proj": {"vx": 1500, "damage": 85, "hitstun": 26, "chip": 10, "h": 80, "kind": 111}}},
			# Облако (вниз, вниз + нога): исчезает на облаке и появляется за спиной.
			"sp_dd_l": {"buttons": "kick", "startup": 14, "active": 1, "recovery": 12, "teleport": {"invul_from": 3, "offset": 110}, "ex": {"startup": 9, "recovery": 5, "teleport": {"invul_from": 2}}},
			# Посох Жуи (вперёд, вперёд + рука): посох вырастает — удар через пол-арены.
			"sp_ff_l": {"buttons": "punch", "startup": 15, "active": 5, "recovery": 26, "damage": 105, "hitstun": 22, "hitstop": 13, "push": 1300, "chip": 10, "box": [40, 130, 400, 60], "ex": {"startup": 12, "damage": 140, "chip": 15, "knockdown": 1, "launch": [500, 1000], "box": [40, 130, 520, 70]}},
			# Прыжок Царя обезьян (назад, назад + рука): взлёт с посохом, неуязвим на старте — против прыжков.
			"sp_bb_l": {"buttons": "punch", "startup": 5, "active": 7, "recovery": 26, "invul": [1, 9], "damage": 95, "hitstun": 22, "hitstop": 12, "push": 800, "box": [10, 90, 110, 330], "knockdown": 1, "launch": [300, 1900], "uppercut": 1, "ex": {"invul": [1, 13], "damage": 135}},
			# «Семьдесят два превращения» (блок + СР + СН): рывок; попал — бьют все его двойники разом.
			"super": {"name": "СЕМЬДЕСЯТ ДВА ПРЕВРАЩЕНИЯ", "startup": 6, "active": 8, "recovery": 40, "lunge": 1000, "damage": 45, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 38, "box": [20, 40, 120, 210], "cinema": {"hold": 100, "damage": 300, "launch": [600, 1600], "tech": 0, "recovery": 16, "scaled": 1}},
			"throw": {"startup": 3, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 22, "damage": 95, "launch": [450, 900], "tech": 1, "recovery": 10}},
		},
	},
	"anubis": {
		# Анубис, страж мира мёртвых: высокий, неторопливый, бьёт жезлом-уасом и хопешем — тяжело и далеко.
		"name": "АНУБИС",
		"color": Color(0.3, 0.36, 0.62),
		"max_hp": 1050,
		"height": 330,
		"crouch_height": 205,
		"push_half": 48,
		"walk_f": 260,
		"walk_b": 220,
		"prejump": 5,
		"jump_vy": 1850,
		"gravity": 95,
		"jump_vx_f": 380,
		"jump_vx_b": 330,
		"landing": 4,
		"run_speed": 600,
		"run_accel": 60,
		"run_stop": 7,
		"run_jump_bonus": 140,
		"backdash_v0": 1100,
		"backdash_decel": 60,
		"backdash_recovery": 7,
		"strings": [
			{"name": "Весы", "moves": ["st_lp", "st_hp"]},
			{"name": "Суд", "moves": ["st_lk", "st_lk", "st_hp"]},
			{"name": "Проводник душ", "moves": ["st_lp", "st_lk", "st_hk"]},
		],
		"moves": {
			"st_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 38, "hitstun": 15, "hitstop": 8, "push": 700, "box": [70, 215, 150, 45]},
			"st_lk": {"startup": 7, "active": 3, "recovery": 11, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 800, "box": [50, 120, 125, 50]},
			# Жезл-уас сверху вниз — далеко и тяжело.
			"st_hp": {"startup": 12, "active": 4, "recovery": 21, "damage": 110, "hitstun": 22, "hitstop": 13, "push": 1150, "box": [70, 100, 220, 130]},
			"st_hk": {"startup": 10, "active": 4, "recovery": 19, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 1050, "box": [45, 160, 140, 95]},
			"cr_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 32, "hitstun": 14, "hitstop": 7, "push": 650, "box": [65, 125, 125, 45]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [55, 0, 140, 40], "level": "low"},
			"cr_hp": {"startup": 9, "active": 5, "recovery": 24, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 900, "box": [20, 60, 150, 270], "knockdown": 1, "launch": [240, 1700], "uppercut": 1},
			"cr_hk": {"startup": 11, "active": 4, "recovery": 24, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 0, 175, 38], "level": "low"},
			"j_lp": {"startup": 5, "active": 6, "damage": 38, "hitstun": 15, "hitstop": 8, "push": 600, "box": [55, 130, 120, 55], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 8, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 600, "box": [55, 60, 120, 65], "level": "overhead"},
			"j_hp": {"startup": 9, "active": 5, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 800, "box": [40, 0, 145, 120], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 6, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 800, "box": [55, 90, 110, 100], "level": "overhead"},
			"st_sweep": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 20, "hitstop": 11, "push": 600, "box": [30, 0, 145, 40], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 14, "active": 4, "recovery": 24, "damage": 120, "hitstun": 22, "hitstop": 14, "push": 1200, "box": [30, 170, 135, 130], "knockdown": 1, "launch": [650, 950], "kick": 1},
			# Скарабеи (назад, вперёд + рука): жуки ползут по земле — блок сидя, живут долго.
			"sp_proj_l": {"buttons": "punch", "startup": 16, "active": 1, "recovery": 22, "proj": {"x": 60, "y": 18, "vx": 600, "vy": 0, "gravity": 0, "w": 90, "h": 36, "kind": 12, "level": "low", "life": 70, "damage": 70, "hitstun": 20, "hitstop": 10, "push": 700, "chip": 8}, "ex": {"startup": 12, "proj": {"vx": 800, "life": 90, "damage": 100, "chip": 12, "kind": 112}}},
			# Песчаный смерч (вниз, вниз + нога): вихрь поднимается вперёд-вверх — против прыжков.
			"sp_dd_l": {"buttons": "kick", "startup": 14, "active": 1, "recovery": 24, "proj": {"x": 80, "y": 60, "vx": 450, "vy": 1100, "gravity": 0, "w": 80, "h": 120, "kind": 13, "life": 40, "damage": 80, "hitstun": 22, "hitstop": 11, "push": 600, "chip": 8}, "ex": {"startup": 10, "proj": {"w": 110, "damage": 115, "kind": 113}}},
			# Хопеш (вперёд, вперёд + рука): шаг с серповидным мечом, держит один удар.
			"sp_ff_l": {"buttons": "punch", "startup": 13, "active": 12, "recovery": 24, "lunge": 700, "armor": 1, "damage": 115, "hitstun": 24, "hitstop": 13, "push": 1300, "chip": 11, "box": [40, 90, 170, 150], "ex": {"armor": 2, "lunge": 900, "damage": 155, "chip": 16, "knockdown": 1, "launch": [450, 1300]}},
			# Взвешивание сердца (назад, назад + рука): захват, забирает секцию шкалы силы. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 6, "active": 2, "recovery": 32, "grab": {"range": 80, "hold": 48, "damage": 130, "drain": 1000, "launch": [500, 900], "tech": 0, "recovery": 12}, "ex": {"grab": {"range": 115, "damage": 180}}},
			# «Суд Осириса» (блок + СР + СН): выпад; попал — весы, перо истины и приговор.
			"super": {"name": "СУД ОСИРИСА", "startup": 8, "active": 8, "recovery": 45, "lunge": 750, "damage": 60, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 45, "box": [25, 40, 150, 240], "cinema": {"hold": 110, "damage": 330, "launch": [700, 1700], "tech": 0, "recovery": 20, "scaled": 1}},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 30, "hold": 28, "damage": 120, "launch": [500, 1000], "tech": 1, "recovery": 10}},
		},
	},
	"avatar": {
		# Аватар — цифровая копия Саши (финал аркады, фаза 1, docs/LORE.md): гладкая «игрушечная» кожа,
		# пустые светящиеся глаза, взгляд всё время в телефоне. Невысокий и быстрый. В выборе бойца его нет.
		"name": "АВАТАР",
		"color": Color(0.45, 0.8, 0.95),
		"boss": 1,
		"max_hp": 1000,
		"height": 250,
		"crouch_height": 165,
		"push_half": 36,
		"walk_f": 360,
		"walk_b": 320,
		"prejump": 2,
		"jump_vy": 2200,
		"gravity": 115,
		"jump_vx_f": 480,
		"jump_vx_b": 420,
		"landing": 2,
		"run_speed": 850,
		"run_accel": 260,
		"run_stop": 3,
		"run_jump_bonus": 220,
		"backdash_v0": 1650,
		"backdash_decel": 118,
		"backdash_recovery": 3,
		"strings": [
			{"name": "Тап-тап", "moves": ["st_lp", "st_lp", "st_hp"]},
			{"name": "Пинок от скуки", "moves": ["st_lk", "st_lk", "st_hk"]},
			{"name": "Ещё одно видео", "moves": ["st_lp", "st_lk", "cr_hk"]},
		],
		"moves": {
			# Удары телефоном и кроссовками — быстрые, но короткие.
			"st_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [50, 150, 110, 40]},
			"st_lk": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 700, "box": [35, 60, 100, 40]},
			"st_hp": {"startup": 9, "active": 4, "recovery": 17, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 950, "box": [50, 110, 160, 70]},
			"st_hk": {"startup": 9, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [35, 110, 115, 80]},
			"cr_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 26, "hitstun": 13, "hitstop": 6, "push": 600, "box": [45, 90, 100, 40]},
			"cr_lk": {"startup": 5, "active": 2, "recovery": 9, "damage": 30, "hitstun": 13, "hitstop": 6, "push": 600, "box": [40, 0, 130, 36], "level": "low"},
			"cr_hp": {"startup": 7, "active": 4, "recovery": 20, "damage": 80, "hitstun": 20, "hitstop": 12, "push": 850, "box": [15, 50, 100, 220], "knockdown": 1, "launch": [220, 1750], "uppercut": 1},
			"cr_hk": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [40, 0, 160, 36], "level": "low"},
			"j_lp": {"startup": 4, "active": 5, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 550, "box": [40, 90, 100, 45], "level": "overhead"},
			"j_lk": {"startup": 5, "active": 7, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 550, "box": [30, 20, 120, 50], "level": "overhead"},
			"j_hp": {"startup": 7, "active": 4, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 750, "box": [30, 0, 110, 90], "level": "overhead"},
			"j_hk": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 750, "box": [30, 10, 130, 60], "level": "overhead"},
			"st_sweep": {"startup": 8, "active": 3, "recovery": 18, "damage": 60, "hitstun": 20, "hitstop": 10, "push": 600, "box": [25, 0, 130, 30], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 11, "active": 4, "recovery": 20, "damage": 95, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [20, 120, 110, 90], "knockdown": 1, "launch": [600, 900], "kick": 1},
			# Банка колы (назад, вперёд + рука): летит по дуге, на земле лопается брызгами.
			"sp_proj_l": {"buttons": "punch", "startup": 13, "active": 1, "recovery": 20, "proj": {"x": 40, "y": 170, "vx": 750, "vy": 1050, "gravity": 65, "w": 40, "h": 50, "kind": 15, "damage": 75, "hitstun": 20, "hitstop": 10, "push": 800, "chip": 8}, "ex": {"startup": 10, "proj": {"vx": 950, "damage": 105, "hitstun": 26, "chip": 13, "kind": 115}}},
			# Жвачка (вниз, вниз + нога): плевок; попавший прилипает и стоит на месте.
			"sp_dd_l": {"buttons": "kick", "startup": 15, "active": 1, "recovery": 24, "proj": {"x": 40, "y": 190, "vx": 800, "vy": 0, "gravity": 0, "w": 44, "h": 36, "kind": 16, "damage": 25, "hitstun": 14, "hitstop": 10, "push": 100, "chip": 0, "stick": 55}, "ex": {"startup": 11, "proj": {"vx": 1100, "stick": 85, "kind": 116}}},
			# Листает ленту (вперёд, вперёд + рука): уткнулся в телефон — перед ним на треть экрана бьёт лента роликов.
			"sp_ff_l": {"buttons": "punch", "startup": 14, "active": 40, "recovery": 24, "rehit": 10, "damage": 24, "hitstun": 14, "hitstop": 4, "push": 120, "chip": 3, "box": [20, 0, 430, 300], "ex": {"active": 60, "damage": 30, "chip": 5}},
			# Селфи (назад, назад + рука): захват, вспышка в лицо — забирает секцию шкалы. Вырваться нельзя.
			"sp_bb_l": {"buttons": "punch", "startup": 5, "active": 2, "recovery": 28, "grab": {"range": 75, "hold": 36, "damage": 110, "drain": 1000, "launch": [400, 800], "tech": 0, "recovery": 10}, "ex": {"grab": {"range": 110, "damage": 150, "drain": 2000}}},
			# «Бесконечная лента» (блок + СР + СН): рывок; попал — огромная лента роликов затягивает и бьёт.
			"super": {"name": "БЕСКОНЕЧНАЯ ЛЕНТА", "startup": 6, "active": 8, "recovery": 40, "lunge": 1000, "damage": 50, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 40, "box": [20, 40, 110, 200], "cinema": {"hold": 100, "damage": 300, "launch": [600, 1600], "tech": 0, "recovery": 16, "scaled": 1}},
			"throw": {"startup": 3, "active": 2, "recovery": 18, "grab": {"range": 25, "hold": 22, "damage": 95, "launch": [450, 900], "tech": 1, "recovery": 10}},
		},
	},
	"scroller": {
		# Скроллер — хозяин шоу (финал аркады, фаза 2): сутулый, в рваном худи с пятнами колы и крошками
		# чипсов, мешковатые треники, шлёпанцы на носки; вместо лица — экран-маска со смайликами,
		# из пальцев тянутся провода-нити. Медленный и тяжёлый; бьётся один длинный раунд.
		"name": "СКРОЛЛЕР",
		"color": Color(0.55, 0.6, 0.4),
		"boss": 1,
		"one_round": 1,
		"max_hp": 1500,
		"height": 330,
		"crouch_height": 210,
		"push_half": 56,
		"walk_f": 240,
		"walk_b": 200,
		"prejump": 6,
		"jump_vy": 1750,
		"gravity": 95,
		"jump_vx_f": 360,
		"jump_vx_b": 300,
		"landing": 5,
		"run_speed": 560,
		"run_accel": 40,
		"run_stop": 8,
		"run_jump_bonus": 120,
		"backdash_v0": 1000,
		"backdash_decel": 55,
		"backdash_recovery": 8,
		"strings": [
			{"name": "Лайк, лайк, дизлайк", "moves": ["st_lp", "st_lp", "st_hp"]},
			{"name": "Шлёпанец", "moves": ["st_lk", "st_hk"]},
			{"name": "Ещё одну катку", "moves": ["st_lp", "st_lk", "cr_hk"]},
		],
		"moves": {
			# Ленивые, но тяжёлые оплеухи и пинки шлёпанцем; нити достают далеко.
			"st_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 700, "box": [70, 200, 150, 50]},
			"st_lk": {"startup": 7, "active": 3, "recovery": 11, "damage": 48, "hitstun": 16, "hitstop": 8, "push": 800, "box": [55, 110, 125, 55]},
			"st_hp": {"startup": 12, "active": 4, "recovery": 21, "damage": 115, "hitstun": 22, "hitstop": 13, "push": 1150, "box": [70, 110, 220, 120]},
			"st_hk": {"startup": 11, "active": 4, "recovery": 20, "damage": 95, "hitstun": 20, "hitstop": 11, "push": 1050, "box": [50, 150, 140, 95]},
			"cr_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 34, "hitstun": 14, "hitstop": 7, "push": 650, "box": [65, 120, 125, 45]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 36, "hitstun": 14, "hitstop": 7, "push": 650, "box": [55, 0, 140, 40], "level": "low"},
			"cr_hp": {"startup": 9, "active": 5, "recovery": 24, "damage": 105, "hitstun": 22, "hitstop": 13, "push": 900, "box": [20, 60, 150, 270], "knockdown": 1, "launch": [240, 1700], "uppercut": 1},
			"cr_hk": {"startup": 11, "active": 4, "recovery": 24, "damage": 82, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 0, 175, 38], "level": "low"},
			"j_lp": {"startup": 5, "active": 6, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 600, "box": [55, 130, 120, 55], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 8, "damage": 46, "hitstun": 16, "hitstop": 8, "push": 600, "box": [55, 60, 120, 65], "level": "overhead"},
			"j_hp": {"startup": 9, "active": 5, "damage": 105, "hitstun": 22, "hitstop": 13, "push": 800, "box": [40, 0, 145, 120], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 6, "damage": 92, "hitstun": 20, "hitstop": 11, "push": 800, "box": [55, 90, 110, 100], "level": "overhead"},
			"st_sweep": {"startup": 9, "active": 3, "recovery": 20, "damage": 72, "hitstun": 20, "hitstop": 11, "push": 600, "box": [30, 0, 150, 40], "level": "low", "knockdown": 1, "launch": [150, 500], "kick": 1},
			"st_round": {"startup": 14, "active": 4, "recovery": 24, "damage": 122, "hitstun": 22, "hitstop": 14, "push": 1200, "box": [30, 170, 135, 130], "knockdown": 1, "launch": [650, 950], "kick": 1},
			# Смайл-бомба (назад, вперёд + рука): кидает эмодзи, тот лопается.
			"sp_proj_l": {"buttons": "punch", "startup": 13, "active": 1, "recovery": 20, "proj": {"x": 60, "y": 200, "vx": 900, "vy": 400, "gravity": 25, "w": 60, "h": 60, "kind": 17, "damage": 85, "hitstun": 20, "hitstop": 11, "push": 900, "chip": 9}, "ex": {"startup": 10, "proj": {"vx": 1200, "damage": 120, "hitstun": 26, "chip": 14, "kind": 117}}},
			# Перехват (вниз, вниз + нога): нить цепляет героя — на 2 секунды лево и право меняются местами.
			"sp_dd_l": {"buttons": "kick", "startup": 12, "active": 1, "recovery": 22, "proj": {"x": 60, "y": 200, "vx": 1500, "vy": 0, "gravity": 0, "w": 80, "h": 30, "kind": 18, "life": 26, "damage": 30, "hitstun": 16, "hitstop": 10, "push": 300, "chip": 0, "invert": 120}, "ex": {"startup": 9, "proj": {"life": 36, "invert": 200, "kind": 118}}},
			# Рывок за нить (вперёд, вперёд + рука): нить цепляет и дёргает героя к Скроллеру.
			"sp_ff_l": {"buttons": "punch", "startup": 10, "active": 1, "recovery": 20, "proj": {"x": 60, "y": 160, "vx": 2400, "vy": 0, "gravity": 0, "w": 80, "h": 40, "kind": 18, "life": 18, "damage": 40, "hitstun": 22, "hitstop": 10, "push": -3000, "chip": 0}, "ex": {"startup": 8, "proj": {"life": 26, "damage": 60, "hitstun": 28, "kind": 118}}},
			# Отрыжка (назад, назад + рука): вблизи — волна газировки отшвыривает героя.
			"sp_bb_l": {"buttons": "punch", "startup": 8, "active": 5, "recovery": 26, "damage": 90, "hitstun": 22, "hitstop": 12, "push": 2400, "chip": 9, "box": [20, 60, 170, 220], "knockdown": 1, "launch": [900, 700], "ex": {"damage": 130, "box": [20, 40, 230, 260]}},
			# «Прямой эфир» (блок + СР + СН): рывок; попал — побеждённые герои-марионетки бьют по очереди.
			"super": {"name": "ПРЯМОЙ ЭФИР", "startup": 7, "active": 8, "recovery": 42, "lunge": 900, "damage": 55, "hitstun": 30, "hitstop": 12, "push": 900, "chip": 45, "box": [25, 40, 150, 240], "cinema": {"hold": 120, "damage": 350, "launch": [700, 1700], "tech": 0, "recovery": 20, "scaled": 1}},
			"throw": {"startup": 4, "active": 2, "recovery": 18, "grab": {"range": 30, "hold": 28, "damage": 120, "launch": [500, 1000], "tech": 1, "recovery": 10}},
		},
	},
}


static func get_data(id: String) -> Dictionary:
	return CHARACTERS[id]
