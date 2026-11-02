extends Node3D
## The camp a world plays from: a placeholder clearing in the woods with a fire in the middle,
## the old man, a small tent, a cash chest (treasury), a goods chest (communal storage) and a
## barrel with a map on it that opens the mission map. Nature comes only from the environment
## library; the fire, tent and barrel have no library asset yet, so they are plain shapes with
## library materials. With a session (Play) it loads the world's camp and the character's
## equipment and saves both when left and every 30 seconds. Layout and prices are placeholders.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const CivilianScene = preload("res://scenes/characters/starting_civilian.tscn")
const CampStock = preload("res://scripts/state/camp_stock.gd")
const Runtime = preload("res://scripts/camp/camp_runtime.gd")
const CashChest = preload("res://scripts/camp/cash_chest.gd")
const GoodsChest = preload("res://scripts/camp/goods_chest.gd")
const Interactable = preload("res://scripts/camp/camp_interactable.gd")
const GameSession = preload("res://scripts/state/game_session.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const InventoryHost = preload("res://ui/inventory/inventory_host.gd")
const MovementHud = preload("res://ui/components/tactical_movement_hud.gd")
const ResourceStrip = preload("res://ui/components/resource_strip.gd")
const TraderWindow = preload("res://ui/camp/trader_window.gd")
const OldManScript = preload("res://scripts/camp/camp_old_man.gd")
const ENV := "res://assets/environment/"
const TREES: Array[PackedScene] = [preload(ENV + "scenes/forest_pine_v1.tscn"), preload(ENV + "scenes/forest_spruce_v1.tscn"), preload(ENV + "scenes/forest_birch_v1.tscn")]
const BOULDER: PackedScene = preload(ENV + "scenes/boulder_v1.tscn")
const FERN: PackedScene = preload(ENV + "scenes/fern_v1.tscn")
const FALLEN_LOG: PackedScene = preload(ENV + "scenes/fallen_log_v1.tscn")
const STUMP: PackedScene = preload(ENV + "scenes/decayed_stump_v1.tscn")
const DEADWOOD: Array[PackedScene] = [preload(ENV + "scenes/pine_fallen_v2.tscn"), preload(ENV + "scenes/pine_rotten_v2.tscn")]
const GRASS: Mesh = preload(ENV + "meshes/grass_tuft_v1.res")
const LITTER: Mesh = preload(ENV + "meshes/leaf_litter_v1.res")
const GROUND_MATERIAL: Material = preload(ENV + "materials/moss_ground_v1.tres")
const WOOD_MATERIAL: StandardMaterial3D = preload(ENV + "materials/weathered_wood_v1.tres")
const MISSION_MAP := "res://scenes/missions/mission_board.tscn"
## A new world's camp starts with these stores (placeholder, the same as Training's).
const STARTING_STOCK = {&"food":100,&"water":100,&"medicine":30,&"meals":30,&"timber":200,&"parts":60,&"cloth":80,&"rounds":500,&"rubles":120,&"lats":3}
const SIZE := 90.0
const CLEARING_RADIUS := 13.0
const PLAYER_SPAWN := Vector3(0, 0.05, 7)
const AUTOSAVE_SECONDS := 30.0
var stock = CampStock.new()
var runtime
var player
var cash_chest
var goods_chest
var tent: Node3D
var map_barrel
var old_man: Node3D
var fire_light: OmniLight3D
var flames: Array[MeshInstance3D] = []
var trade_panel
var inventory
var _prompt: Label
var _crosshair: Label
var _strip
var _rng := RandomNumberGenerator.new()
var _autosave_left := AUTOSAVE_SECONDS
var _time := 0.0

func _ready() -> void:
	_rng.seed = 1944
	runtime = Runtime.new(stock)
	runtime.message = ""
	stock.try_exchange({}, STARTING_STOCK)
	_lighting()
	_ground()
	_woods()
	_fire()
	_tent()
	_chests()
	_map_barrel()
	_old_man()
	player = PlayerScene.instantiate()
	player.name = "Player"
	player.position = PLAYER_SPAWN
	add_child(player)
	# Through startup, the router's inventory host serves this player; opened directly, our own.
	if get_parent() == get_tree().root:
		inventory = InventoryHost.new()
		inventory.world = self
		inventory.player = player
		add_child(inventory)
	_hud()
	_load_session()

# --- Session ---------------------------------------------------------------------------------

func _load_session() -> void:
	if not GameSession.active(): return
	var camp: Dictionary = GameSession.camp_state()
	if not camp.is_empty():
		runtime.restore(camp)
		goods_chest.restore(camp.get("goods", {}))
	var backlog: Dictionary = GameSession.take_reward_backlog()
	for id in backlog:
		if stock.quantities.has(StringName(id)):
			stock.add(StringName(id), int(backlog[id]))
	GameSession.apply_equipment(player)
	tree_exiting.connect(save_session)

## The camp state saved into the world: the shared camp rules plus the goods chest.
func camp_state() -> Dictionary:
	var state: Dictionary = runtime.encode()
	state.goods = goods_chest.encode()
	return state

## Saves the camp into the world and the character's equipment. Safe to call at any time.
func save_session() -> void:
	if not GameSession.active(): return
	GameSession.save_world(camp_state())
	GameSession.save_equipment(player)

func _process(delta: float) -> void:
	_time += delta
	# The fire flickers.
	fire_light.light_energy = 2.2 + sin(_time * 9.0) * 0.25 + sin(_time * 23.0) * 0.15
	for index in range(flames.size()):
		flames[index].scale = Vector3(1.0, 0.85 + 0.2 * sin(_time * (7.0 + index * 3.0) + index), 1.0)
	if GameSession.active():
		_autosave_left -= delta
		if _autosave_left <= 0.0:
			_autosave_left = AUTOSAVE_SECONDS
			save_session()
	var busy: bool = trade_panel.visible
	var mouse_free := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	_prompt.text = "" if busy else ("Click to look around" if mouse_free else player.get_interaction_prompt())
	_crosshair.visible = not busy and not player.is_aiming and player.weapon.aim_fraction < 0.05

# --- Things to use ---------------------------------------------------------------------------

## Leaves for the mission map; MissionLaunch remembers the way back to this camp.
func open_mission_map(_actor = null) -> void:
	MissionLaunch.leave_camp(get_tree(), MISSION_MAP)

## The old man knows people in the village: his trade window buys from him at fixed prices and
## sells him what you carry or keep in the goods chest, cheaply. The player stands still meanwhile.
func open_trade(_actor = null) -> void:
	trade_panel.sources = [{"label":"carried","inventory":player.weapon.state.inventory}, {"label":"goods chest","inventory":goods_chest.inventory}]
	trade_panel.refresh()
	trade_panel.show()
	$HUD.hide()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_trade() -> void:
	trade_panel.hide()
	$HUD.show()
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# --- Layout ----------------------------------------------------------------------------------

func _lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -40, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.5, 0.55, 0.56)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.45, 0.46, 0.43)
	environment.environment.fog_enabled = true
	environment.environment.fog_light_color = Color(0.5, 0.55, 0.56)
	environment.environment.fog_density = 0.012
	add_child(environment)

