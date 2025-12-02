@tool
extends Resource
class_name TileDtef

## NOTE (Very important): DTEF stands for Dungeon Tile Exchange Format

const ANIM_LAYERS := 3

@export var name: String
@export var tile_set: TileSet
@export var anim_tile_sets: Array[TileSet]
@export var anim_tile_sheets: Array[Dictionary]
@export var wall_tiles := Enum.Terrain.Wall
@export var water_tiles := Enum.Terrain.Water
@export var floor_tiles := Enum.Terrain.Floor

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Fetch Assets") var _fetch_assets = fetch_assets
@export_tool_button("Generate Tilesets") var _generate_tilesets = generate_tilesets
@warning_ignore_restore("unused_private_class_variable")

var default_tileset: TileSet

func fetch_assets():
	PMDUtils.fetch_assets("RawAsset", "TileDtef/%s/" % name)

func get_tilesheet_paths() -> Array[String]:
	var path := "%s/%s" % ["res://RawAsset/TileDtef", name]
	if not DirAccess.dir_exists_absolute(path):
		print_rich("[color=red]Filepath %s not found! Fetch assets first...![/color]" % path)
		return []
	return PMDUtils.file_search("", path).filter(func(s: String): return s.ends_with(".png"))

func generate_tilesets():
	var tilesheets_paths := get_tilesheet_paths()
	if tilesheets_paths.is_empty(): return
	
	default_tileset = load("res://resources/dungeon/default_tileset.tres")
	
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(24, 24)
	add_terrain_to_tileset(tile_set)
	var frame_tilesheets_paths = [tilesheets_paths.filter(func(s: String): return s.contains("frame0")), tilesheets_paths.filter(func(s: String): return s.contains("frame1")), tilesheets_paths.filter(func(s: String): return s.contains("frame2"))]
	var base_tilesheets_paths = tilesheets_paths.filter(func(s: String): return s not in frame_tilesheets_paths[0] and s not in frame_tilesheets_paths[1] and s not in frame_tilesheets_paths[2])
	
	anim_tile_sets.clear()
	anim_tile_sheets.clear()
	for i in ANIM_LAYERS:
		anim_tile_sets.append(tile_set.duplicate(true))
		anim_tile_sheets.append({})
	#frame_data.clear()
	
	for sheet: String in base_tilesheets_paths:
		add_tile_source(sheet, frame_tilesheets_paths)
		
func add_terrain_to_tileset(_tile_set: TileSet):
	for terrain_set in default_tileset.get_terrain_sets_count():
		_tile_set.add_terrain_set()
		_tile_set.set_terrain_set_mode(terrain_set, default_tileset.get_terrain_set_mode(terrain_set))
		for terrain in default_tileset.get_terrains_count(terrain_set):
			_tile_set.add_terrain(terrain_set)
			_tile_set.set_terrain_color(terrain_set, terrain, default_tileset.get_terrain_color(terrain_set, terrain))
			_tile_set.set_terrain_name(terrain_set, terrain, default_tileset.get_terrain_name(terrain_set, terrain))
	
func add_tile_source(sheet: String, frame_sheets: Array):
	var source_name := sheet.split("/")[-1].rstrip(".png")
	var source := TileSetAtlasSource.new()
	tile_set.add_source(source)
	source.resource_name = source_name
	source.texture = load(sheet)
	source.texture_region_size = tile_set.tile_size
	#frame_data.append([])
	tileify(source, 2 if source_name == "tileset_more" else -1, 1.0 if source_name == "tileset_0" else 0.05)
	for frame in 3:
		var anim_source := TileSetAtlasSource.new()
		anim_tile_sets[frame].add_source(anim_source)
		anim_source.resource_name = source_name
		anim_source.texture_region_size = anim_tile_sets[frame].tile_size
		var valid_sheets: Array[String] = frame_sheets[frame].filter(func(s: String): return s.contains(source_name))
		valid_sheets.sort_custom(func(a: String, b: String): return int(a.replace("_", ".").split(".")[-3]) < int(b.replace("_", ".").split(".")[-3]))
		var textures := valid_sheets.map(func(s: String): return load(s))
		anim_tile_sheets[frame][source_name] = textures
		if not textures.is_empty():
			anim_source.texture = textures[0]
			tileify(anim_source)
		#frame_data[-1].append({})
		#if not valid_sheets.is_empty():
			#frame_data[-1][-1]["tilesheets"] = valid_sheets.map(func(s: String): return load(s))
			#frame_data[-1][-1]["frame_pos"] = 0
			#frame_data[-1][-1]["time_until_update"] = 0.0
			#frame_data[-1][-1]["frame_offset"] = 1

func tileify(source: TileSetAtlasSource, force_terrain_set := -1, force_probability := 1.0):
	if source.get_tiles_count() != 0 or not source.texture:
		return
	var default_source: TileSetAtlasSource = default_tileset.get_source(0)
	var atlas_size := source.get_atlas_grid_size()
	var image := source.texture.get_image()
	for x in atlas_size.x:
		for y in atlas_size.y:
			var vec := Vector2i(x, y)
			if not default_source.has_tile(vec) or source.has_tile(vec):
				continue
			var size := source.texture_region_size
			if PMDUtils.is_image_region_empty(image, Rect2i(vec * size, size)) :
				continue
			source.create_tile(vec)
			for alt in default_source.get_next_alternative_tile_id(vec):
				if alt != 0 and default_source.has_alternative_tile(vec, alt): 
					source.create_alternative_tile(vec, alt)
			for alt in source.get_next_alternative_tile_id(vec):
				var default_tile_data := default_source.get_tile_data(vec, alt)
				var source_tile_data := source.get_tile_data(vec, alt)
				source_tile_data.terrain_set = default_tile_data.terrain_set if force_terrain_set < 0 else force_terrain_set
				source_tile_data.terrain = default_tile_data.terrain
				source_tile_data.probability = force_probability
				for neighbor in range(16):
					if default_tile_data.is_valid_terrain_peering_bit(neighbor):
						source_tile_data.set_terrain_peering_bit(neighbor, default_tile_data.get_terrain_peering_bit(neighbor))
