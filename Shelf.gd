# shelf.gd
extends Area2D

@export var shelf_id: int = 1
var is_hovered: bool = false
var is_highlighting: bool = false
var highlight_alpha: float = 0.0

func _draw():
	if is_hovered:
		var shape_node = $CollisionShape2D
		if shape_node and shape_node.shape is RectangleShape2D:
			var rect = shape_node.shape.get_rect()
			
			# Сохраняем текущую матрицу трансформации, чтобы рисовать 
			# относительно позиции CollisionShape2D, а не родителя Area2D
			draw_set_transform(shape_node.position, shape_node.rotation, shape_node.scale)
			
			# Рисуем заливку и контур
			draw_rect(rect, Color(1, 1, 1, 0.2), true)  # Полупрозрачный белый
			draw_rect(rect, Color(1, 1, 1, 0.8), false, 2.0) # Яркий контур
			
			# Сбрасываем трансформацию обратно
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func highlight():
	is_highlighting = true
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(self, "highlight_alpha", 1.0, 0.3)
		tween.parallel().tween_callback(queue_redraw)
		tween.tween_property(self, "highlight_alpha", 0.0, 0.3)
		tween.parallel().tween_callback(queue_redraw)
	tween.finished.connect(func(): is_highlighting = false; queue_redraw())
