@tool
extends Resource
class_name FormDefinition

@export var name: String
@export var form_number: int
@export var types: Array[Enum.PokemonType]
@export var base_stats: PokemonBaseStats

@export var default_animations: Array
@export var shiny_animations: Array
@export var female_animations: Array
@export var shiny_female_animations: Array

func add_animations(animations: Array, nums: Array) -> void:
	if len(nums) >= 4 and (nums[2] != 0 and nums[3] != 0): shiny_female_animations = animations
	elif len(nums) >= 4 and nums[3] != 0: female_animations = animations
	elif len(nums) >= 3 and nums[2] != 0: shiny_animations = animations
	else: default_animations = animations

func get_animation_names(shiny: bool, female: bool) -> Array[String]:
	var names: Array[String]
	names.assign(get_animations(shiny, female).map(func(anim) -> String:
		var anim_name: String 
		if anim is String: anim_name = anim.split("->")[0]
		else: anim_name = anim.name
		return anim_name
	))
	return names

func get_animations(shiny: bool, female: bool) -> Array:
	if shiny and female and not shiny_female_animations.is_empty(): return shiny_female_animations
	elif female and not female_animations.is_empty(): return female_animations
	elif shiny and not shiny_animations.is_empty(): return shiny_animations
	else: return default_animations
	
## Supports a variable number of "backup animations". 
## For example, `get_animation(false, false, "Appeal", "Idle")`
## would return Appeal if there is an animation called Appeal, or Idle otherwise.
func get_animation(shiny: bool, female: bool, ...anim_names: Array) -> PokemonAnimation:
	var animations: Array = get_animations(shiny, female)
	for anim_name: String in anim_names:
		var anim_idx := get_animation_names(shiny, female).find(anim_name)
		if anim_idx == -1: continue
		var animation = animations[anim_idx]
		if animation is String:
			anim_idx = get_animation_names(shiny, female).find(animation.split("->")[-1])
			if anim_idx == -1: continue
			animation = animations[anim_idx]
		return animation
	return null
