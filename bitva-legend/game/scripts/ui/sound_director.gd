class_name SoundDirector
extends Node
## Музыка и звуки. Только читает состояние Sim (как отрисовка) и по изменениям между тиками
## понимает, что случилось: удар, блок, парирование, начало раунда. В логику боя не вмешивается.
## Файлы — game/audio/ (tools/fetch_audio.sh, источники и лицензии — docs/AUDIO.md).

const DIR := "res://audio/"
const MUSIC_DB := -9.0
const SFX_DB := -2.0
const VOICE_DB := 0.0
const VOICES := 2
const SFX_PLAYERS := 10
## Удары, у которых свист тяжёлый (палица, размашистые удары).
const HEAVY := ["st_hp", "st_hk", "cr_hp", "cr_hk", "j_hp", "j_hk", "st_sweep", "st_round"]
## У Дракулы удары когтями — со свистом-«разрезом».
const CLAWS := ["st_lp", "st_hp", "cr_lp", "cr_hp", "j_lp", "j_hp"]

var _music := AudioStreamPlayer.new()
var _music_name := ""
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _voice := AudioStreamPlayer.new()
var _voice_queue: Array[String] = []
var _cache := {}
var _rng := RandomNumberGenerator.new()
var _fight_track := 0
## Сколько раз включалась музыка и говорил диктор (для тестов: трек не должен перезапускаться каждый тик).
var music_starts := 0
var voice_lines := 0
## Без экрана (проверки, тесты) — без звука: у «немого» аудиодрайвера играющий поток
## остаётся висеть при выходе, и Godot сообщает об утечке.
var _silent := DisplayServer.get_name() == "headless"

## Что было на прошлом тике — чтобы заметить изменения.
var _last_tick := -1
var _last_phase := -1
var _last_spark := PackedInt32Array([-999, -999])
var _last_state := PackedInt32Array([-1, -1])
var _last_frame := PackedInt32Array([-1, -1])


func _ready() -> void:
	_rng.seed = 1
	_music.volume_db = MUSIC_DB
	_music.bus = Settings.bus_name("music")
	add_child(_music)
	_music.finished.connect(func(): _music.play())
	_voice.volume_db = VOICE_DB
	_voice.bus = Settings.bus_name("voice")
	add_child(_voice)
	_voice.finished.connect(_next_voice)
	for i in SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		p.bus = Settings.bus_name("sfx")
		add_child(p)
		_sfx.append(p)


## При выходе останавливаем всё: иначе Godot ругается на «утёкший» играющий поток.
func _exit_tree() -> void:
	for p in [_music, _voice] + _sfx:
		p.stop()
		p.stream = null
	_cache.clear()


func _load(name: String) -> AudioStream:
	if not _cache.has(name):
		var path := DIR + name + ".ogg"
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


## Звук; если вариантов несколько (name_0 … name_4) — случайный, чтобы удары не звучали одинаково.
func play(name: String, pitch := 1.0, db := 0.0) -> void:
	if _silent:
		return
	var s := _load("sfx/" + name)
	if s == null:
		var variants: Array[AudioStream] = []
		for i in 5:
			var v := _load("sfx/%s_%d" % [name, i])
			if v != null:
				variants.append(v)
		if variants.is_empty():
			return
		s = variants[_rng.randi() % variants.size()]
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.stream = s
	p.pitch_scale = pitch * _rng.randf_range(0.95, 1.05)
	p.volume_db = SFX_DB + db
	p.play()


func say(lines: Array[String]) -> void:
	voice_lines += 1
	if _silent:
		return
	_voice_queue = lines.duplicate()
	_voice.stop()
	_next_voice()


func _next_voice() -> void:
	while not _voice_queue.is_empty():
		var s := _load("voice/" + _voice_queue.pop_front())
		if s != null:
			_voice.stream = s
			_voice.play()
			return


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	music_starts += 1
	var s := _load("music/" + name)
	_music.stop()
	if s != null and not _silent:
		_music.stream = s
		_music.play()


