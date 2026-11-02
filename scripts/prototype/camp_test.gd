extends Node3D

const CampStock = preload("res://scripts/state/camp_stock.gd")
const ResourceStrip = preload("res://ui/components/resource_strip.gd")
const GameSession = preload("res://scripts/state/game_session.gd")
## Seconds between camp autosaves while a character plays a world.
const AUTOSAVE_SECONDS := 30.0
# Generous reset-on-run training supplies, not campaign starting balance.
const TRAINING_STOCK = {&"food":100,&"water":100,&"medicine":30,&"meals":30,&"timber":200,&"parts":60,&"cloth":80,&"rounds":500}
var stock = CampStock.new()
var resource_strip
var debug_overlay
var _autosave_left := AUTOSAVE_SECONDS

@onready var player: CharacterBody3D = $Player
@onready var stock_label: Label = $HUD/Stock
@onready var prompt_label: Label = $HUD/Prompt
@onready var status_label: Label = $HUD/Status


func _ready() -> void:
	stock.try_exchange({},TRAINING_STOCK)
	_load_session()
	stock_label.hide()
	resource_strip = ResourceStrip.new()
	resource_strip.name = "ResourceStock"
	resource_strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	resource_strip.position = Vector2(-595,26)
	$HUD.add_child(resource_strip)
	for pickup_name in ["FoodPickup", "WaterPickup", "MedicinePickup"]:
		get_node(pickup_name).collected.connect(stock.add)
	stock.changed.connect(_update_stock)
	_update_stock()
	var instrument = preload("res://ui/components/tactical_movement_hud.gd").new()
	instrument.name = "TacticalMovement"
	instrument.player = player
	$HUD.add_child(instrument)
	debug_overlay = preload("res://ui/components/training_debug_overlay.gd").new()
	debug_overlay.world = self
	add_child(debug_overlay)


## Playing a world (not Training): its saved camp replaces the starting stores, the character's
## equipment replaces the standard kit, and leaving the camp saves both.
func _load_session() -> void:
	if not GameSession.active(): return
	GameSession.apply_equipment(player)
	# The training course installs the camp systems annex deferred; restore after it exists.
	call_deferred("_restore_camp")
	tree_exiting.connect(save_session)

func _restore_camp() -> void:
	var camp: Dictionary = GameSession.camp_state()
	if not camp.is_empty() and has_node("SystemsAnnex"):
		$SystemsAnnex.runtime.restore(camp)

## Saves the camp into the world and the character's equipment. Safe to call at any time.
func save_session() -> void:
	if not GameSession.active(): return
	GameSession.save_world($SystemsAnnex.runtime.encode() if has_node("SystemsAnnex") else {})
	GameSession.save_equipment(player)

func _process(delta: float) -> void:
	if GameSession.active():
		_autosave_left -= delta
		if _autosave_left <= 0.0:
			_autosave_left = AUTOSAVE_SECONDS
			save_session()
	var mouse_free := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	prompt_label.text = "Click to look around" if mouse_free else player.get_interaction_prompt()
	if debug_overlay.enabled:
		status_label.text = "Left: course / civilian   Right: range   Behind-left: forest trench"
		$HUD/MovementState.text = player.movement_state + (" - " + player.traversal_message if player.traversal_message != "" else "")
		$HUD/WeaponStatus.text = player.weapon.status_text()
	$HUD/Crosshair.visible = not player.is_aiming and player.weapon.aim_fraction < 0.05


func _update_stock() -> void:
	resource_strip.show_stock(stock.quantities)
