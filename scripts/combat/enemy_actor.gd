extends CharacterBody3D
## Bounded local opponent. No ethnicity-based targeting or historical identity.
signal defeated(actor)
signal spotted(actor, at: Vector3)
signal fired(actor, target, hit: bool)
signal reload_started(actor)
const ART = preload("res://assets/characters/training_guard/idle_front_v1.png")
const HitZones = preload("res://scripts/combat/hit_zones.gd")
const BodyHealth = preload("res://scripts/combat/body_health.gd")
const HitSounds = preload("res://scripts/combat/hit_sounds.gd")
const GunshotSound = preload("res://scripts/combat/gunshot_sound.gd")
const FIGURE_HEIGHT := 1.75
# Rules-side firing geometry in actor space (+z is the true facing). The rifle proxy matches it.
const SHOULDER := Vector3(0.18, 1.35, 0.0)
const BARREL_LENGTH := 0.78
const LOWERED_PITCH := 0.6
const RELOAD_PITCH := 0.95
@export var use_polygon: bool = false
@export var character_scene: PackedScene
var polygon_model
var body = BodyHealth.new()
# Placeholder pending owner tuning (open question 5).
var bleed_out_seconds: float = 30.0
var bleed_left: float = 0.0
const CRAWL_SPEED := 0.3
var state: StringName = &"idle"
var active: bool = false
var recognition: float = 0.0
var last_known := Vector3.ZERO
var search_left: float = 0.0
var reaction_left: float = 0.0
var shot_cooldown: float = 0.0
var targets: Array[Node3D] = []
var blood_enabled: bool = true
# Placeholder pending owner tuning; matches the training rifle.
var shot_damage: float = 40.0
# Aim limits, placeholders pending owner tuning. Spread is a cone half-angle in degrees.
var aim_spread_degrees: float = 3.0
var settled_spread_fraction: float = 0.35
var settle_seconds: float = 4.0
var moving_target_spread_degrees: float = 1.5
var aim_time: float = 0.0
var rng := RandomNumberGenerator.new()
# Finite ammunition, placeholders pending owner tuning. Spare magazines keep their own counts,
# so a partial magazine swapped out early is retained rather than refilled from a pool.
var magazine_size: int = 10
var rounds_in_magazine: int = 10
var spare_magazines: Array[int] = [10, 10, 10]
var reload_seconds: float = 3.0
var reload_left: float = 0.0
var fire_interval: float = 1.1
var visual: Node3D
var sprite: Sprite3D
## Placeholder weapon proxy, not character art: shows where the enemy faces and aims.
var rifle: Node3D
var hit_zones
var last_hit_zone: StringName = &""
var _home := Vector3.ZERO
var _patrol_sign: float = 1.0
var _alert_cooldown: float = 0.0
var _hit_tint: float = 0.0

func _ready() -> void:
	_home = global_position
	bleed_left = bleed_out_seconds
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
	hit_zones = HitZones.new()
	hit_zones.name = "HitZones"
	add_child(hit_zones)
	hit_zones.build(self, FIGURE_HEIGHT)
	_build_rifle()
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
	if character_scene != null:
		visual.position.y = 0.0
		sprite.hide()
		polygon_model = load("res://scripts/characters/imported_character.gd").new()
		polygon_model.model_scene = character_scene
		visual.add_child(polygon_model)
	elif use_polygon:
		visual.position.y = 0.0
		sprite.hide()
		polygon_model = load("res://scripts/characters/polygon_character.gd").new()
		polygon_model.variant = "guard"
		visual.add_child(polygon_model)

