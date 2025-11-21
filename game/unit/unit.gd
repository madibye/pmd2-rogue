@tool
extends Node2D
class_name Unit

enum Direction { South, Southeast, East, Northeast, North, Northwest, West, Southwest }

@onready var unit_sprite: AnimatedSprite2D = %UnitSprite
@onready var shadow_sprite: AnimatedSprite2D = %ShadowSprite

@export var definition: UnitDefinition:
	set(x):
		definition = x
		update_spritesheet()
@export var form: String = "":
	set(x):
		form = x
		update_spritesheet()
@export var animation: String:
	set(x):
		animation = x
		update_anim()
@export var direction: Direction:
	set(x):
		direction = x
		update_anim()
		
@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Play Animation") var _play_anim = play_anim
@export_tool_button("Stop Animation") var _stop_anim = stop_anim
@warning_ignore_restore("unused_private_class_variable")

var full_anim_name: StringName

func update_spritesheet():
	await RPGUtils.until_ready(self)
	if not definition:
		unit_sprite.sprite_frames = null
		shadow_sprite.sprite_frames = null
		return
	unit_sprite.sprite_frames = definition.get_spritesheet(form if form != "base" else "")
	shadow_sprite.sprite_frames = definition.get_spritesheet(form if form != "base" else "", "Shadow")
	shadow_sprite.material.set_shader_parameter(&"shadow_size", definition.shadow_size)
	notify_property_list_changed()
	update_anim()

func update_anim():
	await RPGUtils.until_ready(self)
	if unit_sprite.sprite_frames.has_animation(animation):
		full_anim_name = animation
	else:
		full_anim_name = "%s-%s" % [animation, UnitDefinition.DIRECTIONS[direction]]
	unit_sprite.animation = full_anim_name
	shadow_sprite.animation = full_anim_name

func play_anim(anim := ""):
	if not anim.is_empty():
		animation = anim
	unit_sprite.play(full_anim_name)
	shadow_sprite.play(full_anim_name)

func stop_anim():
	unit_sprite.stop()
	shadow_sprite.stop()
	
func _validate_property(property: Dictionary):
	match property["name"]:
		"form":
			if not definition or not definition.spritesheets:
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
			var names := ["base"]
			for n in definition.spritesheets:
				var sn := n.substr(n.find("-")).lstrip("-").rstrip("-Offsets").rstrip("-Shadow")
				if not sn in names:
					names.append(sn)
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property
		"animation":
			if not unit_sprite.sprite_frames:
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
			var names := []
			for n in unit_sprite.sprite_frames.get_animation_names():
				var sn := n.substr(0, n.find("-"))
				if not sn in names:
					names.append(sn)
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property
