extends Node2D

func _ready():
	# Шкафы лаборантской начинаются с ID 3
	$LabWardrobeA.input_event.connect(_on_wardrobe_clicked.bind(3))
	$LabWardrobeB.input_event.connect(_on_wardrobe_clicked.bind(4))

func _on_wardrobe_clicked(_vp, event, _idx, ward_num):
	if event is InputEventMouseButton and event.pressed:
		GlobalSettings.current_wardrobe = ward_num
		# Открываем специфическую сцену для лаборантских шкафов
		get_tree().change_scene_to_file("res://main_scene_lab.tscn")


func _on_back_button_pressed() -> void:
	# Возвращаемся в кабинет
	get_tree().change_scene_to_file("res://Scene_Cabinet_View.tscn")
