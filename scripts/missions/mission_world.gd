extends Node3D
## A basic mission map: a forest edge, a farmstead with a barn, a few village cottages and a road
## checkpoint. Nature is built only from the environment library (assets/environment: trees,
## deadwood, boulders, ferns, ground cover, crate, moss ground material); buildings have no
## library asset yet, so they are plain walls in the library's weathered-wood texture. It places
## map markers (objective spots, exits, enemy spawns) and plays whichever mission definition
## MissionLaunch hands it, through the shared MissionController. Layout is a placeholder for owner
## review; place names are fictional.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const MovementHud = preload("res://ui/components/tactical_movement_hud.gd")
const InventoryHost = preload("res://ui/inventory/inventory_host.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
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
const SIZE := 140.0
const PLAYER_SPAWN := Vector3(-58, 0.02, 34)
const WALL_HEIGHT := 3.0
## Places kept clear of trees and clutter: building plots, the checkpoint and the exits.
const CLEARINGS: Array[Rect2] = [Rect2(26, -46, 38, 34), Rect2(22, 6, 18, 48), Rect2(-4, -14, 24, 20), Rect2(-68, -5, 10, 10), Rect2(2, 58, 12, 12)]
## Played when the scene is opened directly rather than from the mission map.
@export var default_mission: Resource = preload("res://missions/courier_dispatch.tres")
var definition: Resource
var player
var enemies: Array = []
var navigation: NavigationRegion3D
var mission: Node
var inventory
var _prompt: Label
var _crosshair: Label
var _wall_material: StandardMaterial3D
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	definition = MissionLaunch.pending if MissionLaunch.pending != null else default_mission
	_lighting()
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	add_child(navigation)
	_build_map()
	_bake_navigation()
	player = PlayerScene.instantiate()
	player.name = "Player"
	player.position = PLAYER_SPAWN
	add_child(player)
	inventory = InventoryHost.new()
	inventory.world = self
	inventory.player = player
	add_child(inventory)
	_hud()
	mission = MissionController.new()
	mission.name = "Mission"
	mission.definition = definition
	mission.continue_text = "Return to the mission map"
	mission.mission_over.connect(_mission_over)
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

func _mission_over(run) -> void:
	MissionLaunch.record(definition, run.outcome())
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.active = false

func _continue() -> void:
	if get_tree().current_scene == self:
		MissionLaunch.return_to_board(get_tree())

# --- Map ------------------------------------------------------------------------------------

func _build_map() -> void:
	# The library wood texture, mapped in world space so long walls do not stretch it.
	_wall_material = WOOD_MATERIAL.duplicate()
	_wall_material.uv1_triplanar = true
	_wall_material.uv1_world_triplanar = true
	_wall_material.uv1_scale = Vector3(0.5, 0.5, 0.5)
	_rng.seed = 1946
	var ground := _box("Ground", Vector3(0, -0.5, 0), Vector3(SIZE, 1, SIZE), Color.WHITE)
	(ground.get_child(1) as MeshInstance3D).material_override = GROUND_MATERIAL
	_forest()
	_farmstead()
	_village()
	_checkpoint()
	_ground_cover()
	_exit(&"west_path", "forest path", Vector3(-64, 0, 0))
	_exit(&"south_road", "south road", Vector3(8, 0, 64))

## Pine, spruce and birch along the west edge with deadwood, boulders and ferns between them,
## a clear path to the west exit, and scattered trees elsewhere. Seeded: the same every time.
func _forest() -> void:
	var placed := 0
	while placed < 110:
		var at := Vector3(_rng.randf_range(-68, -22), 0, _rng.randf_range(-66, 66))
		if absf(at.z) < 4.0 or at.distance_to(PLAYER_SPAWN) < 4.0 or _blocked(at, 1.0):
			continue
		_tree(TREES[_rng.randi() % TREES.size()], at, _rng.randf_range(0.8, 1.3))
		placed += 1
	for index in range(40):
		var at := Vector3(_rng.randf_range(-20, 66), 0, _rng.randf_range(-66, 66))
		if _blocked(at, 6.0) or absf(at.x - 8.0) < 5.0:
			continue
		_tree(TREES[_rng.randi() % TREES.size()], at, _rng.randf_range(0.8, 1.2))
	for index in range(28):
		var at := Vector3(_rng.randf_range(-66, -20), 0, _rng.randf_range(-64, 64))
		if absf(at.z) < 5.0 or _blocked(at, 2.0):
			continue
		match index % 4:
			0: _place(DEADWOOD[_rng.randi() % DEADWOOD.size()], at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1))
			1: _log(at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.1))
			2: _stump(at, _rng.randf_range(0.8, 1.2))
			_: _place(BOULDER, at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.4))
	for spot in [Vector3(-30, 0, -20), Vector3(-34, 0, 18), Vector3(-28, 0, 46)]:
		_spawn(&"patrol", spot, Vector3(0, 0, 0))

## Ferns, grass tufts and leaf litter; decoration only, no collision.
func _ground_cover() -> void:
	for index in range(220):
		var at := Vector3(_rng.randf_range(-68, 66), 0, _rng.randf_range(-68, 68))
		if not _blocked(at, 0.0) and (at.x < -20.0 or _rng.randf() < 0.25):
			_place(FERN, at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.2))
	_scatter(GRASS, 2600, 0.25)
	_scatter(LITTER, 900, 0.6)

