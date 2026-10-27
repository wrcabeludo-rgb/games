extends SceneTree
## Отладка анимаций: прогоняет демо-сценарий и пишет по тикам, какой кадр рисуется у каждого бойца.
## godot --headless --path game --script res://tests/_anim_probe.gd -- <сценарий> <a,b> <тиков> [meter] [hp] [wins]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	DemoInput.scenario = args[0]
	var chars := PackedStringArray(args[1].split(","))
	var ticks := int(args[2])
	var sim := Sim.new(true, chars)
	if args.size() > 3 and int(args[3]) > 0:
		for f in sim.fighters: f.meter = int(args[3])
	if args.size() > 4 and int(args[4]) > 0:
		sim.fighters[1].hp = int(args[4])
	if args.size() > 5:
		sim.wins[0] = int(args[5])
	var spr := FighterSprites.new()
	for t in ticks:
		sim.step(DemoInput.frame(sim.tick, sim))
		for p in 2:
			var f := sim.fighters[p]
			var foe := sim.fighters[1 - p]
			var hidden := spr.in_pair_scene(f, foe)
			var fr := spr.frame_for(f, sim.tick, foe)
			var path := ""
			var piv := Vector2.ZERO
			if not fr.is_empty():
				path = (fr[0] as Texture2D).resource_path
				piv = fr[1]
			print("P|%d|%d|%s|%d|%d|%d|%d|%s|%d|%d|%d|%s|%d" % [sim.tick, p, Fighter.State.keys()[f.state], f.x / Fighter.SUB,
				f.y / Fighter.SUB, f.facing, spr.draw_facing(f), path, piv.x, piv.y, int(hidden), Sim.Phase.keys()[sim.phase],
				int(spr.visual_lift(f))])
	quit()
