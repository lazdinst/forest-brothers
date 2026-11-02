extends Node3D
## Additive training module. Owns local rules/UI; reuses the world's stock/player.
const Runtime = preload("res://scripts/camp/camp_runtime.gd")
const ResourceStrip = preload("res://ui/components/resource_strip.gd")
# Local fixture identity only; shared-session identities belong to the later authority layer.
const PLAYER_WORKER_ID: StringName = &"training_player"
const ForestLayout = preload("res://scripts/environment/forest_layout.gd")
const Station = preload("res://scripts/camp/camp_station.gd")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MISSION_MAP := "res://scenes/missions/mission_board.tscn"
const COMBAT_ARENA := "res://scenes/combat/combat_arena.tscn"
const Civilian = preload("res://scenes/characters/starting_civilian.tscn")
const ResidentScript = preload("res://scripts/camp/camp_resident.gd")
# Rig fixtures only; the owner rejected this blockout as character art.
@export var use_polygon_characters: bool = false
# Art frozen: preserve the painted default and offer MPFB only for comparison.
@export var use_mpfb_enemy: bool = false
var runtime
var world
var player
var stations: Dictionary = {}
var enemies: Array = []
var resident_nodes: Dictionary = {}
var _plan_views: Dictionary = {}
var _shelter_version: int = -1
var _trench_version: bool = false
var _shelter: Node3D
var _trench: Node3D
var _layer: CanvasLayer
var _overlay: ColorRect
var _heading: Label
var _details: Label
var _resource_strip
var _actions: VBoxContainer
var debug_diagnostics_visible := false
var _summary: Label
var _job_status: Label
var _entry_hint: Label
var _panel_station: StringName = &""
var _panel_resident: StringName = &""
var _actor
var _prior_mouse: int
var _planner: Camera3D
var planning: bool = false
var _planner_hint: Label
var _map_labels: Array[Label] = []
var _bout_active: bool = false
var blood_enabled: bool = true

func _ready() -> void:
	world = get_parent()
	player = world.get_node("Player")
	player.casualty.connect(_player_casualty)
	runtime = Runtime.new(world.stock)
	runtime.can_complete = _completion_clear
	runtime.can_player_work = _can_player_work
	position = Vector3(48,0,0)
	_box(self,"AnnexFloor",Vector3(0,-0.2,0),Vector3(36,0.4,40),Color(0.22,0.25,0.18),true)
	for side in [-1,1]:
		_box(self,"Boundary",Vector3(0,1,side*20),Vector3(36,2,0.3),Color(0.25,0.29,0.25),true)
	# Leave a four-metre opening behind the firing lanes (world x30, z15..19).
	_box(self,"WestBoundaryNorth",Vector3(-18,1,-2.5),Vector3(0.3,2,35),Color(0.25,0.29,0.25),true)
	_box(self,"WestBoundarySouth",Vector3(-18,1,19.5),Vector3(0.3,2,1),Color(0.25,0.29,0.25),true)
	_box(self,"EastBoundary",Vector3(18,1,0),Vector3(0.3,2,40),Color(0.25,0.29,0.25),true)
	_connect_yard()
	_label(self,"CAMP & COMBAT TRAINING ANNEX\nF at stations / one shared stock / prototype costs",Vector3(0,3.0,16))
	_label(self,"WEST PLANNING PLOT\nPlace racks from the build table",Vector3(-10,0.03,3))
	_box(self,"PlanningPlot",Vector3(-9.5,0.006,4),Vector3(9,0.01,12),Color(0.24,0.3,0.23))
	_station(&"depot",&"depot","Communal quartermaster",Vector3(0,0,13))
	_station(&"well",&"well","Well / water collection",Vector3(-12,0,13))
	_station(&"cook",&"cook","Cooking workshop",Vector3(-7,0,13))
	_station(&"food",&"food","Food storage",Vector3(4,0,13))
	_station(&"armourer",&"armourer","Armourer's workbench",Vector3(9,0,13))
	_station(&"ammo",&"ammo","Ammunition storage",Vector3(14,0,13))
	_station(&"medical",&"medical","Medical post / test patient",Vector3(14,0,7))
	_station(&"shelter",&"shelter","Shelter upgrade site",Vector3(8,0,6))
	_station(&"trench",&"trench","Marked trench worksite",Vector3(14,0,1))
	_station(&"planning",&"planning","Build planning table",Vector3(-3,0,6))
	_station(&"hq",&"hq","Headquarters / rescue exercise",Vector3(3,0,6))
	_station(&"combat",&"combat","Enemy test controls",Vector3(0,0,-1))
	_station(&"contact",&"contact","Contact (buys and sells at fixed prices)",Vector3(-12,0,-6))
	_box(self,"LeftCover",Vector3(-3,1,-5),Vector3(6,2,0.35),Color(0.3,0.32,0.29),true)
	_box(self,"RightCover",Vector3(7,1,-8),Vector3(0.5,2,5),Color(0.3,0.32,0.29),true)
	_label(self,"ENEMY TEST LANE\nArm the bout at the control table\n3 rifle hits / non-graphic blood / collapse",Vector3(0,3,-10))
	_spawn_resident(&"resident_01",Vector3(0,0,8),false)
	_spawn_resident(&"rescued_test_01",Vector3(-12,0,-13),true)
	reset_enemies()
	_ui()
	runtime.changed.connect(refresh_panel)
	world.stock.changed.connect(refresh_panel)
	player.weapon.shot_fired.connect(_gun_noise)
	player.movement_noise.connect(_movement_noise)
	_sync_world()

