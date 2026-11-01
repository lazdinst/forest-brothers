extends CanvasLayer
## Presentation/input adapter for the local training rifle. Not network authority.

const WeaponState = preload("res://scripts/weapons/prototype_weapon_state.gd")
const HANDS = preload("res://assets/weapons/test_rifle/first_person_v1.png")
const AIMED_HANDS = preload("res://assets/weapons/test_rifle/iron_sights_v1.png")
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
var _flash: ColorRect
var _sound: AudioStreamPlayer


func _ready() -> void:
	_player = get_parent()
	layer = 1
	rng.randomize()
	_hands = TextureRect.new()
	_hands.texture = HANDS
	_hands.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hands.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hands)
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.8, 0.3)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
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
	_flash_time = 0.06
	if DisplayServer.get_name() != "headless":
		_sound.play()
	var camera: Camera3D = _player.camera
	var start := camera.global_position
	var end := start - camera.global_basis.z * 150.0
	var query := PhysicsRayQueryParameters3D.create(start, end, 1, [_player.get_rid()])
	var hit: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		end = hit.position
		if hit.collider.has_method("take_hit"):
			hit.collider.take_hit()
			hits += 1
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
	get_tree().create_timer(0.06).timeout.connect(tracer.queue_free)


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
	_hands.rotation = _player.camera.rotation.z + sin(_phase * 0.5) * minf(speed, 1.0) * 0.006 * (1.0 - aim_fraction)
	_flash.size = Vector2(15, 20) * scale_factor
	_flash.position = sight_screen_position() - _flash.size * 0.5 if aimed_view else _hands.position + _hands.size * Vector2(0.43, 0.22)
	_flash.visible = _flash_time > 0.0


func sight_screen_position() -> Vector2:
	return _hands.get_global_transform() * (_hands.size * SIGHT_ANCHOR)


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
