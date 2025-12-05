extends Node2D
class_name PokemonController

const VECTOR_TO_DIRECTION := Pokemon.VECTOR_TO_DIRECTION
const BASE_SPEED := 90.0
const RUN_MULTIPLIER := 2.5

var pokemon: Pokemon

var pokemon_sprite: PokemonSprite:
	get: return pokemon.pokemon_sprite
var controllable: bool:
	get: return pokemon.controllable
var direction: Enum.Direction:
	get: return pokemon.direction
	set(x): pokemon.direction = x
var pokemon_position: Vector2:
	get: return pokemon.position
	set(x): pokemon.position = x
	
var action_tween: Tween
var automove := Vector2i.ZERO
var move_blocked := false

func _ready():
	pokemon = get_parent()
	await get_tree().process_frame
	if Engine.is_editor_hint() or not controllable:
		set_process(false)

func _process(delta):
	if not pokemon:
		return
	if pokemon.get_parent() is DungeonFloor:
		do_dungeon_action()
	else:
		do_free_move(delta)
		
func do_free_move(delta: float):
	pokemon_sprite.set_shadow_effect(Enum.ShadowEffect.Controllable if controllable else Enum.ShadowEffect.Default)
	if not controllable:
		pokemon_sprite.play("Idle", 1.0)
		return
	var input_vec := Vector2(Input.get_vector(&"left", &"right", &"up", &"down"))
	var input_dir := Vector2i(roundi(input_vec.x), roundi(input_vec.y))
	var dir: Enum.Direction = VECTOR_TO_DIRECTION.get(input_dir, -1)
	if dir == -1:
		pokemon_sprite.play("Idle", 1.0)
		pokemon_sprite.set_anim_speed(1.0)
		return
	direction = dir
	pokemon_sprite.play("Walk")
	var speed := (RUN_MULTIPLIER if Input.is_action_pressed("run") else 1.0)
	pokemon_sprite.set_anim_speed(speed)
	pokemon_position += input_vec * (delta * BASE_SPEED) * speed
		
func do_dungeon_action():
	if action_tween and action_tween.is_running():
		return
	action_tween = null
	var moving := false
	var input_vec := Vector2i(Input.get_vector(&"left", &"right", &"up", &"down").round())
	move_blocked = move_blocked and input_vec != Vector2i.ZERO
	if (input_vec != Vector2i.ZERO or automove != Vector2i.ZERO) and not move_blocked:
		moving = do_dungeon_movement(input_vec)
	if not moving and pokemon_sprite.sprite.frame_coords.x < 2: 
		set_idle()
	
func do_dungeon_movement(input: Vector2i) -> bool:
	var tile_map: DungeonFloor = pokemon.get_parent()
	var cell := tile_map.local_to_map(pokemon_position)
	pokemon_position = tile_map.map_to_local(cell)
	
	var move_direction := automove if automove != Vector2i.ZERO else input
	var to_cell := cell + move_direction
	
	var can_move_to_target := check_tile_collision(cell, to_cell)
	var automove_was_interrupted := automove != Vector2i.ZERO and automove_interrupted(cell, to_cell)
	direction = VECTOR_TO_DIRECTION.get(move_direction, direction)
	if not can_move_to_target or automove_was_interrupted or VECTOR_TO_DIRECTION.get(move_direction, -1) == -1:
		if automove_was_interrupted:
			move_blocked = true
		automove = Vector2i.ZERO
		return false
	
	var is_running := Input.is_action_pressed("run") or automove != Vector2i.ZERO
	var anim_speed := 2.5 if is_running else 1.0
	var move_time := 0.01 if is_running else 0.25
	if Input.is_action_pressed("run") and not automove_was_interrupted: automove = move_direction
	action_tween = get_tree().create_tween().bind_node(pokemon)
	action_tween.tween_callback(pokemon_sprite.play.bind("Walk", anim_speed))
	action_tween.tween_property(self, ^"pokemon_position", tile_map.map_to_local(cell + move_direction), move_time)
	return true
	
func automove_interrupted(from: Vector2i, to: Vector2i) -> bool:
	var tile_map: DungeonFloor = pokemon.get_parent()
	for room in tile_map.generator.rooms:
		var border_tiles := room.get_border_tiles()
		if from in border_tiles and to not in border_tiles:
			return true
	return false
	
func check_tile_collision(from: Vector2i, to: Vector2i) -> bool:
	var tile_map: DungeonFloor = pokemon.get_parent()
	var from_tile_data := tile_map.get_cell_tile_data(from)
	var to_tile_data := tile_map.get_cell_tile_data(to)
	if not from_tile_data or not to_tile_data: return false
	var dungeon_definition := tile_map.definition
	var from_terrain := dungeon_definition.get_terrain(from_tile_data.terrain_set)
	var to_terrain := dungeon_definition.get_terrain(to_tile_data.terrain_set)
	var corners_terrain: Array[Enum.Terrain]
	if abs((from - to).length()) > 1.0: # If diagonal
		var corner_1_tile_data: TileData = tile_map.get_cell_tile_data(Vector2i(from.x, to.y))
		var corner_2_tile_data: TileData = tile_map.get_cell_tile_data(Vector2i(to.x, from.y))
		if corner_1_tile_data: corners_terrain.append(dungeon_definition.get_terrain(corner_1_tile_data.terrain_set))
		if corner_2_tile_data: corners_terrain.append(dungeon_definition.get_terrain(corner_2_tile_data.terrain_set))
	var allowed_terrains: Array[Enum.Terrain]
	match pokemon.definition.mobility:
		Enum.Mobility.SuperMobile, Enum.Mobility.Ghost: return true
		Enum.Mobility.Flying: allowed_terrains = [Enum.Terrain.Air, Enum.Terrain.Water, Enum.Terrain.Lava, Enum.Terrain.Floor]
		Enum.Mobility.Water: allowed_terrains = [Enum.Terrain.Water, Enum.Terrain.Floor]
		Enum.Mobility.Lava: allowed_terrains = [Enum.Terrain.Lava, Enum.Terrain.Floor]
		Enum.Mobility.Normal, Enum.Mobility.Cocoon: allowed_terrains = [Enum.Terrain.Floor]
	var can_be_in_walls := Enum.Terrain.Wall in allowed_terrains
	var in_wall := from_terrain == Enum.Terrain.Wall
	var in_allowed_terrain := from_terrain in allowed_terrains
	var to_allowed_terrain := to_terrain in allowed_terrains
	var new_terrain := from_terrain != to_terrain
	var stuck_in_terrain := (not in_allowed_terrain and not new_terrain)
	var stuck_in_wall := (stuck_in_terrain and in_wall)
	var corner_walls := corners_terrain.any(func(t): return t == Enum.Terrain.Wall) or to_terrain == Enum.Terrain.Wall or (can_be_in_walls or stuck_in_wall)
	return stuck_in_terrain or (not corner_walls and to_allowed_terrain)
	
func set_idle():
	if pokemon_sprite.animation_name == "Idle":
		return
	pokemon_sprite.play("Idle", 1.0)