func _connect_yard() -> void:
	# Follow baked terrain to its x27 edge, then grade to the camp floor.
	# Keep the generated forest resources intact; mesh and collision share vertices.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for xi in range(13):
		for zi in range(8):
			var x := 24.0 + xi * 0.5
			var z := 15.0 + zi * 0.5
			for corner in [Vector2(x,z),Vector2(x+0.5,z),Vector2(x,z+0.5),Vector2(x+0.5,z),Vector2(x+0.5,z+0.5),Vector2(x,z+0.5)]:
				var blend := smoothstep(27.0,30.0,corner.x)
				var y := lerpf(ForestLayout.height(minf(corner.x,27.0),corner.y),0.0,blend)
				surface.set_uv(corner * 0.25)
				surface.add_vertex(Vector3(corner.x,y+0.012,corner.y)-position)
	surface.generate_normals()
	var mesh := surface.commit()
	var path := MeshInstance3D.new()
	path.name = "YardConnection"
	path.mesh = mesh
	path.material_override = load("res://assets/environment/materials/moss_ground_v1.tres")
	add_child(path)
	var body := StaticBody3D.new()
	path.add_child(body)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)
	_label(self,"CAMP / WORKSHOPS →\nWalk behind the firing lanes",Vector3(3,2.4,18.3)-position)
	_label(self,"CAMP / WORKSHOPS →",Vector3(25,2.4,18.3)-position)
	_label(self,"← SHOOTING RANGE / MOVEMENT COURSE",Vector3(-15,2.4,17))

