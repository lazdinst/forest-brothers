extends Node3D
## Blockout combat arena: grey boxes, a farmhouse shell, a long screening wall and scattered cover.
## The navigation map belongs to this scene only. Layout is a placeholder for owner review.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const SIZE := 70.0
const PLAYER_SPAWN := Vector3(0, 0.02, 28)
const ENEMY_SPAWNS: Array[Vector3] = [Vector3(-6, 0, -12), Vector3(8, 0, -20)]
var player
var enemies: Array = []
var navigation: NavigationRegion3D

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
	_bake_navigation()
	player = PlayerScene.instantiate()
	player.name = "Player"
	player.position = PLAYER_SPAWN
	add_child(player)
	reset_enemies()

func reset_enemies() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	for index in range(ENEMY_SPAWNS.size()):
		var enemy = Enemy.new()
		enemy.name = "ArenaEnemy%d" % index
		enemy.position = ENEMY_SPAWNS[index]
		add_child(enemy)
		enemy.targets.assign([player])
		enemy.spotted.connect(_enemy_spotted)
		# Active by default: the arena is a fight, not a passive exhibit.
		enemy.active = true
		enemies.append(enemy)

func _enemy_spotted(source, at: Vector3) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy != source and enemy.global_position.distance_to(source.global_position) <= 20:
			enemy.receive_alert(at)

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
