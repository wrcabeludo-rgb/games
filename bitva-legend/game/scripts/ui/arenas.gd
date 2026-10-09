class_name Arenas
extends RefCounted
## Арены — карты ивентов Скроллера, собранные из страниц Сашиной книги (docs/LORE.md): у каждого бойца —
## своя карта (страница его истории), у каждой пары — кроссовер-карта (две страницы, склеенные скотчем),
## у Скроллера — логово. Арт лежит в dir (слои как у «Перепутья», docs/ART_ARENA.md); пока его нет —
## заглушка, нарисованная по описанию ниже. На ход боя арена не влияет.
##
## Описание заглушки:
##   sky        — [верх неба, горизонт слева, горизонт справа]; stars — звёзды на тёмной стороне
##   light      — "sun" / "moon" / "none" и где (доля ширины слоя)
##   hills      — цвет дальнего плана; shape — [слева, справа]: soft, sharp, flat, dunes, sea
##   marks      — ориентиры на дальнем плане: [вид, доля ширины, масштаб]
##   trees      — [слева, справа]: birch, dead, cypress, olive, palm, pine, column, peach, apple, screen, cable, none
##   ground     — цвет земли; birds — ravens, gulls, bats, none; indoor — зал (стены вместо неба)
##   stone      — камень на перепутье в центре; glitch — помехи и пиксельная пыль (логово Скроллера)
##   leaves     — листья летят на светлой стороне; fireflies — светлячки на тёмной
##   still      — средний план не качается на ветру (колонны, статуи, экраны)

const DEFAULT := "crossroads"

const LIST := {
	# --- Кроссовер-карты пар ---
	"crossroads": {
		"name": "Перепутье", "dir": "res://art/arena/",
		"sky": [Color(0.08, 0.07, 0.15), Color(0.98, 0.74, 0.4), Color(0.3, 0.07, 0.17)], "stars": true,
		"light": ["moon", 0.8], "hills": Color(0.29, 0.2, 0.24), "shape": ["soft", "sharp"],
		"marks": [["church", 0.12, 1.0], ["castle", 0.86, 1.0]], "trees": ["birch", "dead"],
		"ground": Color(0.2, 0.17, 0.16), "birds": "ravens", "stone": true, "leaves": true, "fireflies": true,
	},
	"coast": {
		"name": "Эгейский берег", "dir": "res://art/arenas/coast/",
		"sky": [Color(0.15, 0.3, 0.55), Color(0.98, 0.85, 0.6), Color(0.35, 0.45, 0.5)], "stars": false,
		"light": ["sun", 0.2], "hills": Color(0.25, 0.45, 0.6), "shape": ["sea", "sharp"],
		"marks": [["temple", 0.22, 1.0], ["rocks", 0.85, 1.2]], "trees": ["olive", "dead"],
		"ground": Color(0.78, 0.68, 0.5), "birds": "gulls",
	},
	"pass": {
		"name": "Перевал", "dir": "res://art/arenas/pass/",
		"sky": [Color(0.12, 0.12, 0.2), Color(0.95, 0.75, 0.5), Color(0.2, 0.25, 0.22)], "stars": false,
		"light": ["sun", 0.15], "hills": Color(0.4, 0.36, 0.38), "shape": ["sharp", "sharp"],
		"marks": [["ruins", 0.18, 1.0], ["tower", 0.84, 1.0]], "trees": ["cypress", "pine"],
		"ground": Color(0.42, 0.36, 0.3), "birds": "ravens",
	},
	"nile": {
		"name": "Берег Нила", "dir": "res://art/arenas/nile/",
		"sky": [Color(0.2, 0.35, 0.65), Color(0.98, 0.8, 0.5), Color(0.85, 0.55, 0.35)], "stars": false,
		"light": ["sun", 0.75], "hills": Color(0.8, 0.62, 0.38), "shape": ["dunes", "dunes"],
		"marks": [["cloud_palace", 0.2, 1.0], ["pyramid", 0.7, 1.0], ["pyramid", 0.84, 0.7]], "trees": ["peach", "palm"],
		"ground": Color(0.76, 0.62, 0.4), "birds": "none",
	},
	# --- Свои арены бойцов ---
	"zastava": {
		"name": "Богатырская застава", "dir": "res://art/arenas/zastava/",
		"sky": [Color(0.25, 0.4, 0.65), Color(0.95, 0.85, 0.6), Color(0.85, 0.75, 0.6)], "stars": false,
		"light": ["sun", 0.5], "hills": Color(0.4, 0.5, 0.3), "shape": ["soft", "soft"],
		"marks": [["fort", 0.5, 1.2]], "trees": ["birch", "pine"],
		"ground": Color(0.38, 0.32, 0.22), "birds": "none",
	},
	"castle_hall": {
		"name": "Замок графа", "still": true, "dir": "res://art/arenas/castle_hall/", "indoor": true,
		"sky": [Color(0.08, 0.03, 0.06), Color(0.3, 0.06, 0.1), Color(0.3, 0.06, 0.1)], "stars": false,
		"light": ["moon", 0.5], "hills": Color(0.18, 0.1, 0.14), "shape": ["flat", "flat"],
		"marks": [["window", 0.3, 1.0], ["throne", 0.5, 1.0], ["window", 0.7, 1.0]], "trees": ["column", "column"],
		"ground": Color(0.22, 0.12, 0.14), "birds": "bats",
	},
	"temple": {
		"name": "Храм Афины", "still": true, "dir": "res://art/arenas/temple/", "indoor": true,
		"sky": [Color(0.55, 0.6, 0.7), Color(0.95, 0.9, 0.8), Color(0.95, 0.9, 0.8)], "stars": false,
		"light": ["none", 0.5], "hills": Color(0.85, 0.82, 0.75), "shape": ["flat", "flat"],
		"marks": [["statue", 0.5, 1.2]], "trees": ["column", "column"],
		"ground": Color(0.8, 0.76, 0.68), "birds": "none",
	},
	"gorgon_isle": {
		"name": "Остров Горгон", "dir": "res://art/arenas/gorgon_isle/",
		"sky": [Color(0.12, 0.18, 0.22), Color(0.4, 0.5, 0.45), Color(0.25, 0.32, 0.35)], "stars": false,
		"light": ["sun", 0.5], "hills": Color(0.3, 0.38, 0.38), "shape": ["sea", "sharp"],
		"marks": [["cave", 0.5, 1.0], ["statue", 0.25, 0.8], ["statue", 0.75, 0.8]], "trees": ["dead", "dead"],
		"ground": Color(0.4, 0.42, 0.38), "birds": "gulls",
	},
	"hesperides": {
		"name": "Сад Гесперид", "dir": "res://art/arenas/hesperides/",
		"sky": [Color(0.3, 0.2, 0.45), Color(1.0, 0.75, 0.45), Color(0.95, 0.6, 0.45)], "stars": false,
		"light": ["sun", 0.6], "hills": Color(0.45, 0.5, 0.35), "shape": ["soft", "soft"],
		"marks": [["giant", 0.85, 1.0]], "trees": ["apple", "apple"],
		"ground": Color(0.4, 0.45, 0.28), "birds": "none",
	},
	"koschei_realm": {
		"name": "Кощеево царство", "dir": "res://art/arenas/koschei_realm/",
		"sky": [Color(0.05, 0.08, 0.06), Color(0.2, 0.3, 0.2), Color(0.15, 0.22, 0.15)], "stars": true,
		"light": ["moon", 0.3], "hills": Color(0.15, 0.2, 0.15), "shape": ["sharp", "sharp"],
		"marks": [["tower", 0.5, 1.4], ["gold", 0.25, 1.0], ["gold", 0.75, 1.0]], "trees": ["dead", "dead"],
		"ground": Color(0.18, 0.2, 0.15), "birds": "ravens",
	},
	"flower_mountain": {
		"name": "Гора Цветов и Плодов", "dir": "res://art/arenas/flower_mountain/",
		"sky": [Color(0.3, 0.55, 0.85), Color(0.95, 0.9, 0.7), Color(0.95, 0.85, 0.7)], "stars": false,
		"light": ["sun", 0.3], "hills": Color(0.35, 0.55, 0.4), "shape": ["sharp", "sharp"],
		"marks": [["waterfall", 0.5, 1.2]], "trees": ["peach", "peach"],
		"ground": Color(0.45, 0.5, 0.3), "birds": "none",
	},
	"duat": {
		"name": "Зал суда Дуата", "still": true, "dir": "res://art/arenas/duat/", "indoor": true,
		"sky": [Color(0.05, 0.06, 0.12), Color(0.2, 0.18, 0.3), Color(0.2, 0.18, 0.3)], "stars": true,
		"light": ["none", 0.5], "hills": Color(0.25, 0.2, 0.15), "shape": ["flat", "flat"],
		"marks": [["scales", 0.5, 1.3]], "trees": ["column", "column"],
		"ground": Color(0.3, 0.25, 0.18), "birds": "none",
	},
	# --- Финал: логово Скроллера ---
	"den": {
		"name": "Логово Скроллера", "still": true, "dir": "res://art/arenas/den/", "indoor": true, "glitch": true,
		"sky": [Color(0.04, 0.05, 0.08), Color(0.16, 0.2, 0.22), Color(0.1, 0.22, 0.3)], "stars": false,
		"light": ["none", 0.5], "hills": Color(0.2, 0.18, 0.15), "shape": ["flat", "flat"],
		"marks": [["boxes", 0.15, 1.0], ["screens", 0.5, 1.4], ["boxes", 0.85, 1.2]], "trees": ["cable", "cable"],
		"ground": Color(0.2, 0.18, 0.14), "birds": "none",
	},
}

