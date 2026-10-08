class_name DemoInput
extends RefCounted
## Записанный сценарий ввода для отладочных скриншотов и проверок без геймпада.
## Илья разбегается (двойное «вперёд»), Дракула делает отскок (двойное «назад»).

## Шаги: [биты игрока 1, биты игрока 2, сколько тиков держать].
const STEPS := [
	[0, 0, 10],
	[InputBits.RIGHT, InputBits.RIGHT, 3],
	[0, 0, 3],
	[InputBits.RIGHT, InputBits.RIGHT, 60],
]
const LENGTH := 26


static func frame(tick: int) -> PackedInt32Array:
	var t := 0
	for s in STEPS:
		t += s[2]
		if tick < t:
			return PackedInt32Array([s[0], s[1]])
	return PackedInt32Array([0, 0])