func _physics_process(delta: float) -> void:
	if state == &"dead":
		return
	shot_cooldown = maxf(0, shot_cooldown - delta)
	if is_reloading() and state != &"downed":
		reload_left -= delta
		if reload_left <= 0.0:
			_finish_reload()
	_alert_cooldown = maxf(0, _alert_cooldown - delta)
	_hit_tint = maxf(0, _hit_tint - delta)
	var shade := Color.WHITE
	var viewer_camera := get_viewport().get_camera_3d()
	if viewer_camera != null:
		# The painted sprite always faces the camera, so dim it when the body is turned away.
		var lit := lerpf(0.5, 1.0, clampf((facing_toward(viewer_camera.global_position) + 0.3) / 0.6, 0.0, 1.0))
		shade = Color(lit, lit, lit)
	sprite.modulate = Color(1,0.5,0.5) if _hit_tint > 0 else shade
	if polygon_model != null:
		polygon_model.set_hit_flash(_hit_tint > 0)
	if state == &"downed":
		_crawl(delta)
		return
	var viewer := get_viewport().get_camera_3d()
	if viewer != null and polygon_model == null:
		var facing := viewer.global_position - visual.global_position
		facing.y = 0
		if facing.length_squared() > 0.001:
			visual.global_basis = Basis.looking_at(-facing)
	_update_rifle(delta)
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
		var stance_factor: float = lerpf(0.4, 1.0, seen.locomotion.height_fraction(seen.body_shape.shape.height))
		stance_factor *= 1.0 + minf(Vector2(seen.velocity.x, seen.velocity.z).length() / 10.0, 0.5)
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
			aim_time += delta
			if rounds_in_magazine <= 0 and not is_reloading():
				start_reload()
			if reaction_left <= 0.0 and shot_cooldown <= 0.0 and rounds_in_magazine > 0 and not is_reloading():
				_shoot(seen)
		else:
			state = &"suspicious"
	else:
		aim_time = 0.0
		# Out of contact, top up a half-empty rifle so the next fight starts loaded.
		if rounds_in_magazine * 2 <= magazine_size and not is_reloading():
			start_reload()
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
	# Patrol keeps the same lane-facing AI heading for every visual.
	if polygon_model != null:
		polygon_model.play(&"aim" if state==&"engage" else (&"walk" if Vector2(velocity.x,velocity.z).length()>0.1 else &"idle"))

func can_see(actor: Node3D) -> bool:
	var eye := global_position + Vector3.UP * 1.55
	var chest: Vector3 = actor.global_position + Vector3.UP * (actor.body_shape.shape.height * 0.6)
	var toward := chest-eye
	toward.y = 0.0
	if toward.length_squared() > 0.001 and global_basis.z.dot(toward.normalized()) < 0.3:
		return false
	if eye.distance_to(chest) > 18.0:
		return false
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,chest,3,[get_rid()]))
	return not hit.is_empty() and hit.collider == actor

func hear_noise(at: Vector3, loudness: float = 1.0) -> void:
	if not active or state == &"dead" or state == &"downed" or global_position.distance_to(at) > 22*loudness or state == &"engage":
		return
	last_known = Vector3(snappedf(at.x,2), global_position.y, snappedf(at.z,2))
	search_left = 6.0
	state = &"search"

func receive_alert(at: Vector3) -> void:
	if active and state != &"dead" and state != &"downed":
		last_known = at
		search_left = 6.0

func _shoot(actor: Node3D) -> void:
	shot_cooldown = fire_interval
	rounds_in_magazine -= 1
	var start := global_transform * SHOULDER
	var end: Vector3 = actor.center_of_mass() if actor.has_method("center_of_mass") else actor.global_position + Vector3.UP * 1.0
	var space := get_world_3d().direct_space_state
	var direction := _spread_direction((end - start).normalized(), shot_spread_degrees(actor))
	var reach := start + direction * (start.distance_to(end) + 40.0)
	var result := space.intersect_ray(PhysicsRayQueryParameters3D.create(start,reach,3,[get_rid()]))
	var hit: bool = not result.is_empty() and result.collider == actor
	# Damage goes to whatever the ray met, including other actors (friendly fire).
	if not result.is_empty() and result.collider.has_method("receive_hit"):
		var zone: StringName = &""
		if "hit_zones" in result.collider and result.collider.hit_zones != null:
			zone = HitZones.zone_along(space, result.collider, result.position, direction)
			hit = hit and zone != &""
		if zone != &"" or not ("hit_zones" in result.collider):
			result.collider.receive_hit(shot_damage, result.position, result.normal, self, zone)
	if not hit and actor.has_method("near_miss"):
		var stop: Vector3 = reach if result.is_empty() else result.position
		var closest := Geometry3D.get_closest_point_to_segment(end, start, stop)
		if closest.distance_to(end) < 2.0:
			actor.near_miss(closest)
	fired.emit(self, actor, hit)
	_gunshot(start)
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
	flash.global_position = muzzle_world_position()
	get_tree().create_timer(0.06).timeout.connect(flash.queue_free)

