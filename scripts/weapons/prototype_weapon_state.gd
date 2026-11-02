extends RefCounted
## Timed weapon rule owner; the inventory contains every physical cartridge.
const DEFAULT_DEFINITION = preload("res://weapons/svt_inspired_training.tres")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
var definition: Resource
var inventory
# Read-only legacy views for existing camp/test callers. Never ammunition authority.
var magazines: Array[int]:
	get:
		var counts: Array[int] = []
		for id in inventory.initial_magazine_ids:
			var mag = inventory.magazine(id)
			counts.append(mag.rounds.size() if mag != null else 0)
		return counts
var loaded_magazine: int:
	get: return inventory.initial_magazine_ids.find(inventory.weapon().inserted_magazine_id) if inventory.weapon() != null else -1
var loose_rounds: int:
	get: return inventory.loose_count(inventory.primary_ammo_id)
	set(value):
		var difference: int = value - loose_rounds
		if difference > 0:
			var added: bool = inventory.add_loose(difference)
			assert(added, "Cartridge transfer needs free inventory space")
		elif difference < 0:
			var removed: bool = inventory.remove_loose(-difference)
			assert(removed, "Insufficient physical cartridges")
var cleanliness: float:
	get: return inventory.weapon().condition if inventory.weapon() != null else 0.0
	set(value):
		if inventory.weapon() != null: inventory.weapon().condition = clampf(value,0,1)
var jammed: bool:
	get: return inventory.weapon().jammed if inventory.weapon() != null else false
	set(value):
		if inventory.weapon() != null: inventory.weapon().jammed = value
var busy: StringName = &""
var time_left := 0.0
var action_duration := 1.0
var cooldown := 0.0
var message := "Chamber empty — K to chamber"
var revision := 0
var repeat_pack := false
var target_magazine_id: StringName
var target_stack_id: StringName
var _action_committed := false
var _clip: Resource

func _init(content: Resource = DEFAULT_DEFINITION) -> void:
	definition = content
	assert(definition.validation_error() == "", definition.validation_error())
	inventory = Inventory.new(definition.weapon_id,definition.capacity,definition.initial_loaded,definition.initial_spare,definition.initial_loose,&"",definition.ammo_type_id,definition.caliber,definition.magazine_type_id,definition.ammo_display_name)
	inventory.changed.connect(_inventory_changed)

func _inventory_changed() -> void: revision += 1

func total_rounds() -> int: return inventory.total_rounds()
func jam_probability() -> float: return 0.002 + pow(1.0-cleanliness,2.0)*0.3
func equipped() -> bool: return inventory.equipped()

func spare_id() -> StringName:
	for item in inventory.items.values():
		if item is Inventory.MagazineInstance and inventory.carried(item) and item.location.kind != &"magwell": return item.id
	return &""

func stack_for(magazine_id: StringName) -> StringName:
	for item in inventory.items.values():
		if item is Inventory.AmmoStack and inventory.carried(item) and inventory.compatible(inventory.magazine(magazine_id),item.ammo_type_id): return item.id
	return &""

func request_action(action: StringName, item_id: StringName = &"", stack_id: StringName = &"", continuous := false) -> bool:
	if busy != &"": return false
	target_magazine_id = item_id
	target_stack_id = stack_id
	repeat_pack = continuous and action in [&"pack",&"unload"]
	return start_action(action)

func start_action(action: StringName) -> bool:
	if busy != &"": return false
	if not equipped() and action in [&"reload",&"remove_magazine",&"chamber",&"eject_chamber",&"clean",&"clear"]: return reject("Equip a rifle first")
	var clip = definition.get_clip(action)
	if clip == null: return false
	if action in [&"reload",&"pack",&"unload"]:
		if target_magazine_id == &"": target_magazine_id = spare_id()
		var mag = inventory.magazine(target_magazine_id)
		if mag == null or not inventory.carried(mag) or mag.location.kind == &"magwell": return reject("Select a carried magazine")
		if action == &"pack":
			if target_stack_id == &"" or not inventory.items.has(target_stack_id): target_stack_id = stack_for(mag.id)
			if target_stack_id == &"" or mag.rounds.size() >= mag.capacity: return reject("Magazine full or no compatible cartridges")
		if action == &"unload" and mag.rounds.is_empty(): return reject("Magazine is empty")
	if action == &"inspect" and target_magazine_id == &"": target_magazine_id = inventory.weapon().inserted_magazine_id if equipped() else &""
	if action == &"inspect" and inventory.magazine(target_magazine_id) == null: return reject("Select a magazine to inspect")
	if action == &"clear" and not jammed: return false
	if action == &"chamber" and inventory.weapon().chambered_round != null: return reject("Chamber is already loaded")
	_clip = clip
	action_duration = clip.duration
	busy = action
	time_left = action_duration
	_action_committed = false
	message = String(action).capitalize()
	revision += 1
	return true

