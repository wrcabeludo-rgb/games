class_name Loc
extends RefCounted
## Языки интерфейса: русский (исходный текст — он же ключ) и английский.
## Функции отрисовки текста (Hud._text, MenuView._text_c, PauseView._text) переводят строку сами;
## строки с подстановкой (%s, %d) переводятся явно до подстановки: Loc.t("РАУНД %d") % n.
## Нет перевода — показывается русский текст.

const LANGS := ["ru", "en"]
const LANG_NAMES := ["Русский", "English"]

static var lang := "ru"

const EN := {
	# Бойцы, суперприёмы, строки
	"ИЛЬЯ МУРОМЕЦ": "ILYA MUROMETS",
	"ДРАКУЛА": "DRACULA",
	"УДАР С НЕБЕС": "STRIKE FROM THE HEAVENS",
	"КРОВАВАЯ ЛУНА": "BLOOD MOON",
	"Кулачный бой": "Fistfight",
	"Богатырский пинок": "Bogatyr Kick",
	"Сверху и снизу": "High and Low",
	"Когти ночи": "Claws of the Night",
	"Взмах плаща": "Cape Sweep",
	"Вальс": "Waltz",
	"ЛР": "LP", "ЛН": "LK", "СР": "HP", "СН": "HK",
	" (низ)": " (low)",
	# Бой
	"РАУНД %d": "ROUND %d",
	"ФИНАЛЬНЫЙ РАУНД": "FINAL ROUND",
	"БОЙ!": "FIGHT!",
	"НОКАУТ!": "K.O.!",
	"ДВОЙНОЙ НОКАУТ!": "DOUBLE K.O.!",
	"ВРЕМЯ!": "TIME!",
	"НИЧЬЯ": "DRAW",
	"Раунд за: %s": "Round goes to %s",
	"%s ПОБЕЖДАЕТ!": "%s WINS!",
	"Удар — реванш   ·   Enter или Options — выбор бойца": "Attack — rematch   ·   Enter or Options — character select",
	"ПАРИРОВАНИЕ!": "PARRY!",
	"УДАР": "HIT", "УДАРА": "HITS", "УДАРОВ": "HITS",
	"урон %d": "damage %d",
	"СИЛА": "POWER",
	"СУПЕР ГОТОВ!": "SUPER READY!",
	"ТРЕНИРОВКА · F6 или R1 + тачпад — выйти": "TRAINING · F6 or R1 + touchpad — exit",
	"Esc / Options — пауза, приёмы и настройки": "Esc / Options — pause, moves and settings",
	"ИИ · ": "CPU · ",
	"Игрок %d · %s": "Player %d · %s",
	"сборка %s · %s · %d FPS": "build %s · %s · %d FPS",
	"Строки: %s — попавший удар (и в блок) отменяется в спецприём": "Strings: %s — a connecting hit (or blocked) cancels into a special",
	"Спецприёмы: назад, вперёд + рука · вниз, вниз + нога · вперёд, вперёд + рука · назад, назад + рука — захват":
		"Specials: back, forward + punch · down, down + kick · forward, forward + punch · back, back + punch — grab",
	"Назад + ЛН — подсечка · назад + СН — с разворота · вниз + СР — апперкот · ЛР вплотную — бросок · тап «вперёд» в момент удара — парирование":
		"Back + LK — sweep · back + HK — roundhouse · down + HP — uppercut · LP up close — throw · tap forward as a hit lands — parry",
	"R1/L — блок · F3/Options — ИИ · F4/F5/тачпад — бойцы · F6/R1+тачпад — тренировка · F7 — спрайты · F1 — ввод · F2 — хитбоксы · R/Create — заново · F11 · Esc":
		"R1/L — block · F3 — CPU · F4/F5/touchpad — fighters · F6/R1+touchpad — training · F7 — sprites · F1 — inputs · F2 — hitboxes · R/Create — restart · F11 · Esc",
	# ИИ, устройства, уведомления
	"выкл": "off", "лёгкий": "easy", "средний": "medium", "сложный": "hard",
	"ИИ соперника: %s": "CPU opponent: %s",
	"ТРЕНИРОВКА · соперник — ИИ (%s), F3 или Options — сменить": "TRAINING · opponent — CPU (%s), F3 to change",
	"Тренировка выключена — обычный бой": "Training off — regular fight",
	"Спрайты бойцов: ": "Fighter sprites: ",
	"включены": "on",
	"выключены (заглушки)": "off (placeholders)",
	"Подключён: %s": "Connected: %s",
	"ГЕЙМПАД ОТКЛЮЧИЛСЯ (%s) · отключений: %d": "GAMEPAD DISCONNECTED (%s) · drops: %d",
	"геймпад %d": "gamepad %d",
	" · отключений геймпада: %d": " · gamepad drops: %d",
	"стрелки": "arrows",
	"любой геймпад (%d) + клавиатура (%s)": "any gamepad (%d) + keyboard (%s)",
	"клавиатура (%s)": "keyboard (%s)",
	"%s + клавиатура (%s)": "%s + keyboard (%s)",
	# Меню
	"БИТВА ЛЕГЕНД": "CLASH OF LEGENDS",
	"Нажмите Enter или крест": "Press Enter or Cross",
	"Options / F10 — настройки   ·   Esc — выход   ·   F11 — полный экран":
		"Options / F10 — settings   ·   Esc — quit   ·   F11 — fullscreen",
	"ВЫБОР БОЙЦА": "CHOOSE YOUR FIGHTER",
	"ГОТОВ!": "READY!",
	"В БОЙ!": "TO BATTLE!",
	"ИИ": "CPU",
	"Соперник: %s   ·   F3 — сменить   ·   Options / F10 — настройки": "Opponent: %s   ·   F3 — change   ·   Options / F10 — settings",
	"второй игрок": "player 2",
	"ИИ, ": "CPU, ",
	"←→↑↓ — выбор   ·   Enter / крест — подтвердить   ·   K / круг — назад":
		"←→↑↓ — select   ·   Enter / Cross — confirm   ·   K / Circle — back",
	"ПРОТИВ": "VS",
	"Enter / крест — пропустить": "Enter / Cross — skip",
	# Пауза и настройки
	"ПАУЗА": "PAUSE",
	"Продолжить": "Resume",
	"Заново": "Restart",
	"Приёмы": "Move list",
	"Настройки": "Settings",
	"Выбор бойца": "Character select",
	"Главное меню": "Main menu",
	"НАСТРОЙКИ": "SETTINGS",
	"Музыка": "Music",
	"Звуки": "Sound effects",
	"Диктор": "Announcer",
	"Вибрация": "Vibration",
	"Соперник": "Opponent",
	"Полный экран": "Fullscreen",
	"Подсказки на экране": "On-screen hints",
	"Язык": "Language",
	"Назад": "Back",
	"выключена": "off", "обычная": "normal", "сильная": "strong",
	"да": "yes", "нет": "no",
	"показывать": "show", "скрыть": "hide",
	"↑↓ — пункт   ·   ←→ — изменить   ·   Enter / крест — выбрать   ·   Esc / круг — назад":
		"↑↓ — item   ·   ←→ — change   ·   Enter / Cross — select   ·   Esc / Circle — back",
	"ПРИЁМЫ": "MOVE LIST",
	"У всех бойцов": "All fighters",
	"Назад, вперёд + рука": "Back, forward + punch",
	"Вниз, вниз + нога": "Down, down + kick",
	"Вперёд, вперёд + рука": "Forward, forward + punch",
	"Назад, назад + рука": "Back, back + punch",
	"Бросок палицы — снаряд по дуге (ЛР ближе, СР дальше)": "Mace Toss — arcing projectile (LP near, HP far)",
	"Удар оземь — волна по земле, блок сидя или прыжок": "Ground Slam — shockwave, block low or jump",
	"Богатырский таран — рывок, держит один удар": "Bogatyr Charge — dash that absorbs one hit",
	"Мельница — дальний захват, вырваться нельзя": "Windmill — long-range grab, can't be broken",
	"Стая летучих мышей — быстрый снаряд": "Bat Swarm — fast projectile",
	"Туманный рывок — неуязвим, появляется за спиной": "Mist Dash — invulnerable, reappears behind",
	"Гипнотический взгляд — ударивший застывает": "Hypnotic Gaze — the attacker freezes",
	"Укус — захват, лечит Дракулу": "Bite — grab that heals Dracula",
	"Назад + ЛН": "Back + LK", "подсечка": "sweep",
	"Назад + СН": "Back + HK", "удар с разворота": "spinning roundhouse",
	"Вниз + СР": "Down + HP", "апперкот": "uppercut",
	"ЛР вплотную": "LP up close", "бросок (вырваться — ЛР)": "throw (break — LP)",
	"Тап «вперёд» в момент удара": "Tap forward as a hit lands", "парирование": "parry",
	"Спецприём + блок": "Special + block", "усиленный (1 секция)": "enhanced (1 bar)",
	"Блок + СР + СН": "Block + HP + HK", "суперприём (вся шкала)": "super (full meter)",
	"ЛР, ЛН, СР, СН — лёгкий и сильный удар рукой и ногой · попавшая строка (и в блок) отменяется в спецприём":
		"LP, LK, HP, HK — light and heavy punch and kick · a connecting string (or blocked) cancels into a special",
}


static func t(s: String) -> String:
	if lang == "ru":
		return s
	return EN.get(s, s)


## Язык при первом запуске — по языку системы.
static func system_default() -> String:
	return "ru" if OS.get_locale_language() in ["ru", "uk", "be", "kk"] else "en"
