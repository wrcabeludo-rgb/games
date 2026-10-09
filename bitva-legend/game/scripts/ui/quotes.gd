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
	# Финал: Аватар (цифровой Саша) и Скроллер против каждого героя.
	"avatar|ilya": [
		[["avatar", "Отстань, дед. У меня видос не досмотрен.",
			"Leave me alone, old man. My video isn't finished."],
		["ilya", "Эх, Сашка… Я тридцать три года на печи сиднем сидел — знаю, каково это. Вставай!",
			"Oh, Sasha… I sat on a stove for thirty-three years — I know how it feels. Get up!"]],
	],
	"avatar|dracula": [
		[["avatar", "Ты кто? А, вампир. Видел тебя в рилсе. Скучно.",
			"Who are you? Oh, the vampire. Saw you in a reel. Boring."],
		["dracula", "Я пятьсот лет не видел своего отражения. А ты смотришь в своё — и не узнаёшь себя.",
			"I haven't seen my reflection in five hundred years. You stare at yours — and don't recognise yourself."]],
	],
	"avatar|koschei": [
		[["avatar", "Можно я тут навсегда останусь? Тут ничего не болит.",
			"Can I just stay here forever? Nothing hurts here."],
		["koschei", "Я тоже так думал. Тысячу лет назад. Не повторяй моей ошибки.",
			"I thought so too. A thousand years ago. Don't repeat my mistake."]],
	],
	"avatar|hercules": [
		[["avatar", "Двенадцать подвигов? Я за вечер двенадцать уровней прошёл.",
			"Twelve labours? I beat twelve levels in one evening."],
		["hercules", "А я свои — двенадцать лет. Поэтому и помню каждый.",
			"Mine took twelve years. That's why I remember every one."]],
	],
	"athena|avatar": [
		[["avatar", "Зачем читать, если есть краткий пересказ за минуту?",
			"Why read when there's a one-minute summary?"],
		["athena", "Пересказ даёт ответы. Книга учит задавать вопросы.",
			"A summary gives answers. A book teaches you to ask questions."]],
	],
	"avatar|medusa": [
		[["avatar", "Не смотри на меня. Я в телефоне.",
			"Don't look at me. I'm on my phone."],
		["medusa", "Вот так и каменеют, мальчик. Не от моего взгляда — от своего.",
			"That's how people turn to stone, boy. Not from my gaze — from their own."]],
	],
	"avatar|sunwukong": [
		[["avatar", "Семьдесят два превращения? У меня сто скинов.",
			"Seventy-two transformations? I've got a hundred skins."],
		["sunwukong", "Скин меняет одёжку, а я меняю себя! Давай, догоняй!",
			"A skin changes your clothes — I change myself! Come on, keep up!"]],
	],
	"anubis|avatar": [
		[["avatar", "Тут никто не умирает. Тут просто листают.",
			"Nobody dies here. They just scroll."],
		["anubis", "Поэтому тут никто и не живёт.",
			"That is why nobody lives here either."]],
	],
	"ilya|scroller": [
		[["scroller", "НОВЫЙ ИВЕНТ! Илья Муромец против… меня! Ставьте лайки, не переключайтесь!",
			"NEW EVENT! Ilya Muromets versus… me! Smash that like, don't switch!"],
		["ilya", "Так это ты нитки дёргаешь? Ну, сейчас я их посрываю.",
			"So you're the one pulling the strings? Well, I'll tear them off."]],
	],
	"dracula|scroller": [
		[["scroller", "Граф! Ты мой самый популярный персонаж. Подпишешь контракт навечно?",
			"Count! You're my most popular character. Sign a contract — forever?"],
		["dracula", "Я уже подписал один договор навечно. Больше не подписываю.",
			"I have already signed one contract for eternity. I sign no more."]],
	],
	"koschei|scroller": [
		[["scroller", "Кощеюшка, мы с тобой похожи: оба бессмертные, оба никуда не выходим.",
			"Koschei, old pal, we're alike: both deathless, both never go outside."],
		["koschei", "Я хотя бы чахну над златом. А ты — над крошками от чипсов.",
			"At least I waste away over gold. You — over chip crumbs."]],
	],
	"hercules|scroller": [
		[["scroller", "Тринадцатый подвиг — пройти меня! Донаты приветствуются.",
			"Labour thirteen — beat me! Donations welcome."],
		["hercules", "Я вычистил Авгиевы конюшни. Твою берлогу тоже вычищу.",
			"I cleaned the Augean stables. I'll clean out your den too."]],
	],
	"athena|scroller": [
		[["scroller", "Богиня мудрости! Лайкни мой стрим, а?",
			"Goddess of wisdom! Like my stream, yeah?"],
		["athena", "Мудрость — это знать, когда выключить.",
			"Wisdom is knowing when to switch it off."]],
	],
	"medusa|scroller": [
		[["scroller", "Медуза! На тебя смотрят миллионы! Ну скажи, приятно?",
			"Medusa! Millions are watching you! Feels good, right?"],
		["medusa", "Миллионы смотрят — никто не видит. Я знаю разницу.",
			"Millions watch — nobody sees. I know the difference."]],
	],
	"scroller|sunwukong": [
		[["scroller", "Царь обезьян! Ты же любишь веселье — оставайся тут навсегда!",
			"Monkey King! You love fun — stay here forever!"],
		["sunwukong", "Я пятьсот лет просидел под горой. Хватит с меня клеток — даже весёлых.",
			"I spent five hundred years under a mountain. No more cages — not even fun ones."]],
	],
	"anubis|scroller": [
		[["scroller", "Тут у меня никто не умирает, пёсик. Вечный контент.",
			"Nobody dies in here, doggy. Eternal content."],
		["anubis", "Вечный — значит, мёртвый. Весы ждут.",
			"Eternal means dead. The scales are waiting."]],
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
	"avatar": ["Подожди, щас досмотрю…", "Hang on, almost done watching…"],
	"scroller": ["НОВЫЙ ИВЕНТ! Не переключайтесь!", "NEW EVENT! Don't switch!"],
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
	"avatar": ["Ещё одно видео — и спать. Честно.", "One more video and then bed. Honest."],
	"scroller": ["Ну вот. Ещё одну катку? Ещё одну… навсегда.", "There. One more match? One more… forever."],
}

