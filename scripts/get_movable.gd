extends Node2D


@onready var Game: Node2D = get_parent()
var board: Array


func piece_at(loc: Vector2i) -> String:   
	return board[loc.x][loc.y]


func is_white_piece(piece: String) -> bool:
	return piece == piece.to_upper()


func get_movable(pos: Vector2i, only_attacks: bool, game_board: Array = []) -> Array:
	if game_board.is_empty():
		board = Game.board.duplicate(true)
	else:
		board = game_board.duplicate(true)
	
	match piece_at(pos):
		"P":
			return pawn_white(pos, only_attacks)
		"p":
			return pawn_black(pos, only_attacks)
		"N":
			return knight(pos, true, only_attacks)
		"n":
			return knight(pos, false, only_attacks)
		"B":
			return bishop(pos, true, only_attacks)
		"b":
			return bishop(pos, false, only_attacks)
		"R":
			return rook(pos, true, only_attacks)
		"r":
			return rook(pos, false, only_attacks)
		"Q":
			return queen(pos, true, only_attacks)
		"q":
			return queen(pos, false, only_attacks)
		"K":
			return king(pos, true, only_attacks)
		"k":
			return king(pos, false, only_attacks)
		_:
			return []


func has_no_attack(pos: Vector2i, white: bool) -> bool:
	if white:
		return !(pos in Game.attack_black)
	else:
		return !(pos in Game.attack_white)


func does_reveal_check(prev_pos: Vector2i, new_pos: Vector2i, white: bool) -> bool:
	var tmp_board: Array = board.duplicate(true)
	var tmp_piece: String = piece_at(prev_pos)
	
	tmp_board[prev_pos.x][prev_pos.y] = "-"
	tmp_board[new_pos.x][new_pos.y] = tmp_piece

	var attack: Array = []
	var king_pos: Vector2i

	for i: int in range(Game.GRID_SIZE):
		for j: int in range(Game.GRID_SIZE):
			var piece: String = piece_at(Vector2i(i, j))

			if piece == "-":
				continue

			if piece == "K" && white:
				king_pos = Vector2i(i, j)
				continue
			elif piece == "k" && !white:
				king_pos = Vector2i(i, j)
				continue
			
			if white && !is_white_piece(piece):
				attack += get_movable(Vector2i(i, j), true, tmp_board)
			elif !white && is_white_piece(piece):
				attack += get_movable(Vector2i(i, j), true, tmp_board)
		
	board = Game.board.duplicate(true)
	
	return king_pos in attack


func move_or_take_if_able(prev_pos: Vector2i, new_pos: Vector2i, white: bool, movable: Array, only_attack: bool) -> void:
	if !only_attack:
		if does_reveal_check(prev_pos, new_pos, white):
			return

	if piece_at(new_pos) == "-":
		movable.push_back(new_pos)
		return

	if white && is_white_piece(piece_at(new_pos)):
		return
	elif !white && !is_white_piece(piece_at(new_pos)):
		return

	movable.push_back(new_pos)


func pawn_white(pos: Vector2i, only_attacks: bool) -> Array:
	var movable: Array
	
	if only_attacks:
		pass
	elif piece_at(Vector2i(pos.x, pos.y - 1)) != "-":
		pass
	else:
		if !does_reveal_check(pos, Vector2i(pos.x, pos.y - 1), true):
			movable.push_back(Vector2i(pos.x, pos.y - 1))
		
		if pos.y != Game.GRID_SIZE - 2:
			pass
		elif piece_at(Vector2i(pos.x, pos.y - 2)) != "-":
			pass
		elif does_reveal_check(pos, Vector2i(pos.x, pos.y - 2), true):
			pass
		else:
			movable.push_back(Vector2i(pos.x, pos.y - 2))
	
	if pos.x > 0:
		if only_attacks:
			movable.push_back(Vector2i(pos.x - 1, pos.y - 1))
		else:
			if piece_at(Vector2i(pos.x - 1, pos.y - 1)) != "-" && !is_white_piece(piece_at(Vector2i(pos.x - 1, pos.y - 1))):
				if !does_reveal_check(pos, Vector2i(pos.x - 1, pos.y - 1), true):
					movable.push_back(Vector2i(pos.x - 1, pos.y - 1))
					
			elif pos.y == 3 && Game.can_be_captured_ep.x == pos.x - 1 && piece_at(Vector2i(pos.x - 1, 3)) == "p":
				movable.push_back(Vector2i(pos.x - 1, pos.y - 1))

	if pos.x < Game.GRID_SIZE - 1:
		if only_attacks:
			movable.push_back(Vector2i(pos.x + 1, pos.y - 1))
		else:
			if piece_at(Vector2i(pos.x + 1, pos.y - 1)) != "-" && !is_white_piece(piece_at(Vector2i(pos.x + 1, pos.y - 1))):
				if !does_reveal_check(pos, Vector2i(pos.x + 1, pos.y - 1), true):
					movable.push_back(Vector2i(pos.x + 1, pos.y - 1))
					
			elif pos.y == 3 && Game.can_be_captured_ep_x == pos.x + 1 && piece_at(Vector2i(pos.x + 1, 3)) == "p":
				movable.push_back(Vector2i(pos.x + 1, pos.y - 1))

	return movable


