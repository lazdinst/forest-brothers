extends CharacterBody3D
## Input/movement for the local prototype. Traversal uses swept physical motion.

@export var walk_speed: float = 3.3
@export var sprint_speed: float = 5.2
@export var crouch_speed: float = 1.5
@export var jump_speed: float = 5.5
@export var mouse_sensitivity: float = 0.002
@export var lean_distance: float = 0.32

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var weapon = $Weapon

var interaction_target: Node = null
var gravity: float = 20.0
var is_crouching: bool = false
var is_sprinting: bool = false
var is_aiming: bool = false
var is_vaulting: bool = false
var movement_state: String = "Standing"
var traversal_message: String = ""
var _spawn_position: Vector3
var _lean: float = 0.0
var _vault_points: Array[Vector3] = []
var _vault_time: float = 0.0
var _head_probe := SphereShape3D.new()


func _ready() -> void:
	_spawn_position = global_position
	body_shape.shape = body_shape.shape.duplicate()
	_head_probe.radius = 0.12
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func controls_active() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and not controls_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not controls_active():
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * mouse_sensitivity, -1.45, 1.45)
	elif event.is_action_pressed("interact"):
		try_interact()
	elif event.is_action_pressed("fire"):
		weapon.command(&"fire")
	elif event.is_action_pressed("reload"):
		weapon.command(&"reload")
	elif event.is_action_pressed("clear_jam"):
		weapon.command(&"clear")
	elif event.is_action_pressed("clean_weapon"):
		weapon.command(&"clean")
	elif event.is_action_pressed("dirty_weapon"):
		weapon.command(&"dirty")
	elif event.is_action_pressed("inspect_weapon"):
		weapon.command(&"inspect")
	elif event.is_action_pressed("reset_position"):
		global_position = _spawn_position
		velocity = Vector3.ZERO
		is_vaulting = false


func _physics_process(delta: float) -> void:
	var active := controls_active()
	_update_stance(active)
	is_aiming = active and Input.is_action_pressed("aim") and not is_vaulting and weapon.state.busy == &""
	if is_vaulting:
		_advance_vault(delta)
	else:
		var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if active else Vector2.ZERO
		var direction := global_basis * Vector3(axes.x, 0.0, axes.y)
		is_sprinting = active and Input.is_action_pressed("sprint") and not is_crouching and not is_aiming and axes.y < 0.0
		var speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else walk_speed)
		if is_aiming:
			speed *= 0.65
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if not is_on_floor():
			velocity.y -= gravity * delta
		elif active and Input.is_action_just_pressed("jump") and not is_crouching:
			velocity.y = jump_speed
		move_and_slide()
		if active and Input.is_action_just_pressed("vault"):
			try_vault()
	_update_camera(delta, active)
	refresh_interaction_target()
	movement_state = "Vaulting" if is_vaulting else ("Airborne" if not is_on_floor() else ("Crouching" if is_crouching else ("Running" if is_sprinting else ("Walking" if Vector2(velocity.x, velocity.z).length() > 0.1 else "Standing"))))


func _update_stance(active: bool) -> void:
	var want_crouch := active and Input.is_action_pressed("crouch")
	if not want_crouch and is_crouching and not _capsule_clear(global_position, 1.8):
		want_crouch = true
	is_crouching = want_crouch
	var height := 1.1 if is_crouching else 1.8
	body_shape.shape.height = height
	body_shape.position.y = height * 0.5


func _update_camera(delta: float, active: bool) -> void:
	var eye_height := 1.0 if is_crouching else 1.6
	camera.position.y = move_toward(camera.position.y, eye_height, delta * 3.0)
	var lean_input := Input.get_axis("lean_left", "lean_right") if active and not is_vaulting else 0.0
	_lean = move_toward(_lean, lean_input, delta * 5.0)
	var motion := global_basis.x * _lean * lean_distance
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _head_probe
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * camera.position.y)
	query.motion = motion
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var safe := get_world_3d().direct_space_state.cast_motion(query)
	var fraction: float = safe[0] if not safe.is_empty() else 0.0
	camera.position.x = _lean * lean_distance * fraction
	camera.rotation.z = -_lean * fraction * deg_to_rad(8.0)
	# Iron-sight alignment is in weapon presentation; aiming does not zoom the world.
	camera.fov = 60.0


func _capsule_clear(feet: Vector3, height: float) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * (height * 0.5 + 0.025))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func try_vault() -> bool:
	if is_vaulting or is_crouching or not is_on_floor():
		return false
	var forward := -global_basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, global_position + Vector3.UP * 0.6 + forward * 1.2, 1, [get_rid()])
	var face := space.intersect_ray(query)
	if face.is_empty() or not face.collider.is_in_group("vaultable"):
		traversal_message = "Move closer to a marked low obstacle"
		return false
	var probe: Vector3 = face.position + forward * 0.2
	var top := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(probe.x, global_position.y + 1.5, probe.z), Vector3(probe.x, global_position.y + 0.15, probe.z), 1, [get_rid()]))
	if top.is_empty() or top.normal.y < 0.7 or top.position.y - global_position.y > 1.25:
		traversal_message = "Too high to climb"
		return false
	var landing_probe: Vector3 = face.position + forward * 1.3
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(landing_probe.x, top.position.y + 0.3, landing_probe.z), Vector3(landing_probe.x, global_position.y - 0.4, landing_probe.z), 1, [get_rid()]))
	if floor_hit.is_empty() or floor_hit.normal.y < 0.7:
		return false
	var destination: Vector3 = floor_hit.position + Vector3.UP * 0.02
	if not _capsule_clear(destination, 1.8):
		traversal_message = "Landing is blocked"
		return false
	var lift: float = maxf(top.position.y, destination.y) + 0.12
	_vault_points.assign([global_position, Vector3(global_position.x, lift, global_position.z), Vector3(destination.x, lift, destination.z), destination])
	_vault_time = 0.0
	is_vaulting = true
	is_sprinting = false
	velocity = Vector3.ZERO
	traversal_message = ""
	return true


func _advance_vault(delta: float) -> void:
	_vault_time += delta
	var progress := minf(_vault_time / 0.65, 1.0) * 3.0
	var segment := mini(int(progress), 2)
	var desired := _vault_points[segment].lerp(_vault_points[segment + 1], clampf(progress - segment, 0.0, 1.0))
	var collision := move_and_collide(desired - global_position)
	if collision != null:
		is_vaulting = false
		traversal_message = "Traversal interrupted by an obstacle"
	elif progress >= 3.0:
		is_vaulting = false


func refresh_interaction_target() -> void:
	interaction_ray.force_raycast_update()
	interaction_target = null
	if interaction_ray.is_colliding():
		var candidate := interaction_ray.get_collider() as Node
		if is_instance_valid(candidate) and candidate.has_method("interact") and candidate.has_method("get_prompt"):
			interaction_target = candidate


func try_interact() -> void:
	refresh_interaction_target()
	if is_instance_valid(interaction_target):
		interaction_target.interact(self)


func get_interaction_prompt() -> String:
	return interaction_target.get_prompt() if is_instance_valid(interaction_target) else ""
