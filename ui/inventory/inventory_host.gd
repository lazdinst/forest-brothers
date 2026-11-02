extends Node
## Opens the carried-inventory screen over any scene with a player. Training and the combat
## arena share this one owner, so every place with a player gets the same inventory.
## Only the given world subtree is suspended (never SceneTree.paused); the mouse is freed
## while open and restored after. This host itself always processes so Tab can close it.
signal opened
signal closed
const InventoryScene = preload("res://ui/inventory/inventory_view.tscn")
const InventorySnapshot = preload("res://ui/inventory/inventory_snapshot.gd")
## Subtree suspended while the inventory is open.
var world: Node
var player: Node
## Optional () -> bool. Return false to refuse opening, e.g. while a camp panel is in use.
var can_open: Callable
## The startup router keeps its own Tab precedence and turns this off.
var handle_tab := true
var is_open := false
var view
var _layer: CanvasLayer
var _previous_process_mode := Node.PROCESS_MODE_INHERIT
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bodies find the host serving the player who searches them.
	add_to_group(&"inventory_host")

## loot: an optional searched body shown beside the player's own gear.
func open(loot = null) -> bool:
	if is_open or not is_instance_valid(player) or not is_instance_valid(world): return false
	if can_open.is_valid() and not can_open.call(): return false
	player.weapon.prepare_inventory()
	_previous_process_mode = world.process_mode
	_previous_mouse_mode = Input.mouse_mode
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_layer = CanvasLayer.new()
	_layer.layer = 110
	add_child(_layer)
	view = InventoryScene.instantiate()
	view.data = InventorySnapshot.from_training(player)
	view.loot = loot
	view.drop_requested.connect(player.weapon.drop_inventory_item)
	_layer.add_child(view)
	view.closed.connect(close)
	is_open = true
	opened.emit()
	return true

func close() -> void:
	if not is_open: return
	is_open = false
	remove_child(_layer)
	_layer.queue_free()
	view = null
	if is_instance_valid(world): world.process_mode = _previous_process_mode
	Input.mouse_mode = _previous_mouse_mode
	closed.emit()

func _input(event: InputEvent) -> void:
	if not handle_tab or not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB): return
	if is_open: close()
	elif not open(): return
	get_viewport().set_input_as_handled()
