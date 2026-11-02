extends CharacterBody3D
## Input/movement for the local prototype. Traversal uses swept physical motion.

# Rejected blockout stays opt-in until a replacement passes visual review.
@export var use_polygon_body: bool = false
const Movement = preload("res://scripts/player/tactical_movement.gd")
const BodyHealth = preload("res://scripts/combat/body_health.gd")
const HitZones = preload("res://scripts/combat/hit_zones.gd")
## Emitted with BodyHealth.DOWNED or BodyHealth.KILLED. The session/drill decides what death means.
signal casualty(player, outcome: StringName)
## Presentation hook: which zone was struck and where the shot came from.
signal hit_taken(zone: StringName, from: Vector3)
## Presentation hook: a bullet passed close by at this point.
signal bullet_passed(at: Vector3)
var body = BodyHealth.new()
var hit_zones
var last_hit_zone: StringName = &""
## Co-op stand-in: solo incapacitation is mission death, so without a nearby teammate a down becomes death.
var has_teammate_nearby: bool = false
# Placeholder pending owner tuning (open question 5).
var bleed_out_seconds: float = 60.0
var bleed_left: float = 0.0
@export var movement_tuning: Resource = preload("res://scripts/player/movement_tuning.gd").new()
var locomotion
var is_prone: bool = false
var _stance_pressed := false
var _stance_scrolled := false
var _sway := Vector2.ZERO
var _sway_time := 0.0
var _step_distance := 0.0
signal movement_noise(origin: Vector3, loudness: float)
@export var jump_speed: float = 5.5
@export var mouse_sensitivity: float = 0.002
@export var lean_distance: float = 0.32

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var weapon = $Weapon

var body_visual
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
	locomotion = Movement.new(movement_tuning)
	_spawn_position = global_position
	body_shape.shape = body_shape.shape.duplicate()
	_head_probe.radius = 0.12
	hit_zones = HitZones.new()
	hit_zones.name = "HitZones"
	add_child(hit_zones)
	hit_zones.build(self, body_shape.shape.height)
	var feedback = load("res://scripts/combat/hit_feedback.gd").new()
	feedback.name = "HitFeedback"
	add_child(feedback)
	feedback.attach(self)
	if use_polygon_body:
		body_visual = load("res://scripts/characters/polygon_character.gd").new()
		body_visual.name = "BodyVisual"
		body_visual.variant = "player"
		add_child(body_visual)
		body_visual.rotation.y = PI
		body_visual.set_first_person(true)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func controls_active() -> bool:
	if not body.is_alive():
		return false
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not controls_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not controls_active():
		return
	if event.is_action("stance_adjust"):
		if event.is_action_pressed("stance_adjust") and not event.is_echo():
			_stance_pressed = true
			_stance_scrolled = false
		elif event.is_action_released("stance_adjust"):
			if _stance_pressed and not _stance_scrolled and not is_vaulting:
				locomotion.prone = false
				locomotion.stance_level = 1 if locomotion.stance_level == 7 else 7
			_stance_pressed = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var step := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
		if _stance_pressed and Input.is_action_pressed("stance_adjust"):
			_stance_scrolled = true
			if not is_vaulting and not locomotion.prone:
				locomotion.stance_level = clampi(locomotion.stance_level + step, 1, 7)
		else:
			locomotion.adjust_speed(step)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("slow_walk") and not event.is_echo():
		locomotion.toggle_slow()
	elif event.is_action_pressed("prone") and not event.is_echo():
		toggle_prone()
	elif event is InputEventMouseMotion:
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
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K:
		weapon.command(&"chamber")
	elif event.is_action_pressed("reset_position"):
		global_position = _spawn_position
		velocity = Vector3.ZERO
		is_vaulting = false


