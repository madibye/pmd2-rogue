@tool
extends Node2D
class_name Unit

enum Direction { South, Southeast, East, Northeast, North, Northwest, West, Southwest }
const VECTOR_TO_DIRECTION: Dictionary[Vector2i, Direction] = {
	Vector2i(-1, 0): Direction.West, Vector2i(-1, 1): Direction.Southwest, Vector2i(0, 1): Direction.South, 
	Vector2i(1, 1): Direction.Southeast, Vector2i(1, 0): Direction.East, Vector2i(1, -1): Direction.Northeast, 
	Vector2i(0, -1): Direction.North, Vector2i(-1, -1): Direction.Northwest
}
const BASE_SPEED := 90.0
const RUN_MULTIPLIER := 2.5

@onready var unit_sprite: AnimatedSprite2D = %UnitSprite
@onready var shadow_sprite: AnimatedSprite2D = %ShadowSprite

@export var definition: UnitDefinition:
	set(x):
		definition = x
		update_spritesheet()
@export var form: String:
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

@export var controllable := false

var full_anim_name: StringName

func _ready():
	if Engine.is_editor_hint() or not controllable:
		set_process(false)
	play_anim(&"Idle")

func _process(delta):
	var input_vec := Vector2(Input.get_vector(&"left", &"right", &"up", &"down"))
	var input_dir := Vector2i(roundi(input_vec.x), roundi(input_vec.y))
	var dir: Direction = VECTOR_TO_DIRECTION.get(input_dir, -1)
	if dir == -1:
		play_anim(&"Idle", false)
		set_anim_speed(1.0)
		return
	direction = dir
	play_anim(&"Walk")
	var speed := (RUN_MULTIPLIER if Input.is_action_pressed("run") else 1.0)
	set_anim_speed(speed)
	position += input_vec * (delta * BASE_SPEED) * speed

func update_spritesheet():
	await RPGUtils.until_ready(self)
	var isp := is_playing()
	if not definition or not definition.forms:
		unit_sprite.sprite_frames = null
		shadow_sprite.sprite_frames = null
		return
	if not form in definition.forms.keys() and not form in definition.forms.values():
		form = definition.forms.values()[0]
		return
	var form_code: String = form if not form in definition.forms.values() else definition.forms.find_key(form)
	unit_sprite.sprite_frames = definition.get_spriteframes(form_code)
	shadow_sprite.sprite_frames = definition.get_spriteframes(form_code, "Shadow")
	shadow_sprite.material.set_shader_parameter(&"shadow_size", definition.shadow_size)
	notify_property_list_changed()
	update_anim()
	if isp: play_anim()

func is_playing(anim := "") -> bool:
	var isp := unit_sprite.is_playing() and shadow_sprite.is_playing()
	var ran := true
	if not anim.is_empty():
		ran = unit_sprite.animation == anim and shadow_sprite.animation == anim
	return isp and ran

func update_anim():
	await RPGUtils.until_ready(self)
	var isp := is_playing()
	if unit_sprite.sprite_frames.has_animation(animation):
		full_anim_name = animation
	else:
		full_anim_name = "%s-%s" % [animation, UnitDefinition.DIRECTIONS[direction]]
	unit_sprite.animation = full_anim_name
	shadow_sprite.animation = full_anim_name
	if isp: play_anim()

func play_anim(anim := "", with_continue := true):
	if is_playing(anim):
		return
	var u := [unit_sprite.get_frame(), unit_sprite.get_frame_progress()]
	var s := [shadow_sprite.get_frame(), shadow_sprite.get_frame_progress()]
	if not anim.is_empty():
		animation = anim
	unit_sprite.play(full_anim_name)
	shadow_sprite.play(full_anim_name)
	if with_continue:
		unit_sprite.set_frame_and_progress(u[0], u[1])
		shadow_sprite.set_frame_and_progress(s[0], s[1])

func stop_anim():
	unit_sprite.stop()
	shadow_sprite.stop()
	
func set_anim_speed(speed := 1.0):
	unit_sprite.speed_scale = speed
	shadow_sprite.speed_scale = speed
	
func _validate_property(property: Dictionary):
	match property["name"]:
		"form":
			if not definition or not definition.forms:
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
			var names := []
			for f in definition.forms:
				if not definition.forms[f] in names and not f in names:
					names.append(definition.forms[f] if not definition.forms[f].is_empty() else f)
			if names.is_empty():
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
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
