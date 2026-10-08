class_name DemoInput
extends RefCounted
## Записанные сценарии ввода для отладочных скриншотов (выбор: «-- --demo=имя»).

const R := InputBits.RIGHT
const L := InputBits.LEFT
const D := InputBits.DOWN

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать]. Первые 80 тиков — вступление.
const SCENARIOS := {
	# Оба бросают снаряды.
	"projectiles": [[0, 0, 80], [L, R, 2], [R | InputBits.HP, L | InputBits.LP, 1], [0, 0, 600]],
	# Илья бьёт оземь, Дракула стоит в верхнем блоке — волна его пробивает.
	"wave": [[0, 0, 80], [R, 0, 40], [D, InputBits.BLOCK, 2], [0, InputBits.BLOCK, 2], [D | InputBits.LK, InputBits.BLOCK, 1], [0, InputBits.BLOCK, 600]],
	# Дракула уходит в туман и появляется за спиной.
	"mist": [[0, 0, 80], [R, L, 40], [0, D, 2], [0, 0, 2], [0, D | InputBits.LK, 1], [0, 0, 600]],
	# Илья подходит и делает подсечку (назад + ЛН).
	"sweep": [[0, 0, 80], [R, 0, 85], [L | InputBits.LK, 0, 1], [0, 0, 600]],
	# Илья подходит вплотную и бросает Дракулу, который держит блок.
	"throw": [[0, 0, 80], [R, InputBits.BLOCK, 140], [InputBits.LP, InputBits.BLOCK, 1], [0, InputBits.BLOCK, 600]],
	# Илья подходит, Дракула бьёт апперкотом (вниз + СР).
	"uppercut": [[0, 0, 80], [R, 0, 100], [0, D | InputBits.HP, 1], [0, 0, 600]],
	# Илья идёт тараном, Дракула ловит его гипнотическим взглядом.
	"counter": [[0, 0, 80], [R, 0, 60], [0, 0, 4], [R, L, 2], [0, 0, 2], [R | InputBits.LP, L | InputBits.LP, 1], [0, 0, 600]],
	# Строка Ильи ЛР, ЛР, СР.
	"string": [[0, 0, 80], [R, 0, 115], [InputBits.LP, 0, 1], [0, 0, 6], [InputBits.LP, 0, 1], [0, 0, 6], [InputBits.HP, 0, 1], [0, 0, 600]],
	# Апперкот Ильи и таран по подброшенному Дракуле.
	"juggle": [[0, 0, 80], [R, 0, 115], [D | InputBits.HP, 0, 1], [0, 0, 9], [R, 0, 2], [0, 0, 1], [R | InputBits.LP, 0, 1], [0, 0, 600]],
}
const LENGTH := 112

static var scenario := "projectiles"


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in SCENARIOS[scenario]:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
