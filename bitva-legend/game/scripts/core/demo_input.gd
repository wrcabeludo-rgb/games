class_name DemoInput
extends RefCounted
## Записанный сценарий ввода для отладочных скриншотов и проверок без геймпада.
## После вступления оба бойца одновременно бросают снаряды: Илья — палицу, Дракула — мышей.

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать].
const STEPS := [
	[0, 0, 80],
	[InputBits.LEFT, InputBits.RIGHT, 2],
	[InputBits.RIGHT | InputBits.HP, InputBits.LEFT | InputBits.LP, 1],
	[0, 0, 600],
]
const LENGTH := 112


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in STEPS:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
