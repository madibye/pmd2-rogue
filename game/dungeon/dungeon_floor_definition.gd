@tool
extends Resource
class_name DungeonFloorDefinition

@export var name: String
@export var tile_dtef: TileDtef
	
func get_terrain(gen_terrain_id: int) -> Enum.Terrain:
	return tile_dtef.floor_tiles if gen_terrain_id == 2 else tile_dtef.water_tiles if gen_terrain_id == 1 else tile_dtef.wall_tiles