func _ground() -> void:
	var ground := _box("Ground", Vector3(0, -0.5, 0), Vector3(SIZE, 1, SIZE), WOOD_MATERIAL)
	(ground.get_child(1) as MeshInstance3D).material_override = GROUND_MATERIAL
	# Edge of the play area: invisible walls just inside the treeline's far edge.
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5 if side.x != 0.0 else SIZE, 6, SIZE if side.x != 0.0 else 0.5)
		shape.shape = box
		wall.add_child(shape)
		wall.position = side * (SIZE / 2.0 - 1.0) + Vector3(0, 3, 0)
		add_child(wall)

## Woods all around the clearing, with deadwood, stumps, ferns, grass and litter.
func _woods() -> void:
	var placed := 0
	while placed < 170:
		var at := Vector3(_rng.randf_range(-44, 44), 0, _rng.randf_range(-44, 44))
		if Vector2(at.x, at.z).length() < CLEARING_RADIUS + 2.0: continue
		_tree(TREES[_rng.randi() % TREES.size()], at, _rng.randf_range(0.8, 1.3))
		placed += 1
	for index in range(30):
		var at := Vector3(_rng.randf_range(-42, 42), 0, _rng.randf_range(-42, 42))
		if Vector2(at.x, at.z).length() < CLEARING_RADIUS: continue
		match index % 3:
			0: _place(DEADWOOD[_rng.randi() % DEADWOOD.size()], at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1))
			1: _place(STUMP, at, 0.0, _rng.randf_range(0.8, 1.2))
			_: _place(BOULDER, at, _rng.randf() * TAU, _rng.randf_range(0.8, 1.3))
	for index in range(160):
		var at := Vector3(_rng.randf_range(-44, 44), 0, _rng.randf_range(-44, 44))
		if Vector2(at.x, at.z).length() > 5.0: _place(FERN, at, _rng.randf() * TAU, _rng.randf_range(0.7, 1.2))
	_scatter(GRASS, 1600, 4.0)
	_scatter(LITTER, 700, 2.5)

