class_name DemoInput
extends RefCounted
## Записанный сценарий ввода для отладочных скриншотов и проверок без геймпада.

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать].
const STEPS := [
	[0, 0, 10],
	[InputBits.DOWN, InputBits.LEFT, 6],
	[InputBits.DOWN | InputBits.RIGHT, InputBits.LEFT | InputBits.UP, 6],
	[InputBits.RIGHT, InputBits.UP, 6],
	[InputBits.RIGHT | InputBits.LP, InputBits.UP | InputBits.HK, 4],
	[0, 0, 8],
	[InputBits.LEFT, InputBits.BLOCK, 5],
	[InputBits.RIGHT, InputBits.BLOCK | InputBits.DOWN, 5],
	[InputBits.RIGHT | InputBits.HP, InputBits.DOWN | InputBits.LK, 4],
	[InputBits.BLOCK, InputBits.HP | InputBits.HK, 12],
]
const LENGTH := 66


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in STEPS:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
