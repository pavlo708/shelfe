# GlobalSettings.gd
extends Node

var current_cabinet: int = 1
var current_wardrobe: int = 1 
var current_shelf_id: int = 0
var currently_editing_id: int = 0

# Новая переменная для возврата
var last_scene_path: String = "res://main_scene.tscn" 

func get_full_id(local_id: int) -> int:
	# 1 (каб) * 1000 + 6 (шкаф) * 100 + 1 (полка) = 1601
	return (current_cabinet * 1000) + (current_wardrobe * 100) + local_id
	
	
