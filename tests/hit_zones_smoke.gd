extends SceneTree
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const HitZones = preload("res://scripts/combat/hit_zones.gd")
var failures: Array[String] = []
var enemy
func _initialize() -> void:
	call_deferred("_run")
func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
# Fires a body ray like the rifle (mask 1), then resolves the zone along it.
func _zone_from_front(x: float, y: float) -> StringName:
	var space: PhysicsDirectSpaceState3D = enemy.get_world_3d().direct_space_state
	var from := Vector3(x, y, 3)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, Vector3(x, y, -3), 1))
	if hit.is_empty() or hit.collider != enemy:
		return &"miss"
	return HitZones.zone_along(space, enemy, hit.position, Vector3.FORWARD)
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	enemy = Enemy.new()
	world.add_child(enemy)
	await _frames(3)
	var zones: Array = enemy.hit_zones.zones()
	_check(zones.size()==5 and zones.all(func(z): return z.collision_layer==8 and z.collision_mask==0),"Standing layout has five zone volumes on layer 8 only")
	_check(enemy.collision_layer==1,"Movement capsule stays on world layer")
	_check(_zone_from_front(0, 1.63)==&"head","Shot at head height hits head")
	_check(_zone_from_front(0, 1.2)==&"torso","Shot at chest height hits torso")
	_check(_zone_from_front(0.25, 1.15)==&"arms","Shot at shoulder edge hits arm")
	_check(_zone_from_front(0, 0.5)==&"legs","Shot at knee height hits legs")
	_check(_zone_from_front(0.6, 1.2)==&"miss","Shot beside the body misses")
	enemy.rotation.y = PI / 2
	await _frames(2)
	_check(_zone_from_front(0, 1.15)==&"arms","Zones follow the actor's true facing")
	enemy.rotation.y = 0
	enemy.hit_zones.set_layout(&"downed")
	await _frames(2)
	var space: PhysicsDirectSpaceState3D = enemy.get_world_3d().direct_space_state
	_check(enemy.hit_zones.zones().size()==1,"Downed layout is one flat shape")
	_check(HitZones.zone_along(space, enemy, Vector3(0, 0.07, 1.0), Vector3.FORWARD)==&"torso","Downed shape lies on the ground")
	_check(HitZones.zone_along(space, enemy, Vector3(0, 1.63, 0.3), Vector3.FORWARD)==&"","Downed body has no standing head zone")
	enemy.hit_zones.set_layout(&"standing")
	enemy.receive_hit(10, enemy.global_position + Vector3.UP, Vector3.FORWARD, null, &"legs")
	_check(enemy.last_hit_zone==&"legs" and enemy.health==90,"Enemy records the reported zone")
	enemy.receive_hit(500, enemy.global_position + Vector3.UP, Vector3.FORWARD)
	await _frames(2)
	_check(HitZones.zone_along(space, enemy, Vector3(0, 1.2, 0.3), Vector3.FORWARD)==&"","Corpse zones stop catching shots")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: zone layers, head/torso/arm/leg rays, miss, facing, downed layout, recorded zone, corpse")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
