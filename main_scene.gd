# main_scene.gd
extends Node2D

@onready var info_panel = $UI/InfoPanel
@onready var edit_items_box: TextEdit = $UI/InfoPanel/VBoxContainer/EditItemsBox
@onready var shelf_title_label = $UI/InfoPanel/VBoxContainer/TitleLabel
@onready var tooltip_label: Label = $UI/TooltipLabel
@onready var export_status_label: Label = $UI/ExportStatusLabel
@onready var search_input: LineEdit = $UI/LineEdit
@onready var export_dialog: FileDialog = $UI/ExportDialog

var current_hovered_shelf: Area2D = null
func _ready():
	info_panel.hide()
	tooltip_label.hide()
	
	if search_input:
		search_input.text_submitted.connect(_on_search_submitted)
	
	# Инициализируем полки
	for shelf in $Shelves.get_children():
		if shelf is Area2D:
			# 1. Получаем ID
			var s_id = shelf.shelf_id if "shelf_id" in shelf else int(shelf.name.replace("Shelf", ""))
			shelf.shelf_id = s_id # Синхронизируем на всякий случай
			
			# 2. Очищаем старые сигналы (чтобы не дублировались)
			if shelf.input_event.is_connected(_on_shelf_clicked): shelf.input_event.disconnect(_on_shelf_clicked)
			
			# 3. ПОДКЛЮЧАЕМ ВСЁ ЗАНОВО
			shelf.input_event.connect(_on_shelf_clicked.bind(s_id))
			shelf.mouse_entered.connect(_on_shelf_mouse_entered.bind(shelf))
			shelf.mouse_exited.connect(_on_shelf_mouse_exited.bind(shelf))
			
	edit_items_box.editable = false 
	# Скрываем кнопку сохранения, если она есть (например, по имени узла)
	var save_btn = info_panel.find_child("SaveButton", true, false)
	if save_btn: save_btn.hide()
	
func _on_shelf_clicked(_viewport, event, _shape_idx, s_id):
	# Проверяем, что это именно нажатие кнопки мыши
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# ПКМ - переход
			enter_zoomed_shelf(s_id)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# ЛКМ - информация
			show_shelf_info_combined(s_id)

func _process(_delta):
	# Тултип следует за мышкой
	if tooltip_label.visible:
		tooltip_label.global_position = get_global_mouse_position() + Vector2(15, 15)

func enter_zoomed_shelf(shelf_id):
	GlobalSettings.current_shelf_id = shelf_id
	get_tree().change_scene_to_file("res://zoomed_shelf.tscn")

func _on_search_submitted(new_text: String):
	if new_text.strip_edges() == "": return
	
	var found_ids = DataManager.find_all_shelves_by_item(new_text)
	print("Найдено в полках: ", found_ids) # Посмотри в консоль Godot (снизу)
	
	search_input.release_focus()
	
	for shelf in $Shelves.get_children():
		if shelf.has_method("highlight"):
			# Получаем ID полки из её скрипта
			if shelf.shelf_id in found_ids:
				shelf.highlight()
				
func _on_shelf_mouse_entered(shelf):
	current_hovered_shelf = shelf
	
	# Прямая установка переменной в скрипте shelf.gd
	if "is_hovered" in shelf:
		shelf.is_hovered = true
	
	shelf.queue_redraw()
	
	tooltip_label.text = "Полка №" + str(shelf.shelf_id)
	tooltip_label.show()

func _on_shelf_mouse_exited(shelf):
	# Выключаем подсветку СРАЗУ при уходе
	if "is_hovered" in shelf:
		shelf.is_hovered = false
	
	shelf.queue_redraw()
	
	# А тултип скрываем, только если мышь не перешла на другую полку
	if current_hovered_shelf == shelf:
		current_hovered_shelf = null
		tooltip_label.hide()
		
func show_shelf_info_combined(shelf_id):
	GlobalSettings.currently_editing_id = shelf_id
	shelf_title_label.text = "Содержимое полки №" + str(shelf_id)
	
	var display_lines = []
	
	# 1. Берем содержимое основной полки
	if DataManager.cabinet_data.has(shelf_id):
		display_lines.append_array(DataManager.cabinet_data[shelf_id])
	
	# 2. Берем содержимое отсеков (101, 107 и т.д.) БЕЗ надписи "[Отсек]"
	var all_keys = DataManager.cabinet_data.keys()
	all_keys.sort()
	var prefix = shelf_id * 100
	for key in all_keys:
		if key > prefix and key < prefix + 100:
			# Добавляем только предметы, без технических пометок
			display_lines.append_array(DataManager.cabinet_data[key])
	
	# Объединяем в текст. Если пусто — будет пустая строка.
	edit_items_box.text = "\n".join(display_lines)
	info_panel.show()

func _on_close_button_pressed():
	DataManager.save_data_to_disk()
	info_panel.hide()

func _on_export_button_pressed():
	# Просто открываем окно выбора файла
	export_dialog.popup_centered()
	
func _on_export_file_selected(path: String):
	# Когда пользователь выбрал путь и нажал "Сохранить"
	var success = DataManager.export_to_path(path)
	
	if success:
		export_status_label.text = "Файл успешно сохранен!"
	else:
		export_status_label.text = "Ошибка при сохранении файла."
	
	export_status_label.show()
	await get_tree().create_timer(3.0).timeout
	export_status_label.hide()
	
func _on_text_changed():
	pass