func pawn_black(pos: Vector2i, only_attacks: bool) -> Array:
	var movable: Array
	
	if only_attacks:
		pass
	elif piece_at(Vector2i(pos.x, pos.y + 1)) != "-":
		pass
	else:
		if !does_reveal_check(pos, Vector2i(pos.x, pos.y + 1), false):
			movable.push_back(Vector2i(pos.x, pos.y + 1))
		
		if pos.y != 1:
			pass
		elif piece_at(Vector2i(pos.x, pos.y + 2)) != "-":
			pass
		elif does_reveal_check(pos, Vector2i(pos.x, pos.y + 2), false):
			pass
		else:
			movable.push_back(Vector2i(pos.x, pos.y + 2))

	if pos.x > 0:
		if only_attacks:
			movable.push_back(Vector2i(pos.x - 1, pos.y + 1))
		else:
			if piece_at(Vector2i(pos.x - 1, pos.y + 1)) != "-" && is_white_piece(piece_at(Vector2i(pos.x - 1, pos.y + 1))):
				if !does_reveal_check(pos, Vector2i(pos.x - 1, pos.y + 1), false):
					movable.push_back(Vector2i(pos.x - 1, pos.y + 1))
					
			elif pos.y == Game.GRID_SIZE - 4 && Game.can_be_captured_ep_x == pos.x - 1 && piece_at(Vector2i(pos.x - 1, Game.GRID_SIZE - 4)) == "P":
				movable.push_back(Vector2i(pos.x - 1, pos.y + 1))

	if pos.x < Game.GRID_SIZE - 1:
		if only_attacks:
			movable.push_back(Vector2i(pos.x + 1, pos.y + 1))
		else:
			if piece_at(Vector2i(pos.x + 1, pos.y + 1)) != "-" && is_white_piece(piece_at(Vector2i(pos.x + 1, pos.y + 1))):
				if !does_reveal_check(pos, Vector2i(pos.x + 1, pos.y + 1), false):
					movable.push_back(Vector2i(pos.x + 1, pos.y + 1))
					
			elif pos.y == Game.GRID_SIZE - 4 && Game.can_be_captured_ep.x == pos.x + 1 && piece_at(Vector2i(pos.x + 1, Game.GRID_SIZE - 4)) == "P":
				movable.push_back(Vector2i(pos.x + 1, pos.y + 1))

	return movable


func knight(pos: Vector2i, white: bool, only_attacks: bool) -> Array:
	var movable: Array

	if pos.x > 1 && pos.y > 0:
		move_or_take_if_able(pos, Vector2i(pos.x - 2, pos.y - 1), white, movable, only_attacks)

	if pos.x > 1 && pos.y < Game.GRID_SIZE - 1:
		move_or_take_if_able(pos, Vector2i(pos.x - 2, pos.y + 1), white, movable, only_attacks)

	if pos.x < Game.GRID_SIZE - 2 && pos.y > 0:
		move_or_take_if_able(pos, Vector2i(pos.x + 2, pos.y - 1), white, movable, only_attacks)

	if pos.x < Game.GRID_SIZE - 2 && pos.y < Game.GRID_SIZE - 1:
		move_or_take_if_able(pos, Vector2i(pos.x + 2, pos.y + 1), white, movable, only_attacks)

	if pos.x > 0 && pos.y > 1:
		move_or_take_if_able(pos, Vector2i(pos.x - 1, pos.y - 2), white, movable, only_attacks)

	if pos.x < Game.GRID_SIZE - 1 && pos.y > 1:
		move_or_take_if_able(pos, Vector2i(pos.x + 1, pos.y - 2), white, movable, only_attacks)

	if pos.x > 0 && pos.y < Game.GRID_SIZE - 2:
		move_or_take_if_able(pos, Vector2i(pos.x - 1, pos.y + 2), white, movable, only_attacks)

	if pos.x < Game.GRID_SIZE - 1 && pos.y < Game.GRID_SIZE - 2:
		move_or_take_if_able(pos, Vector2i(pos.x + 1, pos.y + 2), white, movable, only_attacks)

	return movable


