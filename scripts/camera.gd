extends Camera2D


@onready var GAME: Node2D = get_node("/root/Game")
const PIXEL: int = 16
var prev_viewport_size: int = 0

func _process(_delta) -> void:
	position = Vector2i(GAME.GRID_SIZE * GAME.OFFSET * PIXEL / 2, GAME.GRID_SIZE * GAME.OFFSET * PIXEL / 2)
	
	var viewport_size: int = mini(get_viewport().size[0], get_viewport().size[1])
	var cam_zoom: float
	
	if viewport_size != prev_viewport_size:
		prev_viewport_size = viewport_size
	
	cam_zoom = float(viewport_size) / (GAME.GRID_SIZE * GAME.OFFSET * PIXEL)

	set_zoom(Vector2i(cam_zoom, cam_zoom))