func _station(id: StringName, kind: StringName, title: String, at: Vector3) -> void:
	var station = Station.new()
	station.name = String(id).to_pascal_case()+"Station"
	station.annex = self
	station.station_id = id
	station.kind = kind
	station.title = title
	station.position = at
	add_child(station)
	stations[id] = station
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7,1,0.8)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.5
	station.add_child(collision)
	_box(station,"Table",Vector3(0,0.75,0),Vector3(1.7,0.12,0.8),Color(0.34,0.27,0.18))
	for side in [-0.65,0.65]:
		_box(station,"Leg",Vector3(side,0.35,0),Vector3(0.1,0.7,0.6),Color(0.27,0.22,0.16))
	_label(station,title,Vector3(0,1.65,0))
	if kind == &"well":
		var cylinder := MeshInstance3D.new()
		var ring := CylinderMesh.new()
		ring.top_radius = 0.55
		ring.bottom_radius = 0.6
		ring.height = 0.5
		cylinder.mesh = ring
		cylinder.position.y = 0.6
		station.add_child(cylinder)
	if kind == &"cook":
		_box(station,"Stove",Vector3(0,1,0),Vector3(0.7,0.4,0.5),Color(0.15,0.15,0.13))
	if kind == &"medical":
		_box(station,"PatientCot",Vector3(-2,0.4,0),Vector3(1.0,0.15,2),Color(0.4,0.4,0.32))
		if use_polygon_characters:
			var patient_model = load("res://scripts/characters/polygon_character.gd").new()
			patient_model.position = Vector3(-2,0.68,0.9)
			patient_model.rotation.x = -PI/2
			station.add_child(patient_model)
		else:
			var patient := Sprite3D.new()
			patient.name = "SpritePatient"
			patient.texture = load("res://assets/characters/starting_civilian/starting_civilian_front_v1.png")
			patient.pixel_size = 1.7 / patient.texture.get_height()
			patient.position = Vector3(-2,0.5,0)
			patient.rotation.x = -PI/2
			station.add_child(patient)
		_label(station,"Test patient",Vector3(-2,1.6,0))
	if kind == &"depot" or kind == &"food" or kind == &"ammo":
		# Reuse the environment agent's crate if available; never duplicate its art.
		var path := "res://assets/environment/scenes/crate_v1.tscn"
		if ResourceLoader.exists(path):
			var crate = load(path).instantiate()
			crate.position = Vector3(0,0.82,0)
			crate.scale = Vector3.ONE*0.4
			station.add_child(crate)
			# Display prop only; station owns interaction collision.
			_disable_prop_collision(crate)

func _disable_prop_collision(node: Node) -> void:
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_disable_prop_collision(child)

func _spawn_resident(id: StringName, at: Vector3, rescue: bool) -> void:
	var actor = Civilian.instantiate()
	var textures: Array = [actor.front_texture,actor.side_texture,actor.back_texture,actor.walk_front,actor.walk_side,actor.walk_back]
	actor.set_script(ResidentScript)
	actor.front_texture = textures[0]
	actor.side_texture = textures[1]
	actor.back_texture = textures[2]
	actor.walk_front = textures[3]
	actor.walk_side = textures[4]
	actor.walk_back = textures[5]
	actor.use_polygon = use_polygon_characters
	actor.resident_id = id
	actor.rescuable = rescue
	actor.annex = self
	actor.name = String(id)
	actor.position = at
	add_child(actor)
	resident_nodes[id] = actor
	_label(actor,"Rescue practice civilian" if rescue else "Civilian role stand-in",Vector3(0,2.1,0))

func reset_enemies() -> void:
	_bout_active = false
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.active = false
			remove_child(enemy)
			enemy.queue_free()
	enemies.clear()
	for effect in get_tree().get_nodes_in_group("training_blood"):
		if effect.get_parent() == self:
			effect.queue_free()
	load("res://scripts/combat/blood_trail.gd").clear_in(get_tree())
	for index in range(2):
		var enemy = Enemy.new()
		enemy.name = "TrainingEnemy%d" % index
		enemy.position = Vector3(-4 if index==0 else 5,0,-14-index)
		enemy.targets.assign([player])
		enemy.blood_enabled = blood_enabled
		enemy.use_polygon = use_polygon_characters and index == 0
		if index == 0 and use_mpfb_enemy and not use_polygon_characters:
			enemy.character_scene = preload("res://assets/characters/mpfb_enemy/enemy_v1.glb")
		add_child(enemy)
		enemy.defeated.connect(_enemy_defeated)
		enemy.spotted.connect(_enemy_spotted)
		enemy.fired.connect(_enemy_fired)
		enemies.append(enemy)

func _toggle_enemy_comparison() -> void:
	use_mpfb_enemy = not use_mpfb_enemy
	reset_enemies()
	refresh_panel()

func _movement_noise(at: Vector3, loudness: float) -> void:
	for enemy in enemies:
		enemy.hear_noise(at, loudness)