func receive_hit(damage: float, at: Vector3, _normal: Vector3, source = null, zone: StringName = &"") -> void:
	if state == &"dead" or damage <= 0:
		return
	# Callers without zone information (debug tools, older tests) strike centre mass.
	last_hit_zone = zone if zone != &"" else BodyHealth.TORSO
	var outcome: StringName = body.apply_damage(last_hit_zone, damage)
	_hit_tint = 0.15
	if blood_enabled:
		_blood(at, outcome == BodyHealth.KILLED)
	_impact_sound(at, last_hit_zone)
	if outcome == BodyHealth.KILLED:
		_die()
	elif outcome == BodyHealth.DOWNED:
		_go_down(source)
	elif active:
		hear_noise(at)

## Positional zone sound so the shooter can hear what they hit.
func _impact_sound(at: Vector3, zone: StringName) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = HitSounds.stream(zone)
	player.unit_size = 6.0
	get_parent().add_child(player)
	player.global_position = at
	player.finished.connect(player.queue_free)
	player.play()

func _go_down(source) -> void:
	state = &"downed"
	rifle.hide()
	if source is Node3D:
		last_known = source.global_position
	recognition = 0.0
	velocity = Vector3.ZERO
	bleed_left = bleed_out_seconds
	# A movement capsule standing over a lying body would catch shots aimed at it.
	var flat := BoxShape3D.new()
	flat.size = Vector3(0.5, 0.245, FIGURE_HEIGHT)
	$Body.shape = flat
	$Body.position.y = flat.size.y / 2
	hit_zones.set_layout(&"downed")
	# Call out through the existing local alert so nearby enemies investigate.
	spotted.emit(self, last_known if active else global_position)
	if polygon_model != null:
		polygon_model.set_hit_flash(false)
		polygon_model.play(&"die")
		return
	visual.rotation = Vector3(-PI/2, 0, 0)
	visual.position.y = 0.035

func _crawl(delta: float) -> void:
	bleed_left -= delta
	if bleed_left <= 0.0:
		body.bleed_out()
		_die()
		return
	velocity.x = 0
	velocity.z = 0
	# Placeholder until cover search exists: drag away from the last known threat.
	var away := global_position - last_known
	away.y = 0
	if active and away.length_squared() > 0.01:
		away = away.normalized()
		rotation.y = atan2(-away.x, -away.z)
		velocity.x = away.x * CRAWL_SPEED
		velocity.z = away.z * CRAWL_SPEED
	if not is_on_floor():
		velocity.y -= delta * 20
	move_and_slide()

func _die() -> void:
	var was_downed := state == &"downed"
	state = &"dead"
	active = false
	velocity = Vector3.ZERO
	set_deferred("collision_layer",0)
	$Body.set_deferred("disabled",true)
	hit_zones.disable()
	rifle.hide()
	# Resolve gameplay before choosing a cosmetic corpse animation.
	defeated.emit(self)
	if not was_downed:
		_play_death_visual()

func _play_death_visual() -> void:
	if polygon_model != null:
		polygon_model.set_hit_flash(false)
		polygon_model.play(&"die")
		return
	var tween := create_tween()
	tween.tween_property(visual,"scale:y",0.7,0.18)
	tween.parallel().tween_property(visual,"position:y",0.6,0.18)
	tween.tween_property(visual,"rotation:x",-PI/2,0.6).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(visual,"position:y",0.035,0.6)
	tween.parallel().tween_property(visual,"scale:y",1.0,0.6)

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

