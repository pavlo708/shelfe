#zoomed_shelf
extends Node2D

@onready var shelf_background = $Sprite2D
@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box = $UI/InfoPanel/EditItemsBox

var current_shelf_id = 0
var hovered_index = -1 

func _ready():
	current_shelf_id = GlobalSettings.current_shelf_id
	info_panel.hide()
	edit_items_box.text_changed.connect(_on_text_changed)
	# Показываем нужную группу полок
	var items_group = get_node_or_null("Items" + str(current_shelf_id))
	if items_group:
		items_group.show()
		for i in range(items_group.get_child_count()):
			var child = items_group.get_child(i)
			if child is Area2D:
				child.input_event.connect(_on_item_clicked.bind(i))
				child.mouse_entered.connect(_on_mouse_entered_item.bind(i))
				child.mouse_exited.connect(_on_mouse_exited_item.bind(i))

# Вызывается при наведении
func _on_mouse_entered_item(index):
	hovered_index = index
	queue_redraw()
	
# Вызывается при уходе
func _on_mouse_exited_item(exited_index):
	if hovered_index == exited_index:
		hovered_index = -1
		queue_redraw()

# ЭТА ФУНКЦИЯ РИСУЕТ СВЕТ ПОВЕРХ КОЛЛИЗИИ
func _draw():
	if hovered_index == -1:
		return
		
	var items_group = get_node_or_null("Items" + str(current_shelf_id))
	if not items_group or hovered_index >= items_group.get_child_count():
		return
		
	var area = items_group.get_child(hovered_index) as Area2D
	if not area: return
	
	# Теперь мы не ищем одну коллизию, а перебираем ВСЕ внутри Area2D
	for child in area.get_children():
		if child is CollisionShape2D:
			# Проверяем, что это прямоугольник
			if child.shape is RectangleShape2D:
				var rect_shape = child.shape as RectangleShape2D
				var size = rect_shape.size
				
				# Вычисляем позицию конкретно этой коллизии
				var rect_pos = to_local(child.global_position) - (size / 2)
				
				# Рисуем подсветку для этой части предмета
				draw_rect(Rect2(rect_pos, size), Color(1, 1, 0, 0.3), true) # Заливка
				draw_rect(Rect2(rect_pos, size), Color(1, 1, 0, 0.8), false, 2.0) # Рамка

func _on_item_clicked(_viewport, event, _shape_idx, item_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item_full_id = (current_shelf_id * 100) + (item_index + 1)
		GlobalSettings.currently_editing_id = item_full_id
		
		# Устанавливаем заголовок: всегда начинается с 1 внутри каждой полки
		# Находим Label заголовка внутри InfoPanel
		var title = info_panel.find_child("TitleLabel", true, false)
		if title:
			title.text = "Предмет №" + str(item_index + 1)
		
		var items = DataManager.cabinet_data.get(item_full_id, [])
		edit_items_box.text = "\n".join(items)
		info_panel.show()
		
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
	DataManager.save_data_to_disk() # Сохраняем перед переходом на главную
	get_tree().change_scene_to_file("res://main_scene.tscn")

func _on_close_button_pressed():
	DataManager.save_data_to_disk() # Финальное сохранение перед закрытием
	info_panel.hide()
