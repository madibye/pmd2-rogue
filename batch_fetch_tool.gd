@tool
extends Node2D
class_name BatchFetchTool

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Fetch All Assets") var _fetch_all_assets = fetch_all_assets
@export_tool_button("Generate Pokemon Spritesheets") var _generate_pokemon_spritesheets = generate_pokemon_spritesheets
@export_tool_button("Generate Font Character Spacing") var _generate_character_spacing = generate_character_spacing
@warning_ignore_restore("unused_private_class_variable")

@export var banner_character_spacing: PackedStringArray
@export var wondermail_character_spacing: PackedStringArray

func fetch_all_assets():
	var paths: Array[String]
	paths.append_array(PMDUtils.file_search("", "res://resources/dungeon", true))
	paths.append_array(PMDUtils.file_search("", "res://resources/pokemon", true))
	for path in paths:
		var resource = load(path)
		if resource.has_method(&"fetch_assets"):
			resource.fetch_assets()
	PMDUtils.fetch_assets("DumpAsset", "Content/Font")
	PMDUtils.fetch_assets("DumpAsset", "Content/UI")
	PMDUtils.fetch_assets("RawAsset", "Particle")

func generate_pokemon_spritesheets():
	var paths: Array[String]
	paths.append_array(PMDUtils.file_search("", "res://resources/pokemon", true))
	for path in paths:
		var resource = load(path)
		if resource.has_method(&"generate_sprite_frames"):
			resource.generate_sprite_frames()

func generate_character_spacing():
	var paths_to_size := {"res://assets/font/banner/char_tables.xml": 24, "res://assets/font/wondermail/char_tables.xml": 12}
	for path in paths_to_size:
		var widths: Array[int]
		widths.resize(256)
		var strings := PackedStringArray()
		var p := XMLParser.new()
		p.open(path)
		while p.read() != ERR_FILE_EOF:
			match p.get_node_type():
				XMLParser.NODE_ELEMENT:
					if p.get_named_attribute_value_safe("tableid") not in ["0", ""]:
						break
					if p.has_attribute("id") and p.has_attribute("width"):
						widths[int(p.get_named_attribute_value("id"))] = int(p.get_named_attribute_value("width")) - paths_to_size[path]
		for i in len(widths):
			strings.append("%s-%s %s" % [i, i, widths[i]])
		if path.contains("banner"):
			banner_character_spacing = strings
		elif path.contains("wondermail"):
			wondermail_character_spacing = strings
