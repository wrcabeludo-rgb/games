class_name Endings
extends RefCounted
## Эпилоги аркады: боец одолел Ленту — что стало с ним и с его историей (docs/LORE.md).
## Три абзаца: как пала Лента · что боец сделал со своей легендой · кто в нашем мире снова её рассказывает.
## Каждый абзац — [русский, английский]. Тон: история всерьёз, но с улыбкой.

const ENDINGS := {
	"ilya": [
		["Лента сулила Илье «миллион просмотров». Илья не знал, что это, и на всякий случай дал ей палицей. Экраны посыпались, как щепки с печи.",
			"The Feed promised Ilya \"a million views\". Ilya didn't know what that was, so just in case he hit it with his mace. The screens fell apart like kindling."],
		["Себе он ничего не попросил. Только чтоб каждый, кто дрался на швах, вернулся домой — хоть бы и чудище. Говорят, в ту ночь над Валахией зажглись окна старого замка.",
			"He asked nothing for himself. Only that everyone who fought on the seams got to go home — even the monsters. They say that night the windows of an old castle in Wallachia were lit again."],
		["А в нашем мире дед отложил телефон и сказал внуку: «Слушай. Жил-был в Муроме Илья…» Внук дослушал до конца.",
			"And in our world a grandfather put down his phone and said to his grandson: \"Listen. Once, in Murom, there lived a man called Ilya…\" The boy listened to the very end."],
	],
	"dracula": [
		["«Пятьсот лет я питаюсь чужими жизнями, — сказал граф Ленте. — Но даже я знаю меру». И выпил её досуха — до последнего пикселя.",
			"\"For five hundred years I have fed on the lives of others,\" the Count told the Feed. \"But even I know when to stop.\" And he drained it dry — to the last pixel."],
		["Швы закрылись, и Валахия снова стала целой: реки, холмы, дым над деревнями. Можно вернуться — но человеком. Смертным. Дракула долго смотрел на свою бледную руку.",
			"The seams closed and Wallachia was whole again: rivers, hills, smoke over the villages. He could return — but as a man. Mortal. Dracula looked at his pale hand for a long time."],
		["Утром на холме видели всадника в чёрном плаще: он встречал рассвет и не отводил глаз. А в нашем мире кто-то впервые прочёл «Дракулу» не в пересказе — целиком.",
			"In the morning a rider in a black cloak was seen on the hill, facing the sunrise without looking away. And in our world someone read \"Dracula\" for the first time — not a summary, the whole thing."],
	],
	"koschei": [
		["Лента была как он сам: бессмертная и пустая. Кощей бил её и узнавал себя — и потому бил без жалости.",
			"The Feed was just like him: deathless and empty. Koschei struck it and recognised himself — and so he showed no mercy."],
		["Когда последний экран погас, на ладонь ему упала тонкая игла. Смерть вернулась — а с ней холод ветра, запах хлеба, щекотка травы. Кощей сел на землю и засмеялся, хрипло, как несмазанная дверь.",
			"When the last screen went dark, a thin needle fell into his palm. His death was back — and with it the cold wind, the smell of bread, the tickle of grass. Koschei sat down and laughed, hoarsely, like an unoiled door."],
		["Иглу он спрятал в карман: «Пусть полежит. Мне теперь есть куда торопиться — жить». А в нашем мире мама дочитала дочке сказку про Кощея, и дочка спросила: «А ему было грустно?»",
			"He pocketed the needle: \"Let it wait. I've somewhere to hurry now — to living.\" And in our world a mother finished reading the tale of Koschei, and her daughter asked: \"Was he sad?\""],
	],
	"hercules": [
		["Лента нарезала его жизнь на «12 самых эпичных моментов». Геракл вырвал её из земли, как когда-то Антея, — и держал, пока она не замолчала.",
			"The Feed had cut his life into \"12 most epic moments\". Hercules tore it from the ground, as he once did Antaeus, and held on until it fell silent."],
		["Потом он рассказал свою историю целиком — с безумием, с виной, с тем, за что платил. Это было тяжелее любого подвига. Он положил дубину на землю — впервые с тех пор, как взял её в руки.",
			"Then he told his story whole — the madness, the guilt, the debt he paid. It was harder than any labour. He laid his club on the ground — for the first time since he had first picked it up."],
		["Тринадцатый подвиг — просто сесть у дороги и отдохнуть. А в нашем мире школьник, которому задали «прочитать про Геракла», прочитал. И не про подвиги — про человека.",
			"The thirteenth labour: simply to sit by the road and rest. And in our world a schoolboy told to \"read about Hercules\" actually did. Not about the labours — about the man."],
	],
	"athena": [
		["Лента думала, что богиню мудрости можно утопить в шуме. Афина просто выключила звук — и в тишине Ленте нечем было жить.",
			"The Feed thought the goddess of wisdom could be drowned in noise. Athena simply turned the sound off — and in the silence the Feed had nothing to live on."],
		["Порядок вернулся. Но первое, что сделала Афина, — пошла на остров Горгон и сказала: «Виновата была я». Змеи на голове Медузы стали волосами, а камень в её взгляде — просто взглядом.",
			"Order returned. But the first thing Athena did was go to the Gorgons' isle and say: \"The fault was mine.\" The snakes on Medusa's head became hair, and the stone in her gaze became just a gaze."],
		["Мудрость — это признать ошибку раньше, чем тебя заставят. А в нашем мире кто-то закрыл «10 фактов об Афине» и открыл Гомера.",
			"Wisdom is admitting your mistake before you are made to. And in our world someone closed \"10 facts about Athena\" and opened Homer."],
	],
	"medusa": [
		["Лента смотрела на всех сразу — миллионом экранов. Медуза посмотрела на неё в ответ. Лента окаменела вся, до последнего ролика.",
			"The Feed watched everyone at once through a million screens. Medusa looked back. The Feed turned to stone, every last clip."],
		["Теперь её взгляд слушается её, а не проклятия. И когда на берег пришла Афина, Медуза не отвела глаз — и та не окаменела. Они долго смотрели друг на друга.",
			"Now her gaze obeys her, not the curse. And when Athena came to the shore, Medusa did not look away — and the goddess did not turn to stone. They looked at each other for a long time."],
		["А в нашем мире вышла книга «Медуза. Её версия». Её дочитали до конца.",
			"And in our world a book came out: \"Medusa. Her Side of the Story\". People read it to the end."],
	],
	"sunwukong": [
		["Лента обещала Царю обезьян вечную славу — все смотрят только на него! Укун семьдесят два раза превратился в Ленту, и она запуталась, какая из них настоящая. Так и сломалась.",
			"The Feed promised the Monkey King eternal fame — everyone watching only him! Wukong turned into the Feed seventy-two times, and it lost track of which one was real. That's how it broke."],
		["Слава оказалась скучной: пятнадцать секунд — и тебя уже пролистали. Укун сам вписал своё имя обратно в Книгу жизни и смерти. Мелкими буквами. На самой последней странице. Анубис только кивнул: «Честно».",
			"Fame turned out to be boring: fifteen seconds and you're scrolled past. Wukong wrote his name back into the Book of Life and Death himself. In tiny letters. On the very last page. Anubis just nodded: \"Fair.\""],
		["А в нашем мире кто-то наконец открыл «Путешествие на Запад». Сто глав. Дочитал до тридцатой и не может остановиться.",
			"And in our world someone finally opened \"Journey to the West\". A hundred chapters. Thirty in, they can't put it down."],
	],
	"anubis": [
		["Анубис положил на весы перо истины и сердце Ленты. Сердца у неё не нашлось — только счётчик просмотров. Весы рассудили сами.",
			"Anubis placed the feather of truth on the scales, and the heart of the Feed. It had no heart — only a view counter. The scales decided on their own."],
		["Равновесие восстановлено: истории снова могут жить и снова могут кончаться. А потом камень Межмирья спросил: «А твоё сердце кто-нибудь взвешивал?» Чаши замерли ровно.",
			"Balance is restored: stories can live again, and can end again. Then a voice of the in-between asked: \"And has anyone ever weighed your heart?\" The pans came to rest, perfectly level."],
		["Анубис поправил весы и пошёл обратно. Работа есть работа. А в нашем мире в музее мальчик остановился у статуи с головой шакала и спросил у мамы: «А кто это?» И она рассказала.",
			"Anubis straightened his scales and went back. Work is work. And in our world, in a museum, a boy stopped before a jackal-headed statue and asked his mother: \"Who's that?\" And she told him."],
	],
}


## Абзацы эпилога на текущем языке.
static func lines(id: String) -> Array[String]:
	var out: Array[String] = []
	for row in ENDINGS.get(id, []):
		out.append(row[0] if Loc.lang == "ru" else row[1])
	return out
