extends CanvasLayer
## Presentation/input adapter for the local training rifle. Not network authority.

const WeaponState = preload("res://scripts/weapons/prototype_weapon_state.gd")
const HANDS = preload("res://assets/weapons/test_rifle/first_person_v1.png")
const AIMED_HANDS = preload("res://assets/weapons/test_rifle/iron_sights_v1.png")
const MUZZLE_FLASH = preload("res://assets/weapons/test_rifle/muzzle_flash_v1.png")
const FLASH_SHADER = preload("res://scripts/weapons/weapon_flash.gdshader")
const HIP_MUZZLE := Vector2(0.42, 0.24)
const ADS_MUZZLE := Vector2(0.5, 0.43)
const FLASH_DURATION: float = 0.075
const MUZZLE_DEPTH: float = 0.85
# Measured front-post tip in the original unmodified image, normalized to its canvas.
const SIGHT_ANCHOR := Vector2(0.5, 0.418)
var aim_fraction: float = 0.0
var state = WeaponState.new()
var rng := RandomNumberGenerator.new()
var hits: int = 0
var shots: int = 0
var _fire_requested: bool = false
var _kick: float = 0.0
var _phase: float = 0.0
var _flash_time: float = 0.0
var _player
var _hands: TextureRect
var _flash: TextureRect
var _flash_frames: Array[AtlasTexture] = []
var _gun_material: ShaderMaterial
var _world_light: OmniLight3D
var last_shot_origin := Vector3.ZERO
var last_shot_end := Vector3.ZERO
var last_shot_blocked: bool = false
var _sound: AudioStreamPlayer


func _ready() -> void:
	_player = get_parent()
	layer = 1
	rng.randomize()
	_flash = TextureRect.new()
	_flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_flash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flash.material = additive
	_flash.visible = false
	# Draw fire behind the weapon so it cannot erase the barrel/sight silhouette.
	add_child(_flash)
	var cell := Vector2(MUZZLE_FLASH.get_width(), MUZZLE_FLASH.get_height()) * 0.5
	for index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = MUZZLE_FLASH
		frame.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
		_flash_frames.append(frame)
	_hands = TextureRect.new()
	_hands.texture = HANDS
	_hands.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hands.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gun_material = ShaderMaterial.new()
	_gun_material.shader = FLASH_SHADER
	_hands.material = _gun_material
	add_child(_hands)
	_world_light = OmniLight3D.new()
	_world_light.light_color = Color(1.0, 0.57, 0.22)
	_world_light.light_energy = 0.0
	_world_light.omni_range = 4.0
	_world_light.shadow_enabled = true
	_player.get_node("Camera3D").add_child(_world_light)
	_sound = AudioStreamPlayer.new()
	_sound.volume_db = -18.0
	_sound.stream = _make_test_shot_sound()
	add_child(_sound)


func command(action: StringName) -> void:
	if action == &"fire":
		_fire_requested = true
	elif action == &"dirty":
		state.cleanliness = 0.05
		state.message = "Range test: weapon dirtied"
	else:
		state.start_action(action)


func _physics_process(delta: float) -> void:
	state.advance(delta)
	var active: bool = _player.controls_active()
	if active and Input.is_action_pressed("pack_magazine") and not _player.is_vaulting:
		state.start_action(&"pack")
	else:
		state.cancel_packing()
	if _fire_requested:
		_fire_requested = false
		if active and not _player.is_vaulting and not _player.is_sprinting and state.try_fire(rng.randf()):
			_fire()


func _fire() -> void:
	shots += 1
	_kick = 1.0
	_flash_time = FLASH_DURATION
	if DisplayServer.get_name() != "headless":
		_sound.play()
	var camera: Camera3D = _player.camera
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var eye := camera.global_position
	var aim_point := eye - camera.global_basis.z * 150.0
	var aim_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, aim_point, 1, [_player.get_rid()]))
	if not aim_hit.is_empty():
		aim_point = aim_hit.position
	var start := muzzle_world_position()
	# A painted gun can overlap a wall; the shot must still stop before that wall.
	var obstruction := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, start, 1, [_player.get_rid()]))
	var hit: Dictionary
	last_shot_blocked = not obstruction.is_empty()
	if last_shot_blocked:
		hit = obstruction
		start = hit.position + hit.normal * 0.01
	else:
		var direction := (aim_point - start).normalized()
		hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(start, aim_point + direction * 0.02, 1, [_player.get_rid()]))
	var end := aim_point
	if not hit.is_empty():
		end = hit.position
		if hit.collider.has_method("take_hit"):
			hit.collider.take_hit()
			hits += 1
	last_shot_origin = start
	last_shot_end = end
	_world_light.global_position = start
	if start.distance_to(end) < 0.02:
		return
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.012, start.distance_to(end))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.72, 0.3)
	mesh.material = material
	tracer.mesh = mesh
	_player.get_parent().add_child(tracer)
	tracer.global_position = (start + end) * 0.5
	tracer.look_at(end)
	get_tree().create_timer(0.045).timeout.connect(tracer.queue_free)


