class_name Arcade
extends RefCounted
## Режим «Аркада» (docs/LORE.md): Саша в облике выбранного героя проходит ивенты Скроллера — девять боёв.
## Шесть соперников в случайном порядке, седьмым — заклятый соперник из пары, потом финал в две фазы:
## Аватар (цифровая копия Саши) и сам Скроллер. ИИ крепчает от боя к бою. После Скроллера — эпилог (Endings).

## Пары-соперники.
const RIVALS := {
	"ilya": "dracula", "dracula": "ilya",
	"hercules": "koschei", "koschei": "hercules",
	"athena": "medusa", "medusa": "athena",
	"sunwukong": "anubis", "anubis": "sunwukong",
}
## Финал: фаза 1 и фаза 2.
const AVATAR := "avatar"
const BOSS := "scroller"
const FINALS := [AVATAR, BOSS]
## Уровень ИИ на каждом бою лестницы.
const STAGE_LEVELS := [
	AiController.Level.EASY, AiController.Level.EASY,
	AiController.Level.MEDIUM, AiController.Level.MEDIUM, AiController.Level.MEDIUM,
	AiController.Level.HARD, AiController.Level.HARD, AiController.Level.HARD, AiController.Level.HARD,
]

var player := ""
var ladder: Array[String] = []
var stage := 0
var continues := 0


func _init(id: String, roster: Array, seed_value: int) -> void:
	player = id
	var rival: String = RIVALS.get(id, "")
	var rest: Array[String] = []
	for other in roster:
		if other != "" and other != id and other != rival:
			rest.append(other)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Перемешивание Фишера — Йетса на своём генераторе (воспроизводимо по зерну).
	for i in range(rest.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := rest[i]
		rest[i] = rest[j]
		rest[j] = t
	ladder = rest
	if rival != "":
		ladder.append(rival)
	ladder.append_array(FINALS)


func opponent() -> String:
	return ladder[mini(stage, ladder.size() - 1)]


func ai_level() -> AiController.Level:
	return STAGE_LEVELS[mini(stage, STAGE_LEVELS.size() - 1)]


## Победа в текущем бою: true — лестница пройдена.
func advance() -> bool:
	stage += 1
	return stage >= ladder.size()


func is_final() -> bool:
	return stage == ladder.size() - 1
