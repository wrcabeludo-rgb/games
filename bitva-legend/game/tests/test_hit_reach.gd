extends SceneTree
## Дальность ударов совпадает с рисунком: каждый обычный удар Ильи и Дракулы попадает по стоящему сопернику
## рядом (за дальностью броска) и на расстоянии, до которого на кадрах дотягивается рука/нога (минус запас), и не попадает
## заметно дальше рисунка. Дальность рисунка — по непрозрачным пикселям активных кадров (hit…hit_end).

const R := InputBits.RIGHT
const L := InputBits.LEFT
const D := InputBits.DOWN
const MOVES := {
	"st_lp": InputBits.LP, "st_lk": InputBits.LK, "st_hp": InputBits.HP, "st_hk": InputBits.HK,
	"cr_lp": D | InputBits.LP, "cr_lk": D | InputBits.LK, "cr_hp": D | InputBits.HP, "cr_hk": D | InputBits.HK,
}
const SLACK_IN := 25    # должен попадать, если соперник на столько ближе края рисунка
const SLACK_OUT := 40   # не должен попадать дальше края рисунка на столько


func _init() -> void:
	var ok := true
	for who in ["dracula", "ilya"]:
		var foe := "ilya" if who == "dracula" else "dracula"
		for mv in MOVES:
			var reach := _art_reach(who, mv)
			if reach < 0:
				continue
			var far := _max_range(who, foe, MOVES[mv])
			var half: int = FighterData.get_data(foe).push_half * Fighter.HURT_WIDTH_RATIO / 100
			# Край рисунка + полтела соперника — дальше этого кулак «не дотягивается».
			var visual: int = reach + half
			var good: bool = far >= visual - SLACK_IN and far <= visual + SLACK_OUT and _hits_at(who, foe, MOVES[mv], 140)
			print(("  OK   " if good else "  FAIL ") + "%s %s: попадает до %d px, рисунок до %d px" % [who, mv, far, visual])
			ok = good and ok
	print("ИТОГ: " + ("все тесты пройдены" if ok else "есть ошибки"))
	quit(0 if ok else 1)


func _hits_at(who: String, foe: String, input: int, dist: int) -> bool:
	var sim := Sim.new(false, PackedStringArray([who, foe]))
	sim.fighters[0].x = 900 * Fighter.SUB
	sim.fighters[1].x = (900 + dist) * Fighter.SUB
	var hp := sim.fighters[1].hp
	sim.step(PackedInt32Array([input, 0]))
	for i in 40:
		sim.step(PackedInt32Array([input & D, 0]))
	return sim.fighters[1].hp < hp


func _max_range(who: String, foe: String, input: int) -> int:
	var best := 0
	for d in range(60, 420, 5):
		if _hits_at(who, foe, input, d):
			best = d
	return best


## Дальность рисунка удара вперёд от центра бойца, px игры (720p); -1 — нет листа.
func _art_reach(who: String, mv: String) -> int:
	var base := "res://art/fighters/%s/" % who
	var meta_path := base + mv + ".json"
	if not FileAccess.file_exists(meta_path):
		var alias: String = FighterSprites.ANIM_ALIAS.get(mv, "")
		if alias == "" or not FileAccess.file_exists(base + alias + ".json"):
			return -1
		meta_path = base + alias + ".json"
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	var frames: Array = meta.frames
	var h0: int = int(meta.get("hit", 0))
	var h1: int = int(meta.get("hit_end", h0))
	if h0 <= 0:
		return -1
	var k: float = FighterSprites.SCALE / float(meta.get("res", 1.0))
	var reach := 0.0
	for i in range(h0 - 1, mini(h1, frames.size())):
		var img := Image.load_from_file(ProjectSettings.globalize_path(base + frames[i].file))
		var w := img.get_width()
		var px := -1
		for x in range(w - 1, -1, -1):
			for y in range(0, img.get_height(), 3):
				if img.get_pixel(x, y).a > 0.25:
					px = x
					break
			if px >= 0:
				break
		reach = maxf(reach, (px - float(frames[i].pivot[0])) * k)
	return int(reach)
