@tool
extends Node2D
class_name DungeonFloorGenerator

const BORDER_SIZE := 10
const MIN_ROOM_SIZE := Vector2i(5, 4)
const MIN_ROOM_DISTANCE := 2.0

const FLOOR := 2
const WATER := 1
const WALL := 0

var tile_map: DungeonFloor
var rooms: Array[Room]
var terrain_changes: Dictionary[int, Array]

@export var size := Vector2i(52, 28)
@export var sectors := Vector2i(3, 2)
@export var max_room_size := size
@export var room_amount := Vector2i(2, 10)
@export var generate_corridors := true
@export var is_one_room_monster_house := false

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Generate Floor") var _generate_map = generate_map
@warning_ignore_restore("unused_private_class_variable")

func _init():
	terrain_changes = {FLOOR: [], WATER: [], WALL: []}

func _ready():
	if not tile_map: tile_map = get_parent()
	
func generate_map():
	reset_map()
	generate_rooms_in_sectors()
	perform_merges()
	if generate_corridors:
		make_corridors()
	apply_terrain_changes()
	
func generate_rooms_in_sectors():
	var non_dummy_room_sectors: Array[Vector2i]
	var sector_size := Vector2i((Vector2(size) / Vector2(sectors)).floor())
	while len(non_dummy_room_sectors) < min(sectors.x * sectors.y, PMDUtils.randi_range_vec(room_amount)):
		var sector := Vector2i(randi_range(0, sectors.x - 1), randi_range(0, sectors.y - 1))
		if sector not in non_dummy_room_sectors:
			non_dummy_room_sectors.append(sector)
	for x in sectors.x:
		for y in sectors.y:
			var sector := Vector2i(x, y)
			var sector_rect := Rect2i(sector * sector_size, sector_size)
			var is_dummy := not sector in non_dummy_room_sectors
			var room_size := Vector2i.ONE if is_dummy else Vector2i(randi_range(MIN_ROOM_SIZE.x, min(max_room_size.x, sector_rect.size.x)), randi_range(MIN_ROOM_SIZE.y, min(max_room_size.y, sector_rect.size.y)))
			var potential_room_positions := PMDUtils.get_rect_points(Rect2i(sector_rect.position, sector_rect.size - room_size))
			if potential_room_positions.is_empty():
				continue
			var room_position: Vector2i = PMDUtils.get_rect_points(Rect2i(sector_rect.position, sector_rect.size - room_size)).pick_random()
			var room := Room.new(Rect2i(room_position, room_size))
			room.is_dummy = is_dummy
			room.sectors = [sector]
			place_room(room)
			
func make_corridors():
	for x in sectors.x:
		for y in sectors.y:
			var sector := Vector2i(x, y)
			for adjacent_sector in [sector + Vector2i.UP, sector + Vector2i.LEFT, sector + Vector2i.DOWN, sector + Vector2i.RIGHT]:
				create_corridor(sector, adjacent_sector)
			
func perform_merges():
	var merging_rooms: Array[Room]
	for x in sectors.x:
		for y in sectors.y:
			var room_1 = get_room_at_sector(Vector2i(x, y))
			for room_2 in get_adjacent_rooms(room_1):
				if room_1.is_dummy or room_2.is_dummy:
					continue
				var room_1_border_tiles := room_1.get_border_tiles()
				var room_2_border_tiles := room_2.get_border_tiles()
				for point_1 in room_1_border_tiles:
					for point_2 in room_2_border_tiles:
						if point_1.distance_to(point_2) <= MIN_ROOM_DISTANCE and (room_1 not in merging_rooms and room_2 not in merging_rooms):
							merging_rooms.append_array([room_1, room_2])
	for _i in roundi(len(merging_rooms) * 0.5):
		var room_1: Room = merging_rooms.pop_front()
		var room_2: Room = merging_rooms.pop_front()
		if room_1 and room_2:
			merge_rooms(room_1, room_2)

func get_room_at_sector(_sector: Vector2i) -> Room:
	var valid_rooms := rooms.filter(func(r: Room): return _sector in r.sectors)
	if not valid_rooms: 
		return null
	return valid_rooms[0]

func reset_map():
	tile_map.clear()
	rooms.clear()
	terrain_changes = {FLOOR: [], WATER: [], WALL: []}
	place_tiles(PMDUtils.get_rect_points(Rect2i(Vector2i.ZERO - (Vector2i.ONE * BORDER_SIZE), size + (Vector2i.ONE * BORDER_SIZE * 2))), 0)

func get_tile_terrain(tile: Vector2i) -> int:
	for t in terrain_changes:
		if tile in terrain_changes[t]:
			return t
	var tile_data := tile_map.get_cell_tile_data(tile)
	return -1 if not tile_data else tile_data.terrain_set
	
func get_adjacent_rooms(room: Room) -> Array[Room]:
	var adjacent: Array[Room]
	for _room in rooms:
		if _room in adjacent: continue
		for sector in room.sectors:
			for _sector in _room.sectors:
				if is_equal_approx((_sector - sector).length(), 1.0):
					adjacent.append(_room)
	return adjacent

