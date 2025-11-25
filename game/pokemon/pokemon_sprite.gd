@tool
extends Node2D
class_name PokemonSprite

const Direction := Pokemon.Direction

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var shadow_sprite: AnimatedSprite2D = %ShadowSprite

@export var definition: PokemonDefinition:
	set(x):
		definition = x
		update_spritesheet()
@export var form: String:
	set(x):
		form = x
		update_spritesheet()
@export var shiny: bool:
	set(x):
		shiny = x
		update_spritesheet()
@export var female: bool:
	set(x):
		female = x
		update_spritesheet()
@export var animation: String:
	set(x):
		animation = x
		update_anim()
@export var direction: Direction:
	set(x):
		direction = x
		update_anim()

var full_anim_name: StringName

func _ready():
	play_anim("Idle")

func update_spritesheet():
	await RPGUtils.until_ready(self)
	var isp := is_playing()
	if not definition or not definition.forms:
		sprite.sprite_frames = null
		shadow_sprite.sprite_frames = null
		return
	var form_names := definition.forms.map(func(f: FormDefinition): return f.name)
	var valid_form_defs: Array[FormDefinition] = definition.forms.filter(func(f: FormDefinition): return f.name == form)
	if not form in form_names or not valid_form_defs:
		form = form_names[0]
		return
	var form_def: FormDefinition = valid_form_defs[0]
	var form_id: String = form_def.get_id(shiny, female)
	sprite.sprite_frames = definition.get_spriteframes(form_id)
	shadow_sprite.sprite_frames = definition.get_spriteframes(form_id, "Shadow")
	shadow_sprite.material.set_shader_parameter(&"shadow_size", definition.shadow_size)
	notify_property_list_changed()
	update_anim()
	if isp: play_anim()

func is_playing(anim := "") -> bool:
	return (sprite.is_playing() and shadow_sprite.is_playing()) and (anim.is_empty()) or (sprite.animation.contains(anim) and shadow_sprite.animation.contains(anim))

func update_anim():
	await RPGUtils.until_ready(self)
	if not sprite.sprite_frames:
		return
	var isp := is_playing()
	if sprite.sprite_frames.has_animation(animation):
		full_anim_name = animation
	else:
		full_anim_name = "%s-%s" % [animation, PokemonDefinition.DIRECTIONS[direction]]
	if not sprite.sprite_frames.has_animation(full_anim_name) or not shadow_sprite.sprite_frames.has_animation(full_anim_name):
		return
	print(full_anim_name)
	sprite.animation = full_anim_name
	shadow_sprite.animation = full_anim_name
	if isp: play_anim()

func play_anim(anim := "", with_continue := true):
	if is_playing(anim) or not sprite.sprite_frames:
		return
	var u := [sprite.get_frame(), sprite.get_frame_progress()]
	var s := [shadow_sprite.get_frame(), shadow_sprite.get_frame_progress()]
	if not anim.is_empty():
		animation = anim
	if not sprite.sprite_frames.has_animation(full_anim_name) or not shadow_sprite.sprite_frames.has_animation(full_anim_name):
		return
	sprite.play(full_anim_name)
	shadow_sprite.play(full_anim_name)
	if with_continue:
		sprite.set_frame_and_progress(u[0], u[1])
		shadow_sprite.set_frame_and_progress(s[0], s[1])

func stop_anim():
	sprite.stop()
	shadow_sprite.stop()
	
func set_anim_speed(speed := 1.0):
	sprite.speed_scale = speed
	shadow_sprite.speed_scale = speed
	
func set_controllable(c := false):
	shadow_sprite.material.set_shader_parameter(&"outline_color", Color("fff200ff") if c else Color("00000000"))
	shadow_sprite.material.set_shader_parameter(&"inner_color", Color("a26800ff") if c else Color("000000ff"))

func _validate_property(property):
	match property["name"]:
		"form":
			if not definition or not definition.forms:
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
			var names := []
			for f in len(definition.forms):
				if not definition.forms[f].name in names:
					names.append(definition.forms[f].name)
			if names.is_empty():
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property
		"animation":
			if not sprite.sprite_frames:
				property["hint"] = PROPERTY_HINT_TYPE_STRING
				return property
			var names := []
			for n in sprite.sprite_frames.get_animation_names():
				var sn := n.substr(0, n.find("-"))
				if not sn in names:
					names.append(sn)
			property["hint"] = PROPERTY_HINT_ENUM
			property["hint_string"] = ",".join(names)
			return property

	
