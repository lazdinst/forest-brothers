extends "res://scripts/missions/region_world.gd"
## The deep forest region: dense pine, spruce and birch, a forester's hut in a clearing, an old
## dug-in bunker to the north-west and an open bog of snags and boulders to the south-east, with
## objective spots, enemy posts and two exits. Nature comes only from the environment library;
## the hut and bunker are plain shapes in the library's weathered wood. Layout is a placeholder
## for owner review; place names are fictional.
const SIZE := 140.0
const PLAYER_SPAWN := Vector3(-56, 0.02, 56)
const HUT := Vector3(28, 0, -30)
const BUNKER := Vector3(-24, 0, -38)
const BOG := Rect2(14, 14, 46, 42)
## Kept clear of trees: the hut clearing, the bunker, the bog, the exits and the start.
const CLEARINGS: Array[Rect2] = [Rect2(18, -40, 20, 18), Rect2(-31, -44, 14, 12), BOG, Rect2(-15, -68, 10, 10), Rect2(58, -5, 10, 10), Rect2(-62, 50, 10, 10)]
const AREA := Rect2(-68, -68, 136, 136)

func _build_map() -> void:
	player_spawn = PLAYER_SPAWN
	clearings = CLEARINGS
	_ground(SIZE)
	_forest()
	_hut()
	_bunker()
	_bog()
	_ground_cover()
	_exit(&"north_trail", "north trail", Vector3(-10, 0, -64))
	_exit(&"logging_track", "logging track", Vector3(64, 0, 0))

## Close forest over the whole region with deadwood, stumps and boulders between the trees.
func _forest() -> void:
	var placed := 0
	while placed < 230:
		var at := Vector3(_rng.randf_range(-68, 68), 0, _rng.randf_range(-68, 68))
		if _blocked(at, 1.5):
			continue
		_tree(TREES[_rng.randi() % TREES.size()], at, _rng.randf_range(0.8, 1.3))
		placed += 1
	for index in range(44):
		var at := Vector3(_rng.randf_range(-66, 66), 0, _rng.randf_range(-66, 66))
		if _blocked(at, 2.0):
			continue
		match index % 4:
			0: _place(DEADWOOD[_rng.randi() % DEADWOOD.size()], at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1))
			1: _log(at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.1))
			2: _stump(at, _rng.randf_range(0.8, 1.2))
			_: _place(BOULDER, at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.4))
	for spot in [Vector3(-40, 0, 10), Vector3(0, 0, -10), Vector3(-8, 0, 30), Vector3(40, 0, -55), Vector3(50, 0, 0)]:
		_spawn(&"patrol", spot, Vector3(-56, 0, 56))

## The forester's hut: a cabin with its door to the south, a woodpile of logs and stumps.
func _hut() -> void:
	_shell("ForesterHut", HUT, Vector2(7, 6), &"south", 1.4)
	_log(HUT + Vector3(-7, 0, 1), 1.57, 0.6)
	_log(HUT + Vector3(-7.6, 0, 1), 1.57, 0.6)
	_stump(HUT + Vector3(-5, 0, 5), 1.0)
	_place(CRATE, HUT + Vector3(5, 0, 4.5), 0.4)
	_spot(&"forester_map", HUT + Vector3(2.0, 0.06, -1.5))
	_spot(&"forester_map", HUT + Vector3(-2.2, 0.06, -1.6))
	_spot(&"forester_map", HUT + Vector3(-5, 0.66, 5))
	_spawn(&"hut", HUT + Vector3(0, 0, 6), HUT + Vector3(0, 0, 30))
	_spawn(&"hut", HUT + Vector3(-6, 0, -4), HUT + Vector3(-30, 0, 0))
	_spawn(&"hut", HUT + Vector3(6, 0, -6), HUT + Vector3(20, 0, -30))

## An old dug-in bunker: log walls with the doorway east, a plank roof and crates inside.
func _bunker() -> void:
	_shell("Bunker", BUNKER, Vector2(6, 5), &"east", 1.2, 2.2)
	_box("BunkerRoof", BUNKER + Vector3(0, 2.3, 0), Vector3(6.6, 0.2, 5.6))
	_place(CRATE, BUNKER + Vector3(-1.8, 0, -1.4), 0.1)
	_place(CRATE, BUNKER + Vector3(-1.8, 0, 1.2), -0.2)
	_log(BUNKER + Vector3(0, 0, -4.2), 0.0, 0.7)
	_spot(&"cache", BUNKER + Vector3(-1.8, 0.9, -1.4))
	_spot(&"cache", BUNKER + Vector3(1.0, 0.06, 1.4))
	_spawn(&"bunker", BUNKER + Vector3(6, 0, 2), BUNKER + Vector3(30, 0, 10))
	_spawn(&"bunker", BUNKER + Vector3(-4, 0, 5), BUNKER + Vector3(-20, 0, 30))
	_spawn(&"bunker", BUNKER + Vector3(2, 0, -6), BUNKER + Vector3(10, 0, -30))

## Open boggy ground: snags, boulders and fallen pines with no standing forest.
func _bog() -> void:
	for index in range(22):
		var at := Vector3(_rng.randf_range(BOG.position.x + 2, BOG.end.x - 2), 0, _rng.randf_range(BOG.position.y + 2, BOG.end.y - 2))
		match index % 3:
			0: _place(DEADWOOD[2], at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1))
			1: _place(BOULDER, at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.3))
			_: _place(DEADWOOD[_rng.randi() % 2], at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1))
	_spot(&"cache", Vector3(36, 0.06, 34))
	_spawn(&"patrol", Vector3(30, 0, 30), Vector3(0, 0, 50))

## Ferns, grass tufts and leaf litter; decoration only, no collision. Grass favours the bog.
func _ground_cover() -> void:
	for index in range(260):
		var at := Vector3(_rng.randf_range(-68, 66), 0, _rng.randf_range(-68, 68))
		if not _blocked(at, 0.0):
			_place(FERN, at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.2))
	clearings = clearings.filter(func(area): return area != BOG)
	_scatter(GRASS, 2600, AREA, BOG, 0.45)
	clearings = CLEARINGS
	_scatter(LITTER, 1100, AREA, AREA, 0.0)
