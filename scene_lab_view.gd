extends Node2D

var hovered_wardrobe: int = -1

func _ready():
	# Подключаем 4 зоны шкафов (убедись, что имена Wardrobe3...6 совпадают с деревом сцены)
	for i in [3, 4, 5, 6]:
		var area = get_node_or_null("LabWardrobe" + str(i))
		if area:
			# Подключаем ЛКМ для перехода
			area.input_event.connect(_on_wardrobe_click.bind(i))
			# Подключаем подсветку
			area.mouse_entered.connect(_on_mouse_entered.bind(area))
			area.mouse_exited.connect(_on_mouse_exited.bind(area))


func _on_wardrobe_click(_viewport, event, _shape_idx, wardrobe_id):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GlobalSettings.current_wardrobe = wardrobe_id
		# Переходим в сцену, где отрисован конкретный шкаф с полками
		get_tree().change_scene_to_file("res://main_scene_lab.tscn")

var hovered_area = null
func _on_mouse_entered(area):
	hovered_area = area
	queue_redraw()

func _on_mouse_exited(area):
	if hovered_area == area:
		hovered_area = null
		queue_redraw()

func _draw():
	if hovered_wardrobe != -1:
		var area = get_node_or_null("LabWardrobe" + str(hovered_wardrobe))
		if area:
			var shape_node = area.get_node("CollisionShape2D")
			if shape_node and shape_node.shape is RectangleShape2D:
				var rect = shape_node.shape.get_rect()
				# Рисуем поверх коллизии
				draw_set_transform(area.position + shape_node.position, area.rotation, area.scale)
				draw_rect(rect, Color(1, 1, 1, 0.2), true)
				draw_rect(rect, Color(1, 1, 1, 0.6), false, 2.0)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
