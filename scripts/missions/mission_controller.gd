extends Node
## Plays any MissionDefinition in the scene it is added to. It places each objective item at a
## random ObjectiveSpot with the objective's tag, reads the MissionExit markers, runs MissionRun
## for the mission players, and shows the shared objective HUD and summary screen. A map hosts a
## mission by placing markers and adding this node; nothing here belongs to one mission.
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const MissionReport = preload("res://scripts/missions/mission_report.gd")
const ObjectiveSpot = preload("res://scripts/missions/objective_spot.gd")
const MissionExit = preload("res://scripts/missions/mission_exit.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const GroundEquipment = preload("res://scripts/inventory/ground_equipment.gd")
const SummaryScreen = preload("res://ui/missions/mission_summary_screen.gd")
const MissionHud = preload("res://ui/missions/mission_hud.gd")
const ITEM_GROUP := &"mission_items"
## A participant's outing ended (extracted, killed or timed out); report from MissionReport.
signal participant_ended(player, report: Dictionary)
## Nobody is left in the area.
signal mission_over(run)
## The local player pressed the summary screen's button.
signal continue_requested

@export var definition: Resource
var run
var players: Array = []
var local_player: Node
var summary_screen
var hud

## Holder for objective items lying on the ground, in the shape GroundEquipment expects.
class GroundHolder extends RefCounted:
	var inventory
	var busy: StringName = &""

## Starts a fresh deployment for these players; the local one sees the HUD and summary.
func start(mission_players: Array, local: Node) -> void:
	players = mission_players
	local_player = local
	for old in get_tree().get_nodes_in_group(ITEM_GROUP):
		old.queue_free()
	for objective in definition.objectives:
		if objective.kind != &"carry_out": continue
		var spots := get_tree().get_nodes_in_group(ObjectiveSpot.GROUP).filter(func(spot): return spot.tag == objective.spot_tag)
		if spots.is_empty():
			push_warning("Mission %s: no ObjectiveSpot tagged %s" % [definition.id, objective.spot_tag])
			continue
		place_item(objective.item_id, spots.pick_random().global_position)
	var exits: Array = get_tree().get_nodes_in_group(MissionExit.GROUP).map(func(exit): return exit.area())
	run = MissionRun.new(definition, exits)
	for player in players:
		run.add_participant(participant_id(player), str(player.name), player.weapon.state.inventory, player.body)
		if not player.casualty.is_connected(_casualty):
			player.casualty.connect(_casualty)
	_ensure_ui()
	hud.run = run
	hud.participant = participant_id(local)
	summary_screen.hide()

static func participant_id(player: Node) -> StringName:
	return StringName(str(player.name))

## An item lying at a point as an ordinary ground pickup with its own identity.
func place_item(item_id: StringName, at: Vector3) -> Node3D:
	var holder := GroundHolder.new()
	holder.inventory = Inventory.new()
	holder.inventory.items.clear()
	holder.inventory.active_weapon_id = &""
	var item = holder.inventory.create_supply(item_id)
	item.location.position = at
	var pickup := GroundEquipment.new()
	pickup.weapon_state = holder
	pickup.item_id = item.id
	pickup.add_to_group(ITEM_GROUP)
	get_parent().add_child(pickup)
	pickup.global_position = at
	return pickup

func _physics_process(delta: float) -> void:
	if run == null or run.is_over():
		return
	var positions := {}
	for player in players:
		if is_instance_valid(player) and player.body.is_alive():
			positions[participant_id(player)] = player.global_position
	var before := {}
	for id in run.participants:
		before[id] = run.state_of(id)
	run.advance(delta, positions)
	for player in players:
		var id := participant_id(player)
		if before[id] == MissionRun.ACTIVE and run.state_of(id) != MissionRun.ACTIVE:
			_ended(player)

func _casualty(player, outcome: StringName) -> void:
	if run == null or outcome != &"killed" or run.state_of(participant_id(player)) != MissionRun.ACTIVE:
		return
	run.participant_killed(participant_id(player))
	_ended(player)

func _ended(player) -> void:
	var report := MissionReport.build(run, participant_id(player))
	participant_ended.emit(player, report)
	if player == local_player:
		summary_screen.present(report)
		if DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if run.is_over():
		mission_over.emit(run)

func _ensure_ui() -> void:
	if summary_screen != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "MissionUI"
	layer.layer = 20
	add_child(layer)
	hud = MissionHud.new()
	hud.name = "Objectives"
	layer.add_child(hud)
	summary_screen = SummaryScreen.new()
	summary_screen.name = "Summary"
	summary_screen.continue_requested.connect(func(): continue_requested.emit())
	layer.add_child(summary_screen)