func place_tiles(tiles: Array[Vector2i], terrain: int):
	if terrain != WALL:
		tiles = tiles.filter(func filter_oob_tiles(t): return (t.x >= 0) and (t.x < size.x) and (t.y >= 0) and (t.y < size.y))
	for t in terrain_changes:
		for tile in tiles:
			terrain_changes[t].erase(tile)
	terrain_changes[terrain].append_array(tiles)
	
func filter_oob_tiles(tile: Vector2i):
	return (tile.x > 0) and (tile.x < size.x) and (tile.y > 0) and (tile.y < size.y)
	
func apply_terrain_changes():
	for terrain in terrain_changes:
		tile_map.set_cells_terrain_connect(terrain_changes[terrain], terrain, 0)
	tile_map.sync_tilemaps()
	
func place_room(room: Room):
	rooms.append(room)
	place_tiles(PMDUtils.get_rect_points(room.rect), FLOOR)
	
func create_corridor(sector_1: Vector2i, sector_2: Vector2i):
	var room_1 := get_room_at_sector(sector_1)
	var room_2 := get_room_at_sector(sector_2)
	var direction := sector_2 - sector_1
	if (
		(not room_1 or not room_2 or not generate_corridors) or 
		(not is_equal_approx(direction.length(), 1.0)) or 
		(room_1 in room_2.connected_rooms or room_2 in room_1.connected_rooms)
	):
		return
	var room_1_border_tiles := room_1.get_border_tiles(direction, true)
	var room_2_border_tiles := room_2.get_border_tiles(-direction, true)
	var start_tile: Vector2i = room_1_border_tiles.pick_random()
	var end_tile: Vector2i = room_2_border_tiles.pick_random()
	var horizontal = direction.y == 0
	var distance := absi(start_tile.x - end_tile.x) if horizontal else absi(start_tile.y - end_tile.y)
	if (distance <= 2 and not (room_1.is_dummy or room_2.is_dummy)):
		return
	if distance == 3 and room_1.get_border_tiles(direction, true):
		var valid_start_tiles := room_1_border_tiles.filter(func(t: Vector2i): return (t.y if horizontal else t.x) in room_2_border_tiles.map(func(_t): return (_t.y if horizontal else _t.x)))
		var valid_end_tiles := room_2_border_tiles.filter(func(t: Vector2i): return (t.y if horizontal else t.x) in room_1_border_tiles.map(func(_t): return (_t.y if horizontal else _t.x)))
		if not valid_start_tiles.is_empty() and not valid_end_tiles.is_empty():
			start_tile = valid_start_tiles.pick_random()
			for tile in valid_end_tiles:
				if (tile.y if horizontal else tile.x) == (start_tile.y if horizontal else start_tile.x):
					end_tile = tile
	var scanning_tiles: Array[Vector2i]
	if (horizontal and start_tile.y == end_tile.y) or (not horizontal and start_tile.x == end_tile.x):
		scanning_tiles.append_array(PMDUtils.get_rect_points(PMDUtils.rect_from_corners(start_tile, end_tile)))
	else:
		var turn_vec := Vector2i(randi_range(start_tile.x + (direction.x * 2), end_tile.x - (direction.x * 2)), randi_range(start_tile.y + (direction.y * 2), end_tile.y - (direction.y * 2)))
		var turn_point_1 := Vector2i(start_tile.x, turn_vec.y) if not horizontal else Vector2i(turn_vec.x, start_tile.y)
		var turn_point_2 := Vector2i(end_tile.x, turn_vec.y) if not horizontal else Vector2i(turn_vec.x, end_tile.y)
		scanning_tiles.append_array(
			PMDUtils.get_rect_points(PMDUtils.rect_from_corners(start_tile, turn_point_1)) +
			PMDUtils.get_rect_points(PMDUtils.rect_from_corners(turn_point_1, turn_point_2)) +
			PMDUtils.get_rect_points(PMDUtils.rect_from_corners(turn_point_2, end_tile))
		)
	if (randf() > 0.5):
		scanning_tiles.reverse()
	var corridor_tiles: Array[Vector2i]
	for tile in scanning_tiles:
		if tile in corridor_tiles or tile == start_tile or tile == end_tile: continue
		if get_tile_terrain(tile) == FLOOR: break
		corridor_tiles.append(tile)
	place_tiles(corridor_tiles, FLOOR)
	room_2.connected_rooms.append(room_1)
	room_1.connected_rooms.append(room_2)

func merge_rooms(room_1: Room, room_2: Room):
	room_1.rect = room_1.rect.merge(room_2.rect)
	room_1.sectors.append_array(room_2.sectors)
	if room_2 in rooms:
		rooms.erase(room_2)
	place_room(room_1)
	
func generate_sectors() -> Array[Rect2i]:
	var _sectors: Array[Rect2i]
	var sector_size := Vector2i((Vector2(size) / Vector2(sectors)).floor())
	for x in sectors.x:
		for y in sectors.y:
			_sectors.append(Rect2i(Vector2i(x, y) * sector_size, sector_size))
	return _sectors
