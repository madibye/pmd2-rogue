@tool
extends Resource
class_name FormDefinition

@export var name: String
@export var form_number: int
@export var types: Array[Enum.PokemonType]
@export var base_stats: PokemonBaseStats

@export var spriteframes: Dictionary[String, Array] = {}

func assign_form_spriteframes(_spriteframes: Array[SpriteFrames], nums: Array) -> void:
	var sheet_name = "normal"
	if len(nums) >= 4 and (nums[2] != 0 and nums[3] != 0): sheet_name = "shiny_female"
	elif len(nums) >= 4 and nums[3] != 0: sheet_name = "female"
	elif len(nums) >= 3 and nums[2] != 0: sheet_name = "shiny"
	spriteframes[sheet_name] = _spriteframes
	
func get_spriteframes(shiny: bool, female: bool, type_str := ""):
	var spriteframes_list: Array
	if shiny and female:
		spriteframes_list = spriteframes.get("shiny_female", spriteframes.get("shiny", spriteframes.get("normal")))
	elif female:
		spriteframes_list = spriteframes.get("female", spriteframes.get("normal"))
	elif shiny:
		spriteframes_list = spriteframes.get("shiny", spriteframes.get("normal"))
	else:
		spriteframes_list = spriteframes.get("normal")
	var type_str_matches := spriteframes_list.filter(func(s): return s.resource_name.contains(type_str))
	if type_str_matches.is_empty():
		type_str_matches = spriteframes_list
	return type_str_matches[0]
