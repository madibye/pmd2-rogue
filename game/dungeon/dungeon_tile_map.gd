@tool
extends Node2D

@export var dungeon_name: String

@onready var tile_map_layer: TileMapLayer = %BaseLayer
@onready var frame_0_layer: TileMapLayer = %Frame0Layer
@onready var frame_1_layer: TileMapLayer = %Frame1Layer
@onready var frame_2_layer: TileMapLayer = %Frame2Layer

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Fetch Assets") var _fetch_assets = fetch_assets
@export_tool_button("Generate Tilesets") var _make_tilesets = make_tilesets
@warning_ignore_restore("unused_private_class_variable")

## Various values for the tileset animator to keep track of. Probably should be in one big dict but that's fine.
var frame_data: Array

func _ready():
	make_tilesets()
	sync_tilemaps()
	tile_map_layer.changed.connect(sync_tilemaps)

func fetch_assets():
	RPGUtils.fetch_assets("TileDtef/%s/" % dungeon_name)

func make_tilesets():
	var path := "%s/%s" % ["res://assets/TileDtef", dungeon_name]
	if not DirAccess.dir_exists_absolute(path):
		print_rich("[color=red]Filepath %s not found! Fetch assets first...![/color]" % path)
		return
	tile_map_layer.tile_set = TileSet.new()
	tile_map_layer.tile_set.tile_size = Vector2i(24, 24)
	var tilesheets_paths := RPGUtils.file_search("", path).filter(func(s: String): return s.ends_with(".png"))
	var frame_tilesheets_paths = [tilesheets_paths.filter(func(s: String): return s.contains("frame0")), tilesheets_paths.filter(func(s: String): return s.contains("frame1")), tilesheets_paths.filter(func(s: String): return s.contains("frame2"))]
	var base_tilesheets_paths = tilesheets_paths.filter(func(s: String): return s not in frame_tilesheets_paths[0] and s not in frame_tilesheets_paths[1] and s not in frame_tilesheets_paths[2])

	frame_0_layer.tile_set = tile_map_layer.tile_set.duplicate(true)
	frame_1_layer.tile_set = tile_map_layer.tile_set.duplicate(true)
	frame_2_layer.tile_set = tile_map_layer.tile_set.duplicate(true)
	frame_data.clear()
	
	for sheet: String in base_tilesheets_paths:
		var n := sheet.split("/")[-1].rstrip(".png")
		var tsas := TileSetAtlasSource.new()
		tile_map_layer.tile_set.add_source(tsas)
		tsas.resource_name = n
		tsas.texture = load(sheet)
		tsas.texture_region_size = tile_map_layer.tile_set.tile_size
		frame_data.append([])
		tileify(tsas)
		for f in 3:
			var a_tsas := TileSetAtlasSource.new()
			get("frame_%s_layer" % str(f)).tile_set.add_source(a_tsas)
			a_tsas.resource_name = n
			a_tsas.texture_region_size = tile_map_layer.tile_set.tile_size
			var valid_ts: Array[String] = frame_tilesheets_paths[f].filter(func(s: String): return s.contains(n))
			frame_data[-1].append({})
			if not valid_ts.is_empty():
				frame_data[-1][-1]["tilesheets"] = valid_ts.map(func(s: String): return load(s))
				frame_data[-1][-1]["frame_pos"] = 0
				frame_data[-1][-1]["time_until_update"] = 0.0
				frame_data[-1][-1]["frame_offset"] = 1
		
func _process(delta):
	for t in len(frame_data):
		for l in len(frame_data[t]):
			attempt_advance_frame(t, l, delta)
	sync_tilemaps()
		
func tileify(tsas: TileSetAtlasSource):
	if tsas.get_tiles_count() != 0:
		return
	var atlas_size := tsas.get_atlas_grid_size()
	for x in atlas_size.x:
		for y in atlas_size.y:
			tsas.create_tile(Vector2i(x, y))

func attempt_advance_frame(t: int, l: int, delta: float) -> bool:
	var tsas: TileSetAtlasSource = get("frame_%s_layer" % str(l)).tile_set.get_source(t)
	if not tsas or not (frame_data[t][l].get("frame_pos", 0)) < len(frame_data[t][l].get("tilesheets", [])):
		return false
	frame_data[t][l]["time_until_update"] -= delta
	if frame_data[t][l]["time_until_update"] >= 0.0:
		return false
	var new_frame_pos: int = frame_data[t][l]["frame_pos"] + frame_data[t][l]["frame_offset"]
	if new_frame_pos >= len(frame_data[t][l]["tilesheets"]) or new_frame_pos < 0:
		new_frame_pos = frame_data[t][l]["frame_pos"] + frame_data[t][l]["frame_offset"]
		if new_frame_pos >= len(frame_data[t][l]["tilesheets"]) or new_frame_pos < 0:
			new_frame_pos = 0
	frame_data[t][l]["frame_pos"] = new_frame_pos
	tsas.texture = frame_data[t][l]["tilesheets"][new_frame_pos]
	if tsas.texture:
		frame_data[t][l]["time_until_update"] += float(tsas.texture.resource_path.split(".")[1]) / 60.0
		tileify(tsas)
	return true

func sync_tilemaps():
	if frame_0_layer: frame_0_layer.tile_map_data = tile_map_layer.tile_map_data
	if frame_1_layer: frame_1_layer.tile_map_data = tile_map_layer.tile_map_data
	if frame_2_layer: frame_2_layer.tile_map_data = tile_map_layer.tile_map_data
	
