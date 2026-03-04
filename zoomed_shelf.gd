#zoomed_shelf
extends Node2D

@onready var shelf_background = $Sprite2D
@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box = $UI/InfoPanel/EditItemsBox
@onready var title_label: Label = $UI/InfoPanel/VBoxContainer/TitleLabel

var current_shelf_id = 0
var hovered_index = -1       # Используем это имя везде
var current_group: Node2D = null # Объявляем переменную для группы

func _ready():
	info_panel.hide()
	edit_items_box.editable = true
	current_shelf_id = GlobalSettings.current_shelf_id
	var w_id = GlobalSettings.current_wardrobe
	
	# Скрываем всё, ищем нужную группу (шкаф 3 или 5)
	for child in get_children():
		if child.name.begins_with("Items"): child.hide()
	
	var target_name = ""
	match w_id:
		1: target_name = "Items" + str(current_shelf_id)
		2: target_name = "ItemsWall" + str(current_shelf_id)
		3: target_name = "Items3_" + str(current_shelf_id)
		5: target_name = "Items5_" + str(current_shelf_id)

	current_group = get_node_or_null(target_name)
	if current_group:
		current_group.show()
		for i in range(current_group.get_child_count()):
			var child = current_group.get_child(i)
			if child is Area2D:
				# Передаем индекс предмета i в функцию клика
				child.input_event.connect(_on_item_clicked.bind(i))

	if not edit_items_box.text_changed.is_connected(_on_text_changed):
		edit_items_box.text_changed.connect(_on_text_changed)
				
func _setup_items_in_group(group: Node2D):
	for child in group.get_children():
		if child is Area2D:
			# Сбрасываем старые связи, если они были (на всякий случай)
			if child.mouse_entered.is_connected(_on_mouse_entered):
				child.mouse_entered.disconnect(_on_mouse_entered)
			
			# Подключаем новые
			child.mouse_entered.connect(_on_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_mouse_exited.bind(child))
			child.input_event.connect(_on_item_clicked.bind(child))

# Переменная для хранения текущего подсвеченного объекта
var hovered_node: Area2D = null

func _on_mouse_entered(node: Area2D):
	hovered_node = node
	node.queue_redraw() # Заставляем конкретный Area2D перерисоваться

func _on_mouse_exited(node: Area2D):
	if hovered_node == node:
		hovered_node = null
	node.queue_redraw()
	
func _on_mouse_entered_item(item_idx: int):
	hovered_index = item_idx
	queue_redraw()

func _on_mouse_exited_item(item_idx: int):
	if hovered_index == item_idx:
		hovered_index = -1
	queue_redraw()
	
func _on_item_clicked(_viewport, event, _shape_idx, item_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Создаем УНИКАЛЬНЫЙ ID для предмета: полка + индекс (например 1501 + 1 = 15011)
		var shelf_full_id = GlobalSettings.get_full_id(current_shelf_id)
		var item_id = str(shelf_full_id) + str(item_idx + 1)
		
		GlobalSettings.currently_editing_id = int(item_id)
		
		var data = DataManager.cabinet_data.get(item_id, "")
		edit_items_box.text = str(data)
		
		title_label.text = "Предмет №" + str(item_idx + 1)
		info_panel.show()

# ЭТА ФУНКЦИЯ РИСУЕТ СВЕТ ПОВЕРХ КОЛЛИЗИИ
func _draw():
	if hovered_index == -1 or current_group == null:
		return
		
	if hovered_index >= current_group.get_child_count():
		return
		
	var area = current_group.get_child(hovered_index) as Area2D
	if not area: return
	
	for child in area.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var rect_shape = child.shape as RectangleShape2D
			var size = rect_shape.size
			# Вычисляем позицию с учетом трансформации Area2D и самой коллизии
			var rect_pos = to_local(child.global_position) - (size / 2)
			
			draw_rect(Rect2(rect_pos, size), Color(1, 1, 1, 0.2), true) # Заливка
			draw_rect(Rect2(rect_pos, size), Color(1, 1, 1, 0.8), false, 2.0) # Рамка
		
func _on_text_changed():
	var id = str(GlobalSettings.currently_editing_id)
	if id == "0": return
	DataManager.cabinet_data[id] = edit_items_box.text
	DataManager.save_data_to_disk()
	
func _on_back_button_pressed():
	get_tree().change_scene_to_file(GlobalSettings.last_scene_path)

func _on_close_button_pressed():
	info_panel.hide()

func _on_save_button_pressed():
	# Кнопка "Сохранить" теперь просто закрывает окно, так как сохранение идет в реальном времени
	DataManager.save_data_to_disk()
	info_panel.hide()