func _gun_noise(at: Vector3) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.hear_noise(at)

func _enemy_defeated(_enemy) -> void:
	if runtime.exercise_active:
		runtime.exercise_objective = true
	runtime.message = "Enemy defeated. Corpse collision disabled; reset at test controls."
	refresh_panel()

func _enemy_spotted(source, at: Vector3) -> void:
	for enemy in enemies:
		if enemy != source and enemy.global_position.distance_to(source.global_position) <= 12:
			enemy.receive_alert(at)

func _enemy_fired(_source, _target, _hit: bool) -> void:
	# Enemy rays now apply zone damage themselves; the drill only reacts to casualties.
	pass

func _player_casualty(_player, outcome: StringName) -> void:
	if outcome == &"downed":
		runtime.message = "Downed (simulated teammate nearby). Any further hit kills; bleed-out %.0f s." % player.bleed_out_seconds
		refresh_panel()
		return
	_bout_active = false
	for enemy in enemies:
		enemy.active = false
	var cause: String = "head hit" if player.last_hit_zone == &"head" and player.body.health[&"head"] <= 0 else "torso, finishing hit or bleed-out"
	_teleport(Vector3(0,0.02,17))
	player.restore_for_drill()
	runtime.message = "Drill debrief: killed (%s). Campaign gear-loss and mission-death rules are not active in this drill." % cause
	refresh_panel()

func _ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 6
	add_child(_layer)
	_summary = Label.new()
	_summary.position = Vector2(28,225)
	_summary.add_theme_font_size_override("font_size",15)
	_summary.add_theme_color_override("font_outline_color",Color.BLACK)
	_summary.add_theme_constant_override("outline_size",5)
	_summary.hide()
	_layer.add_child(_summary)
	_entry_hint = Label.new()
	_entry_hint.position = Vector2(28,315)
	_entry_hint.text = "Camp / NPC / enemy training: follow signs behind the firing lanes to the right"
	_entry_hint.add_theme_font_size_override("font_size",16)
	_entry_hint.add_theme_constant_override("outline_size",5)
	_entry_hint.hide()
	_layer.add_child(_entry_hint)
	_overlay = ColorRect.new()
	_overlay.color = Color(0.035,0.045,0.035,1.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_overlay)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",150)
	margin.add_theme_constant_override("margin_right",150)
	margin.add_theme_constant_override("margin_top",65)
	margin.add_theme_constant_override("margin_bottom",45)
	_overlay.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	margin.add_child(box)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size",25)
	box.add_child(_heading)
	_resource_strip = ResourceStrip.new()
	# Explicit ink works for both standalone and journal-themed training panels.
	var resource_paper := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e6d5b5")
	paper.set_content_margin_all(10)
	resource_paper.add_theme_stylebox_override("panel",paper)
	box.add_child(resource_paper)
	_resource_strip.ink = Color("493a29")
	_resource_strip.outlined = false
	resource_paper.add_child(_resource_strip)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size.y = 140
	_details.add_theme_font_size_override("font_size",17)
	box.add_child(_details)
	_job_status = Label.new()
	_job_status.add_theme_font_size_override("font_size",16)
	box.add_child(_job_status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_actions = VBoxContainer.new()
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_actions)
	var close := Button.new()
	close.text = "Close / Escape"
	close.custom_minimum_size.y = 40
	close.pressed.connect(close_panel)
	box.add_child(close)
	_overlay.hide()
	_planner_hint = Label.new()
	_planner_hint.position = Vector2(25,90)
	_planner_hint.text = "BUILD PLANNING\nClick the marked west plot to place a rack plan.\nEsc returns to first person.\nUse the planning table to build yourself or assign a civilian."
	_planner_hint.add_theme_font_size_override("font_size",18)
	_planner_hint.add_theme_constant_override("outline_size",4)
	_planner_hint.hide()
	_layer.add_child(_planner_hint)
	_planner = Camera3D.new()
	_planner.projection = Camera3D.PROJECTION_ORTHOGONAL
	_planner.size = 26
	add_child(_planner)
	_planner.position = Vector3(-0.5,27,5)
	_planner.look_at(global_position+Vector3(-0.5,0,5),Vector3.FORWARD)
	for id in stations:
		var label := Label.new()
		label.text = {&"depot":"Quartermaster",&"well":"Well",&"cook":"Cooking",&"food":"Food store",&"armourer":"Armourer",&"ammo":"Ammo store",&"medical":"Medical post",&"shelter":"Shelter upgrade",&"trench":"Trench",&"planning":"Build table",&"hq":"HQ / Rescue",&"combat":"Enemy controls",&"contact":"Contact"}.get(id,stations[id].title)
		label.custom_minimum_size.x = 130
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size",13)
		label.add_theme_constant_override("outline_size",4)
		label.position = _planner.unproject_position(stations[id].global_position)-Vector2(65,20)
		label.hide()
		_layer.add_child(label)
		_map_labels.append(label)

