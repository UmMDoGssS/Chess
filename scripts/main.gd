extends Node2D


signal game_end(type)

const GRID_SIZE: int = 8
const LAYOUT: String = "rnbqkbnr"

var piece_atlas_map: Dictionary

var board: Array # 2d array
var half_turn: int = 0
var movable: Array
var all_game_pos: Dictionary # use to check three fold repetion using fen notation
var turns_since_pawn_moves_or_capture: int

var attack_white: Array
var attack_black: Array
var white_king_pos: Vector2i
var black_king_pos: Vector2i

var can_be_captured_ep_x: int
var can_be_captured_ep: bool
var can_castle_white: Array
var can_castle_black: Array

var selected_piece_pos: Vector2i = Vector2i(-1, -1)
var pause_select: bool = false


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


func is_white_turn() -> bool:
	return half_turn % 2 == 0


func piece_at(loc: Vector2i) -> String:
	return board[loc.x][loc.y]


func coord_to_chess_sq(coord: Vector2i) -> String:
	return char("a".to_ascii_buffer()[0] + coord.x) + char("0".to_ascii_buffer()[0] + GRID_SIZE - coord.y)


func chess_sq_to_coord(chess_sq: String) -> Vector2i:
	return Vector2i(chess_sq[0].to_lower().to_ascii_buffer()[0] - "a".to_ascii_buffer()[0], GRID_SIZE - chess_sq[1].to_ascii_buffer()[0])


func gen_board() -> void:
	for i: int in range(GRID_SIZE):
		board.push_back([])
		
		for j: int in range(GRID_SIZE):
			board[i].push_back([])
			board[i][j] = "-"
			
			if is_dark_sq(Vector2i(i, j)):
				$BoardLayer.set_cell(Vector2i(i, j), 0, Vector2i(1, 0))
			else:
				$BoardLayer.set_cell(Vector2i(i, j), 0, Vector2i(0, 0))


func place_piece(piece: String, pos: Vector2i) -> void:
	board[pos.x][pos.y] = piece
	
	if piece == "K":
		white_king_pos = pos
	elif piece == "k":
		black_king_pos = pos

	if piece == "-":
		$PieceLayer.set_cell(Vector2i(pos.x, pos.y))
		return
	
	if is_white_piece(piece): # White
		$PieceLayer.set_cell(Vector2i(pos.x, pos.y), piece_atlas_map[piece], Vector2i(0, 0))
	else: # Black
		$PieceLayer.set_cell(Vector2i(pos.x, pos.y), piece_atlas_map[piece], Vector2i(0, 0))


func set_board(layout: String) -> void:
	for i: int in mini(GRID_SIZE, len(layout)):
		place_piece(layout[i].to_lower(), Vector2i(i, 0)) # Black
		place_piece(layout[i].to_upper(), Vector2i(i, GRID_SIZE - 1)) # White
		
		if layout[i].to_lower() == "k":
			black_king_pos = Vector2i(i, 0)
			white_king_pos = Vector2i(i, GRID_SIZE - 1)
		
	for i: int in GRID_SIZE:
		place_piece("p", Vector2i(i, 1)) # White
		place_piece("P", Vector2i(i, GRID_SIZE - 2)) # White


func set_castle(layout: String) -> void:
	for i: int in mini(GRID_SIZE, len(layout)):
		if layout[i].to_lower() == "r":
			can_castle_white.push_back(i)
			can_castle_black.push_back(i)


func get_fen() -> String:
	var fen: String = "/"
	var count: int
	
	for i: int in range(GRID_SIZE - 1, -1, -1):
		count = 0
		
		for j: int in range(GRID_SIZE):
			var piece: String = piece_at(Vector2i(j, i))
			
			if piece != "-":
				if count > 0:
					fen += char(count + "0".to_ascii_buffer()[0])
					count = 0
				
				fen += piece
			else:
				count += 1
		
		if count > 0:
			fen += char(count + "0".to_ascii_buffer()[0])
		
		fen += "/"
	
	return fen


func is_captures(new_pos: Vector2i) -> bool:
	return piece_at(new_pos) != "-"


func is_pawn_moves(pos: Vector2i) -> bool:
	return piece_at(pos).to_lower() == "p"


func is_in_check(white: bool) -> bool:
	if white:
		return white_king_pos in attack_black
	else:
		return black_king_pos in attack_white


func has_legal_move(white: bool) -> bool:
	var moves: Array = []
	
	for i: int in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if piece_at(Vector2i(i, j)) == "-":
				continue
			
			if white && !is_white_piece(piece_at(Vector2i(i, j))):
				continue
			elif !white && is_white_piece(piece_at(Vector2i(i, j))):
				continue
			
			moves += $GetMovable.get_movable(Vector2i(i, j), false)
			
			if !moves.is_empty():
				return true
	
	return false


