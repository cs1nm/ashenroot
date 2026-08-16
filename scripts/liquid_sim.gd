extends RefCounted
class_name LiquidSim


# Finite tile-based liquid simulation with partial fill levels. A liquid tile
# stores how much of the block it occupies (1..LEVEL_MAX eighths), so pools can
# settle into a flat surface and a single unit of water no longer teleports
# between neighbouring cells forever. Liquids preserve their volume, wake when
# the player approaches or terrain changes, and settle without scanning the
# entire world every frame.
const FLOW_STEP_INTERVAL := 0.10
const MAX_SPREADS_PER_STEP := 96
const MAX_CHECKS_PER_STEP := 360
const LIQUID_PROCESS_RADIUS_X := 52
const LIQUID_PROCESS_RADIUS_Y := 40
const WAKE_DISTANCE_TILES := 6.0
# A full block is LEVEL_MAX eighths; half a block is LEVEL_MAX / 2.
const LEVEL_MAX := 8
const LEVEL_HALF := 4
# Levels only even out when the gap is wide enough to split, which is what
# stops two neighbours from trading the same drop back and forth forever.
const MIN_EQUALIZE_DIFFERENCE := 2
# Lava is thicker, so it needs a steeper slope before it levels out.
const LAVA_EQUALIZE_DIFFERENCE := 3

var _water_tile := 27
var _lava_tile := 28
var _air_tile := 0
var _reaction_tile := 3

var _liquid_queue: Array[Vector2i] = []
var _queued_positions: Dictionary = {}
var _liquid_positions: Dictionary = {}
# Fill level per liquid tile, keyed like the other lookups. A liquid tile with
# no entry is treated as a full block, which keeps old saves working.
var _levels: Dictionary = {}
# Positions changed during the latest simulation step. The server consumes this
# coalesced set to replicate final tile + level states in one network batch.
var _changed_positions: Dictionary = {}
var _queue_index := 0
var _spreads_this_step := 0
var _flow_accumulator := 0.0
var _flow_tick := 0
var _last_wake_centers: Array[Vector2i] = []


func setup(water_tile: int, lava_tile: int, air_tile: int = 0, reaction_tile: int = 3) -> void:
	_water_tile = water_tile
	_lava_tile = lava_tile
	_air_tile = air_tile
	_reaction_tile = reaction_tile


func clear() -> void:
	_liquid_queue.clear()
	_queued_positions.clear()
	_liquid_positions.clear()
	_levels.clear()
	_changed_positions.clear()
	_queue_index = 0
	_spreads_this_step = 0
	_flow_accumulator = 0.0
	_flow_tick = 0
	_last_wake_centers.clear()


func rebuild(world: Array) -> void:
	clear()
	for y in range(world.size()):
		var row: Array = world[y]
		for x in range(row.size()):
			if _is_liquid_tile(int(row[x])):
				_liquid_positions[_key(x, y)] = true
				_levels[_key(x, y)] = LEVEL_MAX


func register_liquid(world_x: int, world_y: int) -> void:
	_liquid_positions[_key(world_x, world_y)] = true
	if not _levels.has(_key(world_x, world_y)):
		_levels[_key(world_x, world_y)] = LEVEL_MAX
	_enqueue_liquid(Vector2i(world_x, world_y))


func unregister_liquid(world_x: int, world_y: int) -> void:
	var position_key := _key(world_x, world_y)
	_liquid_positions.erase(position_key)
	_queued_positions.erase(position_key)
	_levels.erase(position_key)


func is_liquid(x: int, y: int) -> bool:
	return _liquid_positions.has(_key(x, y))


func get_level(x: int, y: int) -> int:
	# How much of the tile the liquid fills, in eighths. Renderers and physics
	# use this to draw and treat partially filled blocks correctly.
	if not _liquid_positions.has(_key(x, y)):
		return 0
	return int(_levels.get(_key(x, y), LEVEL_MAX))


func get_fill_ratio(x: int, y: int) -> float:
	return float(get_level(x, y)) / float(LEVEL_MAX)


func set_level(x: int, y: int, level: int) -> void:
	var clamped := clampi(level, 0, LEVEL_MAX)
	if clamped <= 0:
		unregister_liquid(x, y)
		return
	var position_key := _key(x, y)
	_liquid_positions[position_key] = true
	_levels[position_key] = clamped


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


func process(delta: float, world: Array, player_tile_x: int, player_tile_y: int, solid_tiles: Dictionary) -> int:
	var centers: Array[Vector2i] = [Vector2i(player_tile_x, player_tile_y)]
	return process_centers(delta, world, centers, solid_tiles)


func process_centers(delta: float, world: Array, player_centers: Array[Vector2i], _solid_tiles: Dictionary) -> int:
	_flow_accumulator += delta
	if _flow_accumulator < FLOW_STEP_INTERVAL:
		return 0
	_flow_accumulator = fmod(_flow_accumulator, FLOW_STEP_INTERVAL)
	_flow_tick += 1
	_spreads_this_step = 0
	_changed_positions.clear()
	if player_centers.is_empty():
		return 0

	_wake_near_players(world, player_centers)
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

		if not _is_near_any_player(pos, player_centers):
			continue
		changed_tiles += _try_spread_liquid(pos.x, pos.y, world)

	_discard_processed_queue_entries()
	return changed_tiles


