extends Node2D

@onready var GAME: Node2D = get_node("/root/Game")


func piece_at(loc: Vector2i) -> String:
	return GAME.board_pos[loc.x][loc.y]


func is_white_piece(piece: String) -> bool:
	return piece == piece.to_upper()


func place_or_take_if_able(pos: Vector2i, white: bool, movable: Array) -> void:
	if piece_at(pos) == "-":
		movable.push_back(pos)
		return
	
	if white && is_white_piece(piece_at(pos)):
		return
	elif !white && !is_white_piece(piece_at(pos)):
		return
	
	movable.push_back(pos)


func pawn_white(pos: Vector2i) -> Array:
	var movable: Array
	if piece_at(Vector2i(pos.x, pos.y - 1)) == "-":
		movable.push_back(Vector2i(pos.x, pos.y - 1))
	
	if pos.y != GAME.GRID_SIZE - 2:
		pass
	elif piece_at(Vector2i(pos.x, pos.y - 1)) != "-":
		pass
	elif piece_at(Vector2i(pos.x, pos.y - 2)) != "-":
		pass
	else:
		movable.push_back(Vector2i(pos.x, pos.y - 2))
		GAME.can_be_captured_ep = Vector2i(pos.x, 1)

	if pos.x > 0:
		if piece_at(Vector2i(pos.x - 1, pos.y - 1)) != "-":
			if !is_white_piece(piece_at(Vector2i(pos.x - 1, pos.y - 1))):
				movable.push_back(Vector2i(pos.x - 1, pos.y - 1))

		elif pos.y == 3 && GAME.can_be_captured_ep.x == pos.x - 1 && piece_at(Vector2i(pos.x - 1, 3)) == "p":
			movable.push_back(Vector2i(pos.x - 1, pos.y - 1))
			GAME.is_ep_capture = true

	
	if pos.x < GAME.GRID_SIZE - 1:
		if piece_at(Vector2i(pos.x + 1, pos.y - 1)) != "-":
			if !is_white_piece(piece_at(Vector2i(pos.x + 1, pos.y - 1))):
				movable.push_back(Vector2i(pos.x + 1, pos.y - 1))

		elif pos.y == 3 && GAME.can_be_captured_ep.x == pos.x + 1 && piece_at(Vector2i(pos.x + 1, 3)) == "p":
			movable.push_back(Vector2i(pos.x + 1, pos.y - 1))
			GAME.is_ep_capture = true

	return movable


func pawn_black(pos: Vector2i) -> Array:
	var movable: Array
	if piece_at(Vector2i(pos.x, pos.y + 1)) == "-":
		movable.push_back(Vector2i(pos.x, pos.y + 1))

	if pos.y != 1:
		pass
	elif piece_at(Vector2i(pos.x, pos.y + 2)) != "-":
		pass
	elif piece_at(Vector2i(pos.x, pos.y + 1)) != "-":
		pass
	else:
		movable.push_back(Vector2i(pos.x, pos.y + 2))
		GAME.can_be_captured_ep = Vector2i(pos.x, 1)

	if pos.x > 0:
		if piece_at(Vector2i(pos.x - 1, pos.y + 1)) != "-":
			if is_white_piece(piece_at(Vector2i(pos.x - 1, pos.y + 1))):
				movable.push_back(Vector2i(pos.x - 1, pos.y + 1))

		elif pos.y == GAME.GRID_SIZE - 4 && GAME.can_be_captured_ep.x == pos.x - 1 && piece_at(Vector2i(pos.x - 1, GAME.GRID_SIZE - 4)) == "p":
			movable.push_back(Vector2i(pos.x - 1, pos.y + 1))
			GAME.is_ep_capture = true

	if pos.x < GAME.GRID_SIZE - 1:
		if piece_at(Vector2i(pos.x + 1, pos.y + 1)) != "-":
			if is_white_piece(piece_at(Vector2i(pos.x + 1, pos.y + 1))):
				movable.push_back(Vector2i(pos.x + 1, pos.y + 1))

		elif pos.y == GAME.GRID_SIZE - 4 && GAME.can_be_captured_ep.x == pos.x + 1 && piece_at(Vector2i(pos.x + 1, GAME.GRID_SIZE - 4)) == "p":
			movable.push_back(Vector2i(pos.x + 1, pos.y + 1))
			GAME.is_ep_capture = true

	return movable


