extends Control
signal closed

const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const MenuFrame = preload("res://ui/components/menu_panel.gd")
const ButtonScene = preload("res://ui/components/menu_button.tscn")
const Grid = preload("res://ui/inventory/inventory_grid.gd")
const CharacterPreview = preload("res://ui/inventory/character_preview.gd")
const Snapshot = preload("res://ui/inventory/inventory_snapshot.gd")
const Symbol = preload("res://ui/inventory/item_symbol.gd")

var data: Dictionary
var composition: Control
var character_preview
var store_grid
var detail: Label
var store_items: Array = []
var filter := "all"
var close_button: Button

func _ready() -> void:
	theme = JournalTheme.create()
	if data.is_empty(): data = Snapshot.demo()
	_build()
	resized.connect(_fit)
	_fit()
	close_button.grab_focus()

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
	var caption := "Layout preview · sample outfit & supplies" if data.demo else "Carried equipment · communal camp stocks · view only"
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
	var rifle_button := _button(character,"ON SLING\n"+data.rifle,Vector2(0,533),Vector2(498,86),_inspect.bind(data.rifle,"Loaded magazine: %d / %d rounds. Condition: %d%%. %s" % [data.loaded,data.capacity,data.cleanliness,"Jammed" if data.jammed else "Ready"]))
	var rifle_symbol := Symbol.new()
	rifle_symbol.kind = "rifle"
	rifle_symbol.position = Vector2(380,6)
	rifle_symbol.size = Vector2(95,72)
	rifle_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rifle_button.add_child(rifle_symbol)
	_label(character,"Loaded %d / %d   ·   Condition %d%%" % [data.loaded,data.capacity,data.cleanliness],Vector2(18,628),470,17)
	var carried := _frame(Vector2(572,106),Vector2(406,718))
	_label(carried,"Carried supplies",Vector2(0,0),360,27)
	_label(carried,"02  /  AMMUNITION",Vector2(0,39),360,15)
	var ammo := Grid.new()
	ammo.position = Vector2(0,75)
	ammo.configure(6,2,60)
	carried.add_child(ammo)
	ammo.show_items([
		{"id":"loaded","title":"Loaded mag.","quantity":"%d / %d" % [data.loaded,data.capacity],"kind":"magazine","span":Vector2i(2,2)},
		{"id":"spare","title":"Spare mag.","quantity":"%d / %d" % [data.spare,data.capacity],"kind":"magazine","span":Vector2i(2,2)},
		{"id":"loose","title":"Cartridges","quantity":str(data.loose)+" loose","kind":"rounds","span":Vector2i(2,2)},
	])
	ammo.item_selected.connect(_select_item)
	_label(carried,"PACK SPACE",Vector2(0,220),355,20)
	_label(carried,"Proposed layout · capacity to be decided",Vector2(0,250),355,15)
	var pack := Grid.new()
	pack.position = Vector2(0,287)
	pack.configure(6,6,60)
	carried.add_child(pack)
	pack.show_items(data.pack_items)
	pack.item_selected.connect(_select_item)
	var stores := _frame(Vector2(986,106),Vector2(590,718))
	_label(stores,"Camp stores",Vector2(0,0),540,27)
	_label(stores,"03  /  COMMUNAL STORAGE",Vector2(0,39),540,15)
	_label(stores,"Stored at camp. Viewing does not grant remote access.",Vector2(0,67),540,16)
	for index in range(3):
		var ids := ["all","supplies","rounds"]
		var names := ["All","Supplies","Ammunition"]
		_button(stores,names[index],Vector2(index*180,103),Vector2(176,48),_filter_store.bind(ids[index]))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0,166)
	scroll.size = Vector2(550,480)
	stores.add_child(scroll)
	store_grid = Grid.new()
	store_grid.configure(10,14,52)
	scroll.add_child(store_grid)
	store_grid.item_selected.connect(_select_item)
	for id in data.stock:
		store_items.append({"id":str(id),"title":str(id).capitalize(),"quantity":str(data.stock[id])+" stored","kind":str(id),"span":Vector2i(2,2)})
	_filter_store("all")
	var footer := _frame(Vector2(24,829),Vector2(1552,60))
	detail = _label(footer,"Select equipment or supplies to inspect. All equipment belongs to the group.",Vector2(0,-4),1490,17)

func _filter_store(category: String) -> void:
	filter = category
	var shown: Array = []
	for item in store_items:
		if category == "all" or (category == "rounds" and item.kind == "rounds") or (category == "supplies" and item.kind != "rounds"):
			shown.append(item)
	store_grid.show_items(shown)
	if detail != null: detail.text = "Camp stores · " + ("Ammunition" if category == "rounds" else category.capitalize()) + " · inspect only; access requires the storage location."

func _inspect(title: String, description: String) -> void:
	detail.text = title + "  /  " + description

func _select_item(item: Dictionary) -> void:
	_inspect(item.title, str(item.quantity) + " · " + ("Sample arrangement" if data.demo else "Current training snapshot"))

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		closed.emit()
