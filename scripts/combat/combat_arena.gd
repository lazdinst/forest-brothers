extends Node3D
## Blockout combat arena: grey boxes, a farmhouse shell, a long screening wall and scattered cover.
## The navigation map belongs to this scene only. Layout is a placeholder for owner review.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const AmmoCrate = preload("res://scripts/combat/ammo_crate.gd")
const MovementHud = preload("res://ui/components/tactical_movement_hud.gd")
const InventoryHost = preload("res://ui/inventory/inventory_host.gd")
const ArenaSupplies = preload("res://scripts/combat/arena_supplies.gd")
const BloodTrail = preload("res://scripts/combat/blood_trail.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const ObjectiveSpot = preload("res://scripts/missions/objective_spot.gd")
const MissionExit = preload("res://scripts/missions/mission_exit.gd")
## The mission this arena plays; any definition whose spot tags this map provides works.
const MISSION = preload("res://missions/arena_dispatch.tres")
## Places where a "dispatch" objective may lie.
const DISPATCH_SPOTS: Array[Vector3] = [Vector3(21.5, 0.06, -8.5), Vector3(-2, 0.06, -25.1), Vector3(-16.4, 0.06, -6), Vector3(28, 0.06, -28)]
## The way out: a forest path at the west edge.
const EXIT_AT := Vector3(-32, 0, -4)
const SIZE := 70.0
const PLAYER_SPAWN := Vector3(0, 0.02, 28)
const ENEMY_SPAWNS: Array[Vector3] = [Vector3(-6, 0, -12), Vector3(8, 0, -20)]
var player
var enemies: Array = []
## Temperaments to draw from at each reset, so a hurt enemy may run, hold or push. Tests can
## pin them by setting this to a single value.
var temperament_pool: Array[StringName] = [Enemy.TIMID, Enemy.STEADY, Enemy.AGGRESSIVE]
var navigation: NavigationRegion3D
var ammo_crate: StaticBody3D
var inventory
var _prompt: Label
var _crosshair: Label
var mission: Node

func _ready() -> void:
	_lighting()
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	add_child(navigation)
	_box("Ground", Vector3(0, -0.5, 0), Vector3(SIZE, 1, SIZE), Color(0.36, 0.34, 0.28))
	# Screening wall across the middle with open ends: walking around it is the only way through.
	_box("ScreenWall", Vector3(0, 1.5, 4), Vector3(30, 3, 0.4), Color(0.45, 0.42, 0.38))
	# Farmhouse shell with a doorway on the south side.
	_box("HouseNorth", Vector3(18, 1.5, -10), Vector3(10, 3, 0.4), Color(0.5, 0.44, 0.36))
	_box("HouseWest", Vector3(13.2, 1.5, -6), Vector3(0.4, 3, 8), Color(0.5, 0.44, 0.36))
	_box("HouseEast", Vector3(22.8, 1.5, -6), Vector3(0.4, 3, 8), Color(0.5, 0.44, 0.36))
	_box("HouseSouthLeft", Vector3(15, 1.5, -2), Vector3(3.6, 3, 0.4), Color(0.5, 0.44, 0.36))
	_box("HouseSouthRight", Vector3(21, 1.5, -2), Vector3(3.6, 3, 0.4), Color(0.5, 0.44, 0.36))
	# Low cover: crouch height, so it hides a crouched body but not a standing one.
	for spot in [Vector3(-12, 0.5, 14), Vector3(-4, 0.5, 18), Vector3(7, 0.5, 12), Vector3(-15, 0.5, -6), Vector3(4, 0.5, -6), Vector3(-2, 0.5, -24)]:
		_box("Crate", spot, Vector3(1.6, 1.0, 1.0), Color(0.42, 0.33, 0.22))
	ammo_crate = AmmoCrate.new()
	ammo_crate.name = "AmmoCrate"
	ammo_crate.position = Vector3(3, 0.35, 26)
	_dress_box(ammo_crate, Vector3(0.9, 0.7, 0.6), Color(0.3, 0.36, 0.22))
	navigation.add_child(ammo_crate)
	_bake_navigation()
	player = PlayerScene.instantiate()
	player.name = "Player"
	player.position = PLAYER_SPAWN
	add_child(player)
	# Same carried inventory as training: Tab opens it over this scene.
	inventory = InventoryHost.new()
	inventory.world = self
	inventory.player = player
	add_child(inventory)
	_mission_markers()
	_hud()
	reset_enemies()
	mission = MissionController.new()
	mission.name = "Mission"
	mission.definition = MISSION
	mission.mission_over.connect(_mission_over)
	# Opened from the camp: the summary leads back there; opened directly: go again.
	if MissionLaunch.camp_scene != "":
		mission.continue_text = "Return to camp"
		mission.continue_requested.connect(_return_to_camp)
	else:
		mission.continue_requested.connect(restart)
	add_child(mission)
	mission.start([player], player)

func reset_enemies() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	for pickup in get_tree().get_nodes_in_group(&"combat_loot") + get_tree().get_nodes_in_group(ArenaSupplies.GROUP):
		pickup.queue_free()
	BloodTrail.clear_in(get_tree())
	# A lootable body by the ammunition crate and loose supplies to practise with.
	ArenaSupplies.stage(self)
	for index in range(ENEMY_SPAWNS.size()):
		var enemy = Enemy.new()
		enemy.name = "ArenaEnemy%d" % index
		enemy.position = ENEMY_SPAWNS[index]
		add_child(enemy)
		enemy.targets.assign([player])
		enemy.spotted.connect(_enemy_spotted)
		enemy.defeated.connect(_enemy_defeated)
		# Active by default: the arena is a fight, not a passive exhibit.
		enemy.active = true
		enemy.loot_enabled = true
		enemy.temperament = temperament_pool.pick_random()
		enemies.append(enemy)

func _enemy_defeated(_enemy) -> void:
	if mission != null and mission.run != null and not mission.run.is_over():
		mission.run.count("Enemies killed")

## Nobody is left in the area: enemies stand down.
func _mission_over(_run) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.active = false

## Opened from the camp: the summary leads back there.
func _return_to_camp() -> void:
	if get_tree().current_scene == self:
		MissionLaunch.return_to_camp(get_tree())

## Go again: a fresh copy of the arena when it is the running scene; otherwise (tests) restage.
func restart() -> void:
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
		return
	player.restore_for_drill()
	player.global_position = PLAYER_SPAWN
	reset_enemies()
	mission.start([player], player)

## Map markers any mission can use: objective spots and the exit.
func _mission_markers() -> void:
	for spot in DISPATCH_SPOTS:
		var marker := ObjectiveSpot.new()
		marker.tag = &"dispatch"
		marker.position = spot
		add_child(marker)
	var exit := MissionExit.new()
	exit.name = "WestExit"
	exit.id = &"west_path"
	exit.label = "forest path"
	exit.position = EXIT_AT
	add_child(exit)

func _enemy_spotted(source, at: Vector3) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy != source and enemy.global_position.distance_to(source.global_position) <= 20:
			enemy.receive_alert(at, source)

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

func _box(box_name: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 1
	body.position = at
	_dress_box(body, size, color)
	# Children of the region are its baking source.
	navigation.add_child(body)
	return body

func _lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.62, 0.66, 0.68)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.55, 0.55, 0.52)
	add_child(environment)

func _dress_box(body: StaticBody3D, size: Vector3, color: Color) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)

## Same compact movement instrument as the training yard, plus crosshair and interaction prompt.
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
	var mouse_free := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	_prompt.text = "Click to look around" if mouse_free else player.get_interaction_prompt()
	var summary_open: bool = mission != null and mission.summary_screen != null and mission.summary_screen.visible
	if summary_open: _prompt.text = ""
	_crosshair.visible = not player.is_aiming and player.weapon.aim_fraction < 0.05 and not summary_open