## The fire: crossed logs in a ring of stones, with a warm flickering light.
func _fire() -> void:
	var fire := Node3D.new()
	fire.name = "Fire"
	add_child(fire)
	for index in range(12):
		var angle := index * TAU / 12.0
		var stone: Node3D = BOULDER.instantiate()
		stone.position = Vector3(cos(angle), -0.04, sin(angle)) * 0.7
		stone.rotation.y = angle * 3.0
		stone.scale = Vector3.ONE * 0.1
		fire.add_child(stone)
	for angle in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
		var log_piece: Node3D = FALLEN_LOG.instantiate()
		log_piece.rotation.y = angle
		log_piece.scale = Vector3(0.18, 0.3, 0.3)
		log_piece.position.y = 0.05
		fire.add_child(log_piece)
	fire_light = OmniLight3D.new()
	fire_light.position = Vector3(0, 0.6, 0)
	fire_light.light_color = Color(1.0, 0.62, 0.3)
	fire_light.omni_range = 9.0
	fire_light.shadow_enabled = true
	fire.add_child(fire_light)
	# The embers: a small glowing mound (plain shape) until there is fire art.
	var embers := MeshInstance3D.new()
	var mound := SphereMesh.new()
	mound.radius = 0.35
	mound.height = 0.25
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.9, 0.35, 0.1)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.45, 0.12)
	glow.emission_energy_multiplier = 2.5
	mound.material = glow
	embers.mesh = mound
	embers.position.y = 0.05
	fire.add_child(embers)
	# Flames: glowing cones that flicker (plain shapes until there is fire art).
	for index in range(3):
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.16 - index * 0.03
		cone.height = 0.7 - index * 0.12
		var hot := glow.duplicate() as StandardMaterial3D
		hot.albedo_color = Color(1.0, 0.55 + index * 0.12, 0.15)
		hot.emission = Color(1.0, 0.5 + index * 0.15, 0.15)
		hot.emission_energy_multiplier = 3.0
		hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cone.material = hot
		flame.mesh = cone
		flame.position = Vector3(cos(index * 2.1) * 0.12, cone.height / 2.0 + 0.08, sin(index * 2.1) * 0.12)
		fire.add_child(flame)
		flames.append(flame)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.9
	cylinder.height = 0.5
	shape.shape = cylinder
	shape.position.y = 0.25
	body.add_child(shape)
	fire.add_child(body)
	for at in [Vector3(-2.4, 0, 0.6), Vector3(2.2, 0, -1.4)]:
		_place(FALLEN_LOG, at, atan2(at.x, at.z) + PI / 2.0, 0.35)

## A small A-frame tent of plain shapes in the library's wood, its open end facing the fire.
func _tent() -> void:
	tent = Node3D.new()
	tent.name = "Tent"
	tent.position = Vector3(-5.5, 0, -4.5)
	tent.rotation.y = atan2(5.5, 4.5)
	add_child(tent)
	var canvas := WOOD_MATERIAL.duplicate() as StandardMaterial3D
	canvas.albedo_color = Color(0.62, 0.6, 0.46)
	for side in [-1.0, 1.0]:
		var sheet := _box("Canvas", Vector3(side * 0.62, 0.62, 0), Vector3(0.06, 1.55, 2.6), canvas, tent)
		sheet.rotation.z = side * 0.72
	_box("Ridge", Vector3(0, 1.22, 0), Vector3(0.08, 0.08, 2.9), WOOD_MATERIAL, tent)
	for z in [-1.3, 1.3]:
		_box("Pole", Vector3(0, 0.62, z), Vector3(0.07, 1.24, 0.07), WOOD_MATERIAL, tent)
	_box("BackWall", Vector3(0, 0.45, -1.28), Vector3(1.6, 0.9, 0.05), canvas, tent)

func _chests() -> void:
	cash_chest = CashChest.new(stock)
	cash_chest.name = "CashChest"
	cash_chest.position = Vector3(-8.0, 0, -1.6)
	cash_chest.rotation.y = 0.4
	add_child(cash_chest)
	_sign("CASH CHEST", cash_chest.position + Vector3(0, 1.3, 0))
	goods_chest = GoodsChest.new()
	goods_chest.name = "GoodsChest"
	goods_chest.position = Vector3(-4.6, 0, 2.4)
	goods_chest.rotation.y = 0.9
	add_child(goods_chest)
	_sign("GOODS CHEST", goods_chest.position + Vector3(0, 1.3, 0))

