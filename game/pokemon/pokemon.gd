@tool
extends Node2D
class_name Pokemon

enum Direction { South, Southeast, East, Northeast, North, Northwest, West, Southwest }
const VECTOR_TO_DIRECTION: Dictionary[Vector2i, Direction] = {
	Vector2i(-1, 0): Direction.West, Vector2i(-1, 1): Direction.Southwest, Vector2i(0, 1): Direction.South, 
	Vector2i(1, 1): Direction.Southeast, Vector2i(1, 0): Direction.East, Vector2i(1, -1): Direction.Northeast, 
	Vector2i(0, -1): Direction.North, Vector2i(-1, -1): Direction.Northwest
}
const BASE_SPEED := 90.0
const RUN_MULTIPLIER := 2.5

@onready var pokemon_sprite: PokemonSprite = %PokemonSprite

@export var definition: PokemonDefinition:
	set(x):
		definition = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.definition = x
		notify_property_list_changed()
@export var form: String:
	set(x):
		form = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.form = x
		notify_property_list_changed()
@export var shiny: bool:
	set(x):
		shiny = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.shiny = x
		notify_property_list_changed()
@export var female: bool:
	set(x):
		female = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.female = x
		notify_property_list_changed()
@export var animation: String:
	set(x):
		animation = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.animation = x
@export var direction: Direction:
	set(x):
		direction = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.direction = x

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Play Animation") var _play_anim = play_anim
@export_tool_button("Stop Animation") var _stop_anim = stop_anim
@warning_ignore_restore("unused_private_class_variable")

@export var controllable := false:
	set(x):
		controllable = x
		await RPGUtils.until_ready(self)
		pokemon_sprite.set_controllable(x)

var full_anim_name: StringName

func _ready():
	await get_tree().process_frame
	if Engine.is_editor_hint():
		set_process(false)

func _process(delta):
	pokemon_sprite.set_controllable(controllable)
	if not controllable:
		return
	var input_vec := Vector2(Input.get_vector(&"left", &"right", &"up", &"down"))
	var input_dir := Vector2i(roundi(input_vec.x), roundi(input_vec.y))
	var dir: Direction = VECTOR_TO_DIRECTION.get(input_dir, -1)
	if dir == -1:
		pokemon_sprite.play_anim("Idle", false)
		pokemon_sprite.set_anim_speed(1.0)
		return
	direction = dir
	pokemon_sprite.play_anim("Walk")
	var speed := (RUN_MULTIPLIER if Input.is_action_pressed("run") else 1.0)
	pokemon_sprite.set_anim_speed(speed)
	position += input_vec * (delta * BASE_SPEED) * speed
	
func play_anim(anim := "", with_continue := true):
	pokemon_sprite.play_anim(anim, with_continue)
	
func stop_anim():
	pokemon_sprite.stop_anim()
	
func _validate_property(property: Dictionary):
	match property["name"]:
		"form":
			if not definition or not definition.forms:
				property["hint"] = PROPERTY_HINT_NONE
				form = ""
				return property
			var names := []
			for f in len(definition.forms):
				if not definition.forms[f].name in names:
					names.append(definition.forms[f].name)
			if names.is_empty():
				property["hint"] = PROPERTY_HINT_NONE
				form = ""
				return property
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			if form not in names:
				form = names[0]
			return property
		"animation":
			if not pokemon_sprite.sprite.sprite_frames:
				property["hint"] = PROPERTY_HINT_NONE
				return property
			var names := []
			for n in pokemon_sprite.sprite.sprite_frames.get_animation_names():
				var sn := n.substr(0, n.find("-"))
				if not sn in names:
					names.append(sn)
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property