func open_station(station, actor) -> void:
	_actor = actor
	_panel_station = station.station_id
	_panel_resident = &""
	_show_panel()

func open_resident(resident, actor) -> void:
	_actor = actor
	_panel_station = &""
	_panel_resident = resident.resident_id
	_show_panel()

func _show_panel() -> void:
	_prior_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_overlay.show()
	refresh_panel()

func close_panel() -> void:
	_overlay.hide()
	runtime.cancel_player_jobs(PLAYER_WORKER_ID)
	Input.mouse_mode = _prior_mouse

func _button(title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 36
	button.pressed.connect(action)
	_actions.add_child(button)

func refresh_panel() -> void:
	if _overlay == null or not _overlay.visible:
		return
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	_resource_strip.show_stock(runtime.stock.quantities)
	_details.text = "COMMUNAL CAMP STORES\n" + runtime.message + "\nDo tasks yourself, or assign a civilian. Stay here while working yourself; closing cancels and refunds materials. Civilian jobs continue when you leave."
	if _panel_resident != &"":
		_heading.text = "Civilian assignment"
		var record: Dictionary = runtime.residents[_panel_resident]
		_details.text += "\nRole: %s   Current job: %s" % [record.role,record.busy]
		for role in [&"cook",&"builder",&"unassigned"]:
			_button("Assign as " + String(role),runtime.assign_role.bind(_panel_resident,role))
		return
	if not stations.has(_panel_station):
		return
	var station = stations[_panel_station]
	_heading.text = station.title
	match station.kind:
		&"depot":
			_button("Claim training cache (once this session)",runtime.claim_cache)
			_details.text += "\nTreasury: %d rubles, %d lats." % [runtime.stock.count(&"rubles"),runtime.stock.count(&"lats")]
			_button("Deposit carried rubles and lats into the treasury",runtime.deposit_money.bind(player.weapon.state))
		&"contact":
			_details.text += "\nTreasury: %d rubles, %d lats. Fixed prices; goods go to the communal stores." % [runtime.stock.count(&"rubles"),runtime.stock.count(&"lats")]
			for good in runtime.PRICES:
				var offer: Dictionary = runtime.PRICES[good]
				_button("Buy %d %s for %d rubles" % [offer.amount,offer.label.to_lower(),offer.rubles],runtime.buy.bind(good,&"rubles"))
				_button("Buy %d %s for %d lats" % [offer.amount,offer.label.to_lower(),offer.lats],runtime.buy.bind(good,&"lats"))
		&"well": _recipe_button(&"water",_panel_station)
		&"cook": _recipe_button(&"cook",_panel_station)
		&"food":
			_button("Serve one communal meal + water to starting resident",runtime.feed_resident.bind(&"resident_01"))
			_details.text += "\nRaw food %d / Meals %d — both stored communally. No spoilage simulation." % [runtime.stock.count(&"food"),runtime.stock.count(&"meals")]
		&"armourer":
			_details.text += "\nCarried rifle cleanliness %d%%. Service does not clear a jam." % roundi(player.weapon.state.cleanliness*100)
			_recipe_button(&"repair",_panel_station)
		&"ammo":
			_details.text += "\n" + player.weapon.status_text()
			_button("Withdraw 10 loose cartridges",runtime.withdraw_ammo.bind(player.weapon.state,10))
			_button("Deposit 10 loose cartridges",runtime.deposit_ammo.bind(player.weapon.state,10))
		&"medical":
			_details.text += "\nTest patient: bleeding %s / fracture %s / recovery %.0fs" % [runtime.patient.bleeding,runtime.patient.fracture,runtime.patient.recovery]
			for recipe in [&"bandage",&"splint",&"recover"]:
				_recipe_button(recipe,_panel_station)
			_button("Restore training body (debug)",_restore_player)
		&"shelter": _recipe_button(&"upgrade",_panel_station)
		&"trench": _recipe_button(&"dig",_panel_station)
		&"planning":
			_button("Enter overhead build view / place rack plans",start_planning)
			for id in runtime.plans:
				if runtime.plans[id].status == &"planned":
					_recipe_button(&"rack",id)
				if runtime.jobs.has(id):
					if runtime.jobs[id].worker != &"":
						_button("Assist " + String(id),runtime.assist.bind(id))
					_button("Cancel " + String(id),runtime.cancel_job.bind(id))
		&"hq":
			_details.text += "\nRESCUE EXERCISE ONLY: active %s / pending %d / residents %d / completed objectives %d" % [runtime.exercise_active,runtime.pending_recruits.size(),runtime.residents.size(),runtime.quests_completed]
			_button("Begin rescue exercise / reset enemies",_begin_exercise)
			_button("Safe return (secures pending civilians)",runtime.resolve_exercise.bind(true))
			_button("Group-death result (lose pending civilians)",runtime.resolve_exercise.bind(false))
			_details.text += "
MISSION-PLANNING TABLE: choose a region and missions; the outing returns here. Camp work in this session does not carry over yet."
			_button("Open the mission map",_leave_camp.bind(MISSION_MAP))
			_button("Combat arena (training outing)",_leave_camp.bind(COMBAT_ARENA))
		&"combat":
			_details.text += "\nBody %s. Enemies fire only while the bout is armed.\nEnemy weapons are flash proxies. Sprite default; MPFB comparison has frozen pose/clothing issues." % _body_text()
			_button("Arm enemies / start exposure test",arm_bout)
			_button("Reset enemies / corpses / blood",reset_enemies)
			_button("Compare first enemy: %s (resets bout)" % ("MPFB" if use_mpfb_enemy else "Sprite"),_toggle_enemy_comparison)
			_button("Toggle non-graphic blood: %s" % blood_enabled,_toggle_blood)
			_button("Simulate nearby teammate (dev, allows downed state): %s" % player.has_teammate_nearby,_toggle_teammate)
	if runtime.jobs.has(_panel_station):
		if runtime.jobs[_panel_station].worker != &"":
			_button("Foreman assistance (once per civilian job)",runtime.assist.bind(_panel_station))
		_button("Cancel job / refund reserved supplies",runtime.cancel_job.bind(_panel_station))

## Leaves for the mission map or the combat arena; MissionLaunch remembers the way back.
func _leave_camp(path: String) -> void:
	close_panel()
	MissionLaunch.leave_camp(get_tree(), path)

func _recipe_button(recipe: StringName, station: StringName) -> void:
	var data: Dictionary = runtime.RECIPES[recipe]
	var description := "%s — %s — %.1fs" % [data.label,_cost_text(data.cost),data.seconds]
	_button("Do it yourself: " + description,_start_job.bind(recipe,station,true))
	if data.role != &"":
		_button("Assign civilian %s: %s" % [data.role,description],_start_job.bind(recipe,station,false))

func _start_job(recipe: StringName, station: StringName, do_it_yourself: bool = true) -> void:
	runtime.start_job(recipe,station,runtime.request_id(),player.weapon.state,PLAYER_WORKER_ID if do_it_yourself else &"")

func _can_player_work(player_id: StringName, station_id: StringName) -> bool:
	if player_id != PLAYER_WORKER_ID or not _overlay.visible or planning or _panel_resident != &"":
		return false
	var work_station: StringName = &"planning" if runtime.plans.has(station_id) else station_id
	return _panel_station == work_station and stations.has(work_station) and player.global_position.distance_to(stations[work_station].global_position) <= 3.0

func _restore_player() -> void:
	player.restore_for_drill()
	runtime.message = "Training body restored; not a campaign medical treatment"
	refresh_panel()

func _toggle_teammate() -> void:
	player.has_teammate_nearby = not player.has_teammate_nearby
	refresh_panel()

func arm_bout() -> void:
	_bout_active = true
	for enemy in enemies:
		if enemy.state != &"dead":
			enemy.active = true
	close_panel()
	_teleport(Vector3(0,0.02,-2))

func _toggle_blood() -> void:
	blood_enabled = not blood_enabled
	for enemy in enemies:
		enemy.blood_enabled = blood_enabled
	refresh_panel()

func start_planning() -> void:
	_overlay.hide()
	planning = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.weapon.hide()
	if player.body_visual != null:
		player.body_visual.set_first_person(false)
	world.get_node("HUD").hide()
	_planner_hint.show()
	for label in _map_labels:
		label.show()
	_planner.make_current()

func stop_planning() -> void:
	planning = false
	player.camera.make_current()
	player.weapon.show()
	if player.body_visual != null:
		player.body_visual.set_first_person(true)
	world.get_node("HUD").show()
	_planner_hint.hide()
	for label in _map_labels:
		label.hide()
	Input.mouse_mode = _prior_mouse

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (planning or _overlay.visible):
		if planning:
			stop_planning()
		else:
			close_panel()
		get_viewport().set_input_as_handled()
	elif planning and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var plane := Plane(Vector3.UP,0)
		var at = plane.intersects_ray(_planner.project_ray_origin(event.position),_planner.project_ray_normal(event.position))
		if at != null:
			var local: Vector3 = at-global_position
			runtime.place_plan(StringName("rack_"+runtime.request_id()),Vector2(snappedf(local.x,1),snappedf(local.z,1)))
		get_viewport().set_input_as_handled()

func _teleport(at: Vector3) -> void:
	player.global_position = global_position+at
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO

func _process(delta: float) -> void:
	if runtime == null:
		return
	_sync_world()
	if planning:
		_planner_hint.text = "BUILD PLANNING\nClick west plot to place a rack plan. Esc returns.\nBuild yourself or assign a civilian at the planning table.\nTimber %d / Parts %d / Plans %d / Residents %d\n%s" % [runtime.stock.count(&"timber"),runtime.stock.count(&"parts"),runtime.plans.size(),runtime.residents.size(),runtime.message]
	_entry_hint.visible = debug_diagnostics_visible and player.global_position.x < 29 and not _overlay.visible and not planning
	_summary.visible = debug_diagnostics_visible and player.global_position.x > 29 and not _overlay.visible and not planning
	if _overlay.visible:
		var lines: Array[String] = []
		for id in runtime.jobs:
			lines.append("%s — %s: %.1fs remaining" % ["You are working" if runtime.jobs[id].player != &"" else "Civilian / station",runtime.RECIPES[runtime.jobs[id].recipe].label,runtime.jobs[id].left])
		_job_status.text = "\n".join(lines)
	if _summary.visible:
		var states: Array[String] = []
		for enemy in enemies:
			states.append("%s: torso %.0f / %s" % [enemy.name,enemy.body.health[&"torso"],enemy.state])
		_summary.text = runtime.message+"\nBody %s | Jobs %d | Residents %d | Pending %d\n" % [_body_text(),runtime.jobs.size(),runtime.residents.size(),runtime.pending_recruits.size()] + " / ".join(states)

func _sync_world() -> void:
	for id in runtime.residents:
		if not resident_nodes.has(id):
			_spawn_resident(id,Vector3(2,0,9),false)
		elif resident_nodes[id].rescuable:
			var slot: int = runtime.residents.keys().find(id)-1
			resident_nodes[id].arrive_at(global_position+Vector3(2+slot*2,0,9))
	for id in runtime.plans:
		var plan: Dictionary = runtime.plans[id]
		if _plan_views.get(id,{}).get("status",&"") == plan.status:
			continue
		if _plan_views.has(id):
			_plan_views[id].node.queue_free()
		var marker := Node3D.new()
		marker.position = Vector3(plan.at.x,0,plan.at.y)
		add_child(marker)
		var color := Color(0.3,0.65,0.72,0.4) if plan.status != &"complete" else Color(0.4,0.29,0.18)
		_box(marker,"Rack",Vector3(0,0.65,0),Vector3(1.6,1.3,0.7),color,plan.status==&"complete")
		_label(marker,String(plan.status),Vector3(0,1.8,0))
		_plan_views[id] = {"status":plan.status,"node":marker}
	if _shelter_version != runtime.shelter_tier:
		_shelter_version = runtime.shelter_tier
		if is_instance_valid(_shelter):
			_shelter.queue_free()
		_shelter = Node3D.new()
		_shelter.position = Vector3(9,0,3)
		add_child(_shelter)
		for side in [-1,1]:
			var roof := _box(_shelter,"CanvasRoof",Vector3(side*0.75,1.6,0),Vector3(2.0,0.08,2.5),Color(0.35,0.34,0.23))
			roof.rotation.z = -side*0.65
			if runtime.shelter_tier > 0:
				_box(_shelter,"TimberWall",Vector3(side*1.4,0.65,0),Vector3(0.12,1.3,2.5),Color(0.36,0.27,0.17),true)
	if runtime.trench_complete and not _trench_version:
		_trench_version = true
		_trench = Node3D.new()
		_trench.position = Vector3(13,0,-2)
		add_child(_trench)
		_box(_trench,"AuthoredTrench",Vector3(0,0.01,0),Vector3(2.5,0.02,2),Color(0.09,0.07,0.04))
		for side in [-1,1]:
			_box(_trench,"EarthBank",Vector3(side*1.35,0.2,0),Vector3(0.3,0.4,2.1),Color(0.26,0.19,0.1),true)

func _box(parent: Node, node_name: String, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = node_name
	node.position = at
	parent.add_child(node)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = material
	mesh.mesh = box
	node.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)
	return node

func _label(parent: Node, text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 38
	label.pixel_size = 0.0025
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


func _begin_exercise() -> void:
	if runtime.begin_exercise():
		reset_enemies()
		var available := false
		for id in resident_nodes:
			if resident_nodes[id].rescuable and resident_nodes[id].visible:
				available = true
		if not available:
			_spawn_resident(StringName("rescued_"+runtime.request_id()),Vector3(-12,0,-13),true)

func _cost_text(cost: Dictionary) -> String:
	var entries: Array[String] = []
	for id in cost:
		entries.append("%d %s" % [cost[id],id])
	return ", ".join(entries) if not entries.is_empty() else "no materials"
func _physics_process(delta: float) -> void:
	if runtime != null:
		runtime.advance(delta)

func _completion_clear(recipe: StringName, station: StringName) -> bool:
	if recipe not in [&"rack",&"upgrade"]:
		return true
	var shape := BoxShape3D.new()
	var center := Vector3(9,1.3,3)
	shape.size = Vector3(3,2.5,3)
	if recipe == &"rack":
		var at: Vector2 = runtime.plans[station].at
		center = Vector3(at.x,0.7,at.y)
		shape.size = Vector3(1.6,1.3,0.7)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,global_position+center)
	query.collision_mask = 3
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _body_text() -> String:
	var parts: Array[String] = [String(player.body.state)]
	for zone in player.body.ZONES:
		parts.append("%s %.0f" % [zone, player.body.health[zone]])
	return " ".join(parts)
