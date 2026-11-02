extends CanvasLayer
signal shot_fired(origin: Vector3)
## Presentation/input adapter for the local training rifle. Not network authority.

const WeaponState = preload("res://scripts/weapons/prototype_weapon_state.gd")
const GroundEquipment = preload("res://scripts/inventory/ground_equipment.gd")
const HitZones = preload("res://scripts/combat/hit_zones.gd")
const GunshotSound = preload("res://scripts/combat/gunshot_sound.gd")
const DEFAULT_DEFINITION = preload("res://weapons/svt_inspired_training.tres")
const MAGAZINE_SHADER = preload("res://scripts/weapons/weapon_magazine.gdshader")
@export var definition: Resource = DEFAULT_DEFINITION
const FLASH_SHADER = preload("res://scripts/weapons/weapon_flash.gdshader")
const FLASH_DURATION: float = 0.075
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
var _magazine: TextureRect
var _magazine_material: ShaderMaterial
var action_phase: String = ""
var _flash: TextureRect
var _flash_frames: Array[AtlasTexture] = []
var _gun_material: ShaderMaterial
var _world_light: OmniLight3D
var last_shot_origin := Vector3.ZERO
var last_shot_end := Vector3.ZERO
var last_shot_blocked: bool = false
var last_hit_zone: StringName = &""
var _sound: AudioStreamPlayer
var _ground_items: Dictionary = {}


func _ready() -> void:
	_player = get_parent()
	state = WeaponState.new(definition)
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
	var cell := Vector2(definition.flash_texture.get_width(), definition.flash_texture.get_height()) * 0.5
	for index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = definition.flash_texture
		frame.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
		_flash_frames.append(frame)
	_magazine = TextureRect.new()
	_magazine.texture = definition.hip_texture
	_magazine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_magazine.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_magazine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_magazine_material = ShaderMaterial.new()
	_magazine_material.shader = MAGAZINE_SHADER
	_magazine.material = _magazine_material
	_magazine.visible = false
	add_child(_magazine)
	_hands = TextureRect.new()
	_hands.texture = definition.hip_texture
	_hands.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hands.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gun_material = ShaderMaterial.new()
	_gun_material.shader = FLASH_SHADER
	_hands.material = _gun_material
	var polygon: PackedVector2Array = definition.magazine_uv.duplicate()
	polygon.resize(8)
	for material in [_gun_material, _magazine_material]:
		material.set_shader_parameter("mag_polygon", polygon)
		material.set_shader_parameter("mag_count", definition.magazine_uv.size())
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
		state.request_action(action)

func prepare_inventory() -> void:
	_fire_requested = false
	state.cancel_packing()


func _physics_process(delta: float) -> void:
	state.advance(delta)
	sync_ground_items()
	var active: bool = _player.controls_active()
	if active and Input.is_action_pressed("pack_magazine") and not _player.is_vaulting:
		state.start_action(&"pack")
	else:
		state.cancel_packing()
	if _fire_requested:
		_fire_requested = false
		if active and not _player.is_vaulting and not _player.is_sprinting and state.try_fire(rng.randf()):
			_fire()

func sync_ground_items() -> void:
	for id in _ground_items.keys():
		if not state.inventory.items.has(id) or state.inventory.items[id].location.kind != &"ground":
			if is_instance_valid(_ground_items[id]): _ground_items[id].queue_free()
			_ground_items.erase(id)
	for item in state.inventory.items.values():
		if item.location.kind != &"ground": continue
		if _ground_items.has(item.id) and is_instance_valid(_ground_items[item.id]):
			_ground_items[item.id].global_position = item.location.position
			continue
		var pickup := GroundEquipment.new()
		pickup.weapon_state = state
		pickup.item_id = item.id
		_player.get_parent().add_child(pickup)
		pickup.global_position = item.location.position
		_ground_items[item.id] = pickup

