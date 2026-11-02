extends RefCounted
## Leaves blood drops behind one bleeder: closer together the heavier the bleeding, and a small
## pool after standing still for a while. Each bleeding player or wounded enemy owns one.
## Placeholder spacing pending owner tuning.
const BloodTrail = preload("res://scripts/combat/blood_trail.gd")
var spacing_light := 1.6
var spacing_heavy := 0.7
var pool_seconds := 4.0
var _last := Vector3.INF
var _still := 0.0

## Intensity 0 means not bleeding, 0.5 light, 1 heavy. Returns true when it dripped.
func update(owner: Node3D, delta: float, intensity: float) -> bool:
	if intensity <= 0.0 or not owner.is_inside_tree():
		_last = Vector3.INF
		return false
	var at := owner.global_position
	var spacing := lerpf(spacing_light, spacing_heavy, clampf(intensity * 2.0 - 1.0, 0.0, 1.0))
	if _last == Vector3.INF or Vector2(at.x - _last.x, at.z - _last.z).length() >= spacing:
		_still = 0.0
		_last = at
		BloodTrail.find_or_create(owner).add_drop(at, intensity, owner)
		return true
	_still += delta
	if _still >= pool_seconds:
		_still = 0.0
		BloodTrail.find_or_create(owner).add_drop(at, intensity * 1.6, owner)
		return true
	return false