func action_progress() -> float: return clampf(1.0-time_left/action_duration,0,1)

func cancel_action() -> void:
	busy = &""
	time_left = 0
	_clip = null
	repeat_pack = false
	target_magazine_id = &""
	target_stack_id = &""
	message = "Action stopped"
	revision += 1

func cancel_packing() -> void:
	if busy == &"pack" and not repeat_pack: cancel_action()

func advance(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if busy == &"": return
	time_left = maxf(0,time_left-delta)
	if not _action_committed and action_progress()+0.00001 >= _clip.commit_at:
		_commit_action()
		_action_committed = true
	if time_left > 0: return
	var finished := busy
	busy = &""
	_clip = null
	if repeat_pack and finished in [&"pack",&"unload"] and start_action(finished): return
	repeat_pack = false
	target_magazine_id = &""
	target_stack_id = &""
	revision += 1

func _commit_action() -> void:
	var success := true
	match busy:
		&"pack": success = inventory.load_round(target_magazine_id,target_stack_id)
		&"unload": success = inventory.unload_round(target_magazine_id)
		&"reload": success = inventory.insert_magazine(target_magazine_id)
		&"remove_magazine": success = inventory.remove_magazine()
		&"chamber": success = inventory.chamber()
		&"eject_chamber": success = inventory.eject_chamber()
		&"inspect": success = inventory.inspect_magazine(target_magazine_id)
		&"clear": jammed = false
		&"clean": cleanliness = 1
	if not success:
		message = inventory.error
		repeat_pack = false
	elif busy == &"inspect": message = inventory.knowledge(target_magazine_id)
	else: message = "JAMMED — J to clear" if jammed else String(busy).capitalize()+" complete"
	revision += 1

func try_fire(roll: float) -> bool:
	if busy != &"" or cooldown > 0 or not equipped(): return false
	if jammed: return reject("JAMMED — J to clear")
	if inventory.weapon().chambered_round == null: return reject("Chamber empty — K to chamber")
	if roll < jam_probability():
		jammed = true
		return reject("JAMMED — J to clear")
	if not inventory.consume_shot(): return false
	cleanliness = maxf(0,cleanliness-0.008)
	cooldown = definition.fire_interval
	message = "Fired"
	revision += 1
	return true

func move_item(id: StringName, kind: StringName, slot: int) -> bool:
	if busy != &"": return reject("Finish or cancel the current action first")
	if not inventory.move_item(id,Inventory.Location.new(kind,inventory.owner_id,slot)): return reject(inventory.error)
	message = "Item moved"
	return true

func reject(text: String) -> bool:
	message = text
	revision += 1
	return false

func encode() -> Dictionary:
	return {"version":1,"weapon_id":str(definition.weapon_id),"inventory":inventory.encode()}

func restore(snapshot: Dictionary) -> bool:
	if snapshot.get("version") != 1 or snapshot.get("weapon_id") != str(definition.weapon_id) or not snapshot.get("inventory") is Dictionary: return false
	if not inventory.restore(snapshot.inventory): return false
	cancel_action()
	message = "Equipment restored"
	return true

func save_equipment(path: String) -> bool:
	# Explicit equipment snapshot API for the future campaign save owner. No autosave
	# or player quickload is installed: camp and mission rollback remain separate work.
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return reject("Could not write equipment snapshot")
	file.store_string(JSON.stringify(encode()))
	file.flush()
	var result := file.get_error()
	file.close()
	return result == OK

func load_equipment(path: String) -> bool:
	if not FileAccess.file_exists(path): return reject("Equipment snapshot not found")
	var snapshot = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not snapshot is Dictionary: return reject("Invalid equipment snapshot")
	return restore(snapshot)