func bishop(pos: Vector2i, white: bool, only_attacks: bool) -> Array:
	var movable: Array
	var direction: String = "ul"

	while !direction.is_empty():
		var ray: Vector2i

		if direction == "ul":
			ray = Vector2i(-1, -1)
		elif direction == "ur":
			ray = Vector2i(1, -1)
		elif direction == "dl":
			ray = Vector2i(-1, 1)
		elif direction == "dr":
			ray = Vector2i(1, 1)

		while pos.x + ray.x >= 0 && pos.x + ray.x < Game.GRID_SIZE && pos.y + ray.y >= 0 && pos.y + ray.y < Game.GRID_SIZE:
			var tmp_pos: Vector2i = Vector2i(pos.x + ray.x, pos.y + ray.y)
			
			if !only_attacks:
				if does_reveal_check(pos, tmp_pos, white):
					break
				
			if piece_at(tmp_pos) == "-":
				movable.push_back(tmp_pos)
			elif white && !is_white_piece(piece_at(tmp_pos)):
				movable.push_back(tmp_pos)
				break
			elif !white && is_white_piece(piece_at(tmp_pos)):
				movable.push_back(tmp_pos)
				break
			else:
				break

			if direction == "ul":
				ray.x -= 1
				ray.y -= 1
			elif direction == "ur":
				ray.x += 1
				ray.y -= 1
			elif direction == "dl":
				ray.x -= 1
				ray.y += 1
			elif direction == "dr":
				ray.x += 1
				ray.y += 1

		if direction == "ul":
			direction = "ur"
		elif direction == "ur":
			direction = "dl"
		elif direction == "dl":
			direction = "dr"
		elif direction == "dr":
			direction = ""

	return movable


func rook(pos: Vector2i, white: bool, only_attacks: bool) -> Array:
	var movable: Array
	var direction: String = "u"

	while !direction.is_empty():
		var ray: Vector2i

		if direction == "u":
			ray = Vector2i(0, -1)
		elif direction == "d":
			ray = Vector2i(0, 1)
		elif direction == "l":
			ray = Vector2i(-1, 0)
		elif direction == "r":
			ray = Vector2i(1, 0)

		while pos.x + ray.x >= 0 && pos.x + ray.x < Game.GRID_SIZE && pos.y + ray.y >= 0 && pos.y + ray.y < Game.GRID_SIZE:
			var tmp_pos: Vector2i = Vector2i(pos.x + ray.x, pos.y + ray.y)

			if !only_attacks:
				if does_reveal_check(pos, tmp_pos, white):
					break
					
			if piece_at(tmp_pos) == "-":
				movable.push_back(tmp_pos)
			elif white && !is_white_piece(piece_at(tmp_pos)):
				movable.push_back(tmp_pos)
				break
			elif !white && is_white_piece(piece_at(tmp_pos)):
				movable.push_back(tmp_pos)
				break
			else:
				break

			if direction == "u":
				ray.y -= 1
			elif direction == "d":
				ray.y += 1
			elif direction == "l":
				ray.x -= 1
			elif direction == "r":
				ray.x += 1

		if direction == "u":
			direction = "d"
		elif direction == "d":
			direction = "l"
		elif direction == "l":
			direction = "r"
		elif direction == "r":
			direction = ""

	return movable


func queen(pos: Vector2i, white: bool, only_attacks: bool) -> Array:
	return bishop(pos, white, only_attacks) + rook(pos, white, only_attacks)


func is_king_side_castle(pos_x: int) -> bool:
	return pos_x >= Game.GRID_SIZE / 2


func can_castle(white: bool, rook_x: int) -> bool:
	var king_pos_x: int = Game.white_king_pos.x if white else Game.black_king_pos.x
	var tmp_y: int = Game.GRID_SIZE - 1 if white else 0

	if is_king_side_castle(rook_x):
		for tmp_x: int in range(king_pos_x + 1, Game.GRID_SIZE - 1):
			if tmp_x == rook_x:
				continue

			if !has_no_attack(Vector2i(tmp_x, tmp_y), white):
				return false

			if piece_at(Vector2i(tmp_x, tmp_y)) != "-":
				return false
				
	else:
		for tmp_x: int in range(king_pos_x - 1, 0, -1):
			if tmp_x == rook_x:
				continue

			if !has_no_attack(Vector2i(tmp_x, tmp_y), white):
				return false

			if piece_at(Vector2i(tmp_x, tmp_y)) != "-":
				return false

	return !Game.is_in_check(white)


func king(pos: Vector2i, white: bool, only_attacks) -> Array:
	var movable: Array
	
	for i: int in range(pos.x - 1, pos.x + 2):
		for j: int in range(pos.y - 1, pos.y + 2):
			var new_pos: Vector2i = Vector2i(i, j)
			
			if new_pos == pos:
				continue
			
			if new_pos.x >= 0 && new_pos.y >= 0 && new_pos.x < Game.GRID_SIZE && new_pos.y < Game.GRID_SIZE:
				move_or_take_if_able(pos, new_pos, white, movable, only_attacks)
	
	var castle: Array = Game.can_castle_white if white else Game.can_castle_black
	var rook_y: int = Game.GRID_SIZE - 1 if white else 0

	for rook_x: int in castle:
		if can_castle(white, rook_x):
			movable.push_back(Vector2i(rook_x, rook_y))

	return movable
