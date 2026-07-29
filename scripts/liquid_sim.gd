extends RefCounted
class_name LiquidSim


# Finite tile-based liquid simulation. Liquids preserve their volume, wake when
# the player approaches or terrain changes, and settle without scanning the
# entire world every frame.
const FLOW_STEP_INTERVAL := 0.10
const MAX_SPREADS_PER_STEP := 96
const MAX_CHECKS_PER_STEP := 360
const LIQUID_PROCESS_RADIUS_X := 52
const LIQUID_PROCESS_RADIUS_Y := 40
const WAKE_DISTANCE_TILES := 6.0

var _water_tile := 27
var _lava_tile := 28
var _air_tile := 0
var _reaction_tile := 3

var _liquid_queue: Array[Vector2i] = []
var _queued_positions: Dictionary = {}
var _liquid_positions: Dictionary = {}
var _queue_index := 0
var _spreads_this_step := 0
var _flow_accumulator := 0.0
var _flow_tick := 0
var _last_wake_center := Vector2i(-99999, -99999)


func setup(water_tile: int, lava_tile: int, air_tile: int = 0, reaction_tile: int = 3) -> void:
	_water_tile = water_tile
	_lava_tile = lava_tile
	_air_tile = air_tile
	_reaction_tile = reaction_tile


func clear() -> void:
	_liquid_queue.clear()
	_queued_positions.clear()
	_liquid_positions.clear()
	_queue_index = 0
	_spreads_this_step = 0
	_flow_accumulator = 0.0
	_flow_tick = 0
	_last_wake_center = Vector2i(-99999, -99999)


func rebuild(world: Array) -> void:
	clear()
	for y in range(world.size()):
		var row: Array = world[y]
		for x in range(row.size()):
			if _is_liquid_tile(int(row[x])):
				_liquid_positions[_key(x, y)] = true


func register_liquid(world_x: int, world_y: int) -> void:
	_liquid_positions[_key(world_x, world_y)] = true
	_enqueue_liquid(Vector2i(world_x, world_y))


func unregister_liquid(world_x: int, world_y: int) -> void:
	var position_key := _key(world_x, world_y)
	_liquid_positions.erase(position_key)
	_queued_positions.erase(position_key)


func is_liquid(x: int, y: int) -> bool:
	return _liquid_positions.has(_key(x, y))


func on_tile_changed(world_x: int, world_y: int, new_tile: int) -> void:
	if _is_liquid_tile(new_tile):
		register_liquid(world_x, world_y)
	else:
		unregister_liquid(world_x, world_y)

	# Removing or placing a block can release any neighboring settled liquid.
	for y in range(world_y - 1, world_y + 2):
		for x in range(world_x - 1, world_x + 2):
			if _liquid_positions.has(_key(x, y)):
				_enqueue_liquid(Vector2i(x, y))


func process(delta: float, world: Array, player_tile_x: int, player_tile_y: int, _solid_tiles: Dictionary) -> int:
	_flow_accumulator += delta
	if _flow_accumulator < FLOW_STEP_INTERVAL:
		return 0
	_flow_accumulator = fmod(_flow_accumulator, FLOW_STEP_INTERVAL)
	_flow_tick += 1
	_spreads_this_step = 0

	var player_center := Vector2i(player_tile_x, player_tile_y)
	_wake_near_player(world, player_center)
	if _liquid_queue.is_empty():
		return 0

	var changed_tiles := 0
	var checked := 0
	var processing_end := _liquid_queue.size()
	while _queue_index < processing_end and checked < MAX_CHECKS_PER_STEP and _spreads_this_step < MAX_SPREADS_PER_STEP:
		var pos: Vector2i = _liquid_queue[_queue_index]
		_queue_index += 1
		checked += 1
		_queued_positions.erase(_key(pos.x, pos.y))

		if absi(pos.x - player_tile_x) > LIQUID_PROCESS_RADIUS_X or absi(pos.y - player_tile_y) > LIQUID_PROCESS_RADIUS_Y:
			continue
		changed_tiles += _try_spread_liquid(pos.x, pos.y, world)

	_discard_processed_queue_entries()
	return changed_tiles


func _wake_near_player(world: Array, center: Vector2i) -> void:
	if _last_wake_center.x > -90000 and _last_wake_center.distance_to(center) < WAKE_DISTANCE_TILES:
		return
	_last_wake_center = center
	var min_y := maxi(0, center.y - LIQUID_PROCESS_RADIUS_Y)
	var max_y := mini(world.size() - 1, center.y + LIQUID_PROCESS_RADIUS_Y)
	for y in range(min_y, max_y + 1):
		var row: Array = world[y]
		var min_x := maxi(0, center.x - LIQUID_PROCESS_RADIUS_X)
		var max_x := mini(row.size() - 1, center.x + LIQUID_PROCESS_RADIUS_X)
		for x in range(min_x, max_x + 1):
			if _is_liquid_tile(int(row[x])):
				_liquid_positions[_key(x, y)] = true
				_enqueue_liquid(Vector2i(x, y))


