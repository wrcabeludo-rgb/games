class_name Endings
extends RefCounted
## Эпилоги аркады (docs/LORE.md): Саша в облике героя победил Скроллера и порвал последнюю нить.
## Три абзаца: как пал Скроллер · что герой сказал Саше на прощание · утро, Саша с книгой.
## Каждый абзац — [русский, английский]. Тон: история всерьёз, но с улыбкой.

const ENDINGS := {
	"ilya": [
		["Илья сгрёб все нити в кулак и дёрнул. Скроллер шлёпнулся на пол среди коробок из-под пиццы, а смайлик на его экране сменился на «😶».",
			"Ilya gathered every string in his fist and pulled. The Scroller flopped down among the pizza boxes, and the smiley on his screen turned to \"😶\"."],
		["«Я тридцать три года на печи просидел, Сашка, — сказал богатырь. — Встать — самое трудное. Дальше — проще». И хлопнул его по плечу так, что тот чуть не сел.",
			"\"I sat on that stove for thirty-three years, Sasha,\" said the hero. \"Getting up is the hardest part. After that it gets easier.\" And he clapped him on the shoulder so hard the boy nearly sat down."],
		["Саша проснулся за столом, щекой на книге. Телефон погас. Он перевернул страницу: «Поехал Илья во чистое поле…» — и читал, пока мама не позвала завтракать.",
			"Sasha woke up at his desk, his cheek on the book. The phone had gone dark. He turned the page — \"And Ilya rode out into the open field…\" — and kept reading until Mum called him for breakfast."],
	],
	"dracula": [
		["Граф отнял у Скроллера его публику: просто вышел со сцены — и все экраны повернулись вслед за ним. Без зрителей Скроллер сдулся, как проколотый мяч.",
			"The Count stole the Scroller's audience: he simply walked off the stage — and every screen turned to follow him. Without viewers the Scroller deflated like a punctured ball."],
		["«Я потерял своё отражение пятьсот лет назад, юноша, — сказал Дракула. — Ты своё чуть не потерял за полгода. Береги его». И впервые за пятьсот лет улыбнулся без клыков.",
			"\"I lost my reflection five hundred years ago, young man,\" said Dracula. \"You nearly lost yours in half a year. Take care of it.\" And for the first time in five hundred years he smiled without fangs."],
		["Утром Саша посмотрел в зеркало в ванной — долго, внимательно. Потом пошёл в школьную библиотеку и спросил: «А у вас есть настоящий „Дракула“? Не пересказ?»",
			"In the morning Sasha looked in the bathroom mirror — long and carefully. Then he went to the school library and asked: \"Do you have the real 'Dracula'? Not a summary?\""],
	],
	"koschei": [
		["Скроллер был таким же, как он сам: бессмертным и пустым. Кощей бил его и узнавал себя — и потому бил без жалости, пока провода не обвисли.",
			"The Scroller was just like him: deathless and empty. Koschei struck him and recognised himself — and so he showed no mercy until the cords hung slack."],
		["«Здесь ничего не болит, мальчик, — проскрипел Кощей. — Поэтому здесь ничего и не радует. Иди туда, где болит. Там живут». И, кажется, впервые сам себе позавидовал.",
			"\"Nothing hurts here, boy,\" Koschei creaked. \"That's why nothing brings joy here either. Go where things hurt. That's where people live.\" And for once, it seemed, he envied himself."],
		["Саша проснулся и ушиб коленку о стол. Было больно — и почему-то очень хорошо. За завтраком он спросил папу: «А почему Кощей бессмертный? Расскажешь?» Папа рассказал.",
			"Sasha woke up and banged his knee on the desk. It hurt — and somehow felt very good. At breakfast he asked his dad: \"Why is Koschei deathless? Will you tell me?\" Dad told him."],
	],
	"hercules": [
		["Тринадцатый подвиг Геракл назвал «Чистка берлоги»: вымел крошки, выкинул банки, распахнул окна — и Скроллер, не выносящий свежего воздуха, рассыпался в пыль.",
			"Hercules called his thirteenth labour \"Cleaning the Den\": he swept up the crumbs, threw out the cans, flung the windows open — and the Scroller, who couldn't stand fresh air, crumbled to dust."],
		["«Подвиги не проходят за вечер, малыш, — сказал Геракл. — Их проходят годами. Зато потом помнишь каждый». И отдал Саше на память львиный коготь.",
			"\"Labours aren't beaten in an evening, kid,\" said Hercules. \"They take years. But then you remember every one.\" And he gave Sasha a lion's claw to keep."],
		["Утром Саша, к изумлению мамы, сам убрал свою комнату. Потом сел дочитывать про двенадцать подвигов — по одному в день, чтобы помнить каждый.",
			"In the morning, to his mother's amazement, Sasha tidied his room himself. Then he sat down to finish the twelve labours — one a day, so he'd remember every one."],
	],
	"athena": [
		["Скроллер думал, что богиню мудрости можно утопить в шуме. Афина просто нажала «выключить звук» — и в тишине ему нечем стало жить.",
			"The Scroller thought the goddess of wisdom could be drowned in noise. Athena simply pressed \"mute\" — and in the silence he had nothing left to live on."],
		["«Ты всё время спрашивал, что посмотреть, — сказала Афина. — А надо спрашивать, кем стать. Задай мне вопрос. Любой». Саша задал. Потом ещё один. Потом ещё десять.",
			"\"You kept asking what to watch,\" said Athena. \"You should ask who to become. Ask me a question. Any question.\" Sasha did. Then another. Then ten more."],
		["Утром на уроке Саша впервые поднял руку сам — не чтобы ответить, а чтобы спросить. Учительница улыбнулась: «Хороший вопрос. Давай найдём ответ в книге».",
			"That morning in class Sasha raised his hand on his own for the first time — not to answer, but to ask. The teacher smiled: \"Good question. Let's find the answer in a book.\""],
	],
	"medusa": [
		["Скроллер смотрел на всех сразу — тысячами экранов. Медуза посмотрела в ответ. Экраны окаменели один за другим, и шоу закончилось тишиной.",
			"The Scroller watched everyone at once through thousands of screens. Medusa looked back. The screens turned to stone one by one, and the show ended in silence."],
		["«Все видят во мне чудовище, потому что видят только картинку, — сказала Медуза. — Ты дочитал до конца. Ты знаешь мою правду». Саша посмотрел ей в глаза — и не окаменел.",
			"\"Everyone sees a monster in me because they only see the picture,\" said Medusa. \"You read to the end. You know my truth.\" Sasha looked her in the eye — and did not turn to stone."],
		["Утром Саша нарисовал Медузу — не страшную, а грустную и красивую. Одноклассник засмеялся: «Это же монстр!» — «Ты просто не дочитал», — ответил Саша.",
			"In the morning Sasha drew Medusa — not scary, but sad and beautiful. A classmate laughed: \"That's a monster!\" — \"You just didn't read to the end,\" Sasha replied."],
	],
	"sunwukong": [
		["Скроллер обещал Царю обезьян вечную славу. Укун семьдесят два раза превратился в Скроллера, и тот запутался, кто из них настоящий. Так и сломался.",
			"The Scroller promised the Monkey King eternal fame. Wukong turned into the Scroller seventy-two times, and he lost track of which one was real. That's how he broke."],
		["«Я пятьсот лет просидел под горой, потому что не умел остановиться, — сказал Укун. — Не повторяй. Беги — но к чему-то, а не от скуки!» И вручил Саше волосок: «На удачу».",
			"\"I spent five hundred years under a mountain because I didn't know when to stop,\" said Wukong. \"Don't do the same. Run — but towards something, not away from boredom!\" And he gave Sasha a single hair: \"For luck.\""],
		["Утром Саша первым выбежал во двор и позвал ребят играть в «Царя обезьян». Вечером открыл «Путешествие на Запад». Сто глав. Ему хватит надолго.",
			"In the morning Sasha was first out into the yard, calling the kids to play \"Monkey King\". In the evening he opened \"Journey to the West\". A hundred chapters. That'll last him a while."],
	],
	"anubis": [
		["Анубис положил на весы перо истины и сердце Скроллера. Сердца не нашлось — только счётчик просмотров. Весы рассудили сами, и экран-маска погас.",
			"Anubis placed the feather of truth on the scales, and the Scroller's heart. There was no heart — only a view counter. The scales decided on their own, and the screen-mask went dark."],
		["«Здесь никто не умирает и никто не живёт, — сказал Анубис. — У каждой истории должен быть конец. Иначе она не история, а лента. Твоя страница не дописана, Саша. Иди дописывать».",
			"\"Here nobody dies and nobody lives,\" said Anubis. \"Every story must have an ending. Otherwise it is not a story, it is a feed. Your page is not finished, Sasha. Go and write it.\""],
		["Утром Саша дочитал книгу легенд до последней страницы. Закрыл — и сразу открыл новую тетрадь. На первой странице написал: «Глава первая. Саша».",
			"In the morning Sasha read the book of legends to the very last page. He closed it — and at once opened a new notebook. On the first page he wrote: \"Chapter One. Sasha.\""],
	],
}


## Абзацы эпилога на текущем языке.
static func lines(id: String) -> Array[String]:
	var out: Array[String] = []
	for row in ENDINGS.get(id, []):
		out.append(row[0] if Loc.lang == "ru" else row[1])
	return out
