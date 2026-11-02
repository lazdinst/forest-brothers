extends Node
## Hosts NPC interactions in one scene, for any number of NPCs: registers each NPC body with its
## definition (so F shows "Interact — name"), keeps every NPC's relationship and memory state
## (saved with the world), and runs the interaction menu, dialogue window and trade window. The
## scene supplies the player, the camp rules and a context provider; nothing here names an NPC.
## While a window is open the player stands still and the mouse is free; closing restores both.
const State = preload("res://scripts/npc/npc_state.gd")
const Database = preload("res://scripts/npc/dialogue_database.gd")
const Controller = preload("res://scripts/npc/dialogue_controller.gd")
const Trade = preload("res://scripts/npc/npc_trade.gd")
const MenuWindow = preload("res://ui/npc/npc_interaction_menu.gd")
const DialogueWindow = preload("res://ui/npc/dialogue_window.gd")
const TraderWindow = preload("res://ui/camp/trader_window.gd")
signal ui_opened
signal ui_closed
var player: Node
## CampRuntime: treasury, sale values and selling.
var runtime
## () -> Dictionary: world context for dialogue conditions (see DialogueRules).
var context_provider: Callable
## () -> Array of inventories bought or given items may go to, in order.
var item_destinations: Callable
## () -> Array of {"label", "inventory"} the player may sell from.
var sell_sources: Callable
var definitions := {}
var states := {}
var databases := {}
var menu
var dialogue
var trader
var controller
var trade
var current: StringName = &""
var _was_open := false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	menu = MenuWindow.new()
	layer.add_child(menu)
	menu.action_chosen.connect(_menu_action)
	dialogue = DialogueWindow.new()
	layer.add_child(dialogue)
	dialogue.closed.connect(_back_to_menu)
	trader = TraderWindow.new()
	trader.hide()
	layer.add_child(trader)
	trader.closed.connect(_back_to_menu)

## Makes an NPC body interactable. The body needs `prompt` and `action` (CampInteractable or
## the old man's script); its state starts empty unless restore() brings a saved one.
func register(body: Node, definition) -> void:
	definitions[definition.id] = definition
	if not states.has(definition.id): states[definition.id] = State.new()
	body.prompt = "F  Interact — " + definition.display_name
	body.action = func(_actor): open(definition.id)

func state_of(id: StringName):
	return states.get(id)

func is_open() -> bool:
	return menu.visible or dialogue.visible or trader.visible

## The interaction menu for one NPC.
func open(id: StringName) -> void:
	if not definitions.has(id): return
	current = id
	dialogue.hide()
	trader.hide()
	menu.present(definitions[id])
	_set_open(true)

func _menu_action(action: StringName) -> void:
	match action:
		&"talk": talk()
		&"trade": open_trade()
		_: close()

func talk() -> void:
	var definition = definitions[current]
	if not databases.has(current): databases[current] = Database.load_file(definition.dialogue_path)
	controller = Controller.new(definition, states[current], databases[current])
	controller.ended.connect(close)
	controller.open_requested.connect(func(action: String): if action == "trade": open_trade())
	controller.gifts_requested.connect(_give)
	menu.hide()
	controller.start(_context())
	dialogue.bind(controller, definition)

func open_trade() -> void:
	var definition = definitions[current]
	if definition.trade_stock.is_empty() or runtime == null:
		close()
		return
	trade = Trade.new(definition, states[current], runtime)
	trade.destinations = item_destinations.call() if item_destinations.is_valid() else []
	trade.restock(int(_context().get("outings", 0)))
	trader.runtime = runtime
	trader.trade = trade
	trader.sources = sell_sources.call() if sell_sources.is_valid() else []
	menu.hide()
	dialogue.hide()
	trader.refresh()
	trader.show()

func close() -> void:
	menu.hide()
	dialogue.hide()
	trader.hide()
	_set_open(false)

func _back_to_menu() -> void:
	open(current)

func _give(supply_ids: Array) -> void:
	var giver = Trade.new(definitions[current], states[current], runtime)
	giver.destinations = item_destinations.call() if item_destinations.is_valid() else []
	for id in supply_ids: giver.give(id)

func _context() -> Dictionary:
	return context_provider.call() if context_provider.is_valid() else {}

func _set_open(open_now: bool) -> void:
	if open_now == _was_open: return
	_was_open = open_now
	if player != null: player.process_mode = Node.PROCESS_MODE_DISABLED if open_now else Node.PROCESS_MODE_INHERIT
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open_now else Input.MOUSE_MODE_CAPTURED
	if open_now: ui_opened.emit()
	else: ui_closed.emit()

## Every NPC's state for the world save.
func encode() -> Dictionary:
	var saved := {}
	for id in states: saved[str(id)] = states[id].encode()
	return saved

func restore(saved: Dictionary) -> void:
	for id in saved:
		var state = State.new()
		state.restore(saved[id])
		states[StringName(id)] = state
