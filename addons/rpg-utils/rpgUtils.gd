extends Object
class_name RPGUtils

## This script contains many helpful static functions to be used throughout the game.

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

## Gets the name from an enum
static func get_enum_value_name(_enum: Dictionary, value: int) -> String:
	return _enum.find_key(value)