func _discard_processed_queue_entries() -> void:
	if _queue_index <= 0:
		return
	if _queue_index >= _liquid_queue.size():
		_liquid_queue.clear()
		_queue_index = 0
		return
	var remaining: Array[Vector2i] = []
	for index in range(_queue_index, _liquid_queue.size()):
		remaining.append(_liquid_queue[index])
	_liquid_queue = remaining
	_queue_index = 0


func _enqueue_liquid(pos: Vector2i) -> void:
	var position_key := _key(pos.x, pos.y)
	if _queued_positions.has(position_key):
		return
	_queued_positions[position_key] = true
	_liquid_queue.append(pos)


func _is_liquid_tile(tile: int) -> bool:
	return tile == _water_tile or tile == _lava_tile


func _is_opposite_liquid(source_tile: int, target_tile: int) -> bool:
	return (source_tile == _water_tile and target_tile == _lava_tile) or (source_tile == _lava_tile and target_tile == _water_tile)


func _try_spread_liquid(x: int, y: int, world: Array) -> int:
	if y < 0 or y >= world.size():
		return 0
	var row: Array = world[y]
	if x < 0 or x >= row.size():
		return 0

	var current_tile := int(row[x])
	if not _is_liquid_tile(current_tile):
		_liquid_positions.erase(_key(x, y))
		return 0

	# Lava remains finite like water, but its high viscosity makes it settle slower.
	if current_tile == _lava_tile and (_flow_tick + absi(x * 17 + y * 31)) % 3 != 0:
		_enqueue_liquid(Vector2i(x, y))
		return 0

	var below := Vector2i(x, y + 1)
	var below_tile := _tile_at(world, below)
	if _is_opposite_liquid(current_tile, below_tile):
		_spreads_this_step += 1
		return _solidify_contact(Vector2i(x, y), below, world)
	if below_tile == _air_tile:
		_spreads_this_step += 1
		return _move_liquid(Vector2i(x, y), below, current_tile, world)

	var first_dir := -1 if (_flow_tick + x + y) % 2 == 0 else 1
	for direction in [first_dir, -first_dir]:
		var diagonal := Vector2i(x + direction, y + 1)
		var diagonal_tile := _tile_at(world, diagonal)
		if _is_opposite_liquid(current_tile, diagonal_tile):
			_spreads_this_step += 1
			return _solidify_contact(Vector2i(x, y), diagonal, world)
		if diagonal_tile == _air_tile:
			_spreads_this_step += 1
			return _move_liquid(Vector2i(x, y), diagonal, current_tile, world)

	for direction in [first_dir, -first_dir]:
		var side := Vector2i(x + direction, y)
		var side_tile := _tile_at(world, side)
		if _is_opposite_liquid(current_tile, side_tile):
			_spreads_this_step += 1
			return _solidify_contact(Vector2i(x, y), side, world)
		if side_tile != _air_tile:
			continue
		var side_below_tile := _tile_at(world, side + Vector2i.DOWN)
		if side_below_tile != _air_tile:
			_spreads_this_step += 1
			return _move_liquid(Vector2i(x, y), side, current_tile, world)
	return 0


func _move_liquid(source: Vector2i, target: Vector2i, liquid_tile: int, world: Array) -> int:
	world[source.y][source.x] = _air_tile
	world[target.y][target.x] = liquid_tile
	_liquid_positions.erase(_key(source.x, source.y))
	_liquid_positions[_key(target.x, target.y)] = true
	_enqueue_liquid(Vector2i(target.x, target.y))
	_enqueue_liquid_neighbors(source, world)
	_enqueue_liquid_neighbors(target, world)
	return 2


func _solidify_contact(source: Vector2i, target: Vector2i, world: Array) -> int:
	world[source.y][source.x] = _reaction_tile
	world[target.y][target.x] = _reaction_tile
	_liquid_positions.erase(_key(source.x, source.y))
	_liquid_positions.erase(_key(target.x, target.y))
	_queued_positions.erase(_key(source.x, source.y))
	_queued_positions.erase(_key(target.x, target.y))
	_enqueue_liquid_neighbors(source, world)
	_enqueue_liquid_neighbors(target, world)
	return 2


func _enqueue_liquid_neighbors(center: Vector2i, world: Array) -> void:
	for y in range(center.y - 1, center.y + 2):
		if y < 0 or y >= world.size():
			continue
		var row: Array = world[y]
		for x in range(center.x - 1, center.x + 2):
			if x >= 0 and x < row.size() and _is_liquid_tile(int(row[x])):
				_liquid_positions[_key(x, y)] = true
				_enqueue_liquid(Vector2i(x, y))


func _tile_at(world: Array, pos: Vector2i) -> int:
	if pos.y < 0 or pos.y >= world.size():
		return _reaction_tile
	var row: Array = world[pos.y]
	if pos.x < 0 or pos.x >= row.size():
		return _reaction_tile
	return int(row[pos.x])


func _key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]
