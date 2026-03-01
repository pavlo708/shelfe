extends Node2D

func _ready():
	# Подключаем Большой шкаф (ID 1)
	if has_node("BigWardrobe"):
		$BigWardrobe.input_event.connect(_on_wardrobe_clicked.bind(1))
	
	# Подключаем Шкаф у стены (ID 2)
	if has_node("WallWardrobe"):
		$WallWardrobe.input_event.connect(_on_wardrobe_clicked.bind(2))
	
	# Подключаем дверь в лаборантскую
	if has_node("LabDoor"):
		$LabDoor.input_event.connect(_on_lab_door_clicked)

func _on_wardrobe_clicked(_viewport, event, _shape_idx, ward_num):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Записываем "адрес" шкафа (1, 2, 3...)
		GlobalSettings.current_wardrobe = ward_num
		
		# Загружаем нужный визуальный файл
		if ward_num == 1:
			get_tree().change_scene_to_file("res://main_scene.tscn")
		elif ward_num == 2:
			get_tree().change_scene_to_file("res://main_scene_wall.tscn")
		elif ward_num >= 3:
			get_tree().change_scene_to_file("res://main_scene_lab.tscn")

func _on_lab_door_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://Scene_Lab_View.tscn")

func _on_back_button_pressed():
	# Кнопка возврата в коридор (меню кабинетов)
	get_tree().change_scene_to_file("res://Scene_Menu_Cabinets.tscn")
