extends Node
class_name PMDUtils

## This script contains many helpful static functions to be used throughout the game.

#region A few DogUtils (by moondog & Sketched)

## Gets the first child of a node of the given type.
static func get_child_of_type(node: Node, type, recursive := false) -> Node:
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
		if recursive:
			return get_child_of_type(child, type, true)
	return null

## Gets all children of a node of the given type.
static func get_children_of_type(node: Node, type, recursive := false) -> Array[Node]:
	var children: Array[Node] = []
	if not node: return children
	for child in node.get_children():
		if is_instance_of(child, type):
			children.append(child)
		if recursive:
			children.append_array(get_children_of_type(child, type, true))
	return children

## Continues looking upwards until finding an ancestor of the given type.
static func get_ancestor_of_type(node: Node, type) -> Node:
	node = node.get_parent()
	while not is_instance_of(node, type):
		node = node.get_parent()
		if not node:
			break
	return node

## Awaits a node being ready or instantly returns if it is already ready.
static func until_ready(node: Node) -> void:
	if not node.is_node_ready():
		await node.ready
		
#endregion

## Gets the name from an enum
static func get_enum_value_name(_enum: Dictionary, value: int) -> String:
	return _enum.find_key(value)
	
static func fetch_assets(repo: String, path: String):
	var output: Array
	OS.execute("./fetch_assets.sh", [repo, path], output)
	print_rich("[color=light_blue]%s[/color]" % output)
	
## Searches the directory for files matching the name `search_term`. Returns all files found.
static func file_search(search_term, path := "res://", recursive := false, show_hidden := false) -> Array[String]:
	var dir = DirAccess.open(path)
	if not dir:
		return [] as Array[String]
	dir.set_include_hidden(show_hidden)
	dir.list_dir_begin()
	var item = dir.get_next()
	var return_paths: Array[String]
	while item != "":
		if item == search_term or search_term.is_empty():
			return_paths.append("%s/%s" % [dir.get_current_dir(), item])
		if dir.current_is_dir() and item != "." and recursive:
			return_paths.append_array(file_search(search_term, dir.get_current_dir() + "/" + item, recursive, show_hidden))
		item = dir.get_next()
	return return_paths

static func safe_make_dir_absolute(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_absolute(folder)
	
static func randf_range_vec(vec: Vector2) -> float:
	return randf_range(vec.x, vec.y)
	
static func randi_range_vec(vec: Vector2i) -> int:
	return randi_range(vec.x, vec.y)
	
static func rect_from_corners(start: Vector2i, end: Vector2i):
	var real_start := Vector2i(min(start.x, end.x), min(start.y, end.y))
	var real_end := Vector2i(max(start.x, end.x), max(start.y, end.y))
	var rect := Rect2i(real_start, (real_end + Vector2i.ONE) - real_start)
	return rect
	
## Gets all points on a Rect2i. Useful for functions that need to iterate over all said points.
static func get_rect_points(rect: Rect2i) -> Array[Vector2i]:
	var points: Array[Vector2i]
	rect.size = Vector2i(max(1, rect.size.x), max(1, rect.size.y))
	for ry in range(rect.position.y, rect.end.y):
		for rx in range(rect.position.x, rect.end.x):
			points.append(Vector2i(rx, ry))
	return points

## Provided an image and a region, checks all pixels to see if they're empty, returning false if it encounters a non-empty pixel.
static func is_image_region_empty(image: Image, region: Rect2i):
	for point in get_rect_points(region):
		if image.get_pixelv(point).a >= 0.01:
			return false
	return true
