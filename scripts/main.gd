extends Node2D


@onready var BOARD_LAYER: TileMapLayer = get_node("Board")
@onready var PIECE_LAYER: TileMapLayer = get_node("Piece")
@onready var HIGHLIGHT_LAYER: TileMapLayer = get_node("Highlight")
@onready var GET_MOVABLE: Node2D = get_node("GetMovable")
const GRID_SIZE: int = 8
const LAYOUT: String = "rnbqkbnr"
var piece_atlas_map: Dictionary
var board_pos: Array
var white_king_pos: Vector2i
var black_king_pos: Vector2i
var is_white_turn: bool = true
var can_be_captured_ep: Vector2i = Vector2i(-1, 0) # y is a countdown for when en passant can happen
var is_ep_capture: bool = false
var movable: Array
var selected_piece_pos: Vector2i = Vector2i(-1, -1)


func gen_piece_atlas_dict() -> void:
	var pieces: String = "kqrbnp"
	var count: int = 2
	
	for piece: String in pieces:
		piece_atlas_map[piece.to_upper()] = count # White
		piece_atlas_map[piece] = count + 1 # Black
		
		count += 2


func is_dark_sq(pos: Vector2i) -> bool:
	return (pos.x + pos.y) % 2 == 1


func is_white_piece(piece: String) -> bool:
	return piece == piece.to_upper()


func piece_at(loc: Vector2i) -> String:
	return board_pos[loc.x][loc.y]


func coord_to_chess_sq(coord: Vector2i) -> String:
	return char("a".to_ascii_buffer()[0] + coord.x) + char("0".to_ascii_buffer()[0] + GRID_SIZE - coord.y)


func chess_sq_to_coord(chess_sq: String) -> Vector2i:
	return Vector2i(chess_sq[0].to_lower().to_ascii_buffer()[0] - "a".to_ascii_buffer()[0], GRID_SIZE - chess_sq[1].to_ascii_buffer()[0])


func gen_board() -> void:
	for i: int in range(GRID_SIZE):
		board_pos.push_back([])
		
		for j: int in range(GRID_SIZE):
			board_pos[i].push_back([])
			board_pos[i][j] = "-"
			
			if is_dark_sq(Vector2i(i, j)):
				BOARD_LAYER.set_cell(Vector2i(i, j), 0, Vector2i(1, 0))
			else:
				BOARD_LAYER.set_cell(Vector2i(i, j), 0, Vector2i(0, 0))


func place_piece(piece: String, pos: Vector2i) -> void:
	board_pos[pos.x][pos.y] = piece
	
	if piece == "K":
		white_king_pos = pos
	elif piece == "k":
		black_king_pos = pos

	if piece == "-":
		PIECE_LAYER.set_cell(Vector2i(pos.x, pos.y))
		return
			
	if piece == "P" && pos.y == 0:
		place_piece("Q", pos)
		return
		
	if piece == "p" && pos.y == GRID_SIZE - 1:
		place_piece("q", pos)
		return
	
	if is_white_piece(piece): # White
		PIECE_LAYER.set_cell(Vector2i(pos.x, pos.y), piece_atlas_map[piece], Vector2i(0, 0))
	else: # Black
		PIECE_LAYER.set_cell(Vector2i(pos.x, pos.y), piece_atlas_map[piece], Vector2i(0, 0))


func set_board(layout: String) -> void:
	for i: int in mini(GRID_SIZE, len(layout)):
		place_piece(layout[i].to_lower(), Vector2i(i, 0)) # Black
		place_piece(layout[i].to_upper(), Vector2i(i, GRID_SIZE - 1)) # Black
		
	for i: int in GRID_SIZE:
		place_piece("p", Vector2i(i, 1)) # White
		place_piece("P", Vector2i(i, GRID_SIZE - 2)) # White


