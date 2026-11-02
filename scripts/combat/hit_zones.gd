extends Node3D
## Builds per-state hit zone volumes on an actor, following its true facing (not the camera-facing sprite).
## Layouts are proportions of figure height so another sprite or pose scales correctly.
const HitZone = preload("res://scripts/combat/hit_zone.gd")
const BodyHealth = preload("res://scripts/combat/body_health.gd")
# zone, shape kind, centre (x and z in metres, y as fraction of height), size (y as fraction of height)
const LAYOUTS := {
	&"standing": [
		[BodyHealth.HEAD, &"sphere", Vector3(0, 0.93, 0), Vector3(0.12, 0.07, 0.12)],
		[BodyHealth.TORSO, &"box", Vector3(0, 0.68, 0), Vector3(0.38, 0.36, 0.26)],
		[BodyHealth.ARMS, &"box", Vector3(0.25, 0.66, 0), Vector3(0.12, 0.34, 0.14)],
		[BodyHealth.ARMS, &"box", Vector3(-0.25, 0.66, 0), Vector3(0.12, 0.34, 0.14)],
		[BodyHealth.LEGS, &"box", Vector3(0, 0.25, 0), Vector3(0.44, 0.5, 0.24)],
	],
	# Any hit on a downed body kills, so one flat shape is enough.
	# Absolute metres: a lying body keeps its length whatever the standing height was.
	&"downed": [
		[BodyHealth.TORSO, &"box", Vector3(0, 0.1225, 0), Vector3(0.5, 0.245, 1.75)],
	],
}
const ABSOLUTE_LAYOUTS: Array[StringName] = [&"downed"]
var actor: Node3D
var height: float = 1.75
var layout: StringName = &""

func build(owner_node: Node3D, figure_height: float, start_layout: StringName = &"standing") -> void:
	actor = owner_node
	height = figure_height
	set_layout(start_layout)

func set_layout(next: StringName) -> void:
	if next == layout or not LAYOUTS.has(next):
		return
	layout = next
	_rebuild()

## Rescales the current layout, e.g. when a player's stance changes height.
func set_height(figure_height: float) -> void:
	if absf(figure_height - height) < 0.02:
		return
	height = figure_height
	_rebuild()

func _rebuild() -> void:
	var scale_y: float = 1.0 if ABSOLUTE_LAYOUTS.has(layout) else height
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for entry in LAYOUTS[layout]:
		var area = HitZone.new(entry[0], actor)
		var collision := CollisionShape3D.new()
		var centre: Vector3 = entry[2]
		var size: Vector3 = entry[3]
		if entry[1] == &"sphere":
			var sphere := SphereShape3D.new()
			sphere.radius = size.y * scale_y
			collision.shape = sphere
		else:
			var box := BoxShape3D.new()
			box.size = Vector3(size.x, size.y * scale_y, size.z)
			collision.shape = box
		area.add_child(collision)
		area.position = Vector3(centre.x, centre.y * scale_y, centre.z)
		add_child(area)

func disable() -> void:
	for area in get_children():
		area.set_deferred("collision_layer", 0)

func zones() -> Array:
	return get_children()

## Continues a shot that struck this actor's movement capsule and returns the zone it meets, or &"" for a gap.
static func zone_along(space: PhysicsDirectSpaceState3D, body: Node3D, from: Vector3, direction: Vector3) -> StringName:
	var query := PhysicsRayQueryParameters3D.create(from - direction * 0.05, from + direction * 1.2, HitZone.LAYER)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.hit_from_inside = true
	var skipped: Array[RID] = []
	for attempt in range(6):
		query.exclude = skipped
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return &""
		if hit.collider.owner_actor == body:
			return hit.collider.zone
		skipped.append(hit.rid)
	return &""
