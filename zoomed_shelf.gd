#zoomed_shelf
extends Node2D

@onready var shelf_background = $Sprite2D
@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box = $UI/InfoPanel/EditItemsBox

var current_shelf_id = 0
var hovered_index = -1       # Используем это имя везде
var current_group: Node2D = null # Объявляем переменную для группы

func _ready():
	current_shelf_id = GlobalSettings.current_shelf_id
	var w_id = GlobalSettings.current_wardrobe
	
	# 1. Скрываем вообще всё, что начинается на "Items"
	for child in get_children():
		if child is Node2D and child.name.begins_with("Items"):
			child.hide()
	
	# 2. Формируем ИМЯ узла, который мы хотим показать
	var target_name = ""
	
	match w_id:
		1: # Большой шкаф в кабинете
			target_name = "Items" + str(current_shelf_id)
		2: # Шкаф у стены
			target_name = "ItemsWall" + str(current_shelf_id)
		3: # Первый шкаф лабы
			target_name = "Items3_" + str(current_shelf_id)
		5: # Второй шкаф лабы
			target_name = "Items5_" + str(current_shelf_id)
		# Шкафы 4 и 6 мы не обрабатываем, так как сделали им "прямое редактирование"
	
	print("Пытаюсь найти узел: ", target_name) # Смотри это в консоли Godot!

	# 3. Пытаемся включить узел
	current_group = get_node_or_null(target_name)
	
	if current_group:
		current_group.show()
		print("Узел найден и показан!")
		
		# Подключаем сигналы к предметам внутри группы
		for i in range(current_group.get_child_count()):
			var child = current_group.get_child(i)
			if child is Area2D:
				child.input_event.connect(_on_item_clicked.bind(i))
				child.mouse_entered.connect(_on_mouse_entered_item.bind(i))
				child.mouse_exited.connect(_on_mouse_exited_item.bind(i))
	else:
		print("ОШИБКА: В сцене zoomed_shelf нет узла с именем ", target_name)
				
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
	hovered_index = item_idx # Исправлено имя
	queue_redraw() # Рисуем свет

func _on_mouse_exited_item(item_idx: int):
	if hovered_index == item_idx:
		hovered_index = -1 # Исправлено имя
	queue_redraw()
	
func _on_item_clicked(_viewport, event, _shape_idx, item_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Универсальный ID предмета: 
		# (Кабинет * 1000) + (Шкаф * 100) + (Полка * 10) + Индекс предмета
		var base_shelf_id = GlobalSettings.get_full_id(current_shelf_id)
		var item_unique_id = (base_shelf_id * 10) + (item_idx + 1)
		
		GlobalSettings.currently_editing_id = item_unique_id
		
		info_panel.show()
		# Загружаем данные (теперь как массив строк или текст)
		var data = DataManager.cabinet_data.get(str(item_unique_id), "")
		edit_items_box.text = str(data)

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
	# 1. Получаем текущий ID предмета/полки
	var id_to_save = GlobalSettings.currently_editing_id
	if id_to_save == 0: return # На всякий случай
	
	# 2. Собираем текст в массив
	var raw_text = edit_items_box.text
	var new_items = []
	for line in raw_text.split("\n"):
		if line.strip_edges() != "":
			new_items.append(line.strip_edges())
	
	# 3. Обновляем данные в оперативной памяти
	DataManager.cabinet_data[id_to_save] = new_items
	
	# 4. Сохраняем на физический диск (автоматически)
	DataManager.save_data_to_disk()
	
	# Необязательно: можно добавить принт для проверки, потом удалишь
	# print("Автосохранение для ID: ", id_to_save)
func _on_save_button_pressed():
	var id_to_save = GlobalSettings.currently_editing_id
	var raw_text = edit_items_box.text
	var new_items = []
	
	# Правильное разбиение текста на строки
	for line in raw_text.split("\n"):
		if line.strip_edges() != "":
			new_items.append(line.strip_edges())
	
	# Сохраняем в СИНГЛТОН (DataManager), а не в локальную переменную
	DataManager.cabinet_data[id_to_save] = new_items
	
	# Вызываем сохранение на диск
	DataManager.save_data_to_disk()
	
	info_panel.hide()

func _on_back_button_pressed():
	# Переходим по сохраненному пути
	get_tree().change_scene_to_file(GlobalSettings.last_scene_path)

func _on_close_button_pressed():
	DataManager.save_data_to_disk() # Финальное сохранение перед закрытием
	info_panel.hide()
