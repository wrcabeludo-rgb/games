class_name Quotes
extends RefCounted
## Реплики бойцов: перед боем (экран «ПРОТИВ») и после победы в матче.
## Тон — «пафос + юмор». Каждая реплика — [русский, английский].

## Перед боем: пара бойцов (по алфавиту) → варианты диалога; в диалоге — [кто говорит, ru, en].
const INTRO := {
	"dracula|ilya": [
		[["ilya", "Ты, что ли, кровопийца заморский? Ну держись: у нас на Руси кровь не раздают.",
			"So you're the overseas bloodsucker? Brace yourself: in Rus we don't give blood away."],
		["dracula", "Какой… колоритный ужин. Надеюсь, вы не слишком солёный.",
			"What a… colourful dinner. I do hope you're not too salty."]],
		[["ilya", "Тридцать лет и три года я на печи сидел. Встал — и сразу ты. Не повезло тебе.",
			"Thirty-three years I sat on the stove. First thing I see when I get up — you. Bad luck for you."],
		["dracula", "Тридцать три года? Я четыреста лет пролежал в гробу. Не впечатлён.",
			"Thirty-three years? I spent four hundred in a coffin. Not impressed."]],
		[["dracula", "На камне написано: «Прямо поедешь — убиту быть». Вы ведь прямо, богатырь?",
			"The stone says: «Ride straight on and you'll be slain». You are going straight, hero?"],
		["ilya", "Камень-то про тебя писал, упырь. Я грамоте не учён, зато палицей учён.",
			"That stone was writing about you, ghoul. I never learned letters, but I learned the mace."]],
	],
	"ilya|ilya": [
		[["ilya", "Ты кто таков? Я — Илья Муромец!", "And who might you be? I am Ilya Muromets!"],
		["ilya", "Врёшь! Это я Илья Муромец. А ты, видать, Илья Подмосковец.",
			"Liar! I'm Ilya Muromets. You must be some Ilya from the suburbs."]],
	],
	"dracula|dracula": [
		[["dracula", "Вас тоже не отражают зеркала? Какое совпадение.", "Mirrors don't show you either? What a coincidence."],
		["dracula", "Один из нас — подделка. И я в своём замке не потерплю дешёвых копий.",
			"One of us is a fake. And I tolerate no cheap copies in my castle."]],
	],
}

## Победа: победитель → проигравший → варианты [ru, en].
const WIN := {
	"ilya": {
		"dracula": [
			["Вот и вся заморская наука. Чесночку тебе на дорожку!", "So much for foreign learning. Have some garlic for the road!"],
			["Лежи, отдыхай. Гроб-то, небось, помягче был?", "Lie down, rest. Your coffin was comfier, I bet?"],
			["Палица — она и в Карпатах палица.", "A mace is a mace, even in the Carpathians."],
		],
		"ilya": [
			["Двух Муромцев земля Русская не выдержит.", "The Russian land can't hold two of me."],
		],
	},
	"dracula": {
		"ilya": [
			["Крепкий старик. Кровь — как медовуха: с ног сшибает.", "A sturdy old man. Blood like mead — knocks you off your feet."],
			["Ваша борода — единственное, что оказало мне сопротивление.", "Your beard was the only thing that put up a fight."],
			["Не расстраивайтесь, богатырь. Вы были великолепны… на вкус.", "Don't be upset, hero. You were magnificent… in taste."],
		],
		"dracula": [
			["Двум графам в одном замке тесно.", "One castle is too small for two counts."],
		],
	},
}


static func _pick(lines: Array, seed_value: int):
	return lines[absi(seed_value) % lines.size()]


## Диалог перед боем: массив [кто, текст] на текущем языке (бойцы a и b — в любом порядке).
static func intro(a: String, b: String, seed_value: int) -> Array:
	var ids := [a, b]
	ids.sort()
	var variants: Array = INTRO.get("%s|%s" % ids, [])
	if variants.is_empty():
		return []
	var out := []
	for line in _pick(variants, seed_value):
		out.append([line[0], line[1] if Loc.lang == "ru" else line[2]])
	return out


## Победная реплика или "".
static func win(winner: String, loser: String, seed_value: int) -> String:
	var lines: Array = WIN.get(winner, {}).get(loser, [])
	if lines.is_empty():
		return ""
	var q: Array = _pick(lines, seed_value)
	return q[0] if Loc.lang == "ru" else q[1]
