#GlobalSettings
extends Node

# Переменная для хранения ID текущей открытой полки
var current_shelf_id: int = 0

# Можно также хранить настройки или пути, если они понадобятся везде
var is_editing_enabled: bool = true

var currently_editing_id: int = 0

var editing_line_index: int = -1
