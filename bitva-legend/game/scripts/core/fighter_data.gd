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
	},
}


static func get_data(id: String) -> Dictionary:
	return CHARACTERS[id]
