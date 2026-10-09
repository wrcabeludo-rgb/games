extends Node
## Дополнительные пакеты данных: бойцы в высоком разрешении лежат рядом с игрой отдельными файлами
## (<id>.pck), чтобы каждый архив сборки был меньше 100 МБ. Подключаются до загрузки бойцов.


func _init() -> void:
	var dir := OS.get_executable_path().get_base_dir()
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".pck") and file != "BitvaLegend.pck":
			if not ProjectSettings.load_resource_pack(dir.path_join(file)):
				push_warning("Не удалось подключить пакет " + file)