## Победа: победитель → проигравший → варианты [ru, en].
const WIN := {
	"ilya": {
		"avatar": [["Вставай, Сашка. Ты ж богатырь, а не лежебока.", "Up you get, Sasha. You're a bogatyr, not a couch potato."]],
		"scroller": [["Всё, кукольник. Нитки кончились.", "That's it, puppeteer. You're out of string."]],
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
		"avatar": [["Посмотри в зеркало, юноша. Видишь? Это ты. Не потеряй его.", "Look in the mirror, young man. See? That's you. Don't lose him."]],
		"scroller": [["Твоя публика разошлась, хозяин. Даже я знаю, когда уйти со сцены.", "Your audience has left, host. Even I know when to leave the stage."]],
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
		"avatar": [["Тринадцатый подвиг — вернуть мальчика домой. Беру.", "Labour thirteen: bring the boy home. I'll take it."]],
		"scroller": [["Берлога вычищена. Окна открыть, крошки вымести.", "The den is clean. Open the windows, sweep the crumbs."]],
		"koschei": [["Вставай, костлявый. Смерть свою найдёшь — приходи, вместе поищем покой.",
			"Get up, bony. When you find your death, come — we'll look for peace together."]],
	},
	"koschei": {
		"avatar": [["Больно? Хорошо. Значит, живой.", "Does it hurt? Good. That means you're alive."]],
		"scroller": [["Смерть моя в игле, а твоя — в розетке. Выдернул.", "My death is in a needle — yours is in a socket. Unplugged."]],
		"hercules": [["Сильный… А вину свою так и не поднял. Тяжелее палицы, а?",
			"Strong… Yet you never lifted your guilt. Heavier than a club, eh?"]],
	},
	"athena": {
		"avatar": [["Вопрос был не «что посмотреть», а «кем стать».", "The question was never 'what to watch', but 'who to become'."]],
		"scroller": [["Выключено.", "Switched off."]],
		"medusa": [["Ты права. Я виновата. Но я не могу позволить тебе мстить миру.",
			"You are right. I am to blame. But I cannot let you take revenge on the world."]],
	},
	"medusa": {
		"avatar": [["Посмотри на меня. Видишь — не окаменел. Значит, ещё не поздно.", "Look at me. See — you didn't turn to stone. It's not too late."]],
		"scroller": [["Посмотри мне в глаза. А, у тебя нет глаз. Только экран.", "Look me in the eye. Ah, you have no eyes. Only a screen."]],
		"athena": [["Теперь ты знаешь, каково это — проиграть ни за что.",
			"Now you know what it's like to lose for nothing."]],
	},
	"anubis": {
		"avatar": [["Сердце бьётся. Значит, твоя страница ещё не дописана.", "Your heart is beating. Your page is not finished yet."]],
		"scroller": [["На весах — пусто. Приговор: выключить.", "The scale holds nothing. Verdict: switch off."]],
		"sunwukong": [["Твоё имя снова в книге. Не бойся — до твоей страницы ещё далеко.",
			"Your name is back in the book. Fear not — your page is still far off."]],
	},
	"sunwukong": {
		"avatar": [["Ха! Догнал! А теперь — бегом из этой клетки!", "Ha! Caught you! Now — run out of this cage!"]],
		"scroller": [["Ивент окончен! Награда — свобода!", "Event over! The reward is freedom!"]],
		"anubis": [["Передай весам: Царь обезьян ещё погуляет!", "Tell your scales: the Monkey King isn't done playing!"]],
	},
}

