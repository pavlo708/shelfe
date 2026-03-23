extends Node2D

var hovered_area: Area2D = null

func _ready():
	# 1. Переход в Шкаф №7 (второй кабинет)
	if has_node("BigWardrobe"):
		$BigWardrobe.input_event.connect(_on_wardrobe_clicked.bind(7))
	
	# 2. Переход в Лаборантскую из второго кабинета
	if has_node("LabDoor"):
		$LabDoor.input_event.connect(_on_lab_door_clicked)
		
		# Подсветка при наведении (как в первом кабинете)
	for child in get_children():
		if child is Area2D:
			child.mouse_entered.connect(_on_area_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_area_mouse_exited.bind(child))

func _on_area_mouse_entered(area: Area2D):
	hovered_area = area
	if "is_hovered" in area: 
		area.is_hovered = true
	area.queue_redraw()

func _on_area_mouse_exited(area: Area2D):
	if "is_hovered" in area: 
		area.is_hovered = false
	area.queue_redraw()
	if hovered_area == area:
		hovered_area = null
		
func _on_wardrobe_clicked(_viewport, event, _shape_idx, ward_num):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Записываем "адрес" нового шкафа
		GlobalSettings.current_wardrobe = ward_num
		
		# Переходим на промежуточную сцену шкафа 
		get_tree().change_scene_to_file("res://main/main_scene2.tscn")

func _on_lab_door_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Переход в ту же лаборантскую (или создай scene_lab2_view.tscn)
		get_tree().change_scene_to_file("res://scenes/scene_lab_view.tscn")

func _on_back_button_pressed():
	# Для кнопки "Назад" в интерфейсе
	get_tree().change_scene_to_file("res://scenes/scene_menu_cabinets.tscn")
