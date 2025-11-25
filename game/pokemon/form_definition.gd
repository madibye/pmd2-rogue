@tool
extends Resource
class_name FormDefinition

@export var name: String
@export var form_number: int
@export var types: Array[Type.T]
@export var abilities: Array[AbilityDefinition]
@export var base_stats: PokemonBaseStats

@export var ids: PackedStringArray = PackedStringArray(["", "", "", ""])

func assign_id(rn: String, nums: Array) -> void:
	if len(nums) >= 4 and (nums[2] != 0 and nums[3] != 0): ids[3] = rn
	elif len(nums) >= 4 and nums[3] != 0: ids[2] = rn
	elif len(nums) >= 3 and nums[2] != 0: ids[1] = rn
	else: ids[0] = rn
	
func get_id(shiny: bool, female: bool):
	if shiny and female and ids[3]:
		return ids[3]
	if female and ids[2]:
		return ids[2]
	if shiny and ids[1]:
		return ids[1]
	return ids[0]
