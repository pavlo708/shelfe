extends Node2D

var hovered_area: Area2D = null

func _ready():
		# Подключаем Большой шкаф (ID 1)
	if has_node("BigWardrobe"):
		$BigWardrobe.input_event.connect(_on_wardrobe_clicked.bind(1))
	
	# Подключаем Шкаф у стены (ID 2)
	if has_node("WallWardrobe"):
		$WallWardrobe.input_event.connect(_on_wardrobe_clicked.bind(2))
	
	# Подключаем дверь в лаборантскую
	if has_node("LabDoor"):
		$LabDoor.input_event.connect(_on_lab_door_clicked)
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
		
func _on_wardrobe_clicked(_viewport, event, _shape_idx, ward_num):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Записываем "адрес" шкафа (1, 2, 3...)
		GlobalSettings.current_wardrobe = ward_num
		
		# Загружаем нужный визуальный файл
		if ward_num == 1:
			get_tree().change_scene_to_file("res://main_scene.tscn")
		elif ward_num == 2:
			get_tree().change_scene_to_file("res://main_scene_wall.tscn")
		elif ward_num >= 3:
			get_tree().change_scene_to_file("res://main_scene_lab.tscn")

func _on_lab_door_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://scene_lab_view.tscn")

func _on_back_button_pressed():
	# Кнопка возврата в коридор (меню кабинетов)
	get_tree().change_scene_to_file("res://scene_menu_cabinets.tscn")
	
