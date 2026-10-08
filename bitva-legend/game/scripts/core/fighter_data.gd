class_name FighterData
extends RefCounted
## Параметры бойцов. Размеры — в пикселях, скорости — в субпикселях за тик
## (1 пиксель = Fighter.SUB субпикселей), время — в тиках (60 тиков = 1 секунда).

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
	},
}


static func get_data(id: String) -> Dictionary:
	return CHARACTERS[id]
