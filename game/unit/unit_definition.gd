@tool
extends Resource
class_name UnitDefinition

const UNIT_ASSET_FOLDER := "res://assets/Sprite"
const SPRITE_FRAME_FOLDER := "res://resources/spriteframes"

@export var name: String
@export_range(1, 4) var stars: int
@export var dex_number: int
@export var ability: AbilityDefinition
@export var traits: Array[Trait.T]
@export var base_stats: UnitBaseStats
@export var evolutions: Dictionary[UnitDefinition, EvolutionCondition]
@export var spritesheets: Dictionary[String, SpriteFrames]
@export var shadow_size: float

#region Helper functions

func get_spritesheet(form_str := "", type_str := "") -> SpriteFrames:
	var query := str(dex_number).pad_zeros(4)
	if form_str:
		query += "-%s" % form_str
	if type_str:
		query += "-%s" % type_str
	return spritesheets.get(query, null)

#endregion

#region A bunch of XML parsing stuff for animations!!

const DIRECTIONS = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Generate Sprite Frames") var _generate_sprite_frames = generate_sprite_frames
@warning_ignore_restore("unused_private_class_variable")

func generate_sprite_frames():
	spritesheets.clear()
	
	var path := "%s/%s" % [UNIT_ASSET_FOLDER, str(dex_number).pad_zeros(4)]
	if not DirAccess.dir_exists_absolute(path):
		print_rich("[color=red]Filepath %s not found![/color]" % path)
		return
	var anim_data_files := recursive_search("AnimData.xml", path)
	for file in anim_data_files:
		var folder := file.replace("/AnimData.xml", "")
		var data := xml_to_anim_data(file)
		var normal_sprf := SpriteFrames.new()
		var offset_sprf := SpriteFrames.new()
		var shadow_sprf := SpriteFrames.new()
		for s in [normal_sprf, offset_sprf, shadow_sprf]:
			s.remove_animation(&"default")
		for anim in data:
			var n: String = anim.get("name")
			if anim.get("copy_of"):
				var valid := data.filter(func(a): return a.get("name") == anim.get("copy_of"))
				if not valid.is_empty():
					anim = valid[0]
			var normal_spritesheet: Texture2D = load("%s/%s-Anim.png" % [folder, anim.get("name")])
			var offset_spritesheet: Texture2D = load("%s/%s-Offsets.png" % [folder, anim.get("name")])
			var shadow_spritesheet: Texture2D = load("%s/%s-Shadow.png" % [folder, anim.get("name")])
			var rows := floori(normal_spritesheet.get_size().y / anim.get("frame_size", Vector2.ZERO).y)
			var cols := floori(normal_spritesheet.get_size().x / anim.get("frame_size", Vector2.ZERO).x)
			for y in rows:
				for x in cols:
					add_frame_to_sprite(normal_sprf, n, normal_spritesheet, anim.get("frame_size", Vector2.ZERO), x, y, anim.get("durations", []), DIRECTIONS[y] if rows > 1 else "")
					add_frame_to_sprite(offset_sprf, n, offset_spritesheet, anim.get("frame_size", Vector2.ZERO), x, y, anim.get("durations", []), DIRECTIONS[y] if rows > 1 else "")
					add_frame_to_sprite(shadow_sprf, n, shadow_spritesheet, anim.get("frame_size", Vector2.ZERO), x, y, anim.get("durations", []), DIRECTIONS[y] if rows > 1 else "")
		var sprf_extensions: Dictionary[SpriteFrames, String] = {normal_sprf: "", offset_sprf: "-Offsets", shadow_sprf: "-Shadow"}
		for s in sprf_extensions:
			var rn := folder.replace(UNIT_ASSET_FOLDER + "/", "").replace("/", "-") + sprf_extensions[s]
			var new_folder := "%s/%s" % [SPRITE_FRAME_FOLDER, str(dex_number).pad_zeros(4)]
			if not DirAccess.dir_exists_absolute(new_folder):
				DirAccess.make_dir_absolute(new_folder)
			ResourceSaver.save(s, "%s/%s.tres" % [new_folder, rn])
			spritesheets[rn] = s

