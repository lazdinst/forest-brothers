extends Node3D
## Shared blood drops on the ground, left by bleeding players and wounded enemies. The drops are
## the trail: anyone can see them, and enemies read them (drops_from) to track a wounded player.
## One trail per scene, found or created on first use. Drops are small, dark, non-graphic marks
## that fade out. Every number is a placeholder pending owner tuning.
const GROUP := &"blood_trail"
const MAX_DROPS := 600

var drop_lifetime := 600.0 # seconds a drop stays on the ground before it is gone
var now := 0.0 # scene time the drops are stamped with; advances with this node's processing
## Every drop: {position, time, intensity, source (instance id), node}.
var drops: Array[Dictionary] = []
var _material: StandardMaterial3D

static func find_or_create(near: Node):
	var tree := near.get_tree()
	var existing := tree.get_first_node_in_group(GROUP)
	if existing != null: return existing
	var trail = load("res://scripts/combat/blood_trail.gd").new()
	trail.name = "BloodTrail"
	var host: Node = tree.current_scene if tree.current_scene != null else near.get_parent()
	host.add_child(trail)
	return trail

func _ready() -> void:
	add_to_group(GROUP)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(0.26, 0.03, 0.025, 0.85)

func _physics_process(delta: float) -> void:
	now += delta
	while not drops.is_empty() and (now - drops[0].time > drop_lifetime or not is_instance_valid(drops[0].node)):
		_remove(0)
	# Prune drops whose marks were cleaned up by a reset elsewhere in the list.
	if Engine.get_physics_frames() % 120 == 0:
		for index in range(drops.size() - 1, -1, -1):
			if not is_instance_valid(drops[index].node): drops.remove_at(index)
	# Older drops fade toward the end of their life.
	for drop in drops:
		var age: float = now - drop.time
		if age > drop_lifetime * 0.7:
			drop.node.transparency = clampf((age - drop_lifetime * 0.7) / (drop_lifetime * 0.3), 0.0, 1.0)

## Drops one mark on the ground below a point. Intensity scales its size.
func add_drop(at: Vector3, intensity: float, source: Object) -> void:
	var ground := at
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.6, at + Vector3.DOWN * 2.0, 1))
	if not hit.is_empty(): ground = hit.position
	var mark := MeshInstance3D.new()
	# A thin, slightly squashed disc reads as a drop rather than a tile.
	var disc := CylinderMesh.new()
	var radius := lerpf(0.035, 0.11, clampf(intensity / 1.6, 0.0, 1.0))
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.002
	disc.radial_segments = 9
	disc.rings = 1
	disc.material = _material
	mark.mesh = disc
	mark.scale = Vector3(randf_range(0.7, 1.3), 1.0, randf_range(0.7, 1.3))
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark)
	mark.global_position = ground + Vector3.UP * 0.012
	mark.rotation.y = randf() * TAU
	drops.append({"position":ground,"time":now,"intensity":intensity,"source":source.get_instance_id(),"node":mark})
	if drops.size() > MAX_DROPS: _remove(0)

func _remove(index: int) -> void:
	if is_instance_valid(drops[index].node): drops[index].node.queue_free()
	drops.remove_at(index)

## Removes every drop, for arena and drill resets.
func clear() -> void:
	for drop in drops:
		if is_instance_valid(drop.node): drop.node.queue_free()
	drops.clear()

## Clears the scene's trail, if it has one.
static func clear_in(tree: SceneTree) -> void:
	var trail := tree.get_first_node_in_group(GROUP)
	if trail != null: trail.clear()

## Live drops left by one source, newest last.
func drops_from(source: Object) -> Array[Dictionary]:
	var id := source.get_instance_id()
	var found: Array[Dictionary] = []
	for drop in drops:
		if drop.source == id and is_instance_valid(drop.node): found.append(drop)
	return found
