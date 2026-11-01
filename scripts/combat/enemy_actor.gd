extends CharacterBody3D
## Bounded local opponent. No ethnicity-based targeting or historical identity.
signal defeated(actor)
signal spotted(actor, at: Vector3)
signal fired(actor, target, hit: bool)
const ART = preload("res://assets/characters/training_guard/idle_front_v1.png")
@export var use_polygon: bool = false
var polygon_model
var health: float = 100.0
var state: StringName = &"idle"
var active: bool = false
var recognition: float = 0.0
var last_known := Vector3.ZERO
var search_left: float = 0.0
var reaction_left: float = 0.0
var shot_cooldown: float = 0.0
var targets: Array[Node3D] = []
var blood_enabled: bool = true
var visual: Node3D
var sprite: Sprite3D
var _home := Vector3.ZERO
var _patrol_sign: float = 1.0
var _alert_cooldown: float = 0.0
var _hit_tint: float = 0.0

func _ready() -> void:
	_home = global_position
	collision_layer = 1
	collision_mask = 1 | 2
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	var collision := CollisionShape3D.new()
	collision.name = "Body"
	collision.shape = capsule
	collision.position.y = 0.875
	add_child(collision)
	visual = Node3D.new()
	visual.name = "Visual"
	visual.position.y = 0.9
	add_child(visual)
	sprite = Sprite3D.new()
	sprite.texture = ART
	sprite.pixel_size = 1.9 / ART.get_height()
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.no_depth_test = false
	visual.add_child(sprite)
	if use_polygon:
		visual.position.y = 0.0
		sprite.hide()
		polygon_model = load("res://scripts/characters/polygon_character.gd").new()
		polygon_model.variant = "guard"
		visual.add_child(polygon_model)

func _physics_process(delta: float) -> void:
	if state == &"dead":
		return
	shot_cooldown = maxf(0, shot_cooldown - delta)
	_alert_cooldown = maxf(0, _alert_cooldown - delta)
	_hit_tint = maxf(0, _hit_tint - delta)
	sprite.modulate = Color(1,0.5,0.5) if _hit_tint > 0 else Color.WHITE
	if polygon_model != null:
		polygon_model.set_hit_flash(_hit_tint > 0)
	var viewer := get_viewport().get_camera_3d()
	if viewer != null and not use_polygon:
		var facing := viewer.global_position - visual.global_position
		facing.y = 0
		if facing.length_squared() > 0.001:
			visual.global_basis = Basis.looking_at(-facing)
	if not active:
		return
	var seen: Node3D = null
	for actor in targets:
		if is_instance_valid(actor) and can_see(actor):
			seen = actor
			break
	velocity.x = 0
	velocity.z = 0
	if seen != null:
		var stance_factor: float = 0.65 if seen.is_crouching else 1.0
		var distance_factor := clampf(1.8-global_position.distance_to(seen.global_position)/18.0,0.5,1.5)
		recognition = minf(1.0, recognition + delta * 1.5 * stance_factor * distance_factor)
		last_known = seen.global_position
		var facing := last_known-global_position
		rotation.y = atan2(facing.x,facing.z)
		search_left = 6.0
		if recognition >= 1.0:
			if state != &"engage":
				reaction_left = 0.65
			state = &"engage"
			if _alert_cooldown <= 0.0:
				spotted.emit(self, last_known)
				_alert_cooldown = 4.0
			reaction_left -= delta
			if reaction_left <= 0.0 and shot_cooldown <= 0.0:
				_shoot(seen)
		else:
			state = &"suspicious"
	else:
		recognition = maxf(0.0, recognition - delta * 0.5)
		if search_left > 0.0:
			state = &"search"
			search_left -= delta
			var direction := last_known - global_position
			direction.y = 0
			if direction.length() > 1.0:
				direction = direction.normalized()
				velocity.x = direction.x * 0.8
				velocity.z = direction.z * 0.8
		else:
			state = &"patrol"
			var destination := _home + Vector3(_patrol_sign * 1.7,0,0)
			if global_position.distance_to(destination) < 0.2:
				_patrol_sign *= -1
			velocity.x = signf(destination.x - global_position.x) * 0.55
	if not is_on_floor():
		velocity.y -= delta * 20
	move_and_slide()
	if polygon_model != null:
		polygon_model.play(&"aim" if state==&"engage" else (&"walk" if Vector2(velocity.x,velocity.z).length()>0.1 else &"idle"))

