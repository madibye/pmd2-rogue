@tool
extends NinePatchRect
class_name MenuBackground

@export var border_color: Enum.MenuBGColor:
	set(x):
		border_color = x
		match border_color:
			Enum.MenuBGColor.BG2: region_rect.position.y = 28.0
			_: region_rect.position.y = 4.0

@onready var menu_border: MenuBorder = %MenuBorder

func _notification(what):
	if what == NOTIFICATION_DRAW:
		menu_border.position = Vector2.ONE * -4
		menu_border.size = size + (Vector2.ONE * 8)
		custom_minimum_size = menu_border.get_minimum_size() - menu_border.position
