extends Area2D

@export var shelf_id: int = 1
# Достаем спрайт, который лежит ВНУТРИ этой Area2D
@onready var highlight_sprite =$HighlightSprite

func _ready():
	# По умолчанию подсветка каждой полки выключена
	highlight_sprite.visible = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	# Включаем спрайт подсветки ПОВЕРХ основного шкафа
	highlight_sprite.visible = true

func _on_mouse_exited():
	# Выключаем
	highlight_sprite.visible = false

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		DataManager.current_shelf_id = shelf_id
		get_tree().change_scene_to_file("res://ShelfScene.tscn")

func highlight():
	var tween = create_tween()
	highlight_sprite.visible = true
	# Мигаем именно спрайтом подсветки
	tween.tween_property(highlight_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(highlight_sprite, "modulate:a", 1.0, 0.3)
	tween.set_loops(3)
	tween.finished.connect(func(): highlight_sprite.visible = false)