func can_see(actor: Node3D) -> bool:
	var eye := global_position + Vector3.UP * 1.55
	var chest := actor.global_position + Vector3.UP * (0.7 if actor.is_crouching else 1.0)
	var toward := chest-eye
	toward.y = 0.0
	if toward.length_squared() > 0.001 and global_basis.z.dot(toward.normalized()) < 0.3:
		return false
	if eye.distance_to(chest) > 18.0:
		return false
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,chest,3,[get_rid()]))
	return not hit.is_empty() and hit.collider == actor

func hear_noise(at: Vector3, loudness: float = 1.0) -> void:
	if not active or state == &"dead" or global_position.distance_to(at) > 22*loudness or state == &"engage":
		return
	last_known = Vector3(snappedf(at.x,2), global_position.y, snappedf(at.z,2))
	search_left = 6.0
	state = &"search"

func receive_alert(at: Vector3) -> void:
	if active and state != &"dead":
		last_known = at
		search_left = 6.0

func _shoot(actor: Node3D) -> void:
	shot_cooldown = 1.1
	var start := global_position + Vector3(0.2,1.25,0)
	var end := actor.global_position + Vector3.UP * 1.0
	var result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,3,[get_rid()]))
	var hit: bool = not result.is_empty() and result.collider == actor
	fired.emit(self, actor, hit)
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	flash.mesh = sphere
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1,0.7,0.2)
	flash.material_override = material
	add_child(flash)
	flash.position = Vector3(0.2,1.25,0)
	get_tree().create_timer(0.06).timeout.connect(flash.queue_free)

func receive_hit(damage: float, at: Vector3, _normal: Vector3, _source = null) -> void:
	if state == &"dead" or damage <= 0:
		return
	health = maxf(0, health - damage)
	_hit_tint = 0.15
	if blood_enabled:
		_blood(at, health <= 0)
	if health <= 0:
		_die()
	elif active:
		hear_noise(at)

func _die() -> void:
	state = &"dead"
	active = false
	velocity = Vector3.ZERO
	set_deferred("collision_layer",0)
	$Body.set_deferred("disabled",true)
	if polygon_model != null:
		polygon_model.set_hit_flash(false)
		polygon_model.play(&"die")
		defeated.emit(self)
		return
	var tween := create_tween()
	tween.tween_property(visual,"scale:y",0.7,0.18)
	tween.parallel().tween_property(visual,"position:y",0.6,0.18)
	tween.tween_property(visual,"rotation:x",-PI/2,0.6).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(visual,"position:y",0.035,0.6)
	tween.parallel().tween_property(visual,"scale:y",1.0,0.6)
	defeated.emit(self)

func _blood(at: Vector3, lethal: bool) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 10
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.direction = Vector3.UP
	particles.spread = 70
	particles.initial_velocity_min = 0.8
	particles.initial_velocity_max = 1.7
	particles.gravity = Vector3(0,-6,0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.014
	mesh.height = 0.028
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.32,0.025,0.02)
	mesh.material = material
	particles.mesh = mesh
	get_parent().add_child(particles)
	particles.global_position = at
	particles.emitting = true
	particles.add_to_group("training_blood")
	get_tree().create_timer(0.6).timeout.connect(particles.queue_free)
	if lethal:
		var pool := MeshInstance3D.new()
		var disk := CylinderMesh.new()
		disk.top_radius = 0.2
		disk.bottom_radius = 0.2
		disk.height = 0.004
		disk.material = material
		pool.mesh = disk
		get_parent().add_child(pool)
		pool.global_position = Vector3(global_position.x,0.012,global_position.z)
		pool.add_to_group("training_blood")
		get_tree().create_timer(30).timeout.connect(pool.queue_free)
