extends "res://scripts/missions/region_world.gd"
## The farm district region: a forest edge, a farmstead with a barn, a few village cottages and
## a road checkpoint, with objective spots, enemy posts and two exits. Nature comes only from the
## environment library; buildings are plain walls in the library's weathered wood. Layout is a
## placeholder for owner review; place names are fictional.
const SIZE := 140.0
const PLAYER_SPAWN := Vector3(-58, 0.02, 34)
## Places kept clear of trees and clutter: building plots, the checkpoint and the exits.
const CLEARINGS: Array[Rect2] = [Rect2(26, -46, 38, 34), Rect2(22, 6, 18, 48), Rect2(-4, -14, 24, 20), Rect2(-68, -5, 10, 10), Rect2(2, 58, 12, 12)]
const AREA := Rect2(-68, -68, 136, 136)
const FOREST := Rect2(-68, -68, 46, 136)

# --- Map ------------------------------------------------------------------------------------

func _build_map() -> void:
	player_spawn = PLAYER_SPAWN
	clearings = CLEARINGS
	_ground(SIZE)
	_forest()
	_farmstead()
	_village()
	_checkpoint()
	_ground_cover()
	_exit(&"west_path", "forest path", Vector3(-64, 0, 0))
	_exit(&"south_road", "south road", Vector3(8, 0, 64))

## Pine, spruce and birch along the west edge with deadwood, boulders and ferns between them,
## a clear path to the west exit, and scattered trees elsewhere. Seeded: the same every time.
func _forest() -> void:
	var placed := 0
	while placed < 110:
		var at := Vector3(_rng.randf_range(-68, -22), 0, _rng.randf_range(-66, 66))
		if absf(at.z) < 4.0 or at.distance_to(PLAYER_SPAWN) < 4.0 or _blocked(at, 1.0):
			continue
		_tree(TREES[_rng.randi() % TREES.size()], at, _rng.randf_range(0.8, 1.3))
		placed += 1
	for index in range(40):
		var at := Vector3(_rng.randf_range(-20, 66), 0, _rng.randf_range(-66, 66))
		if _blocked(at, 6.0) or absf(at.x - 8.0) < 5.0:
			continue
		_tree(TREES[_rng.randi() % TREES.size()], at, _rng.randf_range(0.8, 1.2))
	for index in range(28):
		var at := Vector3(_rng.randf_range(-66, -20), 0, _rng.randf_range(-64, 64))
		if absf(at.z) < 5.0 or _blocked(at, 2.0):
			continue
		match index % 4:
			0: _place(DEADWOOD[_rng.randi() % DEADWOOD.size()], at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1))
			1: _log(at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.1))
			2: _stump(at, _rng.randf_range(0.8, 1.2))
			_: _place(BOULDER, at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.4))
	for spot in [Vector3(-30, 0, -20), Vector3(-34, 0, 18), Vector3(-28, 0, 46)]:
		_spawn(&"patrol", spot, Vector3(0, 0, 0))

## Ferns, grass tufts and leaf litter; decoration only, no collision.
func _ground_cover() -> void:
	for index in range(220):
		var at := Vector3(_rng.randf_range(-68, 66), 0, _rng.randf_range(-68, 68))
		if not _blocked(at, 0.0) and (at.x < -20.0 or _rng.randf() < 0.25):
			_place(FERN, at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.2))
	_scatter(GRASS, 2600, AREA, FOREST, 0.25)
	_scatter(LITTER, 900, AREA, FOREST, 0.6)

func _farmstead() -> void:
	# House (doorway south) and barn (wide doorway west) north-east of the road.
	_shell("FarmHouse", Vector3(36, 0, -38), Vector2(10, 8), &"south", 1.6)
	_shell("Barn", Vector3(52, 0, -30), Vector2(12, 14), &"west", 4.0)
	_place(CRATE, Vector3(54, 0, -26), 0.3)
	_place(CRATE, Vector3(55.2, 0, -26.4), -0.2)
	_log(Vector3(30, 0, -28), 0.4, 0.9)
	for x in range(26, 62, 3):
		_box("Fence", Vector3(x, 0.5, -16), Vector3(0.12, 1.0, 0.12), Color.WHITE)
	_spot(&"dispatch", Vector3(39, 0.06, -40.5))
	_spot(&"dispatch", Vector3(55, 0.06, -34))
	_spot(&"codebook", Vector3(33, 0.06, -40.5))
	_spawn(&"farm", Vector3(36, 0, -30), Vector3(36, 0, 0))
	_spawn(&"farm", Vector3(44, 0, -22), Vector3(20, 0, 0))
	_spawn(&"farm", Vector3(52, 0, -40), Vector3(40, 0, -10))

func _village() -> void:
	# Three cottages east of the road, doorways facing it.
	for index in range(3):
		var centre := Vector3(30, 0, 14 + index * 14)
		_shell("Cottage%d" % index, centre, Vector2(7, 6), &"west", 1.4)
		_spot(&"medicine", centre + Vector3(2.0, 0.06, -1.5))
	_place(BOULDER, Vector3(20, 0, 28), 0.7, 1.1)
	_log(Vector3(38, 0, 21), 1.57, 0.6)
	for at in [Vector3(24, 0, 9), Vector3(36, 0, 36), Vector3(25, 0, 48)]:
		_tree(BIRCH, at, 1.0)
	_spawn(&"village", Vector3(22, 0, 16), Vector3(0, 0, 16))
	_spawn(&"village", Vector3(24, 0, 34), Vector3(0, 0, 40))
	_spawn(&"village", Vector3(38, 0, 46), Vector3(8, 0, 60))

func _checkpoint() -> void:
	# A hut and low cover where the road crosses the line north of the village.
	_shell("CheckpointHut", Vector3(15, 0, -6), Vector2(4, 3.5), &"west", 1.2)
	_box("Barrier", Vector3(8, 1.0, -2), Vector3(6, 0.12, 0.12), Color.WHITE)
	# Low cover from library pieces: crates, felled logs and boulders.
	for at in [Vector3(3, 0, 2), Vector3(13, 0, 2)]:
		_place(CRATE, at, 0.0)
		_place(CRATE, at + Vector3(1.1, 0, 0), 0.1)
	_log(Vector3(3, 0, -8), 0.0, 0.6)
	_place(BOULDER, Vector3(0, 0, -3), 1.2, 1.2)
	_place(CRATE, Vector3(11, 0, -10), 0.0)
	_spot(&"codebook", Vector3(15.5, 0.06, -6.5))
	_spot(&"codebook", Vector3(11, 0.06, -11.0))
	_spawn(&"checkpoint", Vector3(6, 0, 0), Vector3(-20, 0, 10))
	_spawn(&"checkpoint", Vector3(12, 0, -4), Vector3(8, 0, 30))
	_spawn(&"checkpoint", Vector3(2, 0, -10), Vector3(-30, 0, -10))
	_spawn(&"patrol", Vector3(8, 0, -40), Vector3(8, 0, 0))