func clear_board_highlight() -> void:
	for i: int in range(GRID_SIZE):
		for j: int in range(GRID_SIZE):
			var sq: Vector2i = Vector2i(i, j)
			var atlas_coord: Vector2i = Vector2i(0, 0) if !is_dark_sq(sq) else Vector2i(1, 0)
			
			$BoardLayer.set_cell(sq, 0, atlas_coord, 0)


func highlight_movable(enabled: bool) -> void:
	if !enabled:
		for i: int in range(GRID_SIZE):
			for j: int in range(GRID_SIZE):
				var sq: Vector2i = Vector2i(i, j)
				
				$HighlightLayer.set_cell(sq)
		return
	
	highlight_movable(false)
	
	for sq: Vector2i in movable:
		$HighlightLayer.set_cell(sq, 1, Vector2i(0, 0), 0)


func highlight_prev_move(pos: Vector2i) -> void:
	var atlas_coord: Vector2i = Vector2i(2, 0) if !is_dark_sq(pos) else Vector2i(3, 0)
	
	$BoardLayer.set_cell(pos, 0, atlas_coord, 0)


func highlight_check(white: bool) -> void:
	var king_pos: Vector2i = white_king_pos if white else black_king_pos
	var atlas_coord: Vector2i = Vector2i(4, 0) if !is_dark_sq(king_pos) else Vector2i(5, 0)
	
	$BoardLayer.set_cell(king_pos, 0, atlas_coord, 0)


func highlight(prev_pos: Vector2i) -> void:
	clear_board_highlight()
	highlight_movable(false)
	highlight_prev_move(prev_pos)
	
	if is_in_check(!is_white_turn()):
		highlight_check(!is_white_turn())


func double_pawn_move(prev_pos: Vector2i, new_pos: Vector2i, white: bool) -> void:
	if !is_pawn_moves(prev_pos):
		return
	
	if white && new_pos == Vector2i(prev_pos.x, prev_pos.y - 2):
		can_be_captured_ep_x = new_pos.x
		can_be_captured_ep = true
	elif !white && new_pos == Vector2i(prev_pos.x, prev_pos.y + 2):
		can_be_captured_ep_x = new_pos.x
		can_be_captured_ep = true


func ep_capture(prev_pos: Vector2i, new_pos: Vector2i) -> void:
	if !is_pawn_moves(prev_pos):
		return
	
	var is_ep_capture: bool = new_pos.x != prev_pos.x && piece_at(new_pos) == "-"
	
	if is_ep_capture:
		if is_white_turn():
			place_piece("-", Vector2i(can_be_captured_ep_x, 3))
		else:
			place_piece("-", Vector2i(can_be_captured_ep_x, GRID_SIZE - 4))
	else:
		if can_be_captured_ep:
			can_be_captured_ep = false
		else:
			can_be_captured_ep_x = -2


func pawn_promote(pos: Vector2i, white: bool) -> void:
	if !is_pawn_moves(pos):
		return
	elif white && pos.y != 0:
		return
	elif !white && pos.y != GRID_SIZE - 1:
		return
	
	pause_select = true
	$PromotionButton.hide_all(false)
	$PromotionButton.set_pos(pos)
	
	var option: String = await $PromotionButton.gui_input
	
	if white:
		place_piece(option.to_upper(), pos)
	else:
		place_piece(option.to_lower(), pos)
	
	pause_select = false


func is_castling(prev_pos: Vector2i, new_pos: Vector2i) -> bool:
	var first_piece: String = piece_at(prev_pos)
	var other_piece: String = piece_at(new_pos)
	return first_piece == "K" && other_piece == "R" || first_piece == "k" && other_piece == "r"


func is_king_side_castle(pos_x: int) -> bool:
	return pos_x >= GRID_SIZE / 2


func castling(prev_pos: Vector2i, new_pos: Vector2i) -> void:
	place_piece("-", prev_pos)
	place_piece("-", new_pos)
	
	if is_white_turn():
		if is_king_side_castle(new_pos.x):
			place_piece("K", Vector2i(GRID_SIZE - 2, GRID_SIZE - 1))
			place_piece("R", Vector2i(GRID_SIZE - 3, GRID_SIZE - 1))
		else:
			place_piece("K", Vector2i(2, GRID_SIZE - 1))
			place_piece("R", Vector2i(3, GRID_SIZE - 1))
	else:
		if is_king_side_castle(new_pos.x):
			place_piece("k", Vector2i(GRID_SIZE - 2, 0))
			place_piece("r", Vector2i(GRID_SIZE - 3, 0))
		else:
			place_piece("k", Vector2i(2, 0))
			place_piece("r", Vector2i(3, 0))


