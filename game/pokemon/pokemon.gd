@tool
extends Node2D
class_name Pokemon

const VECTOR_TO_DIRECTION: Dictionary[Vector2i, Enum.Direction] = {
	Vector2i(-1, 0): Enum.Direction.West, Vector2i(-1, 1): Enum.Direction.Southwest, Vector2i(0, 1): Enum.Direction.South, 
	Vector2i(1, 1): Enum.Direction.Southeast, Vector2i(1, 0): Enum.Direction.East, Vector2i(1, -1): Enum.Direction.Northeast, 
	Vector2i(0, -1): Enum.Direction.North, Vector2i(-1, -1): Enum.Direction.Northwest
}

@onready var pokemon_sprite: PokemonSprite = %PokemonSprite

@export var definition: PokemonDefinition:
	set(x):
		var same := x == definition
		definition = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.definition = x
		notify_property_list_changed()
@export var form: String:
	set(x):
		var same := x == form
		form = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.form = x
		notify_property_list_changed()
@export var shiny: bool:
	set(x):
		var same := x == shiny
		shiny = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.shiny = x
		notify_property_list_changed()
@export var female: bool:
	set(x):
		var same := x == female
		female = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.female = x
		notify_property_list_changed()
@export var animation: String:
	set(x):
		var same := x == animation
		animation = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.animation_name = x
@export var direction: Enum.Direction:
	set(x):
		var same := x == direction
		direction = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.direction = x

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Play Animation") var _play_anim = play_anim
@export_tool_button("Pause Animation") var _pause_anim = pause_anim
@export_tool_button("Stop Animation") var _stop_anim = stop_anim
@warning_ignore_restore("unused_private_class_variable")

@export var controllable := false:
	set(x):
		var same := x == controllable
		controllable = x
		if same: return
		await PMDUtils.until_ready(self)
		pokemon_sprite.shadow_effect = (Enum.ShadowEffect.Controllable if x else Enum.ShadowEffect.Default)

var full_anim_name: StringName
	
func play_anim(anim := ""):
	pokemon_sprite.play(anim)
	
func pause_anim():
	pokemon_sprite.pause()
	
func stop_anim():
	pokemon_sprite.stop()
	
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
			if not pokemon_sprite.get_form_definition():
				property["hint"] = PROPERTY_HINT_NONE
				return property
			var names := []
			for anim in pokemon_sprite.get_form_definition().get_animations(shiny, female):
				var anim_name: String
				if anim is String: anim_name = anim.split("->")[0]
				else: anim_name = anim.name
				if not anim_name in names:
					names.append(anim_name)
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property
