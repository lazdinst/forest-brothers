extends Node3D
## A basic mission map: a forest edge, a farmstead with a barn, a few village cottages and a road
## checkpoint, built from blockout shapes. It places map markers (objective spots, exits, enemy
## spawns) and then plays whichever mission definition MissionLaunch hands it, through the shared
## MissionController. The layout is a placeholder for owner review; place names are fictional.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const MovementHud = preload("res://ui/components/tactical_movement_hud.gd")
const InventoryHost = preload("res://ui/inventory/inventory_host.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const ObjectiveSpot = preload("res://scripts/missions/objective_spot.gd")
const MissionExit = preload("res://scripts/missions/mission_exit.gd")
const EnemySpawn = preload("res://scripts/missions/enemy_spawn.gd")
const SIZE := 140.0
const PLAYER_SPAWN := Vector3(-58, 0.02, 34)
const WALL_HEIGHT := 3.0
const WALL_COLOR := Color(0.5, 0.44, 0.36)
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
	_box("Ground", Vector3(0, -0.5, 0), Vector3(SIZE, 1, SIZE), Color(0.36, 0.38, 0.27))
	# A dirt road north to south past the checkpoint; visual only.
	_flat("Road", Vector3(8, 0.01, 0), Vector2(5, SIZE), Color(0.42, 0.36, 0.27))
	_forest()
	_farmstead()
	_village()
	_checkpoint()
	_exit(&"west_path", "forest path", Vector3(-64, 0, 0))
	_exit(&"south_road", "south road", Vector3(8, 0, 64))

## Pines and birches along the west edge, with a clear path to the west exit. Seeded, so the
## forest is the same every time.
func _forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1946
	var placed := 0
	while placed < 90:
		var at := Vector3(rng.randf_range(-68, -24), 0, rng.randf_range(-66, 66))
		if absf(at.z) < 4.0 or at.distance_to(PLAYER_SPAWN) < 4.0:
			continue
		_tree(at, rng.randf_range(5.0, 9.0), rng.randf() < 0.3)
		placed += 1
	for spot in [Vector3(-30, 0, -20), Vector3(-34, 0, 18), Vector3(-28, 0, 46)]:
		_spawn(&"patrol", spot, Vector3(0, 0, 0))

func _farmstead() -> void:
	# House (doorway south) and barn (wide doorway west) north-east of the road.
	_shell("FarmHouse", Vector3(36, 0, -38), Vector2(10, 8), &"south", 1.6)
	_shell("Barn", Vector3(52, 0, -30), Vector2(12, 14), &"west", 4.0)
	_box("Haystack", Vector3(54, 0.75, -26), Vector3(3, 1.5, 2), Color(0.62, 0.55, 0.3))
	_box("Cart", Vector3(30, 0.5, -28), Vector3(2.2, 1.0, 1.2), Color(0.38, 0.29, 0.2))
	for x in range(26, 62, 3):
		_box("Fence", Vector3(x, 0.5, -16), Vector3(0.12, 1.0, 0.12), Color(0.35, 0.28, 0.2))
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
	_box("Well", Vector3(20, 0.45, 28), Vector3(1.6, 0.9, 1.6), Color(0.45, 0.43, 0.4))
	_box("Woodpile", Vector3(38, 0.5, 21), Vector3(2.4, 1.0, 1.0), Color(0.4, 0.31, 0.2))
	_spawn(&"village", Vector3(22, 0, 16), Vector3(0, 0, 16))
	_spawn(&"village", Vector3(24, 0, 34), Vector3(0, 0, 40))
	_spawn(&"village", Vector3(38, 0, 46), Vector3(8, 0, 60))

func _checkpoint() -> void:
	# A hut and low cover where the road crosses the line north of the village.
	_shell("CheckpointHut", Vector3(15, 0, -6), Vector2(4, 3.5), &"west", 1.2)
	_box("Barrier", Vector3(8, 1.0, -2), Vector3(6, 0.12, 0.12), Color(0.55, 0.2, 0.18))
	for at in [Vector3(3, 0.5, 2), Vector3(13, 0.5, 2), Vector3(3, 0.5, -8), Vector3(0, 0.5, -3)]:
		_box("Sandbags", at, Vector3(2.4, 1.0, 0.8), Color(0.5, 0.46, 0.36))
	_box("Crate", Vector3(11, 0.5, -10), Vector3(1.6, 1.0, 1.0), Color(0.42, 0.33, 0.22))
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
			_box("%s_%s" % [shell_name, side], at, Vector3(length, WALL_HEIGHT, 0.4) if along_x else Vector3(0.4, WALL_HEIGHT, length), WALL_COLOR)
			continue
		var piece := (length - door_width) / 2.0
		var offset := (door_width + piece) / 2.0
		for side_sign in [-1.0, 1.0]:
			var part := at + (Vector3(side_sign * offset, 0, 0) if along_x else Vector3(0, 0, side_sign * offset))
			_box("%s_%s" % [shell_name, side], part, Vector3(piece, WALL_HEIGHT, 0.4) if along_x else Vector3(0.4, WALL_HEIGHT, piece), WALL_COLOR)

func _tree(at: Vector3, height: float, birch: bool) -> void:
	var body := StaticBody3D.new()
	body.name = "Tree"
	body.collision_layer = 1
	body.position = at
	var collision := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.22
	trunk_shape.height = height
	collision.shape = trunk_shape
	collision.position.y = height / 2.0
	body.add_child(collision)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.14
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = height
	trunk_mesh.material = _material(Color(0.82, 0.8, 0.74) if birch else Color(0.33, 0.24, 0.17))
	trunk.mesh = trunk_mesh
	trunk.position.y = height / 2.0
	body.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0 if not birch else 1.1
	crown_mesh.bottom_radius = 1.6 if not birch else 1.3
	crown_mesh.height = height * 0.6
	crown_mesh.material = _material(Color(0.19, 0.3, 0.18) if not birch else Color(0.38, 0.47, 0.24))
	crown.mesh = crown_mesh
	crown.position.y = height * 0.72
	body.add_child(crown)
	navigation.add_child(body)

func _box(box_name: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
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
	box.material = _material(color)
	mesh.mesh = box
	body.add_child(mesh)
	# Children of the region are its baking source.
	navigation.add_child(body)
	return body

func _flat(flat_name: String, at: Vector3, size: Vector2, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = flat_name
	var plane := PlaneMesh.new()
	plane.size = size
	plane.material = _material(color)
	mesh.mesh = plane
	mesh.position = at
	add_child(mesh)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material

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