func drop_inventory_item(id: StringName) -> bool:
	if state.busy != &"": return state.reject("Finish or cancel the current action first")
	var origin: Vector3 = _player.global_position + Vector3.UP + -_player.global_basis.z * 1.2
	var ground: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+Vector3.DOWN*4,1,[_player.get_rid()]))
	var at: Vector3 = ground.position+Vector3.UP*0.12 if not ground.is_empty() else origin+Vector3.DOWN*0.85
	if not state.inventory.drop_item(id,at): return false
	sync_ground_items()
	return true


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
		last_hit_zone = &""
		if hit.collider.has_method("receive_hit"):
			# Actors with zones are struck only where the shot meets a zone; a gap is a miss.
			var has_zones: bool = "hit_zones" in hit.collider and hit.collider.hit_zones != null
			if has_zones:
				last_hit_zone = HitZones.zone_along(space, hit.collider, hit.position, -camera.global_basis.z)
			if not has_zones or last_hit_zone != &"":
				hit.collider.receive_hit(definition.damage,hit.position,hit.normal,_player,last_hit_zone)
				hits += 1
		elif hit.collider.has_method("take_hit"):
			hit.collider.take_hit()
			hits += 1
	last_shot_origin = start
	shot_fired.emit(start)
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
	var clip: Resource = definition.get_clip(state.busy)
	var pose: Dictionary = clip.sample(state.action_progress()) if clip != null else {}
	action_phase = pose.get("phase", "")
	if _player.is_vaulting:
		dip += 130.0
	if _player.is_sprinting:
		dip += 55.0
	aim_fraction = move_toward(aim_fraction, 1.0 if _player.is_aiming else 0.0, delta * 6.0)
	var aimed_view := aim_fraction >= 0.5
	_hands.texture = definition.ads_texture if aimed_view else definition.hip_texture
	if pose.get("texture") != null:
		_hands.texture = pose.texture
	_hands.size = Vector2.ONE * lerpf(definition.hip_size, definition.ads_size, aim_fraction) * scale_factor
	var hip_position: Vector2 = Vector2(viewport_size.x * 0.5, viewport_size.y) + definition.hip_offset * scale_factor
	var aimed_position: Vector2 = viewport_size * 0.5 - _hands.size * definition.sight_anchor
	_hands.position = hip_position.lerp(aimed_position, aim_fraction)
	# Keep settled sights on the camera ray, including while walking/leaning.
	# A short lowering/raising motion masks the switch between painted views.
	var transition_dip := sin(aim_fraction * PI) * 85.0
	_hands.position += (bob * (1.0 - aim_fraction) + Vector2(_player.camera.position.x * 35.0 * (1.0 - aim_fraction), dip + transition_dip + _kick * 22.0)) * scale_factor
	_hands.position += pose.get("offset", Vector2.ZERO) * scale_factor
	_hands.pivot_offset = _hands.size * (definition.sight_anchor if aimed_view else Vector2(0.5, 0.5))
	# 3D roll is counterclockwise; CanvasItem rotation is clockwise (Y points down).
	_hands.rotation = -_player.camera.rotation.z + sin(_phase * 0.5) * minf(speed, 1.0) * 0.006 * (1.0 - aim_fraction)
	_hands.rotation += deg_to_rad(pose.get("roll", 0.0))
	var separate_magazine: bool = clip != null and clip.animate_magazine and not aimed_view and pose.get("texture") == null
	var physical_weapon = state.inventory.weapon()
	_gun_material.set_shader_parameter("hide_magazine", separate_magazine or physical_weapon == null or physical_weapon.inserted_magazine_id == &"")
	_magazine.visible = separate_magazine
	_hands.visible = state.equipped()
	_magazine.size = _hands.size
	_magazine.position = _hands.position + pose.get("magazine_offset", Vector2.ZERO).rotated(_hands.rotation) * scale_factor
	_magazine.pivot_offset = _hands.pivot_offset
	_magazine.rotation = _hands.rotation
	_magazine.modulate.a = pose.get("magazine_alpha", 1.0)
	_flash.size = Vector2.ONE * (120.0 if aimed_view else 150.0) * scale_factor
	_flash.position = muzzle_screen_position() - _flash.size * 0.5
	_flash.pivot_offset = _flash.size * 0.5
	_flash.rotation = _hands.rotation
	_flash.visible = _flash_time > 0.0
	var strength := _flash_time / FLASH_DURATION
	if _flash.visible:
		_flash.texture = _flash_frames[mini(int((1.0 - strength) * 4.0), 3)]
	_flash.modulate.a = minf(strength * 2.0, 1.0)
	_gun_material.set_shader_parameter("muzzle_uv", definition.ads_muzzle if aimed_view else definition.hip_muzzle)
	_gun_material.set_shader_parameter("flash_strength", strength)
	_world_light.light_energy = strength * 3.0


func sight_screen_position() -> Vector2:
	return _hands.get_global_transform() * (_hands.size * definition.sight_anchor)


func muzzle_screen_position() -> Vector2:
	var anchor: Vector2 = definition.ads_muzzle if aim_fraction >= 0.5 else definition.hip_muzzle
	return _hands.get_global_transform() * (_hands.size * anchor)


func muzzle_world_position() -> Vector3:
	# The current weapon is a 2D view sprite: project its muzzle into a short
	# camera-relative physical barrel. Replace with a 3D socket if art changes.
	return _player.camera.project_position(muzzle_screen_position(), definition.muzzle_depth)


func status_text() -> String:
	if not state.equipped(): return "No equipped rifle · recover it with F"
	return "%s · Magazine: %s · Loose %d\nChamber %s · Clean %d%% · %s" % [definition.display_name,state.inventory.knowledge(state.inventory.weapon().inserted_magazine_id),state.loose_rounds,"loaded" if state.inventory.weapon().chambered_round != null else "empty",roundi(state.cleanliness*100),action_phase if action_phase != "" else state.message]


func _make_test_shot_sound() -> AudioStreamWAV:
	return GunshotSound.stream()