## Меню: своя музыка.
func menu() -> void:
	music("menu")
	_last_tick = -1


## Новый матч — следующий боевой трек (по очереди).
func new_match() -> void:
	_fight_track = _fight_track % 2 + 1
	_music_name = ""
	music("fight_%d" % _fight_track)


## Каждый тик боя.
func update(sim: Sim, vs_ai: bool) -> void:
	if sim.tick == _last_tick:
		return
	var fresh := _last_tick < 0 or sim.tick < _last_tick
	_last_tick = sim.tick
	if fresh:
		_last_phase = -1
		_last_spark = PackedInt32Array([sim.sparks[0], sim.sparks[4]])
	if sim.phase != _last_phase:
		_on_phase(sim, vs_ai)
		_last_phase = sim.phase
	for p in 2:
		var t := sim.sparks[p * 4]
		if t != _last_spark[p]:
			_on_spark(sim.sparks[p * 4 + 3])
		_last_spark[p] = t
		_on_fighter(sim.fighters[p], p)


func _on_phase(sim: Sim, vs_ai: bool) -> void:
	match sim.phase:
		Sim.Phase.INTRO:
			if sim.round_num == 1 and sim.wins[0] == 0 and sim.wins[1] == 0:
				new_match()
			var last := sim.wins[0] == sim.wins_needed - 1 and sim.wins[1] == sim.wins_needed - 1
			say(["final_round" if last or sim.last_bout or sim.round_num > 3 else "round_%d" % sim.round_num] as Array[String])
		Sim.Phase.FIGHT:
			if sim.training:
				return
			say(["fight"] as Array[String])
		Sim.Phase.ROUND_END:
			if sim.end_reason == Sim.EndReason.TIME:
				say(["time"] as Array[String])
			elif sim.end_reason == Sim.EndReason.KO:
				play("hit_heavy", 0.7, 3.0)
		Sim.Phase.FINISHER:
			play("super")
			play("hit_heavy", 0.6, 4.0)
		Sim.Phase.MATCH_END:
			var w := sim.match_winner()
			if w == 2:
				say(["tie"] as Array[String])
			elif vs_ai:
				say(["you_win" if w == 0 else "you_lose"] as Array[String])
			else:
				say(["player_%d" % (w + 1), "winner"] as Array[String])


func _on_spark(kind: int) -> void:
	match kind:
		0:
			play("hit_light")
		1:
			play("hit_heavy")
		2:
			play("block")
		3:
			play("block", 0.8)
		4:
			play("parry", 0.7)
		5:
			play("parry", 1.2)


func _on_fighter(f: Fighter, p: int) -> void:
	var st := f.state
	# Удар начался: первый тик удара (заморозка держит его на месте — не повторяем).
	var started := f.move >= 0 and f.move_frame == 1 and _last_frame[p] != 1
	if started:
		var name: String = Fighter.MOVES[f.move]
		if f.move == Fighter.MOVE_SUPER:
			play("super")
		elif f.id == "dracula" and name in CLAWS:
			play("slash", 1.1 if name in HEAVY else 1.4, -4.0)
		else:
			play("whoosh_heavy" if name in HEAVY else "whoosh_light", 1.0, -3.0)
		if f.id == "dracula" and name in HEAVY:
			play("cape", 1.0, -6.0)
	if st != _last_state[p]:
		match st:
			Fighter.State.LAND:
				play("land", 0.9 if f.id == "ilya" else 1.2, -6.0)
			Fighter.State.KNOCKDOWN:
				play("fall", 0.85 if f.id == "ilya" else 1.0)
			Fighter.State.BACKDASH:
				if f.id == "dracula":
					play("cape", 1.1, -6.0)
	_last_state[p] = st
	_last_frame[p] = f.move_frame if f.move >= 0 else -1