## Many copies of a small mesh in 35 m cells (so each batch can be culled), off the clearings.
## A west_bias share of copies goes to the forest.
func _scatter(mesh: Mesh, count: int, west_bias: float) -> void:
	var cells := {}
	for index in range(count):
		var x := _rng.randf_range(-68, -22) if _rng.randf() < west_bias else _rng.randf_range(-68, 68)
		var at := Vector3(x, 0, _rng.randf_range(-68, 68))
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
	for area in CLEARINGS:
		if area.grow(margin).has_point(Vector2(at.x, at.z)): return true
	return false

func _farmstead() -> void:
	# House (doorway south) and barn (wide doorway west) north-east of the road.
	_shell("FarmHouse", Vector3(36, 0, -38), Vector2(10, 8), &"south", 1.6)
	_shell("Barn", Vector3(52, 0, -30), Vector2(12, 14), &"west", 4.0)
	_place(CRATE, Vector3(54, 0, -26), 0.3)
	_place(CRATE, Vector3(55.2, 0, -26.4), -0.2)
	_log(Vector3(30, 0, -28), 0.4, 0.9)
	for x in range(26, 62, 3):
		_box("Fence", Vector3(x, 0.5, -16), Vector3(0.12, 1.0, 0.12), Color.WHITE)
	_spot(&"dispatch", Vector3(39, 0.06, -40.5))
	_spot(&"dispatch", Vector3(55, 0.06, -34))
	_spot(&"codebook", Vector3(33, 0.06, -40.5))
	_spawn(&"farm", Vector3(36, 0, -30), Vector3(36, 0, 0))
	_spawn(&"farm", Vector3(44, 0, -22), Vector3(20, 0, 0))
	_spawn(&"farm", Vector3(52, 0, -40), Vector3(40, 0, -10))

func _village() -> void:
	# Three cottages east of the road, doorways facing it.
	for index in range(3):
		var centre := Vector3(30, 0, 14 + index * 14)
		_shell("Cottage%d" % index, centre, Vector2(7, 6), &"west", 1.4)
		_spot(&"medicine", centre + Vector3(2.0, 0.06, -1.5))
	_place(BOULDER, Vector3(20, 0, 28), 0.7, 1.1)
	_log(Vector3(38, 0, 21), 1.57, 0.6)
	for at in [Vector3(24, 0, 9), Vector3(36, 0, 36), Vector3(25, 0, 48)]:
		_tree(BIRCH, at, 1.0)
	_spawn(&"village", Vector3(22, 0, 16), Vector3(0, 0, 16))
	_spawn(&"village", Vector3(24, 0, 34), Vector3(0, 0, 40))
	_spawn(&"village", Vector3(38, 0, 46), Vector3(8, 0, 60))

func _checkpoint() -> void:
	# A hut and low cover where the road crosses the line north of the village.
	_shell("CheckpointHut", Vector3(15, 0, -6), Vector2(4, 3.5), &"west", 1.2)
	_box("Barrier", Vector3(8, 1.0, -2), Vector3(6, 0.12, 0.12), Color.WHITE)
	# Low cover from library pieces: crates, felled logs and boulders.
	for at in [Vector3(3, 0, 2), Vector3(13, 0, 2)]:
		_place(CRATE, at, 0.0)
		_place(CRATE, at + Vector3(1.1, 0, 0), 0.1)
	_log(Vector3(3, 0, -8), 0.0, 0.6)
	_place(BOULDER, Vector3(0, 0, -3), 1.2, 1.2)
	_place(CRATE, Vector3(11, 0, -10), 0.0)
	_spot(&"codebook", Vector3(15.5, 0.06, -6.5))
	_spot(&"codebook", Vector3(11, 0.06, -11.0))
	_spawn(&"checkpoint", Vector3(6, 0, 0), Vector3(-20, 0, 10))
	_spawn(&"checkpoint", Vector3(12, 0, -4), Vector3(8, 0, 30))
	_spawn(&"checkpoint", Vector3(2, 0, -10), Vector3(-30, 0, -10))
	_spawn(&"patrol", Vector3(8, 0, -40), Vector3(8, 0, 0))

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
func _shell(shell_name: String, centre: Vector3, size: Vector2, door: StringName, door_width: float) -> void:
	var half := size / 2.0
	var y := WALL_HEIGHT / 2.0
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
			_box("%s_%s" % [shell_name, side], at, Vector3(length, WALL_HEIGHT, 0.4) if along_x else Vector3(0.4, WALL_HEIGHT, length), Color.WHITE)
			continue
		var piece := (length - door_width) / 2.0
		var offset := (door_width + piece) / 2.0
		for side_sign in [-1.0, 1.0]:
			var part := at + (Vector3(side_sign * offset, 0, 0) if along_x else Vector3(0, 0, side_sign * offset))
			_box("%s_%s" % [shell_name, side], part, Vector3(piece, WALL_HEIGHT, 0.4) if along_x else Vector3(0.4, WALL_HEIGHT, piece), Color.WHITE)

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