## Ответ проигравшего — только пары-соперники и зеркальные бои: проигравший → победитель → варианты [ru, en].
## Вариант выбирается тем же зерном, что и победная реплика, поэтому отвечает именно на неё:
## число вариантов совпадает с WIN[победитель][проигравший].
const LOSE := {
	"avatar": {
		"ilya": [["…Дед, а чем там у тебя с Соловьём-разбойником кончилось?", "…Grandpa, how did it end with the Nightingale Robber?"]],
		"dracula": [["…А в зеркале правда я?", "…Is that really me in the mirror?"]],
		"koschei": [["…Ай. Больно. Это… хорошо?", "…Ow. That hurts. Is that… good?"]],
		"hercules": [["…А можно я сам свою комнату уберу?", "…Can I tidy my room myself?"]],
		"athena": [["…А можно вопрос?", "…Can I ask a question?"]],
		"medusa": [["…Не окаменел. Значит, можно смотреть по-настоящему.", "…I didn't turn to stone. So I can really look."]],
		"sunwukong": [["…Ладно. Кто последний до выхода — тот нуб!", "…Fine. Last one to the exit is a noob!"]],
		"anubis": [["…Значит, я ещё не дочитан.", "…So my story isn't finished yet."]],
	},
	"scroller": {
		"ilya": [["Э-эй… кто выключил стрим?..", "He-ey… who turned off the stream?.."]],
		"dracula": [["Не уходите… щас самое интересное…", "Don't go… the best part is coming…"]],
		"koschei": [["Розетка… моя розетка…", "My socket… my socket…"]],
		"hercules": [["Мои подписчики… где мои подписчики?..", "My followers… where are my followers?.."]],
		"athena": [["Звук… выключен…", "Sound… muted…"]],
		"medusa": [["Нет сигнала… нет… сигнала…", "No signal… no… signal…"]],
		"sunwukong": [["Ивент… отменён…", "Event… cancelled…"]],
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