func _physics_process(delta: float) -> void:
	var active := controls_active()
	if body.is_downed():
		bleed_left -= delta
		if bleed_left <= 0.0:
			body.bleed_out()
			_resolve_casualty(BodyHealth.KILLED)
	if not active or not Input.is_action_pressed("stance_adjust"):
		_stance_pressed = false
		_stance_scrolled = false
	_update_load()
	_update_stance(active, delta)
	is_aiming = active and Input.is_action_pressed("aim") and not is_vaulting and weapon.state.busy == &"" and weapon.state.equipped()
	is_sprinting = false
	var before := global_position
	if is_vaulting:
		_advance_vault(delta)
	else:
		var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if active else Vector2.ZERO
		is_sprinting = active and Input.is_action_pressed("sprint") and locomotion.can_sprint() and body_shape.shape.height >= movement_tuning.stance_heights[6] - 0.01 and not is_aiming and axes.y < 0.0
		var speed: float = movement_tuning.sprint_speed * locomotion.load_speed() if is_sprinting else locomotion.walking_speed(body_shape.shape.height, is_aiming)
		axes.x *= movement_tuning.strafe_multiplier
		if axes.y > 0.0: axes.y *= movement_tuning.backward_multiplier
		var direction := global_basis * Vector3(axes.x, 0.0, axes.y)
		var horizontal := Vector2(velocity.x, velocity.z)
		var desired := Vector2(direction.x, direction.z) * speed
		var rate: float = movement_tuning.deceleration if desired.length() < horizontal.length() else (movement_tuning.sprint_acceleration if is_sprinting else movement_tuning.acceleration)
		horizontal = horizontal.move_toward(desired, rate * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.y
		if not is_on_floor():
			velocity.y -= gravity * delta
		elif active and Input.is_action_just_pressed("jump") and not is_crouching and not is_prone and locomotion.spend_legs(movement_tuning.jump_cost):
			velocity.y = jump_speed
		move_and_slide()
		if active and Input.is_action_just_pressed("vault"):
			try_vault()
	var travelled := Vector2(global_position.x - before.x, global_position.z - before.z).length()
	var moving := travelled > 0.001
	locomotion.advance(delta, is_sprinting and moving, moving, is_aiming, weapon.definition.mass_kg, is_vaulting or not is_on_floor())
	_update_noise(travelled)
	_update_camera(delta, active)
	_update_body_visual()
	refresh_interaction_target()
	movement_state = "Vaulting" if is_vaulting else ("Prone" if is_prone else ("Crouching" if is_crouching else ("Running" if is_sprinting else ("Walking" if moving else "Standing"))))

func toggle_prone() -> void:
	if is_vaulting: return
	if not locomotion.prone:
		if not _capsule_clear(global_position, movement_tuning.prone_height): return
		locomotion.previous_stance = locomotion.stance_level
		locomotion.prone = true
	else:
		# Remain prone until a complete restored stance can fit.
		if not _capsule_clear(global_position, movement_tuning.stance_heights[locomotion.previous_stance - 1]): return
		locomotion.prone = false
		locomotion.stance_level = locomotion.previous_stance

func _update_stance(active: bool, delta: float) -> void:
	if is_vaulting: return # Keep the clearance-tested traversal shape.
	var target: float = locomotion.target_height()
	if not body.is_alive():
		target = movement_tuning.prone_height
	elif active and Input.is_action_pressed("crouch") and not locomotion.prone:
		target = movement_tuning.stance_heights[0]
	var height: float = body_shape.shape.height
	var desired := move_toward(height, target, movement_tuning.height_change_speed * delta)
	if desired > height and not _capsule_clear(global_position, desired):
		var low := height
		var high := desired
		for iteration in range(8):
			var middle := (low + high) * 0.5
			if _capsule_clear(global_position, middle): low = middle
			else: high = middle
		desired = low
	body_shape.shape.height = desired
	body_shape.position.y = desired * 0.5
	hit_zones.set_height(desired)
	is_prone = locomotion.prone
	is_crouching = not is_prone and desired < movement_tuning.stance_heights[6] - 0.01

func _update_load() -> void:
	var inventory = weapon.state.inventory
	var weight: float = movement_tuning.additional_equipment_weight
	for item in inventory.items.values():
		if not inventory.carried(item): continue
		match item.kind:
			&"weapon":
				weight += weapon.definition.mass_kg
				if item.chambered_round != null: weight += movement_tuning.cartridge_weight
			&"magazine": weight += movement_tuning.magazine_weight + item.rounds.size() * movement_tuning.cartridge_weight
			&"ammo_stack": weight += item.quantity * movement_tuning.cartridge_weight
	locomotion.carried_weight = weight

func movement_loudness() -> float:
	var pace := clampf(Vector2(velocity.x, velocity.z).length() / movement_tuning.maximum_walk_speed, 0.0, 1.0)
	var volume: float = movement_tuning.sprint_noise if is_sprinting else movement_tuning.walking_noise * pace
	volume *= lerpf(movement_tuning.crouch_noise_multiplier, 1.0, locomotion.height_fraction(body_shape.shape.height))
	if is_prone: volume *= movement_tuning.prone_noise_multiplier
	return volume * lerpf(1.0, 1.4, locomotion.load_fraction())

func _update_noise(distance: float) -> void:
	if not is_on_floor() or is_vaulting:
		_step_distance = 0.0
		return
	_step_distance += distance
	if _step_distance >= (1.7 if is_sprinting else 1.1):
		_step_distance = 0.0
		movement_noise.emit(global_position, movement_loudness())

func _update_camera(delta: float, active: bool) -> void:
	var eye_height: float = body_shape.shape.height - 0.2
	camera.position.y = minf(move_toward(camera.position.y, eye_height, delta * movement_tuning.height_change_speed), eye_height)
	camera.rotation.x -= _sway.x
	camera.rotation.y -= _sway.y
	_sway_time += delta
	var fatigue: float = pow(1.0 - locomotion.arm_fraction(), 2.0) if is_aiming else 0.0
	_sway = Vector2(sin(_sway_time * 2.1), sin(_sway_time * 1.7)) * fatigue * movement_tuning.fatigue_sway_radians
	camera.rotation.x += _sway.x
	camera.rotation.y += _sway.y
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
	shape.radius = body_shape.shape.radius
	shape.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * (height * 0.5 + 0.025))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func try_vault() -> bool:
	if is_vaulting or is_crouching or is_prone or not is_on_floor():
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
	if not _capsule_clear(destination, body_shape.shape.height):
		traversal_message = "Landing is blocked"
		return false
	if not locomotion.spend_legs(movement_tuning.vault_cost):
		traversal_message = "Too exhausted to traverse"
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