func disable_castle(piece: String, pos: Vector2i) -> void:
	if piece == "K":
		can_castle_white = []
	elif piece == "k":
		can_castle_black = []
	elif piece == "R":
		can_castle_white.erase(pos.x)
	elif piece == "r":
		can_castle_black.erase(pos.x)


func update_king_pos(prev_pos: Vector2i, new_pos: Vector2i) -> void:
	if piece_at(prev_pos).to_lower() != "k":
		return
	
	if is_white_piece(piece_at(prev_pos)):
		white_king_pos = new_pos
	else:
		black_king_pos = new_pos


func get_attack() -> void:
	attack_white = []
	attack_black = []

	for i: int in range(GRID_SIZE):
		for j: int in range(GRID_SIZE):
			var sq: String = piece_at(Vector2i(i, j))

			if sq == "-":
				continue

			if is_white_piece(sq):
				attack_white += $GetMovable.get_movable(Vector2i(i, j), true)
			else:
				attack_black += $GetMovable.get_movable(Vector2i(i, j), true)


func game_state() -> void:
	if !has_legal_move(!is_white_turn()):
		if is_in_check(!is_white_turn()):
			pause_select = true
			emit_signal("game_end", "CHECKMATE")
			print("CHECKMATE")
			return
		else:
			pause_select = true
			emit_signal("game_end", "STALEMATE")
			print("STALEMATE")
			return
	
	if all_game_pos[get_fen()] == 2:
		pause_select = true
		emit_signal("game_end", "THREE FOLD REPETION")
		print("THREE FOLD REPETION")
		return
	
	if turns_since_pawn_moves_or_capture == 100:
		pause_select = true
		emit_signal("game_end", "50 MOVE RULE")
		print("50 MOVE RULE")
		return


func get_turns_since_pawn_moves_or_capture(prev_pos: Vector2i, new_pos: Vector2i) -> void:
	if is_pawn_moves(prev_pos):
		turns_since_pawn_moves_or_capture = 0
		return
	elif is_captures(new_pos):
		turns_since_pawn_moves_or_capture = 0
		return
	
	turns_since_pawn_moves_or_capture += 1


func player_select_piece(click_pos: Vector2i) -> void:
	var piece: String = piece_at(click_pos)
	
	if piece != "-":
		if is_white_turn() && is_white_piece(piece) || !is_white_turn() && !is_white_piece(piece):
			selected_piece_pos = click_pos
			movable = $GetMovable.get_movable(click_pos, false)
			highlight_movable(true)
		else:
			selected_piece_pos = Vector2i(-1, -1)
			highlight_movable(false)
	else:
		selected_piece_pos = Vector2i(-1, -1)
		highlight_movable(false)


func player_place_piece(new_pos: Vector2i) -> void:
	if new_pos in movable:
		double_pawn_move(selected_piece_pos, new_pos, is_white_turn())
		ep_capture(selected_piece_pos, new_pos)
		disable_castle(piece_at(selected_piece_pos), selected_piece_pos)
		update_king_pos(selected_piece_pos, new_pos)
		get_turns_since_pawn_moves_or_capture(selected_piece_pos, new_pos)
		
		if is_castling(selected_piece_pos, new_pos):
			castling(selected_piece_pos, new_pos)
		else:
			place_piece(piece_at(selected_piece_pos), new_pos)
			place_piece("-", selected_piece_pos)
		
		await pawn_promote(new_pos, is_white_turn())
		get_attack()
		
		if all_game_pos.get(get_fen()) == null:
			all_game_pos[get_fen()] = 0
		else:
			all_game_pos[get_fen()] += 1
		
		highlight(selected_piece_pos)
		game_state()
		
		selected_piece_pos = Vector2i(-1, -1)
		half_turn += 1
	else:
		player_select_piece(new_pos)


func _ready() -> void:
	gen_piece_atlas_dict()
	gen_board()
	set_board(LAYOUT)
	set_castle(LAYOUT)
	all_game_pos[get_fen()] = 0


func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() != MOUSE_BUTTON_LEFT || !event.is_pressed() || pause_select:
			return
			
		var click_pos: Vector2i = $BoardLayer.local_to_map(get_local_mouse_position())
		
		if click_pos.x < 0 || click_pos.y < 0 || click_pos.x >= GRID_SIZE || click_pos.y >= GRID_SIZE:
			return
		
		if selected_piece_pos == Vector2i(-1, -1):
			player_select_piece(click_pos)
		else:
			player_place_piece(click_pos)
