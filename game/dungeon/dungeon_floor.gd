@tool
extends TileMapLayer
class_name DungeonFloor

@export var definition: DungeonFloorDefinition:
	set(x):
		definition = x
		if definition == null:
			clear()
			set_process(false)
			return
		set_process(true)
		if Engine.is_editor_hint():
			reset_dungeon()

@onready var camera: Camera2D = %Camera2D
@onready var generator: DungeonFloorGenerator = %DungeonFloorGenerator

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Generate Floor") var _generate_floor = reset_dungeon
@warning_ignore_restore("unused_private_class_variable")

var frames_remaining: Array
var anim_layers: Array[TileMapLayer]

func _ready():
	if not Engine.is_editor_hint():
		reset_dungeon()
	
func reset_dungeon():
	await PMDUtils.until_ready(self)
	clear()
	for layer in anim_layers: layer.queue_free()
	tile_set = definition.tile_dtef.tile_set
	anim_layers.clear()
	for layer_id in TileDtef.ANIM_LAYERS:
		anim_layers.append(TileMapLayer.new())
		add_child(anim_layers[layer_id])
		move_child(anim_layers[layer_id], 0)
		anim_layers[layer_id].tile_set = definition.tile_dtef.anim_tile_sets[layer_id]
		frames_remaining.append({})
		for sheet in definition.tile_dtef.anim_tile_sheets[layer_id]:
			frames_remaining[layer_id][sheet] = 0
	set_camera_limits()
	generate_floor()
		
func _process(_delta):
	attempt_advance_frame()
	if Engine.is_editor_hint():
		sync_tilemaps()

func generate_floor():
	generator.generate_map()
	
func set_camera_limits():
	camera.limit_top = -tile_set.tile_size.y * (DungeonFloorGenerator.BORDER_SIZE - 1)
	camera.limit_left = -tile_set.tile_size.x * (DungeonFloorGenerator.BORDER_SIZE - 1)
	camera.limit_bottom = (generator.size * tile_set.tile_size).y + (tile_set.tile_size.y * (DungeonFloorGenerator.BORDER_SIZE - 1))
	camera.limit_right = (generator.size * tile_set.tile_size).x + (tile_set.tile_size.x * (DungeonFloorGenerator.BORDER_SIZE - 1))

func attempt_advance_frame():
	for layer_id in len(frames_remaining):
		for sheet in frames_remaining[layer_id]:
			var source: TileSetAtlasSource
			for src_id in anim_layers[layer_id].tile_set.get_source_count():
				if anim_layers[layer_id].tile_set.get_source(src_id).resource_name == sheet:
					source = anim_layers[layer_id].tile_set.get_source(src_id)
			if not source: continue
			var sheets: Array = definition.tile_dtef.anim_tile_sheets[layer_id][sheet]
			if sheets.is_empty(): continue
			frames_remaining[layer_id][sheet] -= 1
			if frames_remaining[layer_id][sheet] > 0: continue
			var current_idx := (sheets.find(source.texture) + 1) % len(sheets)
			source.texture = sheets[current_idx]
			frames_remaining[layer_id][sheet] = int(source.texture.resource_path.split(".")[1])

func sync_tilemaps():
	for layer in anim_layers:
		layer.tile_map_data = tile_map_data