func _update_body_visual() -> void:
	if body_visual == null:
		return
	body_visual.lean = -camera.rotation.z
	if weapon.state.busy != &"":
		body_visual.sample_action(&"reload" if weapon.state.busy==&"reload" else &"interact",weapon.state.action_progress())
	else:
		var moving := Vector2(velocity.x,velocity.z).length() > 0.1
		body_visual.play(&"crouch" if is_crouching else (&"run" if is_sprinting else (&"walk" if moving else (&"aim" if is_aiming else &"idle"))))

func center_of_mass() -> Vector3:
	if not body.is_alive():
		return global_position + Vector3.UP * 0.12
	return global_position + Vector3.UP * (body_shape.shape.height * 0.6)

func receive_hit(damage: float, at: Vector3, _normal: Vector3, source = null, zone: StringName = &"") -> void:
	if body.is_dead() or damage <= 0:
		return
	last_hit_zone = zone if zone != &"" else BodyHealth.TORSO
	var outcome: StringName = body.apply_damage(last_hit_zone, damage)
	hit_taken.emit(last_hit_zone, source.global_position if source is Node3D else at)
	if outcome == BodyHealth.DOWNED and not has_teammate_nearby:
		body.bleed_out()
		outcome = BodyHealth.KILLED
	if outcome == BodyHealth.DOWNED or outcome == BodyHealth.KILLED:
		_resolve_casualty(outcome)

func near_miss(at: Vector3) -> void:
	if body.is_alive():
		bullet_passed.emit(at)

func _resolve_casualty(outcome: StringName) -> void:
	if outcome == BodyHealth.DOWNED:
		bleed_left = bleed_out_seconds
		hit_zones.set_layout(&"downed")
	velocity = Vector3.ZERO
	casualty.emit(self, outcome)

## Drill-only reset after a debrief. Not a medical treatment or a revival.
func restore_for_drill() -> void:
	body = BodyHealth.new()
	last_hit_zone = &""
	hit_zones.set_layout(&"standing")