func highlight_movable(highlight: bool) -> void:
	if !highlight:
		for i: int in range(GRID_SIZE):
			for j: int in range(GRID_SIZE):
				var sq: Vector2i = Vector2i(i, j)
				
				HIGHLIGHT_LAYER.set_cell(sq)
		return
	
	highlight_movable(false)
	
	for sq: Vector2i in movable:
		HIGHLIGHT_LAYER.set_cell(sq, 1, Vector2i(0, 0), 0)


func highlight_prev_move(pos: Vector2i) -> void:
	if pos == Vector2i(-1, -1):
		for i: int in range(GRID_SIZE):
			for j: int in range(GRID_SIZE):
				var sq: Vector2i = Vector2i(i, j)
				var atlas_coord: Vector2i
				
				if is_dark_sq(sq):
					atlas_coord = Vector2i(1, 0)
				else:
					atlas_coord = Vector2i(0, 0)
				
				BOARD_LAYER.set_cell(sq, 0, atlas_coord, 0)
		
		return
	
	highlight_prev_move(Vector2i(-1, -1))
	
	var atlas_coord: Vector2i
	
	if is_dark_sq(pos):
		atlas_coord = Vector2i(3, 0)
	else:
		atlas_coord = Vector2i(2, 0)
	
	BOARD_LAYER.set_cell(pos, 0, atlas_coord, 0)


func get_movable_sq(pos: Vector2i) -> void:
	movable = []

	match piece_at(pos):
		"P":
			movable = GET_MOVABLE.pawn_white(pos)
		"p":
			movable = GET_MOVABLE.pawn_black(pos)
		"N":
			movable = GET_MOVABLE.knight(pos, true)
		"n":
			movable = GET_MOVABLE.knight(pos, false)
		"B":
			movable = GET_MOVABLE.bishop(pos, true)
		"b":
			movable = GET_MOVABLE.bishop(pos, false)
		"R":
			movable = GET_MOVABLE.rook(pos, true)
		"r":
			movable = GET_MOVABLE.rook(pos, false)
		"Q":
			movable = GET_MOVABLE.queen(pos, true)
		"q":
			movable = GET_MOVABLE.queen(pos, false)
		"K":
			movable = GET_MOVABLE.king(pos, true)
		"k":
			movable = GET_MOVABLE.king(pos, false)


func ep_capture() -> void:
	if is_ep_capture:
		if is_white_turn:
			place_piece("-", Vector2i(can_be_captured_ep.x, 3))
		else:
			place_piece("-", Vector2i(can_be_captured_ep.x, GRID_SIZE - 4))
	else:
		if can_be_captured_ep.y > 0:
			can_be_captured_ep.y -= 1


func player_select_piece(click_pos: Vector2i) -> void:
	var piece: String = piece_at(click_pos)
			
	if piece != "-":
		if is_white_turn && is_white_piece(piece) || !is_white_turn && !is_white_piece(piece):
			selected_piece_pos = click_pos
			get_movable_sq(click_pos)
			highlight_movable(true)
	else:
		selected_piece_pos = Vector2i(-1, -1)
		highlight_movable(false)


func player_place_piece(click_pos: Vector2i) -> void:
	if click_pos in movable:
		place_piece(piece_at(selected_piece_pos), click_pos)
		place_piece("-", selected_piece_pos)
		
		ep_capture()
		
		highlight_movable(false)
		highlight_prev_move(selected_piece_pos)
		selected_piece_pos = Vector2i(-1, -1)
		is_white_turn = !is_white_turn
		is_ep_capture = false
	else:
		player_select_piece(click_pos)


func _ready() -> void:
	gen_piece_atlas_dict()
	gen_board()
	set_board(LAYOUT)


func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() != MOUSE_BUTTON_LEFT || !event.is_pressed():
			return
			
		var click_pos: Vector2i = BOARD_LAYER.local_to_map(get_local_mouse_position())
		
		if click_pos.x < 0 || click_pos.y < 0 || click_pos.x >= GRID_SIZE || click_pos.y >= GRID_SIZE:
			return
		
		if selected_piece_pos == Vector2i(-1, -1):
			player_select_piece(click_pos)
		else:
			player_place_piece(click_pos)
