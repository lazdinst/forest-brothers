extends StaticBody3D
## A dead carrier's gear, left on the body. F opens it beside the player's own inventory
## through whichever InventoryHost serves that player. Searching reveals one item at a time
## and only advances while the body is open, like Tarkov's search.
signal search_progressed
## Placeholder pace (owner asked for a short search delay); not approved balance.
const SEARCH_SECONDS_PER_ITEM := 0.8
## The body's own carrier inventory: rifle in its equipped slot, spare magazines in pockets.
var inventory
## GroundEquipment refuses transfers while its holder is mid-action; a body never is.
var busy: StringName = &""
## Top-level items in reveal order (rifle first, then pockets left to right).
var order: Array[StringName] = []
var revealed := 0
var _search_time := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4,0.35,1.4)
	shape.shape = box
	shape.position.y = 0.18
	add_child(shape)
	if order.is_empty(): build_order()

func build_order() -> void:
	order.clear()
	var listed: Array = []
	for item in inventory.items.values():
		if inventory.carried(item) and item.location.kind in [&"equipped",&"pocket",&"pack",&"worn"]: listed.append(item)
	listed.sort_custom(func(a, b): return [a.location.kind != &"equipped",a.location.slot] < [b.location.kind != &"equipped",b.location.slot])
	for item in listed: order.append(item.id)

func get_prompt() -> String:
	return "F  Search body" if searching() else "F  Loot body"

func interact(actor: Node) -> void:
	for host in get_tree().get_nodes_in_group(&"inventory_host"):
		if host.player == actor:
			host.open(self)
			return

func searching() -> bool:
	return revealed < order.size()

## Fraction of the item currently being searched, or -1 when everything is revealed.
func search_progress() -> float:
	return _search_time / SEARCH_SECONDS_PER_ITEM if searching() else -1.0

func advance_search(delta: float) -> void:
	if not searching(): return
	_search_time += delta
	var before := revealed
	while _search_time >= SEARCH_SECONDS_PER_ITEM and searching():
		_search_time -= SEARCH_SECONDS_PER_ITEM
		revealed += 1
	if not searching(): _search_time = 0.0
	if revealed != before: search_progressed.emit()

func is_revealed(id: StringName) -> bool:
	var index := order.find(id)
	return index >= 0 and index < revealed and inventory.items.has(id)

## Revealed items still on the body.
func visible_items() -> Array:
	var shown: Array = []
	for index in range(revealed):
		if inventory.items.has(order[index]): shown.append(inventory.items[order[index]])
	return shown
