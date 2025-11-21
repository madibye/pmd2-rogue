@tool
extends Node2D
class_name Cell

@onready var mi2d: MeshInstance2D = %MeshInstance2D
@onready var size: Vector2:
	get: return mi2d.mesh.size

var grid: Grid
var board_pos: Vector2i

static func create(_grid: Grid, _position: Vector2, _board_pos: Vector2i) -> Cell:
	var cell: Cell = load("uid://16ljmce8dgqe").instantiate()
	cell.position = _position
	cell.board_pos = _board_pos
	if _grid: 
		cell.grid = _grid
		_grid.add_child(cell)
	return cell
