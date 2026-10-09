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
	# Лента против каждого героя.
	"ilya|lenta": [
		[["lenta", "ТЫ НЕ ПОВЕРИШЬ, что случилось с Ильёй Муромцем дальше! Досмотри до конца!",
			"YOU WON'T BELIEVE what happened to Ilya Muromets next! Watch till the end!"],
		["ilya", "Это ты, что ли, внуков моих от сказок отвадила? Ну, держись, балаболка.",
			"So you're the one who stole my grandchildren's bedtime tales? Brace yourself, chatterbox."]],
	],
	"dracula|lenta": [
		[["lenta", "Граф! Вампиры снова в тренде. Пятнадцать секунд славы — и в следующий ролик.",
			"Count! Vampires are trending again. Fifteen seconds of fame — then on to the next clip."],
		["dracula", "Я пятьсот лет пью чужие жизни. Но даже я не пью их, не распробовав.",
			"I have drunk lives for five hundred years. But even I never drank one without tasting it."]],
	],
	"koschei|lenta": [
		[["lenta", "Бессмертный и пустой. Мы с тобой — одно и то же, дедушка. Подпишись на меня.",
			"Deathless and empty. You and I are the same, old man. Subscribe to me."],
		["koschei", "Потому и бью. Смотреть на тебя — как в зеркало, а я своё отражение ненавижу.",
			"That's why I'll strike. Looking at you is like a mirror — and I hate my reflection."]],
	],
	"hercules|lenta": [
		[["lenta", "«12 самых эпичных подвигов Геракла»! Без скучных подробностей, без вины — только хайлайты!",
			"\"Hercules' 12 most epic labours\"! No boring details, no guilt — just highlights!"],
		["hercules", "Скучные подробности — это и есть моя жизнь. Тринадцатым подвигом будешь ты.",
			"The boring details ARE my life. You'll be my thirteenth labour."]],
	],
	"athena|lenta": [
		[["lenta", "Богиня мудрости! Сколько лайков стоит мудрость? Давай проверим.",
			"The goddess of wisdom! How many likes is wisdom worth? Let's find out."],
		["athena", "Мудрость не измеряют. Её слушают. Тебе этого не понять — ты не умеешь молчать.",
			"Wisdom isn't measured. It's listened to. You wouldn't understand — you can't be silent."]],
	],
	"lenta|medusa": [
		[["lenta", "Медуза! «Монстр, которого убил Персей» — восемь миллионов просмотров! Повторим?",
			"Medusa! \"The monster Perseus slew\" — eight million views! Shall we run it again?"],
		["medusa", "Ты рассказала мою историю миллион раз — и ни разу правильно. Посмотри мне в глаза.",
			"You've told my story a million times — and never once right. Look me in the eye."]],
	],
	"lenta|sunwukong": [
		[["lenta", "Царь обезьян! На тебя смотрят все! Хочешь, будешь смотреть только ты — вечно?",
			"Monkey King! Everyone's watching you! Want to be the only thing they ever watch — forever?"],
		["sunwukong", "Ха! Я на облаке облетал всю Поднебесную. А ты — пятнадцать секунд и свайп. Скука!",
			"Ha! I've circled the whole world on a cloud. You're fifteen seconds and a swipe. Boring!"]],
	],
	"anubis|lenta": [
		[["lenta", "Проводник мёртвых! У меня никто не умирает — истории просто листаются. Удобно, правда?",
			"Guide of the dead! Nothing dies with me — stories just scroll by. Convenient, isn't it?"],
		["anubis", "Ни жизни, ни смерти. Ты нарушаешь равновесие сильнее, чем Царь обезьян. Весы ждут.",
			"Neither life nor death. You break the balance worse than the Monkey King. The scales are waiting."]],
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
	"lenta": ["Новый контент! Пятнадцать секунд — и ты в тренде. Не переключайся!",
		"New content! Fifteen seconds and you're trending. Don't switch!"],
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
	"lenta": ["Следующее видео через три… два… один…", "Next video in three… two… one…"],
}

