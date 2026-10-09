extends SceneTree
## Упаковывает арт одного бойца в отдельный .pck (как его упаковал бы экспорт Godot):
## godot --headless --path game --script res://../tools/... нельзя — запускать так:
## godot --headless --path game --script res://tools_pack_fighter.gd -- <id> <выход.pck>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var id: String = args[0]
	var out: String = args[1]
	var pck := PCKPacker.new()
	pck.pck_start(out)
	var dir := "res://art/fighters/" + id + "/"
	var n := 0
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".json"):
			pck.add_file(dir + file, dir + file)
		elif file.ends_with(".png.import"):
			pck.add_file(dir + file, dir + file)
			var cfg := ConfigFile.new()
			cfg.load(dir + file)
			var imported: String = cfg.get_value("remap", "path")
			pck.add_file(imported, imported)
			n += 1
	pck.flush()
	print("Пакет %s: %d кадров → %s" % [id, n, out])
	quit()
