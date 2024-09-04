extends Control


const PIXEL: int = 128
const PIECE_SYMBOL: Dictionary = {
	"King" : "k",
	"Queen" : "q",
	"Rook" : "r",
	"Bishop" : "b",
	"Knight" : "n",
	"Pawn" : "p",
}


func set_pos(pos: Vector2i) -> void:
	for i: int in range(get_child_count()):
		var child: Button = get_child(i)
		var offset: Vector2i = Vector2i(PIXEL / 2, i * PIXEL / get_child_count())
		
		#child.position = Vector2i(pos.x * PIXEL + offset.x, pos.y * PIXEL + offset.y)
		child.position = Vector2i(pos.x * PIXEL, pos.y * PIXEL + offset.y)


func hide_all(enabled: bool) -> void:
	if !enabled:
		await get_tree().create_timer(0.1).timeout
	
	for i: int in range(get_child_count()):
		var child: Button = get_child(i)
		
		if enabled:
			child.hide()
		else:
			child.show()


func _ready() -> void:
	hide_all(true)
	
	for i: int in range(get_child_count()):
		var child: Button = get_child(i)
		var symbol: String = PIECE_SYMBOL[child.get_name()]
		
		child.connect("pressed", _player_chose.bind(symbol))


func _player_chose(option) -> void:
	emit_signal("gui_input", option)
	hide_all(true)
