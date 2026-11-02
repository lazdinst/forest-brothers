extends Control
## An NPC's trade window, for any NPC with trade stock. Left: the few lots he has, at fixed
## prices, paid from the treasury in rubles or lats. Right: what you can sell him cheaply, from
## what you carry and from the goods chest; the rubles go to the treasury. The rules live in
## NPCTrade (stock, buying) and CampRuntime (sale values); this only shows them and forwards
## choices. Placeholder prices.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const Snapshot = preload("res://ui/inventory/inventory_snapshot.gd")
signal closed
var runtime
## NPCTrade for the NPC being traded with.
var trade
var title_label: Label
var said_label: Label
## Sources to sell from: [{"label", "inventory"}], e.g. carried gear and the goods chest.
var sources: Array = []
var treasury_label: Label
var message_label: Label
var buy_list: VBoxContainer
var sell_list: VBoxContainer
var close_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = JournalTheme.create()
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 40)
	outer.add_theme_constant_override("separation", 10)
	add_child(outer)
	var top := HBoxContainer.new()
	outer.add_child(top)
	title_label = _label(30, JournalTheme.PAPER)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	close_button = Button.new()
	close_button.text = "Leave (Esc)"
	close_button.pressed.connect(func(): closed.emit())
	top.add_child(close_button)
	said_label = _label(17, JournalTheme.PAPER)
	said_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(said_label)
	treasury_label = _label(18, JournalTheme.PAPER)
	outer.add_child(treasury_label)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	outer.add_child(columns)
	buy_list = _column(columns, "He can get")
	sell_list = _column(columns, "Sell to him")
	message_label = _label(17, JournalTheme.PAPER)
	outer.add_child(message_label)
	refresh()

func _column(parent: Node, heading: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var label := _label(22, JournalTheme.BURGUNDY)
	label.text = heading
	column.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	return list

func refresh() -> void:
	if runtime == null or buy_list == null or trade == null: return
	title_label.text = trade.definition.full_name
	said_label.text = trade.definition.trade_line
	treasury_label.text = "Cash chest: %d rubles, %d lats. Bought goods go to your pack (or the goods chest) or the camp stores; sales are paid into the cash chest." % [runtime.stock.count(&"rubles"), runtime.stock.count(&"lats")]
	message_label.text = runtime.message
	for list in [buy_list, sell_list]:
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
	for offer in trade.offers():
		var row := _row(buy_list, "%s  ·  %s" % [offer.label, "%d left" % offer.left if offer.left > 0 else "none left"])
		_button(row, "%d rubles" % offer.rubles, buy.bind(offer.id, &"rubles")).disabled = not trade.can_buy(offer.id, &"rubles")
		_button(row, "%d lats" % offer.lats, buy.bind(offer.id, &"lats")).disabled = not trade.can_buy(offer.id, &"lats")
	var any := false
	for source in sources:
		var inventory = source.inventory
		for item in inventory.items.values():
			# Contents (a rifle's magazine, a magazine's rounds) are sold with their holder.
			if item.location.kind in [&"magwell"]: continue
			var value: int = runtime.sell_value(inventory, item)
			if value <= 0: continue
			any = true
			var record := Snapshot.record(item, inventory)
			var amount: String = (" · " + record.quantity) if record.quantity != "" else ""
			var row := _row(sell_list, "%s%s  (%s)" % [record.title, amount, source.label])
			_button(row, "Sell for %d rubles" % value, sell.bind(inventory, item.id))
	if not any:
		var none := _label(16, JournalTheme.INK)
		none.text = "Nothing he will take. Carry goods here, or keep them in the goods chest."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sell_list.add_child(none)

func buy(id: String, currency: StringName) -> void:
	trade.buy(id, currency)
	refresh()

func sell(inventory, id: StringName) -> void:
	runtime.sell(inventory, id)
	refresh()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		closed.emit()
		get_viewport().set_input_as_handled()

func _row(list: VBoxContainer, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	list.add_child(row)
	var label := _label(17, JournalTheme.INK)
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)
	return row

func _button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	row.add_child(button)
	return button

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
