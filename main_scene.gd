extends Node2D

@onready var search_input = $UI/LineEdit

func _on_line_edit_text_submitted(new_text: String):
	# 1. Ищем ID полки через наш глобальный DataManager
	var shelf_id = DataManager.find_shelf_by_item(new_text)
	
	if shelf_id > 0:
		# 2. Ищем узел полки в сцене. 
		# Предположим, твои Area2D называются "Shelf1", "Shelf2" и лежат внутри узла "Shelves"
		var shelf_node = get_node("Shelves/Shelf" + str(shelf_id))
		
		if shelf_node:
			shelf_node.highlight() # Вызываем функцию подсветки из скрипта полки
	else:
		print("Ничего не найдено")
