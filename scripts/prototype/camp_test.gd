extends Node3D

const CampStock = preload("res://scripts/state/camp_stock.gd")
var stock = CampStock.new()

@onready var player: CharacterBody3D = $Player
@onready var stock_label: Label = $HUD/Stock
@onready var prompt_label: Label = $HUD/Prompt
@onready var status_label: Label = $HUD/Status


func _ready() -> void:
	for pickup_name in ["FoodPickup", "WaterPickup", "MedicinePickup"]:
		get_node(pickup_name).collected.connect(stock.add)
	stock.changed.connect(_update_stock)
	_update_stock()


func _process(_delta: float) -> void:
	var mouse_free := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	prompt_label.text = "Click to look around" if mouse_free else player.get_interaction_prompt()
	status_label.text = "Left: obstacle course   Far left: walking civilian   Right: firing lane"
	$HUD/MovementState.text = player.movement_state + (" - " + player.traversal_message if player.traversal_message != "" else "")
	$HUD/WeaponStatus.text = player.weapon.status_text()
	$HUD/Crosshair.visible = not player.is_aiming and player.weapon.aim_fraction < 0.05


func _update_stock() -> void:
	stock_label.text = "COMMUNAL STOCK\nFood  %d     Water  %d     Medicine  %d" % [stock.count(&"food"), stock.count(&"water"), stock.count(&"medicine")]