func _is_near_any_player(pos: Vector2i, player_centers: Array[Vector2i]) -> bool:
	for center in player_centers:
		if absi(pos.x - center.x) <= LIQUID_PROCESS_RADIUS_X and absi(pos.y - center.y) <= LIQUID_PROCESS_RADIUS_Y:
			return true
	return false


func _wake_near_players(world: Array, player_centers: Array[Vector2i]) -> void:
	if _last_wake_centers.size() > player_centers.size():
		_last_wake_centers.resize(player_centers.size())
	for center_index in range(player_centers.size()):
		var center: Vector2i = player_centers[center_index]
		if center_index < _last_wake_centers.size():
			if _last_wake_centers[center_index].distance_to(center) < WAKE_DISTANCE_TILES:
				continue
			_last_wake_centers[center_index] = center
		else:
			_last_wake_centers.append(center)
		_wake_area(world, center)


func _wake_area(world: Array, center: Vector2i) -> void:
	var min_y := maxi(0, center.y - LIQUID_PROCESS_RADIUS_Y)
	var max_y := mini(world.size() - 1, center.y + LIQUID_PROCESS_RADIUS_Y)
	for y in range(min_y, max_y + 1):
		var row: Array = world[y]
		var min_x := maxi(0, center.x - LIQUID_PROCESS_RADIUS_X)
		var max_x := mini(row.size() - 1, center.x + LIQUID_PROCESS_RADIUS_X)
		for x in range(min_x, max_x + 1):
			if _is_liquid_tile(int(row[x])):
				_liquid_positions[_key(x, y)] = true
				if not _levels.has(_key(x, y)):
					_levels[_key(x, y)] = LEVEL_MAX
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


func _level_at(pos: Vector2i) -> int:
	return int(_levels.get(_key(pos.x, pos.y), LEVEL_MAX))


func _try_spread_liquid(x: int, y: int, world: Array) -> int:
	if y < 0 or y >= world.size():
		return 0
	var row: Array = world[y]
	if x < 0 or x >= row.size():
		return 0

	var current_tile := int(row[x])
	if not _is_liquid_tile(current_tile):
		_liquid_positions.erase(_key(x, y))
		_levels.erase(_key(x, y))
		return 0

	# Lava remains finite like water, but its high viscosity makes it settle slower.
	if current_tile == _lava_tile and (_flow_tick + absi(x * 17 + y * 31)) % 3 != 0:
		_enqueue_liquid(Vector2i(x, y))
		return 0

	var source := Vector2i(x, y)
	var level := _level_at(source)
	if level <= 0:
		_remove_liquid(source, world)
		return 1

	var below := Vector2i(x, y + 1)
	var below_tile := _tile_at(world, below)
	if _is_opposite_liquid(current_tile, below_tile):
		_spreads_this_step += 1
		return _solidify_contact(source, below, world)
	# Gravity first: pour as much as the tile underneath can still take.
	if below_tile == _air_tile or below_tile == current_tile:
		var below_level := 0 if below_tile == _air_tile else _level_at(below)
		var free_space := LEVEL_MAX - below_level
		if free_space > 0:
			var poured := mini(level, free_space)
			_spreads_this_step += 1
			return _transfer_liquid(source, below, current_tile, poured, world)

	var first_dir := -1 if (_flow_tick + x + y) % 2 == 0 else 1
	for direction in [first_dir, -first_dir]:
		var diagonal := Vector2i(x + direction, y + 1)
		var diagonal_tile := _tile_at(world, diagonal)
		if _is_opposite_liquid(current_tile, diagonal_tile):
			_spreads_this_step += 1
			return _solidify_contact(source, diagonal, world)
		if diagonal_tile != _air_tile and diagonal_tile != current_tile:
			continue
		var diagonal_level := 0 if diagonal_tile == _air_tile else _level_at(diagonal)
		if diagonal_level >= LEVEL_MAX:
			continue
		# Only spill diagonally when the tile below that one can hold it, so
		# liquid does not crawl up the side of a slope.
		var under_diagonal := diagonal + Vector2i.DOWN
		var diagonal_below := _tile_at(world, under_diagonal)
		var diagonal_below_has_room := (
			diagonal_below == current_tile and _level_at(under_diagonal) < LEVEL_MAX
		)
		if diagonal_below == _air_tile or diagonal_below_has_room:
			var diagonal_poured := mini(level, LEVEL_MAX - diagonal_level)
			_spreads_this_step += 1
			return _transfer_liquid(source, diagonal, current_tile, diagonal_poured, world)

	# Sideways flow evens the surface out instead of moving whole blocks. The
	# transfer is half the difference, so two neighbours converge on the same
	# level and stop, rather than swapping a drop back and forth.
	var equalize_threshold := MIN_EQUALIZE_DIFFERENCE
	if current_tile == _lava_tile:
		equalize_threshold = LAVA_EQUALIZE_DIFFERENCE
	for direction in [first_dir, -first_dir]:
		var side := Vector2i(x + direction, y)
		var side_tile := _tile_at(world, side)
		if _is_opposite_liquid(current_tile, side_tile):
			_spreads_this_step += 1
			return _solidify_contact(source, side, world)
		if side_tile != _air_tile and side_tile != current_tile:
			continue
		var side_level := 0 if side_tile == _air_tile else _level_at(side)
		var difference := level - side_level
		if difference >= equalize_threshold:
			var amount := maxi(1, difference / 2)
			amount = mini(amount, LEVEL_MAX - side_level)
			if amount <= 0:
				continue
			_spreads_this_step += 1
			return _transfer_liquid(source, side, current_tile, amount, world)
		if difference == 1 and current_tile != _lava_tile:
			# A one-step difference is normally left alone to avoid a drop
			# bouncing between two tiles. It is still worth moving when the
			# slope keeps descending past the neighbour, which drains a long
			# wedge into a flat surface instead of freezing it as a staircase.
			var beyond := Vector2i(side.x + direction, side.y)
			if _tile_at(world, beyond) == current_tile and _level_at(beyond) < side_level:
				_spreads_this_step += 1
				return _transfer_liquid(source, side, current_tile, 1, world)
	return 0


