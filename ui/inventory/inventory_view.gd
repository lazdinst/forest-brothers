extends Control
signal closed
signal drop_requested(item_id: StringName)

const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const MenuFrame = preload("res://ui/components/menu_panel.gd")
const ButtonScene = preload("res://ui/components/menu_button.tscn")
const Grid = preload("res://ui/inventory/inventory_grid.gd")
const CharacterPreview = preload("res://ui/inventory/character_preview.gd")
const Snapshot = preload("res://ui/inventory/inventory_snapshot.gd")
const Symbol = preload("res://ui/inventory/item_symbol.gd")
const AmmunitionArt = preload("res://ui/inventory/ammunition_art.gd")
const WeaponSlot = preload("res://ui/inventory/inventory_weapon_slot.gd")
const MenuModal = preload("res://ui/components/menu_modal.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")

var data: Dictionary
var composition: Control
var character_preview
var pack_grid
var pocket_grid
var detail: Label
var close_button: Button
var weapon_state
var context
var split_amount: SpinBox
var selected_id: StringName
var rifle_button: Button
var rifle_name: Label
var rifle_art
var rifle_status: Label
var ammunition_status: Label
var item_menu: PopupMenu
var backpack_button: Button
var inspect_title: Label
var inspect_body: Label
var inspect_icon: Control
var inspected_id: StringName
var no_pack_label: Label
var _menu_actions: Array[StringName] = []
var _split_destination
var _seen_revision := -1
var _appearance

func _ready() -> void:
	theme = JournalTheme.create()
	if data.is_empty(): data = Snapshot.demo()
	weapon_state = data.runtime
	_appearance = data.appearance
	_build()
	resized.connect(_fit)
	_fit()
	close_button.grab_focus()
	_refresh()

func _physics_process(delta: float) -> void:
	# The startup owner suspends the local world subtree while this fixed-tick adapter
	# advances the same weapon rules. Drawing/animation callbacks never award rounds.
	weapon_state.advance(delta)
	if _seen_revision != weapon_state.revision: _refresh()
	_show_action_progress()

## The busy magazine's cell shows how far the timed action is; rifle actions show on the rifle slot.
func _show_action_progress() -> void:
	var id: StringName = weapon_state.target_magazine_id if weapon_state.busy != &"" else &""
	var value: float = weapon_state.action_progress() if weapon_state.busy != &"" else -1.0
	var shown: bool = pocket_grid.show_progress(id,value)
	shown = pack_grid.show_progress(id,value) or shown
	rifle_button.set_progress(value if weapon_state.busy != &"" and not shown else -1.0)

func _fit() -> void:
	var factor := minf(size.x/1600, size.y/900)
	composition.scale = Vector2.ONE * factor
	composition.position = (size - Vector2(1600,900)*factor)*0.5

func _label(parent: Node, text: String, at: Vector2, width: float, font_size := 20) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _frame(at: Vector2, dimensions: Vector2) -> Control:
	var frame := MenuFrame.new()
	frame.position = at
	frame.size = dimensions
	composition.add_child(frame)
	var body := Control.new()
	body.custom_minimum_size = dimensions - Vector2(40,40)
	frame.add_child(body)
	return body

