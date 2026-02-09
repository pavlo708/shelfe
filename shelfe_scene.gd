extends Node2D

@onready var label = $CanvasLayer/Label # Твой текстовый узел

func _ready():
	var id = DataManager.current_shelf_id
	var items = DataManager.cabinet_data.get(id, [])
	
	if items.is_empty():
		label.text = "На этой полке пусто"
	else:
		label.text = "Полка №" + str(id) + ":\n\n"
		for item in items:
			label.text += "- " + item + "\n"

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_scene.tscn")
