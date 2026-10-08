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
## Спецприёмы: sp_<имя>_l — лёгкая версия, sp_<имя>_h — сильная.
##   proj — снаряд, выпускается на кадре startup:
##     x, y   — откуда вылетает (вперёд от центра, высота), px
##     vx, vy — скорость (вперёд, вверх), субпиксели за тик; gravity — гравитация
##     w, h   — размер хитбокса снаряда, px;  kind — вид для отрисовки (0 палица, 1 мыши)
##     damage, hitstun, hitstop, push — как у ударов; chip — урон сквозь блок

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
		"moves": {
			# Кулаки и ноги Ильи медленнее, зато палица (сильные удары рукой) бьёт далеко.
			"st_lp": {"startup": 5, "active": 3, "recovery": 8, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 700, "box": [40, 180, 90, 40]},
			"st_lk": {"startup": 7, "active": 3, "recovery": 11, "damage": 50, "hitstun": 16, "hitstop": 8, "push": 800, "box": [40, 85, 105, 40]},
			"st_hp": {"startup": 12, "active": 4, "recovery": 20, "damage": 110, "hitstun": 22, "hitstop": 13, "push": 1100, "box": [40, 120, 155, 140]},
			"st_hk": {"startup": 10, "active": 4, "recovery": 18, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [45, 140, 130, 45]},
			"cr_lp": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [45, 110, 85, 35]},
			"cr_lk": {"startup": 6, "active": 3, "recovery": 10, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 650, "box": [40, 0, 110, 30], "level": "low"},
			"cr_hp": {"startup": 10, "active": 5, "recovery": 22, "damage": 100, "hitstun": 22, "hitstop": 12, "push": 900, "box": [25, 150, 95, 170]},
			"cr_hk": {"startup": 11, "active": 4, "recovery": 24, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [40, 0, 165, 30], "level": "low"},
			"j_lp": {"startup": 5, "active": 6, "damage": 40, "hitstun": 15, "hitstop": 8, "push": 600, "box": [30, 70, 85, 50], "level": "overhead"},
			"j_lk": {"startup": 6, "active": 8, "damage": 45, "hitstun": 16, "hitstop": 8, "push": 600, "box": [30, 10, 95, 50], "level": "overhead"},
			"j_hp": {"startup": 9, "active": 5, "damage": 100, "hitstun": 22, "hitstop": 13, "push": 800, "box": [25, -15, 125, 95], "level": "overhead"},
			"j_hk": {"startup": 8, "active": 6, "damage": 90, "hitstun": 20, "hitstop": 11, "push": 800, "box": [30, 15, 125, 50], "level": "overhead"},
			# Бросок палицы: летит по дуге и падает. Медленный, но мощный.
			"sp_proj_l": {"startup": 16, "active": 1, "recovery": 20, "proj": {"x": 60, "y": 200, "vx": 650, "vy": 1100, "gravity": 70, "w": 54, "h": 54, "kind": 0, "damage": 90, "hitstun": 22, "hitstop": 12, "push": 900, "chip": 9}},
			"sp_proj_h": {"startup": 20, "active": 1, "recovery": 22, "proj": {"x": 60, "y": 200, "vx": 950, "vy": 900, "gravity": 70, "w": 54, "h": 54, "kind": 0, "damage": 110, "hitstun": 24, "hitstop": 13, "push": 1000, "chip": 11}},
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
		"moves": {
			# Дракула быстрее и бьёт чаще, но слабее; ноги длиннее рук.
			"st_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 650, "box": [32, 165, 72, 35]},
			"st_lk": {"startup": 5, "active": 3, "recovery": 9, "damage": 35, "hitstun": 14, "hitstop": 7, "push": 700, "box": [30, 80, 95, 35]},
			"st_hp": {"startup": 8, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 950, "box": [32, 150, 115, 50]},
			"st_hk": {"startup": 9, "active": 3, "recovery": 16, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 1000, "box": [32, 115, 135, 45]},
			"cr_lp": {"startup": 4, "active": 2, "recovery": 7, "damage": 25, "hitstun": 13, "hitstop": 6, "push": 600, "box": [35, 100, 72, 30]},
			"cr_lk": {"startup": 5, "active": 2, "recovery": 9, "damage": 30, "hitstun": 13, "hitstop": 6, "push": 600, "box": [30, 0, 105, 28], "level": "low"},
			"cr_hp": {"startup": 7, "active": 4, "recovery": 18, "damage": 75, "hitstun": 20, "hitstop": 11, "push": 850, "box": [22, 140, 85, 155]},
			"cr_hk": {"startup": 9, "active": 3, "recovery": 20, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 1000, "box": [35, 0, 145, 28], "level": "low"},
			"j_lp": {"startup": 4, "active": 5, "damage": 30, "hitstun": 14, "hitstop": 7, "push": 550, "box": [25, 60, 72, 45], "level": "overhead"},
			"j_lk": {"startup": 5, "active": 7, "damage": 35, "hitstun": 15, "hitstop": 7, "push": 550, "box": [25, 10, 85, 45], "level": "overhead"},
			"j_hp": {"startup": 7, "active": 4, "damage": 80, "hitstun": 20, "hitstop": 11, "push": 750, "box": [25, 0, 105, 80], "level": "overhead"},
			"j_hk": {"startup": 7, "active": 5, "damage": 75, "hitstun": 19, "hitstop": 10, "push": 750, "box": [25, 20, 115, 45], "level": "overhead"},
			# Стая летучих мышей: летит прямо. Лёгкая — на уровне груди, сильная — быстрее,
			# но на уровне головы: под ней можно присесть.
			"sp_proj_l": {"startup": 12, "active": 1, "recovery": 22, "proj": {"x": 50, "y": 150, "vx": 800, "vy": 0, "gravity": 0, "w": 68, "h": 44, "kind": 1, "damage": 60, "hitstun": 18, "hitstop": 9, "push": 700, "chip": 6}},
			"sp_proj_h": {"startup": 14, "active": 1, "recovery": 24, "proj": {"x": 50, "y": 225, "vx": 1200, "vy": 0, "gravity": 0, "w": 68, "h": 44, "kind": 1, "damage": 70, "hitstun": 19, "hitstop": 10, "push": 750, "chip": 7}},
		},
	},
}


static func get_data(id: String) -> Dictionary:
	return CHARACTERS[id]
