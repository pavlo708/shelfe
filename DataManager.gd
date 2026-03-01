#DataManager
extends Node 

const SAVE_PATH = "user://cabinet_save.json"

# База данных теперь пустая. Пользователь заполнит её сам.
var cabinet_data = {}

func _ready():
	load_data_from_disk()

# Поиск теперь учитывает новую вложенность
func find_all_shelves_by_item(search_text: String) -> Array:
	var results = []
	search_text = search_text.to_lower()
	
	for full_id in cabinet_data.keys():
		for item in cabinet_data[full_id]:
			if search_text in item.to_lower():
				# Извлекаем данные из ID (Каб + Шкаф + Полка)
				var cab = int(full_id / 1000)
				var ward = int((full_id % 1000) / 100)
				var shelf = full_id % 100
				
				# Если нашли в текущем месте — добавляем для подсветки
				if cab == GlobalSettings.current_cabinet and ward == GlobalSettings.current_wardrobe:
					results.append(shelf)
				else:
					# Если нашли в другом месте — просто выводим инфо (можно вывести в UI потом)
					print("Найдено в Кабинете %d, Шкаф %d, Полка %d" % [cab, ward, shelf])
	return results

func load_data_from_disk():
	if not FileAccess.file_exists(SAVE_PATH):
		return 
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var raw_data = json.data
		cabinet_data = {}
		for key in raw_data.keys():
			cabinet_data[int(key)] = raw_data[key]
	file.close()

func save_data_to_disk():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(cabinet_data)
	file.store_string(json_string)
	file.close()

# КРАСИВЫЙ ЭКСПОРТ ВСЕЙ ШКОЛЫ
func export_to_path(full_path: String) -> bool:
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if not file: return false
	
	file.store_line("ПОЛНЫЙ ОТЧЕТ ПО ОБОРУДОВАНИЮ ШКОЛЫ")
	file.store_line("==================================\n")
	
	var all_ids = cabinet_data.keys()
	all_ids.sort() # Чтобы всё шло по порядку кабинетов и шкафов
	
	var last_cab = -1
	var last_ward = -1
	
	for id in all_ids:
		var cab = int(id / 1000)
		var ward = int((id % 1000) / 100)
		var shelf = id % 100
		
		# Заголовок кабинета
		if cab != last_cab:
			file.store_line("\n>>> КАБИНЕТ №" + str(cab) + " <<<")
			last_cab = cab
			
		# Заголовок шкафа
		if ward != last_ward:
			var ward_name = "Большой шкаф" if ward == 1 else "У стены" if ward == 2 else "Лаборантская (шкаф " + str(ward) + ")"
			file.store_line("\n  [ " + ward_name + " ]")
			last_ward = ward
			
		# Список предметов на полке
		if not cabinet_data[id].is_empty():
			file.store_line("    Полка №" + str(shelf) + ":")
			for item in cabinet_data[id]:
				file.store_line("      • " + item)
	
	file.close()
	return true
