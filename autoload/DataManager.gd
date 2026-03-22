extends Node

var cabinet_data: Dictionary = {}

# Устанавливаем путь динамически
var SAVE_PATH = _get_save_path()

func _ready():
	load_data_from_disk()

# Новая функция для определения пути
func _get_save_path():
	if OS.has_feature("editor"):
		return "res://wardrobe_database.json"
	else:
		# Для скомпилированной игры используем папку с .exe
		return OS.get_executable_path().get_base_dir() + "/wardrobe_database.json"

# Старые функции сохраняем, они будут использовать новый SAVE_PATH
func save_data_to_disk():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cabinet_data, "\t"))
		file.close()

func load_data_from_disk():
	# Проверяем существование файла по новому пути
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary: cabinet_data = data
		file.close()
