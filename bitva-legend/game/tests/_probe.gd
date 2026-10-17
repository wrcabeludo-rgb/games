extends SceneTree
func _init() -> void:
	var t := Time.get_ticks_msec()
	for i in range(1, 45):
		var x = load("res://art/fighters/ilya/idle_%d.png" % i)
	print("idle44 ", Time.get_ticks_msec() - t)
	quit()
