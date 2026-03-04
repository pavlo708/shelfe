extends Node

var cabinet_data: Dictionary = {}
const SAVE_PATH = "user://wardrobe_database.json"

func _ready():
	load_data_from_disk()

# Метод, который мы будем дергать ПРИ КАЖДОМ изменении текста
func save_data_to_disk():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cabinet_data, "\t"))
		file.close()

func load_data_from_disk():
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary: cabinet_data = data
		file.close()