## Current cone half-angle: wide on first exposure, tighter as the enemy keeps aiming, wider at a moving target.
func shot_spread_degrees(actor: Node3D) -> float:
	var settle := clampf(aim_time / settle_seconds, 0.0, 1.0)
	var spread := aim_spread_degrees * lerpf(1.0, settled_spread_fraction, settle)
	if "velocity" in actor:
		spread += moving_target_spread_degrees * clampf(Vector2(actor.velocity.x, actor.velocity.z).length() / 5.0, 0.0, 1.0)
	return spread

func _spread_direction(aim: Vector3, degrees: float) -> Vector3:
	if degrees <= 0.0:
		return aim
	var side := aim.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = aim.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(aim).normalized()
	# Uniform over the cone's disc, so most shots land near the centre but some go wide.
	var radius := tan(deg_to_rad(degrees)) * sqrt(rng.randf())
	var turn := rng.randf() * TAU
	return (aim + (side * cos(turn) + up * sin(turn)) * radius).normalized()

## Positional report so players can locate the shooter by ear.
func _gunshot(at: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var report := AudioStreamPlayer3D.new()
	report.stream = GunshotSound.stream()
	report.unit_size = 18.0
	report.max_distance = 200.0
	get_parent().add_child(report)
	report.global_position = at
	report.finished.connect(report.queue_free)
	report.play()

## 1 when this enemy's body faces the point, -1 when turned fully away.
func facing_toward(point: Vector3) -> float:
	var toward := point - global_position
	toward.y = 0.0
	if toward.length_squared() < 0.0001:
		return 1.0
	var forward := global_basis.z
	forward.y = 0.0
	return forward.normalized().dot(toward.normalized())

func muzzle_world_position() -> Vector3:
	return rifle.global_transform * Vector3(0, 0, BARREL_LENGTH)

func _build_rifle() -> void:
	rifle = Node3D.new()
	rifle.name = "RifleProxy"
	rifle.position = SHOULDER
	rifle.rotation.x = LOWERED_PITCH
	add_child(rifle)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.07, 0.98)
	mesh.mesh = box
	mesh.position.z = BARREL_LENGTH - box.size.z / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.12, 0.09)
	mesh.material_override = material
	rifle.add_child(mesh)

## Rifle lowered while calm; raised toward the target while engaging, which is the tell before a shot.
func _update_rifle(delta: float) -> void:
	var pitch := LOWERED_PITCH
	if is_reloading():
		pitch = RELOAD_PITCH
	elif state == &"engage":
		var muzzle_height := global_position.y + SHOULDER.y
		var flat := Vector2(last_known.x - global_position.x, last_known.z - global_position.z).length()
		pitch = -atan2(last_known.y + 1.0 - muzzle_height, maxf(flat, 0.5))
	rifle.rotation.x = move_toward(rifle.rotation.x, pitch, delta * 3.0)

func is_reloading() -> bool:
	return reload_left > 0.0

func total_rounds() -> int:
	var total := rounds_in_magazine
	for count in spare_magazines:
		total += count
	return total

## Starts a magazine change if a spare holds more rounds than the current one. Returns whether it started.
func start_reload() -> bool:
	if is_reloading() or state == &"dead" or state == &"downed":
		return false
	var best := -1
	for index in range(spare_magazines.size()):
		if spare_magazines[index] > rounds_in_magazine and (best < 0 or spare_magazines[index] > spare_magazines[best]):
			best = index
	if best < 0:
		return false
	reload_left = reload_seconds
	reload_started.emit(self)
	_reload_sound()
	return true

func _finish_reload() -> void:
	reload_left = 0.0
	var best := 0
	for index in range(spare_magazines.size()):
		if spare_magazines[index] > spare_magazines[best]:
			best = index
	var incoming: int = spare_magazines[best]
	spare_magazines.remove_at(best)
	if rounds_in_magazine > 0:
		spare_magazines.append(rounds_in_magazine)
	rounds_in_magazine = incoming

## Positional magazine clatter: an audible opening for nearby players.
func _reload_sound() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var clatter := AudioStreamPlayer3D.new()
	clatter.stream = GunshotSound.reload_stream()
	clatter.unit_size = 4.0
	get_parent().add_child(clatter)
	clatter.global_position = global_transform * SHOULDER
	clatter.finished.connect(clatter.queue_free)
	clatter.play()
