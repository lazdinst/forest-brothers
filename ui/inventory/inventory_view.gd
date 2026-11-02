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
	pocket_grid.configure(4,1,96)
	carried.add_child(pocket_grid)
	var pockets_fit: bool = pocket_grid.show_items(data.pocket_items)
	pocket_grid.item_selected.connect(_select_item)
	pocket_grid.item_dropped.connect(_drop_in_grid.bind(&"pocket"))
	_label(carried,"RIFLE & AMMUNITION",Vector2(455,45),470,20)
	ammunition_status = _label(carried,"",Vector2(455,87),470,18)
	_label(carried,"03  /  PACK SPACE",Vector2(0,238),920,20)
	_label(carried,"One item per square · total pack capacity under review",Vector2(0,269),920,16)
	pack_grid = Grid.new()
	pack_grid.position = Vector2(0,305)
	pack_grid.configure(9,4,90)
	carried.add_child(pack_grid)
	var pack_fits: bool = pack_grid.show_items(data.pack_items)
	pack_grid.item_selected.connect(_select_item)
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

func _refresh() -> void:
	data = Snapshot.from_state(weapon_state,_appearance,bool(data.demo))
	pocket_grid.show_items(data.pocket_items)
	pack_grid.show_items(data.pack_items)
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
	selected_id = weapon_state.inventory.active_weapon_id
	_show_context()

func _show_context() -> void:
	var item = weapon_state.inventory.items.get(selected_id)
	if item == null: return
	var choices: Array = []
	var heading := "Rifle"
	var gun = weapon_state.inventory.weapon()
	var description := "Chamber: " + ("loaded" if gun != null and gun.chambered_round != null else "empty")
	split_amount.hide()
	if weapon_state.busy != &"":
		choices.append({"id":&"cancel_action","caption":"Cancel current action"})
	elif item is Inventory.MagazineInstance:
		heading = item.label
		description = weapon_state.inventory.knowledge(item.id)
		choices.append({"id":&"inspect","caption":"Inspect magazine"})
		if item.location.kind == &"magwell": choices.append({"id":&"remove_magazine","caption":"Remove magazine"})
		else:
			choices.append({"id":&"reload","caption":"Insert / swap into rifle"})
			choices.append({"id":&"pack","caption":"Fill with compatible cartridges"})
			choices.append({"id":&"unload","caption":"Unload cartridges"})
			choices.append({"id":&"drop","caption":"Drop magazine"})
	elif item is Inventory.AmmoStack:
		heading = "Loose cartridges"
		description = "%d cartridges · %s · one stack · maximum 32" % [item.quantity,str(weapon_state.inventory.ammo_definitions[item.ammo_type_id].caliber)]
		if item.quantity > 1:
			split_amount.max_value = item.quantity-1
			split_amount.value = mini(10,item.quantity-1)
			split_amount.show()
			choices.append({"id":&"split","caption":"Split stack"})
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
	choices.append({"id":&"back","caption":"Back"})
	context.present(heading,description,choices)

func _inventory_action(action: StringName) -> void:
	context.dismiss()
	if action == &"back": return
	if action == &"cancel_action": weapon_state.cancel_action()
	elif weapon_state.busy != &"": weapon_state.reject("Finish or cancel the current action first")
	elif action == &"split":
		weapon_state.inventory.split_stack(selected_id,int(split_amount.value))
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

func _drop_in_grid(id: StringName, slot: int, target_id: StringName, container: StringName) -> void:
	if weapon_state.busy != &"":
		weapon_state.reject("Finish or cancel the current action first")
		return
	var source = weapon_state.inventory.items.get(id)
	var target = weapon_state.inventory.items.get(target_id)
	if source is Inventory.AmmoStack and target is Inventory.MagazineInstance:
		weapon_state.request_action(&"pack",target_id,id,true)
	elif source is Inventory.AmmoStack and target is Inventory.AmmoStack:
		weapon_state.inventory.merge_stacks(id,target_id)
	else: weapon_state.move_item(id,container,slot)
	_refresh()

func _inspect(title: String, description: String) -> void:
	detail.text = title + "  /  " + description

func _select_item(item: Dictionary) -> void:
	selected_id = StringName(item.id)
	_show_context()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		closed.emit()
