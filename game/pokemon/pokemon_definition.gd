@tool
extends Resource
class_name PokemonDefinition

const POKEMON_ASSET_FOLDER := "res://RawAsset/Sprite"
const SPRITE_FRAME_FOLDER := "res://resources/spriteframes"

@export var name: String
@export var types: Array[Enum.PokemonType]
@export var base_stats: PokemonBaseStats
@export var evolutions: Dictionary[PokemonDefinition, EvolutionCondition]
@export var mobility := Enum.Mobility.Normal
@export var dex_number: int
@export var forms: Array[FormDefinition]
@export var shadow_size: int

#region A bunch of XML parsing stuff for animations!!

const DIRECTIONS = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Fetch Assets") var _fetch_assets = fetch_assets
@export_tool_button("Generate Sprite Frames") var _generate_sprite_frames = generate_sprite_frames
@warning_ignore_restore("unused_private_class_variable")

func fetch_assets():
	PMDUtils.fetch_assets("RawAsset", "Sprite/%s/" % str(dex_number).pad_zeros(4))

func generate_sprite_frames():
	var path := "%s/%s" % [POKEMON_ASSET_FOLDER, str(dex_number).pad_zeros(4)]
	if not DirAccess.dir_exists_absolute(path):
		print_rich("[color=red]Filepath %s not found! Fetch assets first...![/color]" % path)
		return
	var anim_data_files := PMDUtils.file_search("AnimData.xml", path, true)
	forms.clear()
	for file in anim_data_files:
		var form_anims: Array
		var folder := file.replace("/AnimData.xml", "")
		var anim_data := xml_to_anim_data(file)
		for anim in anim_data:
			var anim_name: String = anim.get("name")
			if anim.get("copy_of"):
				var valid := anim_data.filter(func(a): return a.get("name") == anim.get("copy_of"))
				if not valid.is_empty():
					form_anims.append("%s->%s" % [anim_name, valid[0].get("name")])
			else:
				var durations: Array[int]
				durations.assign(anim.get("durations", []).map(func(d): return roundi(d)))
				var animation := PokemonAnimation.new()
				animation.name = anim_name
				animation.durations = durations
				animation.frame_size = anim.get("frame_size", Vector2i.ZERO)
				animation.anim_texture = load("%s/%s-Anim.png" % [folder, anim.get("name")])
				animation.offsets_texture = load("%s/%s-Offsets.png" % [folder, anim.get("name")])
				animation.shadow_texture = load("%s/%s-Shadow.png" % [folder, anim.get("name")])
				form_anims.append(animation)
				
		insert_form_data(form_anims, folder.replace(POKEMON_ASSET_FOLDER + "/", "").replace("/", "-"))
	ResourceSaver.save(self, "res://resources/pokemon/%s.tres" % name.to_lower())
			
func insert_form_data(form_anims: Array, form_id: String):
	var nums = Array(form_id.split("-")).map(func(st: String): return int(st))
	var matching_forms: Array[FormDefinition] = forms.filter(func(f: FormDefinition): return (len(nums) >= 2 and f.form_number == nums[1]) or len(nums) < 2 and f.form_number == 0)
	var form: FormDefinition
	if matching_forms.is_empty():
		form = FormDefinition.new()
		form.name = name if forms.is_empty() else "%s %s" % [name, len(forms)]
		form.types = types
		form.base_stats = base_stats
		if len(nums) >= 2: form.form_number = nums[1]
		forms.append(form)
	else:
		form = matching_forms[0]
	form.add_animations(form_anims, nums)

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
					shadow_size = int(data)
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
