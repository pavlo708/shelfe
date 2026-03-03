extends Node2D

@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box: TextEdit = $UI/InfoPanel/VBoxContainer/EditItemsBox
@onready var shelf_title_label = $UI/InfoPanel/VBoxContainer/TitleLabel
@onready var tooltip_label: Label = $UI/TooltipLabel
@onready var background_sprite = $Sprite2D # Спрайт фона шкафа

var current_hovered_shelf: Area2D = null

func _ready():
	info_panel.hide()
	tooltip_label.hide()
	
	var w_id = GlobalSettings.current_wardrobe
	_update_background(w_id)

	# 1. Сначала скрываем все шкафы, чтобы не накладывались
	for wardrobe in $Wardrobes.get_children():
		wardrobe.hide()

	# 2. Находим нужный шкаф (например, Wardrobe3)
	var current_wardrobe_node = get_node_or_null("Wardrobes/Wardrobe" + str(w_id))
	
	if current_wardrobe_node:
		current_wardrobe_node.show() # Показываем текущий шкаф
		
		# 3. Ищем узел Shelves внутри этого шкафа
		var shelves_container = current_wardrobe_node.get_node_or_null("Shelves")
		
		if shelves_container:
			for shelf in shelves_container.get_children():
				if shelf is Area2D:
					# Получаем ID (из переменной или из имени узла)
					var s_id = shelf.shelf_id if "shelf_id" in shelf else int(shelf.name.replace("Shelf", ""))
					shelf.shelf_id = s_id
					
					# Подключаем сигналы
					if shelf.input_event.is_connected(_on_shelf_clicked): 
						shelf.input_event.disconnect(_on_shelf_clicked)
					
					shelf.input_event.connect(_on_shelf_clicked.bind(s_id))
					shelf.mouse_entered.connect(_on_shelf_mouse_entered.bind(shelf))
					shelf.mouse_exited.connect(_on_shelf_mouse_exited.bind(shelf))
		else:
			print("ОШИБКА: Узел Shelves не найден внутри Wardrobe", w_id)
	else:
		print("ОШИБКА: Узел Wardrobe", w_id, " не найден в Wardrobes/")

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
		var w_id = GlobalSettings.current_wardrobe
		var full_id = GlobalSettings.get_full_id(s_id)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_info(full_id)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# ПРОВЕРКА: Если шкаф 4 или 6 — не переходим в зум
			if w_id == 4 or w_id == 6:
				# Устанавливаем текущий редактируемый ID
				GlobalSettings.currently_editing_id = full_id
				
				# Заполняем текст из базы данных
				var data = DataManager.cabinet_data.get(str(full_id), "")
				edit_items_box.text = ", ".join(data) if data is Array else str(data)
				
				# Обновляем заголовок и показываем панель
				shelf_title_label.text = "Редактирование: Шкаф №" + str(w_id)
				info_panel.show()
				
				print("Прямое редактирование для шкафа ", w_id)
			else:
				# Для всех остальных шкафов (1, 2, 3, 5) — обычный переход
				GlobalSettings.current_shelf_id = s_id
				GlobalSettings.last_scene_path = get_tree().current_scene.scene_file_path
				get_tree().change_scene_to_file("res://zoomed_shelf.tscn")

func show_info(full_id: int):
	var info_text = "Пусто"
	# В лабе данные часто лежат под ключами типа "1301", "1401"
	if DataManager.cabinet_data.has(str(full_id)):
		var data = DataManager.cabinet_data[str(full_id)]
		info_text = ", ".join(data) if data is Array else str(data)

	var label = get_node_or_null("UI/InfoPanel/VBoxContainer/EditItemsBox")
	if label:
		label.text = info_text
		shelf_title_label.text = "Шкаф " + str(GlobalSettings.current_wardrobe) + " | Полка " + str(full_id % 100)
		$UI/InfoPanel.show()

func _on_back_button_pressed():
	# Возвращаемся к общему виду лаборантской (где 4 шкафа)
	get_tree().change_scene_to_file("res://Scene_Lab_View.tscn")

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
