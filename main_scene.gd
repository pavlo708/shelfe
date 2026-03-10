extends Node2D

@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box: TextEdit = $UI/InfoPanel/VBoxContainer/EditItemsBox
@onready var shelf_title_label = $UI/InfoPanel/VBoxContainer/TitleLabel
@onready var tooltip_label: Label = $UI/TooltipLabel
@onready var search_input: LineEdit = $UI/LineEdit

@onready var zoomed_scene_packed = preload("res://zoomed_shelf.tscn")
var current_hovered_shelf: Area2D = null

func _ready():
	info_panel.hide()
	tooltip_label.hide()
	
	if search_input:
		search_input.text_submitted.connect(_on_search_submitted)
		search_input.text_changed.connect(_on_search_text_changed) # Чтобы снимать подсветку, когда стираем текст
	
	for shelf in $Shelves.get_children():
		if shelf is Area2D:
			var s_id = shelf.shelf_id if "shelf_id" in shelf else int(shelf.name.replace("Shelf", ""))
			shelf.shelf_id = s_id 
			
			if shelf.input_event.is_connected(_on_shelf_clicked): shelf.input_event.disconnect(_on_shelf_clicked)
			if shelf.mouse_entered.is_connected(_on_shelf_mouse_entered): shelf.mouse_entered.disconnect(_on_shelf_mouse_entered)
			if shelf.mouse_exited.is_connected(_on_shelf_mouse_exited): shelf.mouse_exited.disconnect(_on_shelf_mouse_exited)
			
			shelf.input_event.connect(_on_shelf_clicked.bind(s_id))
			shelf.mouse_entered.connect(_on_shelf_mouse_entered.bind(shelf))
			shelf.mouse_exited.connect(_on_shelf_mouse_exited.bind(shelf))
			
	# В main_scene мы только СМОТРИМ собранный список, поэтому отключаем ручной ввод
	edit_items_box.editable = false 
	var save_btn = info_panel.find_child("SaveButton", true, false)
	if save_btn: save_btn.hide()

func _on_shelf_clicked(_viewport, event, _shape_idx, s_id):
	if event is InputEventMouseButton and event.pressed:
		var full_id = GlobalSettings.get_full_id(s_id)
		
		# ЛЕВЫЙ КЛИК: Собираем список предметов из zoomed_shelf
		if event.button_index == MOUSE_BUTTON_LEFT:
			var total_text = ""
			for i in range(1, 21): # Проверяем предметы с 1 по 20
				var item_id = str(full_id) + str(i)
				if DataManager.cabinet_data.has(item_id):
					var item_text = str(DataManager.cabinet_data[item_id]).strip_edges()
					if item_text != "":
						total_text += "• " + item_text + "\n"
			
			if total_text == "":
				total_text = "Полка пуста (Нажмите ПКМ, для редактирования)"
				
			edit_items_box.text = total_text
			shelf_title_label.text = "Содержимое полки №" + str(s_id)
			info_panel.show()
			
		# ПРАВЫЙ КЛИК: Переход в zoomed_shelf
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			GlobalSettings.current_shelf_id = s_id
			GlobalSettings.last_scene_path = get_tree().current_scene.scene_file_path
			get_tree().change_scene_to_packed(zoomed_scene_packed)

# --- ЛОГИКА ПОИСКА И ПОДСВЕТКИ ---

func _on_search_submitted(new_text: String):
	_clear_search_highlights() # Очищаем старую подсветку
	var search_lower = new_text.strip_edges().to_lower()
	if search_lower == "": return
	if search_input: search_input.release_focus()
	
	var found_ids = []
	var expected_base = GlobalSettings.current_cabinet * 1000 + GlobalSettings.current_wardrobe * 100
	
	for key in DataManager.cabinet_data.keys():
		var val = str(DataManager.cabinet_data[key]).to_lower()
		
		if val.find(search_lower) != -1:
			var key_str = str(key)
			if key_str.length() >= 4:
				# Берем первые 4 цифры (это ID полки, даже если ключ 11011 от предмета)
				var shelf_full_id_int = int(key_str.substr(0, 4))
				
				# Проверяем, в этом ли мы шкафу
				if (shelf_full_id_int / 100.0) * 100 == expected_base:
					var local_id = shelf_full_id_int % 100
					if not local_id in found_ids:
						found_ids.append(local_id)
						
	# Создаем визуальную подсветку для найденных полок
	for shelf in $Shelves.get_children():
		var s_id = shelf.shelf_id if "shelf_id" in shelf else int(shelf.name.replace("Shelf", ""))
		if s_id in found_ids:
			_add_highlight_rect(shelf)

func _clear_search_highlights():
	for shelf in $Shelves.get_children():
		var hl = shelf.get_node_or_null("SearchHighlightRect")
		if hl: hl.queue_free()

func _add_highlight_rect(shelf: Area2D):
	var hl = ColorRect.new()
	hl.name = "SearchHighlightRect"
	hl.color = Color(1, 0, 0, 0.4) # Красный полупрозрачный цвет для найденного (можно поменять)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE # Чтобы клики проходили сквозь него
	
	# Подгоняем размер под форму полки
	for child in shelf.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			hl.size = child.shape.size
			hl.position = child.position - (hl.size / 2.0)
			break
			
	shelf.add_child(hl)

func _on_search_text_changed(new_text: String):
	if new_text == "": _clear_search_highlights()

# --- ОСТАЛЬНАЯ ЛОГИКА ---

func _on_shelf_mouse_entered(shelf):
	current_hovered_shelf = shelf
	if "is_hovered" in shelf: shelf.is_hovered = true
	shelf.queue_redraw()
	var s_id = shelf.shelf_id if "shelf_id" in shelf else int(shelf.name.replace("Shelf", ""))
	tooltip_label.text = "Полка №" + str(s_id)
	tooltip_label.show()

func _on_shelf_mouse_exited(shelf):
	if "is_hovered" in shelf: shelf.is_hovered = false
	shelf.queue_redraw()
	if current_hovered_shelf == shelf:
		current_hovered_shelf = null
		tooltip_label.hide()

func _process(_delta):
	if tooltip_label.visible:
		tooltip_label.global_position = get_global_mouse_position() + Vector2(15, 15)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scene_cabinet_view.tscn")

func _on_close_button_pressed():
	info_panel.hide()
