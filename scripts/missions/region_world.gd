extends Node3D
## Shared base for region world scenes: lighting, the player, the HUD, navigation, enemies at
## tagged posts, and the shared MissionController playing whichever composed outing
## MissionLaunch hands over (or the default region's missions when opened directly). Subclasses
## lay out the map in _build_map() from the environment library only (assets/environment);
## buildings have no library asset yet, so they are plain shapes in the library's weathered wood.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const MovementHud = preload("res://ui/components/tactical_movement_hud.gd")
const InventoryHost = preload("res://ui/inventory/inventory_host.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const GameSession = preload("res://scripts/state/game_session.gd")
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const ObjectiveSpot = preload("res://scripts/missions/objective_spot.gd")
const MissionExit = preload("res://scripts/missions/mission_exit.gd")
const EnemySpawn = preload("res://scripts/missions/enemy_spawn.gd")
const ENV := "res://assets/environment/"
const TREES: Array[PackedScene] = [preload(ENV + "scenes/forest_pine_v1.tscn"), preload(ENV + "scenes/forest_spruce_v1.tscn"), preload(ENV + "scenes/forest_birch_v1.tscn")]
const BIRCH: PackedScene = preload(ENV + "scenes/forest_birch_v1.tscn")
const BOULDER: PackedScene = preload(ENV + "scenes/boulder_v1.tscn")
const CRATE: PackedScene = preload(ENV + "scenes/crate_v1.tscn")
const FERN: PackedScene = preload(ENV + "scenes/fern_v1.tscn")
const FALLEN_LOG: PackedScene = preload(ENV + "scenes/fallen_log_v1.tscn")
const STUMP: PackedScene = preload(ENV + "scenes/decayed_stump_v1.tscn")
## Deadwood scenes that carry their own collision.
const DEADWOOD: Array[PackedScene] = [preload(ENV + "scenes/pine_fallen_v2.tscn"), preload(ENV + "scenes/pine_rotten_v2.tscn"), preload(ENV + "scenes/pine_snag_v2.tscn")]
const GRASS: Mesh = preload(ENV + "meshes/grass_tuft_v1.res")
const LITTER: Mesh = preload(ENV + "meshes/leaf_litter_v1.res")
const GROUND_MATERIAL: Material = preload(ENV + "materials/moss_ground_v1.tres")
const WOOD_MATERIAL: StandardMaterial3D = preload(ENV + "materials/weathered_wood_v1.tres")
const WALL_HEIGHT := 3.0
## Played with all its missions when the scene is opened directly rather than from the map.
@export var default_region: Resource
var definition: Resource
## Where the player starts; set by the subclass layout.
var player_spawn := Vector3.ZERO
## Places kept clear of trees and clutter; set by the subclass layout.
var clearings: Array[Rect2] = []
var player
var enemies: Array = []
var navigation: NavigationRegion3D
var mission: Node
var inventory
var _prompt: Label
var _crosshair: Label
var _wall_material: StandardMaterial3D
var _rng := RandomNumberGenerator.new()
var _ended_extracted := false

func _ready() -> void:
	definition = MissionLaunch.pending if MissionLaunch.pending != null else default_region.compose(default_region.missions)
	_lighting()
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	add_child(navigation)
	_rng.seed = 1946
	_wall_material = WOOD_MATERIAL.duplicate()
	# The library wood texture, mapped in world space so long walls do not stretch it.
	_wall_material.uv1_triplanar = true
	_wall_material.uv1_world_triplanar = true
	_wall_material.uv1_scale = Vector3(0.5, 0.5, 0.5)
	_build_map()
	_bake_navigation()
	player = PlayerScene.instantiate()
	player.name = "Player"
	player.position = player_spawn
	add_child(player)
	GameSession.apply_equipment(player)
	inventory = InventoryHost.new()
	inventory.world = self
	inventory.player = player
	add_child(inventory)
	_hud()
	mission = MissionController.new()
	mission.name = "Mission"
	mission.definition = definition
	mission.continue_text = "Return to camp" if MissionLaunch.camp_scene != "" else "Return to the mission map"
	mission.mission_over.connect(_mission_over)
	mission.participant_ended.connect(_participant_ended)
	mission.continue_requested.connect(_continue)
	add_child(mission)
	_spawn_enemies()
	mission.start([player], player)

## Enemies for this mission: per EnemySpawn tag, the requested number at randomly drawn spots.
func _spawn_enemies() -> void:
	var spawns := get_tree().get_nodes_in_group(EnemySpawn.GROUP)
	for tag in definition.enemy_groups:
		var spots := spawns.filter(func(spot): return spot.tag == StringName(tag))
		spots.shuffle()
		for index in range(mini(int(definition.enemy_groups[tag]), spots.size())):
			var enemy = Enemy.new()
			enemy.name = "Enemy_%s_%d" % [tag, index]
			enemy.position = spots[index].position
			enemy.rotation.y = spots[index].rotation.y
			add_child(enemy)
			enemy.targets.assign([player])
			enemy.spotted.connect(_enemy_spotted)
			enemy.defeated.connect(_enemy_defeated)
			enemy.active = true
			enemy.loot_enabled = true
			enemy.temperament = [Enemy.TIMID, Enemy.STEADY, Enemy.AGGRESSIVE].pick_random()
			enemies.append(enemy)

func _enemy_spotted(source, at: Vector3) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy != source and enemy.global_position.distance_to(source.global_position) <= 25:
			enemy.receive_alert(at, source)

func _enemy_defeated(_enemy) -> void:
	if mission.run != null and not mission.run.is_over():
		mission.run.count("Enemies killed")

## Notes how the local player's outing ended, for the save when the outing is over.
func _participant_ended(who, report: Dictionary) -> void:
	if who == player:
		_ended_extracted = report.personal == MissionRun.EXTRACTED

## Saves the outing: mission results, and the character's gear kept on extraction, lost on death.
func _mission_over(run) -> void:
	MissionLaunch.record_run(run)
	GameSession.outing_ended(player, _ended_extracted)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.active = false

func _continue() -> void:
	if get_tree().current_scene == self:
		MissionLaunch.after_outing(get_tree())

# --- Map ------------------------------------------------------------------------------------

## Lays out the region: ground, nature, buildings, objective spots, enemy posts and exits.
func _build_map() -> void:
	pass

## A square of the library moss ground, size metres across, centred on the origin.
func _ground(size: float) -> void:
	var ground := _box("Ground", Vector3(0, -0.5, 0), Vector3(size, 1, size), Color.WHITE)
	(ground.get_child(1) as MeshInstance3D).material_override = GROUND_MATERIAL

## Many copies of a small mesh in 35 m cells (so each batch can be culled), off the clearings.
## A bias share of copies goes inside the favoured rect (x, z), the rest over the whole area.
func _scatter(mesh: Mesh, count: int, area: Rect2, favoured: Rect2, bias: float) -> void:
	var cells := {}
	for index in range(count):
		var within := favoured if _rng.randf() < bias else area
		var at := Vector3(_rng.randf_range(within.position.x, within.end.x), 0, _rng.randf_range(within.position.y, within.end.y))
		if _blocked(at, 0.0):
			continue
		var cell := Vector2i(floori(at.x / 35.0), floori(at.z / 35.0))
		if not cells.has(cell): cells[cell] = []
		cells[cell].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.3)), at))
	for cell in cells:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = cells[cell].size()
		for index in range(multi.instance_count):
			multi.set_instance_transform(index, cells[cell][index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Cover_%s_%d_%d" % [mesh.resource_path.get_file().get_basename(), cell.x, cell.y]
		instance.multimesh = multi
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func _blocked(at: Vector3, margin: float) -> bool:
	for area in clearings:
		if area.grow(margin).has_point(Vector2(at.x, at.z)): return true
	return false

# --- Markers --------------------------------------------------------------------------------

func _spot(tag: StringName, at: Vector3) -> void:
	var marker := ObjectiveSpot.new()
	marker.tag = tag
	marker.position = at
	add_child(marker)

## An enemy post facing a point (enemies look along their +Z).
func _spawn(tag: StringName, at: Vector3, facing: Vector3) -> void:
	var marker := EnemySpawn.new()
	marker.tag = tag
	marker.position = at
	var toward := facing - at
	marker.rotation.y = atan2(toward.x, toward.z)
	add_child(marker)

func _exit(id: StringName, label: String, at: Vector3) -> void:
	var exit := MissionExit.new()
	exit.name = "Exit_%s" % id
	exit.id = id
	exit.label = label
	exit.position = at
	add_child(exit)

# --- Blockout helpers -----------------------------------------------------------------------

## Four walls with a doorway gap in the middle of one side (&"north", &"south", &"east", &"west").
func _shell(shell_name: String, centre: Vector3, size: Vector2, door: StringName, door_width: float, height: float = WALL_HEIGHT) -> void:
	var half := size / 2.0
	var y := height / 2.0
	var sides := {
		&"north": [Vector3(centre.x, y, centre.z - half.y), size.x, true],
		&"south": [Vector3(centre.x, y, centre.z + half.y), size.x, true],
		&"west": [Vector3(centre.x - half.x, y, centre.z), size.y, false],
		&"east": [Vector3(centre.x + half.x, y, centre.z), size.y, false],
	}
	for side in sides:
		var at: Vector3 = sides[side][0]
		var length: float = sides[side][1]
		var along_x: bool = sides[side][2]
		if side != door:
			_box("%s_%s" % [shell_name, side], at, Vector3(length, height, 0.4) if along_x else Vector3(0.4, height, length), Color.WHITE)
			continue
		var piece := (length - door_width) / 2.0
		var offset := (door_width + piece) / 2.0
		for side_sign in [-1.0, 1.0]:
			var part := at + (Vector3(side_sign * offset, 0, 0) if along_x else Vector3(0, 0, side_sign * offset))
			_box("%s_%s" % [shell_name, side], part, Vector3(piece, height, 0.4) if along_x else Vector3(0.4, height, piece), Color.WHITE)

## A library tree with a trunk collider sized as the training forest sizes its own.
func _tree(scene: PackedScene, at: Vector3, size: float) -> void:
	var tree := _place(scene, at, _rng.randf() * TAU, size)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.24 * size
	shape.height = 10.0 * size
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	body.add_child(collision)
	body.position = at
	navigation.add_child(body)
	tree.name = "Tree"

## A library scene placed on the map; scenes with their own StaticBody3D bake into navigation.
func _place(scene: PackedScene, at: Vector3, rotation_y: float, size: float = 1.0) -> Node3D:
	var node: Node3D = scene.instantiate()
	node.position = at
	node.rotation.y = rotation_y
	node.scale = Vector3.ONE * size
	navigation.add_child(node)
	return node

## Fallen log and stump scenes have no collision of their own; add the training forest's boxes.
func _log(at: Vector3, rotation_y: float, size: float) -> void:
	_place(FALLEN_LOG, at, rotation_y, size)
	_deadwood_body(at, rotation_y, Vector3(5.2, 0.58, 0.6) * size, 0.29 * size)

func _stump(at: Vector3, size: float) -> void:
	_place(STUMP, at, 0.0, size)
	_deadwood_body(at, 0.0, Vector3(0.8, 0.6, 0.8) * size, 0.29 * size)

func _deadwood_body(at: Vector3, rotation_y: float, size: Vector3, lift: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.add_to_group("vaultable", true)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = lift
	body.add_child(collision)
	body.position = at
	body.rotation.y = rotation_y
	navigation.add_child(body)

func _box(box_name: String, at: Vector3, size: Vector3, _color: Color = Color.WHITE) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 1
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	# Built pieces (walls, fences, barrier) use the library's weathered wood.
	box.material = _wall_material
	mesh.mesh = box
	body.add_child(mesh)
	# Children of the region are its baking source.
	navigation.add_child(body)
	return body

func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.75
	mesh.agent_max_climb = 0.25
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	navigation.navigation_mesh = mesh
	navigation.bake_navigation_mesh(false)

func _lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.6, 0.64, 0.66)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.55, 0.55, 0.52)
	add_child(environment)

## Movement instrument, crosshair and interaction prompt, as in the combat arena.
func _hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var instrument = MovementHud.new()
	instrument.name = "TacticalMovement"
	instrument.player = player
	layer.add_child(instrument)
	_crosshair = Label.new()
	_crosshair.text = "+"
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair.size = Vector2(16, 32)
	_crosshair.position -= _crosshair.size / 2.0
	layer.add_child(_crosshair)
	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.offset_top = 40
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 4)
	layer.add_child(_prompt)

func _process(_delta: float) -> void:
	if player == null or _prompt == null:
		return
	var summary_open: bool = mission.summary_screen != null and mission.summary_screen.visible
	var mouse_free := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	_prompt.text = "" if summary_open else ("Click to look around" if mouse_free else player.get_interaction_prompt())
	_crosshair.visible = not player.is_aiming and player.weapon.aim_fraction < 0.05 and not summary_open
