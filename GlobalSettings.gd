extends Node

var current_cabinet: int = 1   # 1 или 2
var current_wardrobe: int = 1  # 1-Большой, 2-Стена, 3,4,5...-Лаборантская
var current_shelf_id: int = 0
var currently_editing_id: int = 0

# Универсальный ID: Кабинет(тысячи) + Шкаф(сотни) + Полка(единицы)
func get_full_id(local_shelf_id: int) -> int:
	return (current_cabinet * 1000) + (current_wardrobe * 100) + local_shelf_id
