extends Node3D

const CampStock = preload("res://scripts/state/camp_stock.gd")
const ResourceStrip = preload("res://ui/components/resource_strip.gd")
# Generous reset-on-run training supplies, not campaign starting balance.
const TRAINING_STOCK = {&"food":100,&"water":100,&"medicine":30,&"meals":30,&"timber":200,&"parts":60,&"cloth":80,&"rounds":500}
var stock = CampStock.new()
var resource_strip
var debug_overlay

@onready var player: CharacterBody3D = $Player
@onready var stock_label: Label = $HUD/Stock
@onready var prompt_label: Label = $HUD/Prompt
@onready var status_label: Label = $HUD/Status


func _ready() -> void:
	stock.try_exchange({},TRAINING_STOCK)
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


func _process(_delta: float) -> void:
	var mouse_free := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	prompt_label.text = "Click to look around" if mouse_free else player.get_interaction_prompt()
	if debug_overlay.enabled:
		status_label.text = "Left: course / civilian   Right: range   Behind-left: forest trench"
		$HUD/MovementState.text = player.movement_state + (" - " + player.traversal_message if player.traversal_message != "" else "")
		$HUD/WeaponStatus.text = player.weapon.status_text()
	$HUD/Crosshair.visible = not player.is_aiming and player.weapon.aim_fraction < 0.05


func _update_stock() -> void:
	resource_strip.show_stock(stock.quantities)
