extends Node2D

@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box: TextEdit = $UI/InfoPanel/VBoxContainer/EditItemsBox
@onready var shelf_title_label = $UI/InfoPanel/VBoxContainer/TitleLabel
@onready var tooltip_label: Label = $UI/TooltipLabel
@onready var background_sprite = $Sprite2D 
@onready var search_input: LineEdit = $UI/LineEdit

@onready var zoomed_scene_packed = preload("res://zoomed_shelf.tscn")

var current_hovered_shelf: Area2D = null
var active_shelves_container: Node = null 

func _ready():
	info_panel.hide()
	tooltip_label.hide()
	edit_items_box.editable = false
	
	if search_input:
		search_input.text_submitted.connect(_on_search_submitted)
		search_input.text_changed.connect(_on_search_text_changed)

	var w_id = GlobalSettings.current_wardrobe

	var wardrobes_root = get_node_or_null("Wardrobes")
	if wardrobes_root:
		for wardrobe in wardrobes_root.get_children():
			wardrobe.hide()
	
	var current_wardrobe_node = get_node_or_null("Wardrobes/Wardrobe" + str(w_id))
	if current_wardrobe_node:
		current_wardrobe_node.show() 
		active_shelves_container = current_wardrobe_node.get_node_or_null("Shelves")
		
		if active_shelves_container:
			for shelf in active_shelves_container.get_children():
				if shelf is Area2D:
					var s_id = int(shelf.name.replace("Shelf", ""))
					if "shelf_id" in shelf: shelf.shelf_id = s_id
					
					if shelf.input_event.is_connected(_on_shelf_clicked): shelf.input_event.disconnect(_on_shelf_clicked)
					if shelf.mouse_entered.is_connected(_on_shelf_mouse_entered): shelf.mouse_entered.disconnect(_on_shelf_mouse_entered)
					if shelf.mouse_exited.is_connected(_on_shelf_mouse_exited): shelf.mouse_exited.disconnect(_on_shelf_mouse_exited)
					
					shelf.input_event.connect(_on_shelf_clicked.bind(s_id))
					shelf.mouse_entered.connect(_on_shelf_mouse_entered.bind(shelf))
					shelf.mouse_exited.connect(_on_shelf_mouse_exited.bind(shelf))
					
					_adjust_shelf_visibility(shelf, s_id, w_id)

	if not edit_items_box.text_changed.is_connected(_on_main_text_changed):
		edit_items_box.text_changed.connect(_on_main_text_changed)

func _adjust_shelf_visibility(shelf, _s_id, _w_id):
	# Теперь все полки во всех шкафах видны по умолчанию
	shelf.show()
	shelf.process_mode = PROCESS_MODE_INHERIT

func _on_shelf_clicked(_viewport, event, _shape_idx, s_id):
	if event is InputEventMouseButton and event.pressed:
		var w_id = GlobalSettings.current_wardrobe
		var shelf_full_id = GlobalSettings.get_full_id(s_id)

		if event.button_index == MOUSE_BUTTON_LEFT:
			# Теперь для всех шкафов (включая 6) просто показываем список содержимого
			GlobalSettings.currently_editing_id = 0 
			edit_items_box.editable = false 
			var total_text = ""
			for i in range(1, 21):
				var item_id = str(shelf_full_id) + str(i)
				if DataManager.cabinet_data.has(item_id):
					var item_text = str(DataManager.cabinet_data[item_id]).strip_edges()
					if item_text != "":
						total_text += "• " + item_text + "\n"

			edit_items_box.text = total_text if total_text != "" else "Полка пуста (ПКМ для редактирования)"
			shelf_title_label.text = "Содержимое полки №" + str(s_id)
			info_panel.show()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Добавляем 6 к шкафам 3 и 5, которые поддерживают переход в zoomed_shelf
			if w_id == 3 or w_id == 5 or w_id == 6:
				GlobalSettings.current_shelf_id = s_id
				GlobalSettings.last_scene_path = get_tree().current_scene.scene_file_path
				get_tree().change_scene_to_packed(zoomed_scene_packed)

func _on_main_text_changed():
	var id_to_save = str(GlobalSettings.currently_editing_id)
	if id_to_save != "0":
		DataManager.cabinet_data[id_to_save] = edit_items_box.text
		DataManager.save_data_to_disk()

# --- ЛОГИКА ПОИСКА И ПОДСВЕТКИ ДЛЯ ЛАБОРАТОРИИ ---

func _on_search_submitted(new_text: String):
	_clear_search_highlights()
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
				var shelf_full_id_int = int(key_str.substr(0, 4))
				if (shelf_full_id_int / 100.0) * 100 == expected_base:
					var local_id = shelf_full_id_int % 100
					if not local_id in found_ids:
						found_ids.append(local_id)
						
	if active_shelves_container:
		for shelf in active_shelves_container.get_children():
			var s_id = shelf.shelf_id if "shelf_id" in shelf else int(shelf.name.replace("Shelf", ""))
			if s_id in found_ids:
				_add_highlight_rect(shelf)

func _clear_search_highlights():
	if active_shelves_container:
		for shelf in active_shelves_container.get_children():
			var hl = shelf.get_node_or_null("SearchHighlightRect")
			if hl: hl.queue_free()

func _add_highlight_rect(shelf: Area2D):
	var hl = ColorRect.new()
	hl.name = "SearchHighlightRect"
	hl.color = Color(1, 0, 0, 0.4) # Красный цвет поиска
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
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

func _on_close_button_pressed():
	info_panel.hide()
	
func _on_back_button_pressed():
	if GlobalSettings.current_wardrobe >= 3:
		get_tree().change_scene_to_file("res://scene_lab_view.tscn")
	else:
		get_tree().change_scene_to_file("res://scene_cabinet_view.tscn")
