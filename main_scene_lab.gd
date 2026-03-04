extends Node2D

@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box: TextEdit = $UI/InfoPanel/VBoxContainer/EditItemsBox
@onready var shelf_title_label = $UI/InfoPanel/VBoxContainer/TitleLabel
@onready var tooltip_label: Label = $UI/TooltipLabel
@onready var background_sprite = $Sprite2D # Спрайт фона шкафа

var current_hovered_shelf: Area2D = null

func _ready():
	# 1. Прячем панель информации при старте
	info_panel.hide()
	edit_items_box.editable = false
	# 2. Получаем ID текущего шкафа из глобальных настроек
	var w_id = GlobalSettings.current_wardrobe
	# Обновляем фоновую картинку (стену)
	_update_background(w_id)

	# 3. Сначала скрываем ВСЕ шкафы в контейнере Wardrobes
	var wardrobes_root = get_node_or_null("Wardrobes")
	if wardrobes_root:
		for wardrobe in wardrobes_root.get_children():
			wardrobe.hide()
	else:
		print("ОШИБКА: Узел 'Wardrobes' не найден в сцене!")

	# 4. Находим и показываем КОНКРЕТНЫЙ шкаф
	var current_wardrobe_node = get_node_or_null("Wardrobes/Wardrobe" + str(w_id))
	
	if current_wardrobe_node:
		current_wardrobe_node.show() # ВКЛЮЧАЕМ ВИДИМОСТЬ ШКАФА
		print("Шкаф Wardrobe", w_id, " успешно показан.")
		
		# Ищем полки внутри этого шкафа
		var shelves_container = current_wardrobe_node.get_node_or_null("Shelves")
		if shelves_container:
			for shelf in shelves_container.get_children():
				if shelf is Area2D:
					# Извлекаем ID полки из имени (например, из 'Shelf1' получим 1)
					var s_id = int(shelf.name.replace("Shelf", ""))
					
					# Отключаем старые сигналы, чтобы не было дублей, и подключаем заново
					if shelf.input_event.is_connected(_on_shelf_clicked):
						shelf.input_event.disconnect(_on_shelf_clicked)
					
					shelf.input_event.connect(_on_shelf_clicked.bind(s_id))
		else:
			print("ОШИБКА: Внутри Wardrobe", w_id, " нет узла 'Shelves'!")
	else:
		print("ОШИБКА: Узел Wardrobe", w_id, " не найден по пути Wardrobes/Wardrobe", w_id)

	# 5. Привязываем автосохранение текста
	if not edit_items_box.text_changed.is_connected(_on_main_text_changed):
		edit_items_box.text_changed.connect(_on_main_text_changed)

func _update_background(w_id):
	match w_id:
		3, 5: background_sprite.texture = load("res://LabShelfs/ShelfLab1.png")
		4: background_sprite.texture = load("res://LabShelfs/ShelfLabDoor1.png")
		6: background_sprite.texture = load("res://LabShelfs/ShelfLabPC.png")

func _adjust_shelf_visibility(shelf, s_id, w_id):
	# Если это шкафы с одной полкой (4 и 6), скрываем все полки кроме первой
	if (w_id == 4 or w_id == 6) and s_id > 1:
		shelf.hide()
		shelf.process_mode = PROCESS_MODE_DISABLED # Чтобы не кликалось
	else:
		shelf.show()
		shelf.process_mode = PROCESS_MODE_INHERIT

func _on_shelf_clicked(_viewport, event, _shape_idx, s_id):
	if event is InputEventMouseButton and event.pressed:
		var shelf_full_id = GlobalSettings.get_full_id(s_id)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# СОБИРАЕМ ТЕКСТ ИЗ ВСЕХ ПРЕДМЕТОВ ПОЛКИ
			var total_text = ""
			# Проверяем предметы с 1 по 20 (запас)
			for i in range(1, 21):
				var item_id = str(shelf_full_id) + str(i)
				if DataManager.cabinet_data.has(item_id):
					var item_text = DataManager.cabinet_data[item_id].strip_edges()
					if item_text != "":
						total_text += "• " + item_text + "\n"
			
			if total_text == "": total_text = "Полка пуста"
			
			edit_items_box.text = total_text
			shelf_title_label.text = "Содержимое полки №" + str(s_id)
			info_panel.show()
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Переход в зум для шкафов 3 и 5
			if GlobalSettings.current_wardrobe in [3, 5]:
				GlobalSettings.current_shelf_id = s_id
				GlobalSettings.last_scene_path = get_tree().current_scene.scene_file_path
				get_tree().change_scene_to_file("res://zoomed_shelf.tscn")

func _on_main_text_changed():
	var id_to_save = str(GlobalSettings.currently_editing_id)
	if id_to_save != "0":
		DataManager.cabinet_data[id_to_save] = edit_items_box.text
		DataManager.save_data_to_disk()

func show_info(full_id: int):
	GlobalSettings.currently_editing_id = full_id
	var s_id_str = str(full_id)
	
	# Берем актуальные данные из синглтона
	var data = DataManager.cabinet_data.get(s_id_str, "")
	edit_items_box.text = str(data)
	
	shelf_title_label.text = "Шкаф " + str(GlobalSettings.current_wardrobe) + " | Полка " + str(full_id % 100)
	info_panel.show()

# Остальные функции (mouse_entered/exited) остаются такими же
func _on_shelf_mouse_entered(shelf):
	current_hovered_shelf = shelf
	if "is_hovered" in shelf: shelf.is_hovered = true
	shelf.queue_redraw()
	
	var w_id = GlobalSettings.current_wardrobe
	if w_id == 4:
		tooltip_label.text = "Тумба №4"
	elif w_id == 6:
		tooltip_label.text = "Рабочее место №6"
	else:
		tooltip_label.text = "Полка №" + str(shelf.shelf_id)
		
	tooltip_label.show()

func _on_shelf_mouse_exited(shelf):
	if "is_hovered" in shelf: shelf.is_hovered = false
	shelf.queue_redraw()
	if current_hovered_shelf == shelf:
		current_hovered_shelf = null
		tooltip_label.hide()
		
func _on_save_button_pressed():
	var id_to_save = GlobalSettings.currently_editing_id
	if id_to_save == 0: return
	
	# Разбиваем текст на массив строк (как мы делали в zoomed_shelf)
	var raw_text = edit_items_box.text
	var new_items = []
	for line in raw_text.split("\n"):
		if line.strip_edges() != "":
			new_items.append(line.strip_edges())
	
	# Сохраняем в память и на диск
	DataManager.cabinet_data[str(id_to_save)] = new_items
	DataManager.save_data_to_disk()
	
	info_panel.hide()
	print("Данные для ID ", id_to_save, " сохранены прямо из лабы.")		

func _process(_delta):
	if tooltip_label.visible:
		tooltip_label.global_position = get_global_mouse_position() + Vector2(15, 15)

func _on_close_button_pressed():
	info_panel.hide()
	
func _on_back_button_pressed():
	# Если это шкаф из лаборантской (ID 3, 4, 5...), возвращаемся в лаборантскую
	if GlobalSettings.current_wardrobe >= 3:
		get_tree().change_scene_to_file("res://Scene_Lab_View.tscn")
	else:
		# Если это основные шкафы, возвращаемся в кабинет
		get_tree().change_scene_to_file("res://Scene_Cabinet_View.tscn")
