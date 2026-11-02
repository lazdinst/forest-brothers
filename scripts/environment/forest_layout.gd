extends RefCounted
## Shared bake/check recipe. Metres, fixed content IDs; no runtime randomization.
const SEED := 19461101
const MIN_X := -55
const MAX_X := 45
const MIN_Z := -54
const MAX_Z := 46

static func _rect_weight(p: Vector2, bounds: Rect2, feather: float = 2.0) -> float:
	var nearest := p.clamp(bounds.position, bounds.end)
	return 1.0 - smoothstep(0.0, feather, p.distance_to(nearest))

static func trail_x(z: float) -> float:
	return 2.0 * sin(z * 0.12) - 0.025 * maxf(z - 17.0, 0.0)

static func reserved(p: Vector2, margin: float = 0.0) -> bool:
	# Includes fixture landings, doors/pickups, civilian patrol, rig showcase,
	# annex entry, original woodland collision/vault checks and firing lanes.
	for box in [Rect2(-18, -23, 14, 38), Rect2(-7, -9, 14, 23), Rect2(6, -23, 12, 19), Rect2(6, 0, 10, 10)]:
		if box.grow(margin).has_point(p):
			return true
	return p.x > 26 and p.y > -26 and p.y < 26

static func trench_distance(p: Vector2) -> float:
	var main := p.distance_to(Vector2(-9, clampf(p.y, 19, 33)))
	var branch := p.distance_to(Vector2(clampf(p.x, -18, -9), 27))
	return minf(main, branch)

static func height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	# Broad, low landforms plus smaller hummocks. No vertex-shader-only relief.
	var land := 0.65 * sin(x * 0.085 + 0.7) * cos(z * 0.07)
	land += 0.27 * sin(x * 0.24 + z * 0.12) + 0.14 * cos(z * 0.43 - x * 0.17)
	land += 0.08 * sin(x * 1.05) * sin(z * 0.81)
	land += 0.85 * exp(-p.distance_squared_to(Vector2(-28, -25)) / 170.0)
	land -= 0.6 * exp(-p.distance_squared_to(Vector2(-27, 17)) / 90.0)
	var flat := 0.0
	for box in [Rect2(-18, -23, 14, 38), Rect2(-7, -9, 14, 23), Rect2(6, -23, 12, 19), Rect2(6, 0, 10, 10)]:
		flat = maxf(flat, _rect_weight(p, box, 3.0))
	land *= 1.0 - flat
	# A continuous gently graded route through the woodland, not a stair ramp.
	var trail := 1.0 - smoothstep(1.0, 2.5, absf(x - trail_x(z)))
	land *= 1.0 - trail * 0.65
	# Edge berm bounds this finite prototype; vegetation/fog disguise its extent.
	var edge := maxf(absf(x + 5.0), absf(z + 4.0))
	land += smoothstep(44.0, 50.0, edge) * 1.8
	var cut := (1.0 - smoothstep(0.7, 1.35, trench_distance(p))) * smoothstep(18.5, 23.0, z)
	land = lerpf(land, -1.55, cut)
	return land

static func normal_at(x: float, z: float) -> Vector3:
	return Vector3(height(x - 0.2, z) - height(x + 0.2, z), 0.4, height(x, z - 0.2) - height(x, z + 0.2)).normalized()
