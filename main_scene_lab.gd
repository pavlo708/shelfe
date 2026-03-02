extends Node2D

@onready var wardrobes_container = $Wardrobes
@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box = $UI/InfoPanel/VBoxContainer/EditItemsBox

func _ready():
	info_panel.hide()
	var ward_id = GlobalSettings.current_wardrobe
	
	# Проходим по всем шкафам в контейнере
	for wardrobe in wardrobes_container.get_children():
		# Показываем только тот, чей ID совпадает (например "Wardrobe3")
		if wardrobe.name == "Wardrobe" + str(ward_id):
			wardrobe.show()
			_setup_wardrobe_signals(wardrobe)
		else:
			wardrobe.hide()

# Функция для автоматического подключения всех полок шкафа
func _setup_wardrobe_signals(wardrobe_node):
	var shelves_group = wardrobe_node.get_node("Shelves")
	for shelf in shelves_group.get_children():
		if shelf is Area2D:
			# Извлекаем номер из имени "Shelf5" -> 5
			var s_id = int(shelf.name.replace("Shelf", ""))
			# Подключаем сигналы клика и наведения (как в первом шкафу)
			shelf.input_event.connect(_on_shelf_clicked.bind(s_id))
			if shelf.has_signal("mouse_entered"):
				shelf.mouse_entered.connect(_on_shelf_mouse_entered.bind(shelf))
				shelf.mouse_exited.connect(_on_shelf_mouse_exited.bind(shelf))

func _on_shelf_clicked(_vp, event, _idx, s_id):
	if event is InputEventMouseButton and event.pressed:
		var full_id = GlobalSettings.get_full_id(s_id)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_shelf_info_combined(full_id)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			GlobalSettings.current_shelf_id = s_id
			get_tree().change_scene_to_file("res://zoomed_shelf.tscn")

func show_shelf_info_combined(shelf_id: int):
	GlobalSettings.currently_editing_id = shelf_id
	
	var title = info_panel.find_child("TitleLabel", true, false)
	if title: title.text = "Содержимое полки №" + str(shelf_id)
	
	var display_lines = []
	if DataManager.cabinet_data.has(shelf_id):
		display_lines.append_array(DataManager.cabinet_data[shelf_id])
	
	# Добор из мелких предметов (отсеков)
	var all_keys = DataManager.cabinet_data.keys()
	var prefix = shelf_id * 100
	for key in all_keys:
		if key > prefix and key < prefix + 100:
			display_lines.append_array(DataManager.cabinet_data[key])
			
	edit_items_box.text = "\n".join(display_lines)
	info_panel.show()

# Кнопки UI
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scene_Lab_View.tscn")

func _on_close_button_pressed():
	info_panel.hide()

# Опционально: подсветка как в основном шкафу
func _on_shelf_mouse_entered(shelf):
	if "is_hovered" in shelf: shelf.is_hovered = true
	shelf.queue_redraw()

func _on_shelf_mouse_exited(shelf):
	if "is_hovered" in shelf: shelf.is_hovered = false
	shelf.queue_redraw()
