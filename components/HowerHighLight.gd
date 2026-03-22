# HoverHighlight.gd
extends Area2D

var is_hovered: bool = false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	is_hovered = true
	queue_redraw()

func _on_mouse_exited():
	is_hovered = false
	queue_redraw()

func _draw():
	if is_hovered:
		for child in get_children():
			if child is CollisionShape2D and child.shape is RectangleShape2D:
				var rect = child.shape.get_rect()
				draw_rect(rect, Color(1, 1, 1, 0.2), true) # Заливка
				draw_rect(rect, Color(1, 1, 1, 0.6), false, 2.0) # Контур
