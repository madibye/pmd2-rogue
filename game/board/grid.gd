@tool
extends Node2D
class_name Grid

@export var size := Vector2i(8, 6):
	set(x):
		size = x
		await RPGUtils.until_ready(self)
		_update_size()

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Update Size") var _us = _update_size
@warning_ignore_restore("unused_private_class_variable")

func _ready():
	_update_size()

func _update_size():
	var curr_pos := Vector2.ZERO
	for cell in get_children():
		cell.queue_free()
	for y in size.y:
		var max_height_in_row = 0.0;
		for x in size.x:
			var cell := Cell.create(self, curr_pos, Vector2i(x, y))
			max_height_in_row = maxf(max_height_in_row, cell.size.y)
			curr_pos.x += cell.size.x
		curr_pos.x = 0
		curr_pos.y += max_height_in_row