func _transfer_liquid(
	source: Vector2i, target: Vector2i, liquid_tile: int, amount: int, world: Array
) -> int:
	if amount <= 0:
		return 0
	var source_level := _level_at(source)
	var moved := mini(amount, source_level)
	if moved <= 0:
		return 0
	var target_level := 0
	if int(world[target.y][target.x]) == liquid_tile:
		target_level = _level_at(target)
	moved = mini(moved, LEVEL_MAX - target_level)
	if moved <= 0:
		return 0

	var remaining := source_level - moved
	if remaining > 0:
		_levels[_key(source.x, source.y)] = remaining
	else:
		world[source.y][source.x] = _air_tile
		_liquid_positions.erase(_key(source.x, source.y))
		_levels.erase(_key(source.x, source.y))

	world[target.y][target.x] = liquid_tile
	_liquid_positions[_key(target.x, target.y)] = true
	_levels[_key(target.x, target.y)] = target_level + moved
	_mark_changed(source)
	_mark_changed(target)

	_enqueue_liquid(target)
	if remaining > 0:
		_enqueue_liquid(source)
	_enqueue_liquid_neighbors(source, world)
	_enqueue_liquid_neighbors(target, world)
	return 2


func _remove_liquid(pos: Vector2i, world: Array) -> void:
	world[pos.y][pos.x] = _air_tile
	_liquid_positions.erase(_key(pos.x, pos.y))
	_levels.erase(_key(pos.x, pos.y))
	_mark_changed(pos)
	_enqueue_liquid_neighbors(pos, world)


func _solidify_contact(source: Vector2i, target: Vector2i, world: Array) -> int:
	world[source.y][source.x] = _reaction_tile
	world[target.y][target.x] = _reaction_tile
	_liquid_positions.erase(_key(source.x, source.y))
	_liquid_positions.erase(_key(target.x, target.y))
	_queued_positions.erase(_key(source.x, source.y))
	_queued_positions.erase(_key(target.x, target.y))
	_levels.erase(_key(source.x, source.y))
	_levels.erase(_key(target.x, target.y))
	_mark_changed(source)
	_mark_changed(target)
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
				if not _levels.has(_key(x, y)):
					_levels[_key(x, y)] = LEVEL_MAX
				_enqueue_liquid(Vector2i(x, y))


func _mark_changed(pos: Vector2i) -> void:
	_changed_positions[_key(pos.x, pos.y)] = pos


func consume_state_changes(world: Array) -> Array:
	# Return one authoritative final state per changed position, even if several
	# transfers touched it during the same simulation tick.
	var changes: Array = []
	for position_variant in _changed_positions.values():
		var pos: Vector2i = position_variant
		if pos.y < 0 or pos.y >= world.size():
			continue
		var row: Array = world[pos.y]
		if pos.x < 0 or pos.x >= row.size():
			continue
		changes.append([pos.x, pos.y, int(row[pos.x]), get_level(pos.x, pos.y)])
	_changed_positions.clear()
	return changes


func _tile_at(world: Array, pos: Vector2i) -> int:
	if pos.y < 0 or pos.y >= world.size():
		return _reaction_tile
	var row: Array = world[pos.y]
	if pos.x < 0 or pos.x >= row.size():
		return _reaction_tile
	return int(row[pos.x])


func _key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]


func serialize_levels() -> Dictionary:
	# Full tiles are implied by the world grid, so only partial levels need to
	# travel in saves and network world snapshots.
	var partial_levels: Dictionary = {}
	for level_key in _levels:
		var level := int(_levels[level_key])
		if level > 0 and level < LEVEL_MAX:
			partial_levels[level_key] = level
	return partial_levels


func restore_levels(data: Dictionary) -> void:
	for level_key in data:
		var level := clampi(int(data[level_key]), 1, LEVEL_MAX)
		if _liquid_positions.has(level_key):
			_levels[level_key] = level
