extends Camera2D


@onready var Game: Node2D = get_parent()
const PIXEL: int = 128

func _process(_delta) -> void:
	position = Vector2i(Game.GRID_SIZE * PIXEL / 2, Game.GRID_SIZE * PIXEL / 2)
	
	var viewport_size: int = mini(get_viewport().size[0], get_viewport().size[1])
	var cam_zoom: float
	
	cam_zoom = float(viewport_size) / (Game.GRID_SIZE * PIXEL)

	set_zoom(Vector2(cam_zoom, cam_zoom))
