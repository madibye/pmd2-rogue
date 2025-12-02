extends RefCounted
class_name Room

var rect: Rect2i
var is_monster_house: bool
var is_dummy: bool
var sectors: Array[Vector2i]  ## The sectors this room exists in (usually just one, but can be multiple if merged with an adjacent room)
var connected_rooms: Array[Room]  ## The sectors to which this room is connected with via corridors.

func _init(_rect: Rect2i):
	rect = _rect

func get_border_tiles(direction := Vector2i.ZERO, exclude_corners := false) -> Array[Vector2i]:
	var all_rects: Array[Rect2i] = [
		Rect2i(rect.position, Vector2i(1, rect.size.y)), 
		Rect2i(rect.position, Vector2i(rect.size.x, 1)),
		Rect2i(Vector2i(rect.position.x + rect.size.x - 1, rect.position.y), Vector2i(1, rect.size.y)), 
		Rect2i(Vector2i(rect.position.x, rect.position.y + rect.size.y - 1), Vector2i(rect.size.x, 1))
	]
	var rects: Array[Rect2i]
	match direction:
		Vector2i(-1, 0): rects = [all_rects[0]]
		Vector2i(0, -1): rects = [all_rects[1]]
		Vector2i(1, 0): rects = [all_rects[2]]
		Vector2i(0, 1): rects = [all_rects[3]]
		_: rects = all_rects
	var tiles: Array[Vector2i]
	for _rect in rects:
		var rect_tiles := PMDUtils.get_rect_points(_rect)
		if exclude_corners and len(rect_tiles) > 2:
			rect_tiles.pop_front()
			rect_tiles.pop_back()
		tiles.append_array(rect_tiles)
	return tiles