## Победа: победитель → проигравший → варианты [ru, en].
const WIN := {
	"ilya": {
		"lenta": [["Вот так-то. А теперь — сказку. С начала и до конца.", "There. Now — a story. From the beginning to the end."]],
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
		"lenta": [["Безвкусно. Совершенно безвкусно.", "Tasteless. Utterly tasteless."]],
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
		"lenta": [["Тринадцатый. Этот я расскажу целиком.", "The thirteenth. This one I'll tell in full."]],
		"koschei": [["Вставай, костлявый. Смерть свою найдёшь — приходи, вместе поищем покой.",
			"Get up, bony. When you find your death, come — we'll look for peace together."]],
	},
	"koschei": {
		"lenta": [["Погасла. А я — нет. Странно: впервые этому рад.", "It went dark. I didn't. Strange — for once I'm glad."]],
		"hercules": [["Сильный… А вину свою так и не поднял. Тяжелее палицы, а?",
			"Strong… Yet you never lifted your guilt. Heavier than a club, eh?"]],
	},
	"athena": {
		"lenta": [["Тишина. Вот теперь можно думать.", "Silence. Now we can think."]],
		"medusa": [["Ты права. Я виновата. Но я не могу позволить тебе мстить миру.",
			"You are right. I am to blame. But I cannot let you take revenge on the world."]],
	},
	"medusa": {
		"lenta": [["Окаменела. Красивая статуя. Первая, которую не жалко.", "Turned to stone. A fine statue. The first one I don't regret."]],
		"athena": [["Теперь ты знаешь, каково это — проиграть ни за что.",
			"Now you know what it's like to lose for nothing."]],
	},
	"anubis": {
		"lenta": [["Сердца не нашлось. Приговор вынесен.", "No heart was found. The verdict is given."]],
		"sunwukong": [["Твоё имя снова в книге. Не бойся — до твоей страницы ещё далеко.",
			"Your name is back in the book. Fear not — your page is still far off."]],
	},
	"sunwukong": {
		"lenta": [["Пролистал! Свайп влево, Лента!", "Scrolled past! Swipe left, Feed!"]],
		"anubis": [["Передай весам: Царь обезьян ещё погуляет!", "Tell your scales: the Monkey King isn't done playing!"]],
	},
}

## Ответ проигравшего — только пары-соперники и зеркальные бои: проигравший → победитель → варианты [ru, en].
## Вариант выбирается тем же зерном, что и победная реплика, поэтому отвечает именно на неё:
## число вариантов совпадает с WIN[победитель][проигравший].
const LOSE := {
	"lenta": {
		"ilya": [["Это видео больше недоступно…", "This video is no longer available…"]],
		"dracula": [["Ошибка воспроизведения. Повторите попытку…", "Playback error. Please try again…"]],
		"koschei": [["Нет подключения. Нет… подключения…", "No connection. No… connection…"]],
		"hercules": [["Ролик удалён по жалобе героя…", "Video removed after a hero's complaint…"]],
		"athena": [["Звук… выключен…", "Sound… muted…"]],
		"medusa": [["Буферизация… буфериза…", "Buffering… buffer…"]],
		"sunwukong": [["Вы смотрели это видео 72 раза. Продолжить?..", "You've watched this video 72 times. Continue?.."]],
		"anubis": [["Аккаунт… удалён…", "Account… deleted…"]],
	},
	"dracula": {
		"ilya": [
			["Чеснок? Как банально. Я ждал от вас большего, богатырь.", "Garlic? How banal. I expected more of you, hero."],
			["Гроб хотя бы не разговаривает. Идите уже.", "At least a coffin doesn't talk. Just go."],
			["На той стороне… Князь, у которого нет земли, стоит там, где ему оставили место.",
				"The wrong side… A prince without a land stands where he's left room to stand."],
		],
		"dracula": [["Ничего. У меня есть ещё четыреста лет на реванш.", "No matter. I have four hundred more years for a rematch."]],
	},
	"ilya": {
		"dracula": [
			["Медовуха… Эх, сейчас бы ковшик. Только не с тобой, кровопийца.", "Mead… Could use a mug right now. Just not with you, bloodsucker."],
			["Борода ещё отрастёт. А вот ты ко мне ещё придёшь — увидишь.", "The beard will grow back. And you'll be back for more — you'll see."],
			["Сберегу, княже. И за тебя тоже.", "I will, prince. For you too."],
		],
		"ilya": [["Ладно… Пусть земля держит. Я полежу.", "Fine… Let the land hold you. I'll just lie here."]],
	},
	"koschei": {
		"hercules": [["Покой… Ты так говоришь, будто он где-то есть.", "Peace… You say it as if it exists somewhere."]],
	},
	"hercules": {
		"koschei": [["Тяжелее. Но я её хотя бы несу, а не прячу в яйце.", "Heavier. But at least I carry mine, not hide it in an egg."]],
	},
	"medusa": {
		"athena": [["«Виновата». Тысячи лет я ждала этого слова. Повтори.", "'To blame.' I waited thousands of years for that word. Say it again."]],
	},
	"athena": {
		"medusa": [["Знаю. Теперь — знаю.", "I know. Now — I know."]],
	},
	"sunwukong": {
		"anubis": [["Далеко — это сколько? Я быстро бегаю!", "How far is far? I run fast!"]],
	},
	"anubis": {
		"sunwukong": [["Передам. Весы терпеливы. Я — тоже.", "I will. The scales are patient. So am I."]],
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


## Ответ проигравшего на победную реплику или "".
static func lose(loser: String, winner: String, seed_value: int) -> String:
	var lines: Array = LOSE.get(loser, {}).get(winner, [])
	if lines.is_empty():
		return ""
	var q: Array = _pick(lines, seed_value)
	return q[0] if Loc.lang == "ru" else q[1]