func _button(parent: Node, text: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := ButtonScene.instantiate() as Button
	button.text = text
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size",18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build() -> void:
	composition = Control.new()
	composition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(composition)
	var background := TextureRect.new()
	background.texture = preload("res://ui/assets/field_journal_background_v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = Vector2(1600,900)
	background.modulate = Color(0.38,0.33,0.28)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	composition.add_child(background)
	var title := _label(composition,"MEŽABRĀĻI  /  FIELD INVENTORY",Vector2(44,20),1100,30)
	title.add_theme_color_override("font_color",JournalTheme.PAPER)
	var caption := "Training equipment preview" if data.demo else "On your person · inspect, load & organise · drag items to move"
	var subtitle := _label(composition,caption,Vector2(45,61),1100,17)
	subtitle.add_theme_color_override("font_color",JournalTheme.PAPER)
	close_button = _button(composition,"Back / Esc",Vector2(1360,25),Vector2(195,50),func(): closed.emit())
	var character := _frame(Vector2(24,106),Vector2(540,718))
	_label(character,data.character_name,Vector2(3,0),470,27)
	_label(character,"01  /  WORN & EQUIPPED",Vector2(3,39),470,15)
	character_preview = CharacterPreview.new()
	character_preview.position = Vector2(151,90)
	character_preview.size = Vector2(196,414)
	character.add_child(character_preview)
	character_preview.bind_visual(data.appearance)
	var locations := [Vector2(0,88),Vector2(0,205),Vector2(0,322),Vector2(355,88),Vector2(355,205),Vector2(355,322)]
	var slots := [["head","Headwear"],["outer","Outer layer"],["legs","Trousers"],["back","Backpack"],["belt","Belt / pouches"],["feet","Footwear"]]
	for index in range(slots.size()):
		var slot = slots[index]
		var item_name: String = data.outfit.get(slot[0],"Not recorded")
		if slot[0] == "back":
			# The backpack is a real item: left click selects it, right click opens its actions.
			backpack_button = _button(character,"",locations[index],Vector2(143,94),func(): if data.backpack_id != "": _select(StringName(data.backpack_id)))
			backpack_button.add_theme_font_size_override("font_size",16)
			backpack_button.gui_input.connect(_backpack_input)
			continue
		var button := _button(character,slot[1]+"\n"+item_name,locations[index],Vector2(143,94),_inspect.bind(slot[1],item_name + (" · sample outfit" if data.demo else " · clothing record unavailable")))
		button.add_theme_font_size_override("font_size",16)
	if not character_preview.has_character:
		_label(character,"Appearance in development",Vector2(134,460),226,15)
	else:
		_button(character,"Turn left",Vector2(151,472),Vector2(94,48),func(): character_preview.rotate_character(-0.4))
		_button(character,"Turn right",Vector2(250,472),Vector2(97,48),func(): character_preview.rotate_character(0.4))
	rifle_button = _button(character,"",Vector2(0,520),Vector2(498,114),_select_weapon)
	rifle_button.set_script(WeaponSlot)
	rifle_button.set("weapon_state",weapon_state)
	rifle_button.set_process(true)
	rifle_button.menu_requested.connect(func(at: Vector2): _open_menu_for(weapon_state.inventory.active_weapon_id,at))
	rifle_button.inspect_requested.connect(func(): _show_inspect(weapon_state.inventory.active_weapon_id))
	rifle_name = _label(rifle_button,data.rifle,Vector2(20,5),460,16)
	rifle_art = AmmunitionArt.new()
	rifle_art.kind = "rifle"
	rifle_art.position = Vector2(15,27)
	rifle_art.size = Vector2(460,75)
	rifle_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rifle_button.add_child(rifle_art)
	rifle_status = _label(character,"",Vector2(18,642),470,15)
	var carried := _frame(Vector2(572,106),Vector2(1004,718))
	_label(carried,"On your person",Vector2(0,0),920,27)
	_label(carried,"02  /  POCKETS",Vector2(0,45),420,20)
	_label(carried,"Four slots · up to four items",Vector2(0,75),420,16)
	pocket_grid = Grid.new()
	pocket_grid.position = Vector2(0,110)
	pocket_grid.configure(4,1,64)
	carried.add_child(pocket_grid)
	var pockets_fit: bool = pocket_grid.show_items(data.pocket_items)
	pocket_grid.item_selected.connect(_select_item)
	pocket_grid.item_menu_requested.connect(_open_item_menu)
	pocket_grid.item_quick.connect(_quick)
	pocket_grid.drop_validator = _can_drop_in_grid.bind(&"pocket")
	pocket_grid.item_dropped.connect(_drop_in_grid.bind(&"pocket"))
	_label(carried,"RIFLE & AMMUNITION",Vector2(455,45),470,20)
	ammunition_status = _label(carried,"",Vector2(455,87),470,18)
	_label(carried,"03  /  PACK SPACE",Vector2(0,200),920,20)
	_label(carried,"Pack space · total capacity under review",Vector2(0,231),920,16)
	pack_grid = Grid.new()
	pack_grid.position = Vector2(0,265)
	pack_grid.configure(weapon_state.inventory.pack_columns,ceili(float(weapon_state.inventory.pack_capacity)/weapon_state.inventory.pack_columns),64)
	carried.add_child(pack_grid)
	var pack_fits: bool = pack_grid.show_items(data.pack_items)
	pack_grid.item_selected.connect(_select_item)
	pack_grid.item_menu_requested.connect(_open_item_menu)
	pack_grid.item_quick.connect(_quick)
	pack_grid.drop_validator = _can_drop_in_grid.bind(&"pack")
	no_pack_label = _label(carried,"No backpack worn · only pockets",Vector2(0,275),920,18)
	no_pack_label.hide()
	# Inspect panel beside the pack: double-click any item to read it here.
	var inspect := Panel.new()
	inspect.add_theme_stylebox_override("panel",ItemCard.style(Color("efe2c880"),Color("29251d66")))
	inspect.position = Vector2(600,265)
	inspect.size = Vector2(364,384)
	inspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carried.add_child(inspect)
	_label(inspect,"04  /  INSPECT",Vector2(14,10),336,16)
	inspect_title = _label(inspect,"Double-click an item",Vector2(14,36),336,20)
	inspect_icon = Control.new()
	inspect_icon.position = Vector2(14,72)
	inspect_icon.size = Vector2(336,110)
	inspect_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect.add_child(inspect_icon)
	inspect_body = _label(inspect,"",Vector2(14,192),336,15)
	pack_grid.item_dropped.connect(_drop_in_grid.bind(&"pack"))
	var footer := _frame(Vector2(24,829),Vector2(1552,60))
	detail = _label(footer,"Select equipment or supplies to inspect. All equipment belongs to the group.",Vector2(0,-4),1490,17)
	if not pockets_fit or not pack_fits:
		detail.text = "Carried-item record exceeds the available slots; contents could not be displayed."
	context = MenuModal.new()
	add_child(context)
	context.action_selected.connect(_inventory_action)
	context.canceled.connect(context.dismiss)
	split_amount = SpinBox.new()
	split_amount.min_value = 1
	split_amount.prefix = "Split amount: "
	split_amount.custom_minimum_size.y = 38
	var column: Node = context.panel.get_child(0)
	column.add_child(split_amount)
	column.move_child(split_amount,2)
	split_amount.hide()
	item_menu = PopupMenu.new()
	item_menu.add_theme_font_size_override("font_size",16)
	item_menu.add_theme_color_override("font_color",JournalTheme.INK)
	item_menu.add_theme_color_override("font_hover_color",JournalTheme.PAPER)
	item_menu.add_theme_stylebox_override("panel",ItemCard.style(Color("efe2c8"),JournalTheme.INK))
	item_menu.add_theme_stylebox_override("hover",ItemCard.style(JournalTheme.BURGUNDY,JournalTheme.BURGUNDY))
	item_menu.id_pressed.connect(func(index: int):
		item_menu.hide()
		_inventory_action(_menu_actions[index]))
	add_child(item_menu)

func _refresh() -> void:
	data = Snapshot.from_state(weapon_state,_appearance,bool(data.demo))
	pocket_grid.show_items(data.pocket_items)
	pack_grid.show_items(data.pack_items)
	pack_grid.visible = data.backpack_id != ""
	no_pack_label.visible = not pack_grid.visible
	backpack_button.text = "Backpack\n" + (data.backpack if data.backpack_id != "" else "None worn")
	if inspected_id != &"": _show_inspect(inspected_id)
	rifle_name.text = data.rifle
	rifle_button.disabled = not data.equipped
	rifle_art.visible = data.equipped
	rifle_art.inserted = data.magazine_id != ""
	rifle_art.queue_redraw()
	rifle_status.text = "Magazine: %s · Condition %d%%" % [data.magazine_knowledge,data.cleanliness] if data.equipped else "No equipped rifle"
	ammunition_status.text = "Inserted: %s\nChamber: %s\nLoose cartridges: %d\n%s" % [data.magazine_knowledge,"loaded" if data.chamber else "empty",data.loose,"K chamber · R swap · I inspect"]
	detail.text = weapon_state.message + (" · " + String(weapon_state.busy) if weapon_state.busy != &"" else "")
	_seen_revision = weapon_state.revision

func _select_weapon() -> void:
	_select(weapon_state.inventory.active_weapon_id)

func _select_item(item: Dictionary) -> void:
	_select(StringName(item.id))

## Left click only marks the item and describes it in the lower strip.
func _select(id: StringName) -> void:
	selected_id = id
	pocket_grid.select(id)
	pack_grid.select(id)
	var entry := _describe(id)
	if not entry.is_empty(): detail.text = "%s  /  %s  ·  right-click for actions" % [entry.heading,entry.description]

func _backpack_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT and data.backpack_id != "":
		backpack_button.accept_event()
		_show_inspect(StringName(data.backpack_id))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and data.backpack_id != "":
		backpack_button.accept_event()
		_open_menu_for(StringName(data.backpack_id),backpack_button.get_screen_transform() * event.position)

func _open_item_menu(item: Dictionary, at: Vector2) -> void:
	_open_menu_for(StringName(item.id),at)

## Right click opens a small menu at the cursor instead of the full-screen action list.
func _open_menu_for(id: StringName, at: Vector2) -> void:
	_select(id)
	var entry := _describe(id)
	if entry.is_empty(): return
	item_menu.clear()
	_menu_actions.clear()
	for choice in entry.choices:
		item_menu.add_item(choice.caption,_menu_actions.size())
		_menu_actions.append(choice.id)
	item_menu.reset_size()
	item_menu.popup(Rect2i(Vector2i(at),Vector2i.ZERO))

func _describe(id: StringName) -> Dictionary:
	var item = weapon_state.inventory.items.get(id)
	if item == null: return {}
	var choices: Array = []
	var heading := "Rifle"
	var gun = weapon_state.inventory.weapon()
	var description := "Chamber: " + ("loaded" if gun != null and gun.chambered_round != null else "empty")
	if item is Inventory.MagazineInstance:
		heading = item.label
		description = weapon_state.inventory.knowledge(item.id)
	elif item is Inventory.BackpackInstance:
		heading = item.label
		description = "%d × %d pack · %d items inside · contents stay in it when dropped" % [weapon_state.inventory.pack_columns,ceili(float(weapon_state.inventory.pack_capacity)/weapon_state.inventory.pack_columns),weapon_state.inventory.contents_tree(item).size()-1]
	elif item is Inventory.AmmoStack:
		heading = "Loose cartridges"
		description = "%d cartridges · %s · one stack · maximum 32" % [item.quantity,str(weapon_state.inventory.ammo_definitions[item.ammo_type_id].caliber)]
	if weapon_state.busy != &"":
		choices.append({"id":&"cancel_action","caption":"Cancel current action"})
	elif item is Inventory.MagazineInstance:
		choices.append({"id":&"inspect","caption":"Inspect magazine"})
		if item.location.kind == &"magwell": choices.append({"id":&"remove_magazine","caption":"Remove magazine"})
		else:
			choices.append({"id":&"reload","caption":"Insert / swap into rifle"})
			choices.append({"id":&"pack","caption":"Fill with compatible cartridges"})
			choices.append({"id":&"unload","caption":"Unload cartridges"})
			choices.append({"id":&"drop","caption":"Drop magazine"})
	elif item is Inventory.BackpackInstance:
		choices.append({"id":&"drop","caption":"Drop backpack with its contents"})
	elif item is Inventory.AmmoStack:
		if item.quantity > 1: choices.append({"id":&"split_prompt","caption":"Split stack…"})
		choices.append({"id":&"merge","caption":"Merge into a matching partial stack"})
		choices.append({"id":&"drop","caption":"Drop stack"})
	elif item is Inventory.WeaponInstance:
		if item.location.kind != &"equipped": choices.append({"id":&"equip","caption":"Equip rifle"})
		else:
			choices.append({"id":&"chamber","caption":"Chamber a round"})
			choices.append({"id":&"eject_chamber","caption":"Unload chamber"})
			if item.inserted_magazine_id != &"":
				choices.append({"id":&"inspect_loaded","caption":"Inspect inserted magazine"})
				choices.append({"id":&"remove_magazine","caption":"Remove inserted magazine"})
		choices.append({"id":&"drop","caption":"Drop rifle with its contents"})
	return {"heading":heading,"description":description,"choices":choices}

## Only splitting needs a typed amount, so it keeps the paper dialog. A shift-drag passes
## where the new stack should go; the menu leaves it to the first free cell.
func _show_split_dialog(destination = null) -> void:
	_split_destination = destination
	var stack = weapon_state.inventory.items.get(selected_id) as Inventory.AmmoStack
	if stack == null or stack.quantity < 2: return
	split_amount.max_value = stack.quantity-1
	split_amount.value = mini(10,stack.quantity-1)
	split_amount.show()
	context.present("Split stack","%d cartridges in this stack" % stack.quantity,[{"id":&"split","caption":"Split"},{"id":&"back","caption":"Back"}])

func _inventory_action(action: StringName) -> void:
	context.dismiss()
	if action == &"back": return
	if action == &"cancel_action": weapon_state.cancel_action()
	elif weapon_state.busy != &"": weapon_state.reject("Finish or cancel the current action first")
	elif action == &"split_prompt":
		_show_split_dialog()
		return
	elif action == &"split":
		weapon_state.inventory.split_stack(selected_id,int(split_amount.value),_split_destination)
		_split_destination = null
		weapon_state.message = weapon_state.inventory.error if weapon_state.inventory.error != "" else "Stack split"
	elif action == &"merge":
		var source = weapon_state.inventory.items.get(selected_id)
		var merged := false
		for item in weapon_state.inventory.items.values():
			if item is Inventory.AmmoStack and source is Inventory.AmmoStack and item.id != source.id and item.ammo_type_id == source.ammo_type_id and item.quantity < 32 and weapon_state.inventory.carried(item):
				merged = weapon_state.inventory.merge_stacks(source.id,item.id)
				break
		weapon_state.message = "Stacks merged; overflow retained" if merged else "No matching partial stack"
	elif action == &"equip": weapon_state.inventory.equip_weapon(selected_id)
	elif action == &"drop":
		if drop_requested.get_connections().is_empty(): weapon_state.inventory.drop_item(selected_id,Vector3.ZERO)
		else: drop_requested.emit(selected_id)
	elif action == &"inspect_loaded": weapon_state.request_action(&"inspect",weapon_state.inventory.weapon().inserted_magazine_id)
	else: weapon_state.request_action(action,selected_id if action in [&"inspect",&"reload",&"pack",&"unload"] else &"",&"",action in [&"pack",&"unload"])
	_refresh()

## Facts the carrier can see by looking: never an exact magazine count, only earned knowledge.
func _show_inspect(id: StringName) -> void:
	var inventory = weapon_state.inventory
	var item = inventory.items.get(id)
	for child in inspect_icon.get_children(): child.queue_free()
	if item == null or not inventory.carried(item):
		inspected_id = &""
		inspect_title.text = "Double-click an item"
		inspect_body.text = ""
		return
	inspected_id = id
	var lines: Array[String] = []
	var where := {&"pocket":"In a pocket",&"pack":"In the backpack",&"magwell":"Inserted in the rifle",&"equipped":"Equipped",&"worn":"Worn on the back"}
	if item is Inventory.MagazineInstance:
		inspect_title.text = item.label
		var definition = inventory.magazine_definitions[item.magazine_type_id]
		lines.append("%d-round %s detachable magazine" % [definition.capacity,str(definition.caliber)])
		lines.append("Contents: " + inventory.knowledge(item.id))
		lines.append("Condition %d%%" % roundi(item.condition*100))
		if not item.inspected: lines.append("Right-click · Inspect magazine to check its fill.")
	elif item is Inventory.AmmoStack:
		var ammo = inventory.ammo_definitions[item.ammo_type_id]
		inspect_title.text = ammo.display_name.capitalize()
		lines.append("%d loose cartridges · %s" % [item.quantity,str(ammo.caliber)])
		lines.append("One stack holds at most 32.")
	elif item is Inventory.WeaponInstance:
		inspect_title.text = data.rifle
		lines.append("Chamber: " + ("loaded" if item.chambered_round != null else "empty"))
		lines.append("Magazine: " + (inventory.knowledge(item.inserted_magazine_id) if item.inserted_magazine_id != &"" else "none inserted"))
		lines.append("Condition %d%%%s" % [roundi(item.condition*100)," · jammed" if item.jammed else ""])
	elif item is Inventory.BackpackInstance:
		inspect_title.text = item.label
		lines.append("%d × %d pack · %d items inside" % [inventory.pack_columns,ceili(float(inventory.pack_capacity)/inventory.pack_columns),inventory.contents_tree(item).size()-1])
		lines.append("Everything inside stays in it when dropped.")
	lines.append(where.get(item.location.kind,""))
	lines.append("Belongs to the group; you are carrying it.")
	inspect_body.text = "\n".join(lines)
	var record := Snapshot.record(item,inventory)
	record.rotated = false
	inspect_icon.add_child(ItemCard.icon(record,Rect2(Vector2.ZERO,inspect_icon.size)))

## Ctrl-click: pockets <-> pack. Alt-click: insert a carried magazine into the rifle.
func _quick(item: Dictionary, kind: StringName) -> void:
	var id := StringName(item.id)
	var inventory = weapon_state.inventory
	var source = inventory.items.get(id)
	if source == null: return
	_select(id)
	if kind == &"inspect":
		_show_inspect(id)
		return
	if weapon_state.busy != &"": weapon_state.reject("Finish or cancel the current action first")
	elif kind == &"use" and source is Inventory.MagazineInstance: weapon_state.request_action(&"reload",id)
	elif kind == &"move" and source.location.kind in [&"pocket",&"pack"]:
		var other := &"pack" if source.location.kind == &"pocket" else &"pocket"
		var spot = inventory.empty_location_in(other,id,inventory.footprint(source))
		if spot == null: weapon_state.reject("No room in the " + ("pack" if other == &"pack" else "pockets"))
		else: weapon_state.move_item(id,other,spot.slot,spot.rotated)
	_refresh()

## Preview only: the same checks the drop below will make, without changing anything.
func _can_drop_in_grid(id: StringName, slot: int, target_id: StringName, rotated: bool, split: bool, container: StringName) -> bool:
	if weapon_state.busy != &"": return false
	var inventory = weapon_state.inventory
	var destination = inventory.slot_location(container,slot,rotated)
	if destination == null: return false
	if split: return inventory.can_split_stack(id,destination)
	var source = inventory.items.get(id)
	var target = inventory.items.get(target_id)
	if source is Inventory.AmmoStack and target is Inventory.MagazineInstance: return inventory.can_load_round(target_id,id)
	if source is Inventory.AmmoStack and target is Inventory.AmmoStack and target != source: return inventory.can_merge_stacks(id,target_id)
	return inventory.can_move_item(id,destination)

func _drop_in_grid(id: StringName, slot: int, target_id: StringName, rotated: bool, split: bool, container: StringName) -> void:
	if weapon_state.busy != &"":
		weapon_state.reject("Finish or cancel the current action first")
		return
	if split:
		selected_id = id
		var destination = weapon_state.inventory.slot_location(container,slot)
		if destination != null: _show_split_dialog(destination)
		return
	var source = weapon_state.inventory.items.get(id)
	var target = weapon_state.inventory.items.get(target_id)
	if source is Inventory.AmmoStack and target is Inventory.MagazineInstance:
		weapon_state.request_action(&"pack",target_id,id,true)
	elif source is Inventory.AmmoStack and target is Inventory.AmmoStack and target != source:
		weapon_state.inventory.merge_stacks(id,target_id)
	else: weapon_state.move_item(id,container,slot,rotated)
	_refresh()

func _inspect(title: String, description: String) -> void:
	detail.text = title + "  /  " + description

## R while dragging turns the carried item a quarter, as in Tarkov. Square items stay as they are.
func rotate_drag() -> bool:
	if not get_viewport().gui_is_dragging(): return false
	var payload = get_viewport().gui_get_drag_data()
	if not payload is Dictionary or not payload.has("inventory_item_id"): return false
	var cells: Vector2i = payload.get("cells",Vector2i.ONE)
	if cells.x == cells.y: return false
	payload.turned = not payload.get("turned",false)
	var preview = payload.get("preview")
	if is_instance_valid(preview): preview.rotation = PI/2 if payload.turned else 0.0
	pocket_grid.refresh_hover(payload)
	pack_grid.refresh_hover(payload)
	return true

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and rotate_drag():
		get_viewport().set_input_as_handled()
		return
	# Delete drops the selected item, like Tarkov's discard, but onto the ground for recovery.
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE and not context.visible and not item_menu.visible and weapon_state.inventory.items.has(selected_id):
		get_viewport().set_input_as_handled()
		_inventory_action(&"drop")
		return
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		closed.emit()
