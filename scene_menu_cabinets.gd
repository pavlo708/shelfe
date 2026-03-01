extends Node2D

func _ready():
	# Подключаем клики программно, если не хочешь через инспектор
	$Door1.input_event.connect(_on_door_clicked.bind(1))
	$Door2.input_event.connect(_on_door_clicked.bind(2))

func _on_door_clicked(_viewport, event, _shape_idx, cabinet_num):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GlobalSettings.current_cabinet = cabinet_num
		get_tree().change_scene_to_file("res://Scene_Cabinet_View.tscn")
