class_name DemoInput
extends RefCounted
## Записанный сценарий ввода для отладочных скриншотов и проверок без геймпада.
## Илья подходит и бьёт палицей (СР), Дракула держит блок.

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать].
const STEPS := [
	[0, 0, 5],
	[InputBits.RIGHT, InputBits.BLOCK, 80],
	[InputBits.HP, InputBits.BLOCK, 1],
	[0, InputBits.BLOCK, 60],
]
const LENGTH := 98


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in STEPS:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
