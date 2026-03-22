extends Node2D

var hovered_wardrobe: int = -1
var hovered_area: Area2D = null

func _ready():
	for i in [3, 4, 5, 6]:
		var area = get_node_or_null("LabWardrobe" + str(i))
		if area:
			# Подключаем ЛКМ для перехода
			area.input_event.connect(_on_wardrobe_click.bind(i))
			# Подключаем подсветку
			area.mouse_entered.connect(_on_mouse_entered.bind(area))
			area.mouse_exited.connect(_on_mouse_exited.bind(area))
	# Перебираем все дочерние элементы сцены
	for child in get_children():
		# Если это шкаф или дверь (Area2D)
		if child is Area2D:
			# Отключаем старые сигналы на всякий случай, чтобы не было дублей
			if child.mouse_entered.is_connected(_on_area_mouse_entered):
				child.mouse_entered.disconnect(_on_area_mouse_entered)
			if child.mouse_exited.is_connected(_on_area_mouse_exited):
				child.mouse_exited.disconnect(_on_area_mouse_exited)
			
			# Подключаем сигналы
			child.mouse_entered.connect(_on_area_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_area_mouse_exited.bind(child))

# --- Добавьте эти две функции в конец каждого скрипта ---
func _on_area_mouse_entered(area: Area2D):
	hovered_area = area
	if "is_hovered" in area: 
		area.is_hovered = true
	area.queue_redraw() # Даем команду перерисовать Area2D с подсветкой

func _on_area_mouse_exited(area: Area2D):
	if "is_hovered" in area: 
		area.is_hovered = false
	area.queue_redraw() # Убираем подсветку
	if hovered_area == area:
		hovered_area = null
func _on_wardrobe_click(_viewport, event, _shape_idx, wardrobe_id):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GlobalSettings.current_wardrobe = wardrobe_id
		# Переходим в сцену, где отрисован конкретный шкаф с полками
		get_tree().change_scene_to_file("res://main/main_scene_lab.tscn")


func _on_mouse_entered(area):
	hovered_area = area
	queue_redraw()

func _on_mouse_exited(area):
	if hovered_area == area:
		hovered_area = null
		queue_redraw()
		
var is_hovered: bool = false
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


func _on_back_button_pressed():
		get_tree().change_scene_to_file("res://scenes/scene_cabinet_view.tscn")