func _process(delta: float) -> void:
	_phase += delta * 8.0
	_kick = move_toward(_kick, 0.0, delta * 9.0)
	_flash_time = maxf(0.0, _flash_time - delta)
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := viewport_size.y / 720.0
	var speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	var bob := Vector2(sin(_phase) * 5.0, absf(cos(_phase)) * 7.0) * minf(speed / 3.3, 1.0)
	var dip := 0.0
	if state.busy != &"":
		var progress: float = 1.0 - state.time_left / state.action_duration
		dip = sin(progress * PI) * (120.0 if state.busy == &"reload" else 45.0)
	if _player.is_vaulting:
		dip += 130.0
	if _player.is_sprinting:
		dip += 55.0
	aim_fraction = move_toward(aim_fraction, 1.0 if _player.is_aiming else 0.0, delta * 6.0)
	var aimed_view := aim_fraction >= 0.5
	_hands.texture = AIMED_HANDS if aimed_view else HANDS
	_hands.size = Vector2.ONE * lerpf(570.0, 700.0, aim_fraction) * scale_factor
	var hip_position := Vector2(viewport_size.x * 0.5 - 230.0 * scale_factor, viewport_size.y - 480.0 * scale_factor)
	var aimed_position := viewport_size * 0.5 - _hands.size * SIGHT_ANCHOR
	_hands.position = hip_position.lerp(aimed_position, aim_fraction)
	# Keep settled sights on the camera ray, including while walking/leaning.
	# A short lowering/raising motion masks the switch between painted views.
	var transition_dip := sin(aim_fraction * PI) * 85.0
	_hands.position += (bob * (1.0 - aim_fraction) + Vector2(_player.camera.position.x * 35.0 * (1.0 - aim_fraction), dip + transition_dip + _kick * 22.0)) * scale_factor
	_hands.pivot_offset = _hands.size * (SIGHT_ANCHOR if aimed_view else Vector2(0.5, 0.5))
	# 3D roll is counterclockwise; CanvasItem rotation is clockwise (Y points down).
	_hands.rotation = -_player.camera.rotation.z + sin(_phase * 0.5) * minf(speed, 1.0) * 0.006 * (1.0 - aim_fraction)
	_flash.size = Vector2.ONE * (120.0 if aimed_view else 150.0) * scale_factor
	_flash.position = muzzle_screen_position() - _flash.size * 0.5
	_flash.pivot_offset = _flash.size * 0.5
	_flash.rotation = _hands.rotation
	_flash.visible = _flash_time > 0.0
	var strength := _flash_time / FLASH_DURATION
	if _flash.visible:
		_flash.texture = _flash_frames[mini(int((1.0 - strength) * 4.0), 3)]
	_flash.modulate.a = minf(strength * 2.0, 1.0)
	_gun_material.set_shader_parameter("muzzle_uv", ADS_MUZZLE if aimed_view else HIP_MUZZLE)
	_gun_material.set_shader_parameter("flash_strength", strength)
	_world_light.light_energy = strength * 3.0


func sight_screen_position() -> Vector2:
	return _hands.get_global_transform() * (_hands.size * SIGHT_ANCHOR)


func muzzle_screen_position() -> Vector2:
	var anchor := ADS_MUZZLE if aim_fraction >= 0.5 else HIP_MUZZLE
	return _hands.get_global_transform() * (_hands.size * anchor)


func muzzle_world_position() -> Vector3:
	# The current weapon is a 2D view sprite: project its muzzle into a short
	# camera-relative physical barrel. Replace with a 3D socket if art changes.
	return _player.camera.project_position(muzzle_screen_position(), MUZZLE_DEPTH)


func status_text() -> String:
	return "TEST RIFLE  %d/10   Spare %d/10   Loose %d\nClean %d%%   %s   Hits %d / Shots %d" % [state.magazines[state.loaded_magazine], state.magazines[1 - state.loaded_magazine], state.loose_rounds, roundi(state.cleanliness * 100.0), state.message, hits, shots]


func _make_test_shot_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(2646 * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7331
	for index in range(2646):
		var t := float(index) / 22050.0
		var sample := (noise.randf_range(-1.0, 1.0) * 0.65 + sin(t * TAU * 95.0) * 0.35) * exp(-t * 55.0)
		bytes.encode_s16(index * 2, int(sample * 24000.0))
	stream.data = bytes
	return stream