static func recursive_search(search_term, path: String = "res://", show_hidden: bool = false) -> Array[String]:
	var dir = DirAccess.open(path)
	if not dir:
		return [] as Array[String]
	dir.set_include_hidden(show_hidden)
	dir.list_dir_begin()
	var item = dir.get_next()
	var return_paths: Array[String]
	while item != "":
		if item == search_term:
			return_paths.append("%s/%s" % [dir.get_current_dir(), item])
		if dir.current_is_dir() and item != ".":
			return_paths.append_array(recursive_search(search_term, dir.get_current_dir() + "/" + item, show_hidden))
		item = dir.get_next()
	return return_paths

static func aname(anim: String, dir: String) -> String:
	if dir.is_empty():
		return anim
	return "%s-%s" % [anim, dir]
	
static func add_frame_to_sprite(sprf: SpriteFrames, anim_name: String, spritesheet: Texture2D, region_size: Vector2, x: int, y: int, durations: Array, direction: String = ""):
	var frame_tex := AtlasTexture.new()
	frame_tex.atlas = spritesheet
	frame_tex.region = Rect2(Vector2(x, y) * region_size, region_size)
	var n := aname(anim_name, direction)
	if not n in sprf.get_animation_names():
		sprf.add_animation(n)
		sprf.set_animation_loop(n, true)
		sprf.set_animation_speed(n, 30.0)
	var c := sprf.get_frame_count(n)
	sprf.add_frame(n, frame_tex, 1.0 if not c < len(durations) else float(durations[c]))

func xml_to_anim_data(path: String) -> Array[Dictionary]:
	var p := XMLParser.new()
	if not FileAccess.file_exists(path):
		return []
	p.open(path)
	var xml_pos: Array[String]
	var anims: Array[Dictionary]
	var curr_anim: Dictionary[String, Variant] = {}
	while p.read() != ERR_FILE_EOF:
		match p.get_node_type():
			XMLParser.NODE_ELEMENT:
				var n := p.get_node_name()
				xml_pos.append(n)
			XMLParser.NODE_ELEMENT_END:
				if p.get_node_name() == "Anim" and not curr_anim.is_empty():
					anims.append(curr_anim)
					curr_anim = {}
				xml_pos.erase(p.get_node_name())
			XMLParser.NODE_TEXT:
				var data := p.get_node_data()
				if data.is_empty():
					continue
				if xml_pos[-1] == "ShadowSize":
					shadow_size = float(data)
				if xml_pos[-1] == "Name" and xml_pos[-2] == "Anim":
					curr_anim["name"] = data
				if (xml_pos[-1] == "FrameWidth" or xml_pos[-1] == "FrameHeight") and xml_pos[-2] == "Anim":
					if not curr_anim.get("frame_size") is Vector2i:
						curr_anim["frame_size"] = Vector2i.ZERO
					if xml_pos[-1] == "FrameWidth":
						curr_anim["frame_size"].x = int(data)
					if xml_pos[-1] == "FrameHeight":
						curr_anim["frame_size"].y = int(data)
				if xml_pos[-1] == "Duration" and xml_pos[-2] == "Durations" and xml_pos[-3] == "Anim":
					if not curr_anim.get("durations") is Array:
						curr_anim["durations"] = []
					curr_anim["durations"].append(float(data))
				if xml_pos[-1] == "RushFrame" and xml_pos[-2] == "Anim":
					curr_anim["rush_frame"] = int(data)
				if xml_pos[-1] == "HitFrame" and xml_pos[-2] == "Anim":
					curr_anim["hit_frame"] = int(data)
				if xml_pos[-1] == "ReturnFrame" and xml_pos[-2] == "Anim":
					curr_anim["return_frame"] = int(data)
				if xml_pos[-1] == "CopyOf" and xml_pos[-2] == "Anim":
					curr_anim["copy_of"] = data
	return anims

#endregion
