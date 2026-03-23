extends Node2D

@onready var shelf_background = $Sprite2D
@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box = $UI/InfoPanel/VBoxContainer/EditItemsBox
@onready var title_label: Label = $UI/InfoPanel/VBoxContainer/TitleLabel

var current_shelf_id = 0
var hovered_index = -1 
var current_group: Node2D = null 

func _ready():
	info_panel.hide()
	edit_items_box.editable = true
	current_shelf_id = GlobalSettings.current_shelf_id
	var w_id = GlobalSettings.current_wardrobe
	
	# Скрываем все группы предметов и ищем нужную для текущего шкафа/полки
	for child in get_children():
		if child.name.begins_with("Items"):
			child.hide()

	var target_name = ""
	match w_id:
		1: target_name = "Items" + str(current_shelf_id)
		2: target_name = "ItemsWall" + str(current_shelf_id)
		3: target_name = "Items3_" + str(current_shelf_id)
		5: target_name = "Items5_" + str(current_shelf_id)
		6: target_name = "Items6_" + str(current_shelf_id) 
		7: target_name = "Items7_" + str(current_shelf_id) 

	current_group = get_node_or_null(target_name)
	
	if current_group:
		current_group.show()
		for i in range(current_group.get_child_count()):
			var child = current_group.get_child(i)
			if child is Area2D:
				# 1. Очищаем старые сигналы перед подключением (защита от дублей)
				if child.input_event.is_connected(_on_item_clicked): child.input_event.disconnect(_on_item_clicked)
				if child.mouse_entered.is_connected(_on_mouse_entered_item): child.mouse_entered.disconnect(_on_mouse_entered_item)
				if child.mouse_exited.is_connected(_on_mouse_exited_item): child.mouse_exited.disconnect(_on_mouse_exited_item)

				# 2. Подключаем клик
				child.input_event.connect(_on_item_clicked.bind(i))
				
				# 3. ПОДКЛЮЧАЕМ ПОДСВЕТКУ (то, что было пропущено)
				child.mouse_entered.connect(_on_mouse_entered_item.bind(i))
				child.mouse_exited.connect(_on_mouse_exited_item.bind(i))

	if not edit_items_box.text_changed.is_connected(_on_text_changed):
		edit_items_box.text_changed.connect(_on_text_changed)

# --- Функции управления подсветкой ---

func _on_mouse_entered_item(item_idx: int):
	hovered_index = item_idx
	queue_redraw() # Заставляем вызвать _draw() для отрисовки рамки

func _on_mouse_exited_item(item_idx: int):
	if hovered_index == item_idx:
		hovered_index = -1
		queue_redraw() # Убираем рамку

func _on_item_clicked(_viewport, event, _shape_idx, item_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var shelf_full_id = GlobalSettings.get_full_id(current_shelf_id)
		var item_id = str(shelf_full_id) + str(item_idx + 1)
		GlobalSettings.currently_editing_id = int(item_id)
		
		var data = DataManager.cabinet_data.get(item_id, "")
		edit_items_box.text = str(data)
		title_label.text = "Предмет №" + str(item_idx + 1)
		info_panel.show()

func _on_text_changed():
	var id_to_save = str(GlobalSettings.currently_editing_id)
	if id_to_save != "0":
		DataManager.cabinet_data[id_to_save] = edit_items_box.text
		# DataManager.save_data_to_disk() # Можно добавить автосохранение

# --- Логика рисования подсветки ---

func _draw():
	if hovered_index == -1 or current_group == null:
		return
	
	if hovered_index >= current_group.get_child_count():
		return
		
	var area = current_group.get_child(hovered_index) as Area2D
	if not area:
		return
		
	# Ищем форму коллизии, чтобы нарисовать вокруг нее рамку
	for child in area.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var rect = child.shape.get_rect()
			# Переводим локальные координаты коллизии в глобальные для рисования в Node2D
			var global_pos = child.global_position - global_position
			draw_rect(Rect2(global_pos + rect.position, rect.size), Color(1, 1, 0, 0.3), true) # Желтая заливка
			draw_rect(Rect2(global_pos + rect.position, rect.size), Color(1, 1, 0, 0.8), false, 2.0) # Рамка

func _on_back_button_pressed():
	get_tree().change_scene_to_file(GlobalSettings.last_scene_path)

func _on_close_button_pressed():
	info_panel.hide()

func _on_save_button_pressed():
	# Кнопка "Сохранить" теперь просто закрывает окно, так как сохранение идет в реальном времени
	DataManager.save_data_to_disk()
	info_panel.hide()
