extends Node2D

func _ready():
	# Подключаем каждый шкаф к функции перехода
	$LabWardrobe1.input_event.connect(_on_wardrobe_clicked.bind(3))
	$LabWardrobe2.input_event.connect(_on_wardrobe_clicked.bind(4))
	$LabWardrobe3.input_event.connect(_on_wardrobe_clicked.bind(5))
	$LabWardrobe4.input_event.connect(_on_wardrobe_clicked.bind(6))

func _on_wardrobe_clicked(_vp, event, _idx, ward_num):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GlobalSettings.current_wardrobe = ward_num
		# Переходим в ЕДИНУЮ сцену открытого шкафа
		get_tree().change_scene_to_file("res://main_scene_lab.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scene_Cabinet_View.tscn")
