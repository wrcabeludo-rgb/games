class_name DemoInput
extends RefCounted
## Записанный сценарий ввода для отладочных скриншотов и проверок без геймпада.
## После вступления Илья подходит и бьёт палицей (СР).

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать].
const STEPS := [
	[0, 0, 80],
	[InputBits.RIGHT, 0, 80],
	[InputBits.HP, 0, 1],
	[0, 0, 600],
]
const LENGTH := 30


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in STEPS:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