func knight(pos: Vector2i, white: bool) -> Array:
	var movable: Array
	
	if pos.x > 1 && pos.y > 0:
		place_or_take_if_able(Vector2i(pos.x - 2, pos.y - 1), white, movable)
	
	if pos.x > 1 && pos.y < GAME.GRID_SIZE - 1:
		place_or_take_if_able(Vector2i(pos.x - 2, pos.y + 1), white, movable)
	
	if pos.x < GAME.GRID_SIZE - 2 && pos.y > 0:
		place_or_take_if_able(Vector2i(pos.x + 2, pos.y - 1), white, movable)
	
	if pos.x < GAME.GRID_SIZE - 2 && pos.y < GAME.GRID_SIZE - 1:
		place_or_take_if_able(Vector2i(pos.x + 2, pos.y + 1), white, movable)

	if pos.x > 0 && pos.y > 1:
		place_or_take_if_able(Vector2i(pos.x - 1, pos.y - 2), white, movable)
		
	if pos.x < GAME.GRID_SIZE - 1 && pos.y > 1:
		place_or_take_if_able(Vector2i(pos.x + 1, pos.y - 2), white, movable)
		
	if pos.x > 0 && pos.y < GAME.GRID_SIZE - 2:
		place_or_take_if_able(Vector2i(pos.x - 1, pos.y + 2), white, movable)

	if pos.x < GAME.GRID_SIZE - 1 && pos.y < GAME.GRID_SIZE - 2:
		place_or_take_if_able(Vector2i(pos.x + 1, pos.y + 2), white, movable)

	return movable


func bishop(pos: Vector2i, white: bool) -> Array:
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

		while pos.x + ray.x >= 0 && pos.x + ray.x < GAME.GRID_SIZE && pos.y + ray.y >= 0 && pos.y + ray.y < GAME.GRID_SIZE:
			var tmp_pos: Vector2i = Vector2i(pos.x + ray.x, pos.y + ray.y)

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


func rook(pos: Vector2i, white: bool) -> Array:
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

		while pos.x + ray.x >= 0 && pos.x + ray.x < GAME.GRID_SIZE && pos.y + ray.y >= 0 && pos.y + ray.y < GAME.GRID_SIZE:
			var tmp_pos: Vector2i = Vector2i(pos.x + ray.x, pos.y + ray.y)

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


func queen(pos: Vector2i, white: bool) -> Array:
	return bishop(pos, white) + rook(pos, white)


func king(pos: Vector2i, white: bool) -> Array:
	var movable: Array
	
	if pos.x > 0:
		place_or_take_if_able(Vector2i(pos.x - 1, pos.y), white, movable)
		
		if pos.y > 0:
			place_or_take_if_able(Vector2i(pos.x - 1, pos.y - 1), white, movable)
				
		if pos.y < GAME.GRID_SIZE - 1:
			place_or_take_if_able(Vector2i(pos.x - 1, pos.y + 1), white, movable)

	if pos.x < GAME.GRID_SIZE:
		place_or_take_if_able(Vector2i(pos.x + 1, pos.y), white, movable)
		
		if pos.y > 0:
			place_or_take_if_able(Vector2i(pos.x + 1, pos.y - 1), white, movable)
				
		if pos.y < GAME.GRID_SIZE - 1:
			place_or_take_if_able(Vector2i(pos.x + 1, pos.y + 1), white, movable)

	if pos.y > 0:
		place_or_take_if_able(Vector2i(pos.x, pos.y - 1), white, movable)

	if pos.y < GAME.GRID_SIZE - 1:
		place_or_take_if_able(Vector2i(pos.x, pos.y + 1), white, movable)

	return movable