## A barrel with the district map spread on top: the way to the mission map.
func _map_barrel() -> void:
	map_barrel = Interactable.new()
	map_barrel.name = "MapBarrel"
	map_barrel.position = Vector3(4.8, 0, -3.6)
	map_barrel.prompt = "F  Study the map (mission map)"
	map_barrel.action = open_mission_map
	add_child(map_barrel)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.38
	cylinder.height = 0.95
	shape.shape = cylinder
	shape.position.y = 0.475
	map_barrel.add_child(shape)
	var barrel := MeshInstance3D.new()
	var body := CylinderMesh.new()
	body.top_radius = 0.34
	body.bottom_radius = 0.34
	body.height = 0.95
	body.material = WOOD_MATERIAL
	barrel.mesh = body
	barrel.position.y = 0.475
	map_barrel.add_child(barrel)
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.86, 0.8, 0.64)
	var sheet := _box("Map", Vector3(0, 0.96, 0), Vector3(0.62, 0.01, 0.46), paper, map_barrel)
	sheet.rotation.y = 0.3
	_sign("MISSION MAP", map_barrel.position + Vector3(0, 1.4, 0))

## The old man stands by the fire; F talks to him about trading.
func _old_man() -> void:
	old_man = CivilianScene.instantiate()
	# Swapping the script resets its exported sprites, so carry them over.
	var textures: Array = [old_man.front_texture, old_man.side_texture, old_man.back_texture, old_man.walk_front, old_man.walk_side, old_man.walk_back]
	old_man.set_script(OldManScript)
	old_man.front_texture = textures[0]
	old_man.side_texture = textures[1]
	old_man.back_texture = textures[2]
	old_man.walk_front = textures[3]
	old_man.walk_side = textures[4]
	old_man.walk_back = textures[5]
	old_man.name = "OldMan"
	old_man.position = Vector3(2.4, 0, 1.6)
	old_man.prompt = "F  Talk to the old man (trade)"
	old_man.action = open_trade
	add_child(old_man)

# --- Helpers ---------------------------------------------------------------------------------

func _tree(scene: PackedScene, at: Vector3, size: float) -> void:
	_place(scene, at, _rng.randf() * TAU, size)
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.24 * size
	shape.height = 10.0 * size
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	body.add_child(collision)
	body.position = at
	add_child(body)

func _place(scene: PackedScene, at: Vector3, rotation_y: float, size: float = 1.0) -> Node3D:
	var node: Node3D = scene.instantiate()
	node.position = at
	node.rotation.y = rotation_y
	node.scale = Vector3.ONE * size
	add_child(node)
	return node

func _box(box_name: String, at: Vector3, size: Vector3, material: Material, parent: Node = self) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)
	parent.add_child(body)
	return body

func _sign(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 64
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	add_child(label)

## Many copies of a small mesh in one batch, off the trodden middle of the clearing.
func _scatter(mesh: Mesh, count: int, keep_clear: float) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	var transforms: Array[Transform3D] = []
	for index in range(count):
		var at := Vector3(_rng.randf_range(-44, 44), 0, _rng.randf_range(-44, 44))
		if Vector2(at.x, at.z).length() < keep_clear: continue
		transforms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.3)), at))
	multi.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func _hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var instrument = MovementHud.new()
	instrument.name = "TacticalMovement"
	instrument.player = player
	layer.add_child(instrument)
	_strip = ResourceStrip.new()
	_strip.name = "ResourceStock"
	_strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_strip.position = Vector2(-595, 26)
	layer.add_child(_strip)
	stock.changed.connect(func(): _strip.show_stock(stock.quantities))
	_strip.show_stock.call_deferred(stock.quantities)
	_crosshair = Label.new()
	_crosshair.text = "+"
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair.size = Vector2(16, 32)
	_crosshair.position -= _crosshair.size / 2.0
	layer.add_child(_crosshair)
	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.offset_top = 40
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 4)
	layer.add_child(_prompt)
	var modal_layer := CanvasLayer.new()
	modal_layer.layer = 30
	add_child(modal_layer)
	trade_panel = TraderWindow.new()
	trade_panel.runtime = runtime
	trade_panel.hide()
	modal_layer.add_child(trade_panel)
	trade_panel.closed.connect(_close_trade)
