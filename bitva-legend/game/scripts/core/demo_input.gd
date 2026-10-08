class_name DemoInput
extends RefCounted
## Записанный сценарий ввода для отладочных скриншотов и проверок без геймпада.
## Илья идёт вперёд и садится, Дракула подходит и прыгает через него.

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать].
const STEPS := [
	[0, 0, 10],
	[InputBits.RIGHT, InputBits.LEFT, 30],
	[InputBits.DOWN, InputBits.UP | InputBits.LEFT, 20],
	[InputBits.DOWN, 0, 60],
]
const LENGTH := 60


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in STEPS:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
