extends Resource
class_name PokemonBaseStats

@export_range(0, 255) var hp: int
@export_range(0, 255) var attack: int
@export_range(0, 255) var defense: int
@export_range(0, 255) var special_attack: int
@export_range(0, 255) var special_defense: int
@export_range(0, 255) var speed: int
var base_stat_total:
	get: return hp + attack + defense + special_attack + special_defense + speed
