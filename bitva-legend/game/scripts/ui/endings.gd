class_name Endings
extends RefCounted
## Эпилоги аркады: что победитель загадал у камня и что из этого вышло (docs/LORE.md).
## Каждый абзац — [русский, английский]. Тон: история всерьёз, но с улыбкой.

const ENDINGS := {
	"ilya": [
		["Камень заговорил голосом калик перехожих: «Чего желаешь, богатырь?» Илья почесал бороду. Себе ему было ничего не надо.",
			"The stone spoke in the voice of the wandering pilgrims: \"What do you wish for, hero?\" Ilya scratched his beard. He wanted nothing for himself."],
		["«Чтоб каждый, кто дошёл до тебя, домой вернулся. Хоть бы и чудище». Камень помолчал — и согласился.",
			"\"That everyone who reached you gets to go home. Even the monsters.\" The stone was silent for a while — then agreed."],
		["Говорят, в ту ночь над Валахией впервые за пятьсот лет зажглись окна старого замка. А Илья пошёл на Русь — пешком, не торопясь. Спрашивать он теперь начинал раньше, чем бить.",
			"They say that night, for the first time in five hundred years, the windows of an old castle in Wallachia were lit. Ilya walked home to Rus, unhurried. These days he asked questions before he swung."],
	],
	"dracula": [
		["«Домой», — сказал Дракула. Камень показал ему Валахию: реки, холмы, дым над деревнями — всё как тогда.",
			"\"Home,\" said Dracula. The stone showed him Wallachia: the rivers, the hills, smoke over the villages — all as it once was."],
		["«Вернуться можно, князь. Но там ты будешь человеком. Смертным». Дракула долго смотрел на свою бледную руку.",
			"\"You may return, prince. But there you will be a man. Mortal.\" Dracula looked at his pale hand for a long time."],
		["Утром крестьяне видели на холме всадника в чёрном плаще. Он встречал рассвет — и впервые за пятьсот лет не отвёл глаз.",
			"In the morning the peasants saw a rider in a black cloak on the hill. He was watching the sunrise — and for the first time in five hundred years he did not look away."],
	],
	"koschei": [
		["«Верни мне смерть», — проскрипел Кощей. Камень вздохнул, и на ладонь ему упала тонкая игла.",
			"\"Give me back my death,\" Koschei creaked. The stone sighed, and a thin needle fell into his palm."],
		["И сразу всё навалилось: холод ветра, запах хлеба из далёкой деревни, щекотка травы. Кощей сел на землю и засмеялся — хрипло, как несмазанная дверь.",
			"And everything came at once: the cold wind, the smell of bread from a distant village, the tickle of grass. Koschei sat down on the ground and laughed — hoarsely, like an unoiled door."],
		["Иглу он спрятал в карман. «Пусть полежит. Торопиться-то теперь есть куда — жить».",
			"He put the needle in his pocket. \"Let it wait. I have somewhere to hurry now — to living.\""],
	],
	"hercules": [
		["«Пусть прошлое меня отпустит», — сказал Геракл. Камень ответил: «Такого желания нет. Прошлое не отпускает — его отпускают сами».",
			"\"Let the past let me go,\" said Hercules. The stone replied: \"There is no such wish. The past does not let go — you let go of it.\""],
		["Геракл долго стоял молча. Потом положил дубину на землю — впервые с тех пор, как взял её в руки.",
			"Hercules stood silent for a long time. Then he laid his club on the ground — for the first time since he had first picked it up."],
		["Тринадцатый подвиг оказался самым трудным: просто сесть у дороги и отдохнуть. Он справился. Не сразу, но справился.",
			"The thirteenth labour turned out to be the hardest: simply to sit by the road and rest. He managed it. Not at once — but he managed."],
	],
	"athena": [
		["Афина пришла за порядком. Но у камня, вместо слов о мире между мифами, она сказала другое.",
			"Athena had come for order. But at the stone, instead of words about peace between the myths, she said something else."],
		["«Сними проклятие с Медузы. Виновата была я». Змеи на голове Горгоны стали волосами, а камень в её взгляде — просто взглядом.",
			"\"Lift the curse from Medusa. The fault was mine.\" The snakes on the Gorgon's head became hair, and the stone in her gaze became just a gaze."],
		["Мудрость, как выяснилось, — это не знать ответы. Это признать ошибку раньше, чем тебя заставят.",
			"Wisdom, it turned out, is not knowing the answers. It is admitting your mistake before you are made to."],
	],
	"medusa": [
		["«Посмотри мне в глаза», — сказала Медуза камню. Камень посмотрел. Камню, в общем-то, всё равно.",
			"\"Look me in the eye,\" Medusa told the stone. The stone looked. Stones, frankly, don't mind."],
		["«Тогда пусть взгляд слушается меня, а не проклятия». И когда на перекрёсток пришла Афина, Медуза не отвела глаз — и та не окаменела.",
			"\"Then let my gaze obey me, not the curse.\" And when Athena came to the crossroads, Medusa did not look away — and the goddess did not turn to stone."],
		["Они долго смотрели друг на друга. Впервые за тысячи лет на Медузу смотрели — и она смотрела в ответ.",
			"They looked at each other for a long time. For the first time in thousands of years someone looked at Medusa — and she looked back."],
	],
	"sunwukong": [
		["«Желание? Ха! У меня всё есть», — сказал Сунь Укун. Но камень молчал так выразительно, что Царь обезьян смутился.",
			"\"A wish? Ha! I've got everything,\" said Sun Wukong. But the stone was silent so pointedly that the Monkey King felt embarrassed."],
		["Тогда он сам вписал своё имя обратно в Книгу жизни и смерти. Мелкими буквами. На самой последней странице.",
			"So he wrote his name back into the Book of Life and Death himself. In tiny letters. On the very last page."],
		["Анубис, увидев запись, только покачал головой: «Честно». А Укун уже вызывал камень на бег наперегонки.",
			"Anubis saw the entry and just shook his head: \"Fair.\" Wukong was already challenging the stone to a race."],
	],
	"anubis": [
		["Равновесие восстановлено: имя Сунь Укуна снова в книге. Анубису нечего было желать — он пришёл по работе.",
			"Balance is restored: Sun Wukong's name is back in the book. Anubis had nothing to wish for — he came here for work."],
		["Но камень спросил сам: «А твоё сердце кто-нибудь взвешивал?» И положил на весы перо истины и сердце того, кто тысячи лет взвешивал чужие.",
			"But the stone asked: \"And has anyone ever weighed your heart?\" And it placed on the scales the feather of truth and the heart of the one who had weighed others for thousands of years."],
		["Чаши замерли ровно. Анубис кивнул, поправил весы и пошёл обратно. Работа есть работа.",
			"The pans came to rest, perfectly level. Anubis nodded, straightened his scales and went back. Work is work."],
	],
}


## Абзацы эпилога на текущем языке.
static func lines(id: String) -> Array[String]:
	var out: Array[String] = []
	for row in ENDINGS.get(id, []):
		out.append(row[0] if Loc.lang == "ru" else row[1])
	return out
