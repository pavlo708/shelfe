# shelf.gd
extends Area2D

@export var shelf_id: int = 1
var is_hovered: bool = false
var is_highlighting: bool = false
var highlight_alpha: float = 0.0

func _draw():
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var rect = child.shape.get_rect()
			rect.position += child.position
			
			if is_highlighting:
				draw_rect(rect, Color(1, 1, 0, highlight_alpha * 0.4), true)
				draw_rect(rect, Color(1, 1, 0, highlight_alpha), false, 2.5)
			elif is_hovered:
				draw_rect(rect, Color(1, 1, 1, 0.15), true)
				draw_rect(rect, Color(1, 1, 1, 0.5), false, 1.2)

func highlight():
	is_highlighting = true
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(self, "highlight_alpha", 1.0, 0.3)
		tween.parallel().tween_callback(queue_redraw)
		tween.tween_property(self, "highlight_alpha", 0.0, 0.3)
		tween.parallel().tween_callback(queue_redraw)
	tween.finished.connect(func(): is_highlighting = false; queue_redraw())
