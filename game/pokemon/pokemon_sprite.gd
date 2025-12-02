@tool
extends Node2D
class_name PokemonSprite

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var shadow_sprite: AnimatedSprite2D = %ShadowSprite
@onready var offset_sprite: AnimatedSprite2D = %OffsetSprite

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
@export var animation: String:
	set(x):
		var same := x == animation
		animation = x
		if not same: update_anim(true)
@export var direction: Enum.Direction:
	set(x):
		var same := x == direction
		direction = x
		if not same: update_anim(true)

var full_anim_name: StringName
var shadow_effect: Enum.ShadowEffect = Enum.ShadowEffect.Default

func _ready():
	set_shadow_effect(shadow_effect)
	play_anim("Idle")
	
func get_form_definition() -> FormDefinition:
	var form_names := definition.forms.map(func map_form_to_name(f: FormDefinition): return f.name)
	var valid_form_defs: Array[FormDefinition] = definition.forms.filter(func form_name_is_form(f: FormDefinition): return f.name == form)
	if not form in form_names or not valid_form_defs:
		form = form_names[0]
		return get_form_definition()
	return valid_form_defs[0]

func update_spritesheet():
	await PMDUtils.until_ready(self)
	var isp := is_playing()
	if not definition or not definition.forms:
		sprite.sprite_frames = null
		shadow_sprite.sprite_frames = null
		return
	var form_def := get_form_definition()
	if not form_def:
		return
	
	sprite.sprite_frames = form_def.get_spriteframes(shiny, female)
	shadow_sprite.sprite_frames = form_def.get_spriteframes(shiny, female, "Shadow")
	offset_sprite.sprite_frames = form_def.get_spriteframes(shiny, female, "Offset")
	shadow_sprite.material.set_shader_parameter(&"shadow_size", definition.shadow_size)
	notify_property_list_changed()
	update_anim()
	if isp: play_anim()

func is_playing(anim := "") -> bool:
	return (sprite.is_playing() and shadow_sprite.is_playing()) and (anim.is_empty()) or (sprite.animation.contains(anim) and shadow_sprite.animation.contains(anim))

func update_anim(play := false):
	await PMDUtils.until_ready(self)
	if not sprite.sprite_frames:
		return
	var isp := is_playing()
	var anim_direction := "%s-%s" % [animation, PokemonDefinition.DIRECTIONS[direction]]
	if sprite.sprite_frames.has_animation(anim_direction):
		full_anim_name = anim_direction
	else:
		full_anim_name = animation
	if [sprite, shadow_sprite, offset_sprite].any(func(s: AnimatedSprite2D): return not s.sprite_frames.has_animation(full_anim_name)):
		return
	sprite.animation = full_anim_name
	shadow_sprite.animation = full_anim_name
	offset_sprite.animation = full_anim_name
	if isp or play: play_anim()

func play_anim(anim := "", with_continue := true):
	if is_playing(anim) or not sprite.sprite_frames:
		return
	var frame_and_progress := [sprite.get_frame(), sprite.get_frame_progress(), shadow_sprite.get_frame(), shadow_sprite.get_frame_progress(), offset_sprite.get_frame(), offset_sprite.get_frame_progress()]
	if not anim.is_empty():
		animation = anim
		return
	if [sprite, shadow_sprite, offset_sprite].any(func(s: AnimatedSprite2D): return not s.sprite_frames.has_animation(full_anim_name)):
		return
	sprite.play(full_anim_name)
	shadow_sprite.play(full_anim_name)
	offset_sprite.play(full_anim_name)
	if with_continue:
		sprite.set_frame_and_progress(frame_and_progress[0], frame_and_progress[1])
		shadow_sprite.set_frame_and_progress(frame_and_progress[2], frame_and_progress[3])
		offset_sprite.set_frame_and_progress(frame_and_progress[2], frame_and_progress[3])

func stop_anim():
	sprite.stop()
	shadow_sprite.stop()
	
func set_anim_speed(speed := 1.0):
	sprite.speed_scale = speed
	shadow_sprite.speed_scale = speed
	
func set_shadow_effect(e: Enum.ShadowEffect):
	shadow_sprite.material.set_shader_parameter(&"outline_color", Color("fff200ff") if e == Enum.ShadowEffect.Controllable else Color("00000000"))
	shadow_sprite.material.set_shader_parameter(&"inner_color", Color("a26800ff") if e == Enum.ShadowEffect.Controllable else Color("000000ff"))

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

	