## Кроссовер-карта пары (порядок бойцов не важен).
const SEAMS := {
	"dracula|ilya": "crossroads", "athena|medusa": "coast", "hercules|koschei": "pass", "anubis|sunwukong": "nile",
}
## Своя арена бойца.
const HOME := {
	"ilya": "zastava", "dracula": "castle_hall", "athena": "temple", "medusa": "gorgon_isle",
	"hercules": "hesperides", "koschei": "koschei_realm", "sunwukong": "flower_mountain", "anubis": "duat",
	"avatar": "den", "scroller": "den",
}


static func data(id: String) -> Dictionary:
	return LIST.get(id, LIST[DEFAULT])


static func seam(a: String, b: String) -> String:
	var ids := [a, b]
	ids.sort()
	return SEAMS.get("%s|%s" % ids, "")


static func home(id: String) -> String:
	return HOME.get(id, DEFAULT)


## Арена обычного боя: соперники из пары — на своей кроссовер-карте, зеркальный бой — дома,
## иначе — дома у одного из двоих (choice: 0 или 1 — у кого).
static func for_versus(a: String, b: String, choice: int) -> String:
	for id in [a, b]:
		if id in Arcade.FINALS:
			return home(id)
	var s := seam(a, b)
	if s != "":
		return s
	return home(b if choice == 1 else a)


## Арена боя аркады: финал — в логове Скроллера, заклятый соперник — на кроссовер-карте пары,
## остальные — на своей карте соперника.
static func for_arcade(player: String, opponent: String) -> String:
	if opponent in Arcade.FINALS:
		return home(opponent)
	var s := seam(player, opponent)
	return s if s != "" else home(opponent)
