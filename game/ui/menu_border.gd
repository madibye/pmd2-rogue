@tool
extends NinePatchRect
class_name MenuBorder

@export var border_color: Enum.BorderColor:
	set(x):
		border_color = x
		match border_color:
			Enum.BorderColor.Blue: region_rect.position.y = 24.0
			Enum.BorderColor.Pink: region_rect.position.y = 48.0
			_: region_rect.position.y = 0.0

@export var border_style: Enum.BorderStyle:
	set(x):
		border_style = x
		match border_style:
			Enum.BorderStyle.Frame2: region_rect.position.x = 24.0
			Enum.BorderStyle.Frame3: region_rect.position.x = 48.0
			Enum.BorderStyle.Frame4: region_rect.position.x = 72.0
			Enum.BorderStyle.Frame5: region_rect.position.x = 96.0
			_: region_rect.position.x = 0.0
