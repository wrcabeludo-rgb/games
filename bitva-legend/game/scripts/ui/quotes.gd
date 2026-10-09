class_name Quotes
extends RefCounted
## Реплики бойцов: перед боем (экран «ПРОТИВ») и после победы в матче.
## Тон — «пафос + юмор». Каждая реплика — [русский, английский].

## Перед боем: пара бойцов (по алфавиту) → варианты диалога; в диалоге — [кто говорит, ru, en].
## Истории персонажей и смысл пар — docs/LORE.md.
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
		[["dracula", "Вы защищаете свою землю, богатырь. Я тоже защищал свою. Только моей больше нет.",
			"You defend your land, hero. I defended mine too. Only mine is gone."],
		["ilya", "Жаль тебя, княже. А всё одно — кровь людскую пить не дам.",
			"I pity you, prince. All the same — I won't let you drink people's blood."]],
	],
	"hercules|koschei": [
		[["hercules", "Говорят, ты спрятал свою смерть. Трус! Я свою вину не прячу — я её отрабатываю.",
			"They say you hid your death. Coward! I don't hide my guilt — I work it off."],
		["koschei", "Двенадцать подвигов, и всё ещё не простил себя? Мы похожи больше, чем ты думаешь, силач.",
			"Twelve labours and you still haven't forgiven yourself? We're more alike than you think, strongman."]],
	],
	"athena|medusa": [
		[["athena", "Медуза. Ты обращаешь в камень всех, кто приходит. Этому пора положить конец.",
			"Medusa. You turn to stone everyone who comes. This has to end."],
		["medusa", "Конец положила ты — в своём храме. Меня обидели, а наказала ты — меня. Посмотри мне в глаза, богиня.",
			"You put an end to me — in your own temple. I was wronged, and you punished me. Look me in the eye, goddess."]],
		[["medusa", "Пришла за моей головой, как все твои «герои»?",
			"Come for my head, like all your «heroes»?"],
		["athena", "Я пришла… за ответом. Сначала — поединок. Потом — правда.",
			"I came… for an answer. First the duel. Then the truth."]],
	],
	"anubis|sunwukong": [
		[["anubis", "Сунь Укун. Твоё имя вычеркнуто из Книги жизни и смерти. Весы не терпят пустых строк.",
			"Sun Wukong. Your name is struck from the Book of Life and Death. The scales cannot abide an empty line."],
		["sunwukong", "Вычеркнуто — значит, меня нет! Кого ты тогда ловишь, пёсик?",
			"Struck out — so I don't exist! Then who are you chasing, doggy?"]],
		[["sunwukong", "Эй, шакал! Догонишь — отдам посох. Не догонишь — отдашь весы!",
			"Hey, jackal! Catch me and the staff is yours. Don't — and I get your scales!"],
		["anubis", "Все бегут от смерти. Ни один ещё не добежал.",
			"Everyone runs from death. No one has ever made it."]],
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

## Если для пары нет своего диалога — каждый говорит свою общую фразу: id → [ru, en].
const GENERIC_INTRO := {
	"ilya": ["Ну, выходи, кто бы ты ни был. На Руси гостей встречают — палицей.",
		"Step forward, whoever you are. In Rus we greet guests — with a mace."],
	"hercules": ["Двенадцать подвигов совершил. Ты будешь тринадцатым — коротким.",
		"Twelve labours I have done. You'll be the thirteenth — a short one."],
	"athena": ["Мудрость — знать, когда сражаться. Сейчас — время.",
		"Wisdom is knowing when to fight. Now is the time."],
	"sunwukong": ["Великий Мудрец, равный Небу, приветствует тебя! И сразу прощается.",
		"The Great Sage Equal to Heaven greets you! And says goodbye right away."],
	"dracula": ["Добрый вечер. Позвольте пригласить вас на ужин… в качестве ужина.",
		"Good evening. Allow me to invite you to dinner… as the dinner."],
	"koschei": ["Меня убить нельзя — смерть моя на конце иглы. А жаль. Иногда очень хочется.",
		"I cannot be killed — my death lies at a needle's tip. A pity. Sometimes I'd really like to be."],
	"medusa": ["Ещё один герой. Не смотри мне в глаза — или смотри. Мне уже всё равно.",
		"Another hero. Don't look into my eyes — or do. I no longer care."],
	"anubis": ["Не бойся. Я взвешиваю сердца, а не вырываю их.",
		"Do not fear. I weigh hearts, I do not tear them out."],
}
const GENERIC_WIN := {
	"ilya": ["Отдохни, полежи. А я пойду — ещё не всех чудищ перебил.", "Lie down, rest. I'm off — plenty of monsters left."],
	"hercules": ["Тринадцатый подвиг. Только легче почему-то не стало.", "The thirteenth labour. Somehow it didn't get any lighter."],
	"athena": ["Победа — не правота. Запомни это. И я запомню.", "Victory is not righteousness. Remember that. So will I."],
	"sunwukong": ["Ха! Даже не вспотел. Ну ладно, чуть-чуть.", "Ha! Didn't even break a sweat. Well, maybe a little."],
	"dracula": ["Восхитительно. Повторим в полнолуние?", "Delightful. Shall we repeat it at the full moon?"],
	"koschei": ["Опять победил. Опять не умер. Опять ничего не почувствовал.", "Won again. Didn't die again. Felt nothing again."],
	"medusa": ["Ещё одна статуя в саду. Красивая. Все они красивые.", "One more statue for the garden. Beautiful. They all are."],
	"anubis": ["Твоё сердце легче, чем ты думал. Иди с миром.", "Your heart is lighter than you thought. Go in peace."],
}

## Победа: победитель → проигравший → варианты [ru, en].
const WIN := {
	"ilya": {
		"dracula": [
			["Вот и вся заморская наука. Чесночку тебе на дорожку!", "So much for foreign learning. Have some garlic for the road!"],
			["Лежи, отдыхай. Гроб-то, небось, помягче был?", "Lie down, rest. Your coffin was comfier, I bet?"],
			["Ты, княже, воин справный был. Жаль, что не на той стороне.", "You were a fine warrior, prince. Pity you're on the wrong side."],
		],
		"ilya": [
			["Двух Муромцев земля Русская не выдержит.", "The Russian land can't hold two of me."],
		],
	},
	"dracula": {
		"ilya": [
			["Крепкий старик. Кровь — как медовуха: с ног сшибает.", "A sturdy old man. Blood like mead — knocks you off your feet."],
			["Ваша борода — единственное, что оказало мне сопротивление.", "Your beard was the only thing that put up a fight."],
			["Берегите свою землю, богатырь. Я свою не уберёг.", "Guard your land, hero. I failed to guard mine."],
		],
		"dracula": [
			["Двум графам в одном замке тесно.", "One castle is too small for two counts."],
		],
	},
	"hercules": {
		"koschei": [["Вставай, костлявый. Смерть свою найдёшь — приходи, вместе поищем покой.",
			"Get up, bony. When you find your death, come — we'll look for peace together."]],
	},
	"koschei": {
		"hercules": [["Сильный… А вину свою так и не поднял. Тяжелее палицы, а?",
			"Strong… Yet you never lifted your guilt. Heavier than a club, eh?"]],
	},
	"athena": {
		"medusa": [["Ты права. Я виновата. Но я не могу позволить тебе мстить миру.",
			"You are right. I am to blame. But I cannot let you take revenge on the world."]],
	},
	"medusa": {
		"athena": [["Теперь ты знаешь, каково это — проиграть ни за что.",
			"Now you know what it's like to lose for nothing."]],
	},
	"anubis": {
		"sunwukong": [["Твоё имя снова в книге. Не бойся — до твоей страницы ещё далеко.",
			"Your name is back in the book. Fear not — your page is still far off."]],
	},
	"sunwukong": {
		"anubis": [["Передай весам: Царь обезьян ещё погуляет!", "Tell your scales: the Monkey King isn't done playing!"]],
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
		var out_g := []
		for id in [a, b]:
			if GENERIC_INTRO.has(id):
				out_g.append([id, GENERIC_INTRO[id][0] if Loc.lang == "ru" else GENERIC_INTRO[id][1]])
		return out_g
	var out := []
	for line in _pick(variants, seed_value):
		out.append([line[0], line[1] if Loc.lang == "ru" else line[2]])
	return out


## Победная реплика или "".
static func win(winner: String, loser: String, seed_value: int) -> String:
	var lines: Array = WIN.get(winner, {}).get(loser, [])
	if lines.is_empty():
		if not GENERIC_WIN.has(winner):
			return ""
		lines = [GENERIC_WIN[winner]]
	var q: Array = _pick(lines, seed_value)
	return q[0] if Loc.lang == "ru" else q[1]
