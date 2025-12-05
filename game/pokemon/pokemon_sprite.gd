@tool
extends Node2D
class_name PokemonSprite

signal animation_looped

@onready var sprite: Sprite2D = %AnimSprite
@onready var shadow_sprite: Sprite2D = %ShadowSprite
@onready var offset_sprite: Sprite2D = %OffsetsSprite

@export var definition: PokemonDefinition:
	set(x):
		var same := x == definition
		definition = x
		if not same: update_spritesheet()
@export var form: String:
	set(x):
		var same := x == form
		form = x
		if not same: update_spritesheet()
@export var shiny: bool:
	set(x):
		var same := x == shiny
		shiny = x
		if not same: update_spritesheet()
@export var female: bool:
	set(x):
		var same := x == female
		female = x
		if not same: update_spritesheet()
@export var animation_name: String = "Idle":
	set(x):
		var same := x == animation_name
		animation_name = x
		if not same: update_spritesheet()
@export var direction: Enum.Direction:
	set(x):
		var same := x == direction
		direction = x
		if not same: update_direction()
@export var shadow_effect: Enum.ShadowEffect:
	set(x):
		var same := x == direction
		shadow_effect = x
		if not same: update_shadow_effect()

var frame_size: Vector2i:
	set(x):
		frame_size = x
		await PMDUtils.until_ready(self)
		sprite.hframes = roundi((sprite.texture.get_size() / Vector2(x)).x)
		sprite.vframes = roundi((sprite.texture.get_size() / Vector2(x)).y)
		shadow_sprite.hframes = roundi((shadow_sprite.texture.get_size() / Vector2(x)).x)
		shadow_sprite.vframes = roundi((shadow_sprite.texture.get_size() / Vector2(x)).y)
		offset_sprite.hframes = roundi((offset_sprite.texture.get_size() / Vector2(x)).x)
		offset_sprite.vframes = roundi((offset_sprite.texture.get_size() / Vector2(x)).y)
var frame_coords: Vector2i:
	set(x):
		await PMDUtils.until_ready(self)
		frame_coords = Vector2i(x.x % sprite.hframes, x.y % sprite.vframes)
		sprite.frame_coords = frame_coords
		shadow_sprite.frame_coords = frame_coords
		offset_sprite.frame_coords = frame_coords
var animation: PokemonAnimation
@export var anim_speed: float = 1.0
@export var playing: bool = false:
	set(x):
		playing = x
		set_process(x)
var frame_progress: float
	
func _process(delta):
	if not animation:
		return
	frame_progress += delta
	var duration := (float(animation.durations[frame_coords.x]) / 30.0) / anim_speed
	while frame_progress >= duration:
		frame_coords.x += 1
		frame_progress -= duration
	
func get_form_definition() -> FormDefinition:
	if not definition or not definition.forms:
		return null
	var form_names := definition.forms.map(func map_form_to_name(f: FormDefinition): return f.name)
	var valid_form_defs: Array[FormDefinition] = definition.forms.filter(func form_name_is_form(f: FormDefinition): return f.name == form)
	if not form in form_names or not valid_form_defs:
		form = form_names[0]
		return get_form_definition()
	return valid_form_defs[0]

func update_spritesheet():
	await PMDUtils.until_ready(self)
	if not definition or not definition.forms or (definition and not animation_name in get_form_definition().get_animation_names(shiny, female)):
		sprite.texture = null
		shadow_sprite.texture = null
		offset_sprite.texture = null
		return
	animation = get_form_definition().get_animation(shiny, female, animation_name)
	sprite.texture = animation.anim_texture
	shadow_sprite.texture = animation.shadow_texture
	offset_sprite.texture = animation.offsets_texture
	shadow_sprite.material.set_shader_parameter(&"shadow_size", definition.shadow_size)
	frame_size = animation.frame_size
	update_direction()
	frame_coords = Vector2i(0, direction)
	notify_property_list_changed()
	
# Maybe TODO: Implement `from_backwards` parameter, which makes it play backwards
func play(_name := "", _speed := 1.0):
	if not _name.is_empty():
		animation_name = _name
	anim_speed = _speed
	playing = true
	
func pause():
	playing = false
	
func stop():
	playing = false
	frame_coords.x = 0
	anim_speed = 1.0
	frame_progress = 0
	
func update_shadow_effect():
	await PMDUtils.until_ready(self)
	shadow_sprite.material.set_shader_parameter(&"outline_color", Color("fff200ff") if shadow_effect == Enum.ShadowEffect.Controllable else Color("00000000"))
	shadow_sprite.material.set_shader_parameter(&"inner_color", Color("a26800ff") if shadow_effect == Enum.ShadowEffect.Controllable else Color("000000ff"))

func update_direction():
	frame_coords.y = direction

func _validate_property(property):
	match property["name"]:
		"form":
			if not definition or not definition.forms:
				property["hint"] = PROPERTY_HINT_NONE
				return property
			var names := []
			for f in len(definition.forms):
				if not definition.forms[f].name in names:
					names.append(definition.forms[f].name)
			if names.is_empty():
				property["hint"] = PROPERTY_HINT_NONE
				return property
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property
		"animation_name":
			if not get_form_definition():
				property["hint"] = PROPERTY_HINT_NONE
				return property
			var names := get_form_definition().get_animation_names(shiny, female)
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property

	
