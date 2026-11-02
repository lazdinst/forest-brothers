extends Button
## One body part on the inventory's health figure: its health and injuries, tinted by how hurt
## it is. Drop a medical supply on it to treat that part; the condition owner validates.
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
var part: StringName
## Callables from the view: can_treat(item_id, part) -> bool, treat(item_id, part).
var can_treat: Callable
var treat: Callable
var _hover := false

func setup(part_id: StringName, dimensions: Vector2) -> void:
	part = part_id
	size = dimensions
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	add_theme_font_size_override("font_size",11)
	add_theme_color_override("font_color",JournalTheme.INK)
	add_theme_color_override("font_hover_color",JournalTheme.INK)

## Text and tint from the part's current condition.
func show_condition(health) -> void:
	var current: float = health.health[part]
	var fraction: float = current / health.max_health[part]
	var tags: Array[String] = []
	if health.heavy_bleeding[part]: tags.append("HEAVY")
	elif health.light_bleeding[part]: tags.append("bleed")
	if health.fractured[part]: tags.append("broken")
	if health.destroyed(part): tags.append("lost")
	text = "%s\n%d/%d%s" % [health.LABELS[part],ceili(current),int(health.max_health[part]),("\n" + ", ".join(tags)) if not tags.is_empty() else ""]
	var fill := Color("29251d") if fraction <= 0.0 else Color("8a3a32").lerp(Color("6f8a5a"),fraction)
	fill.a = 0.55
	var border := JournalTheme.BURGUNDY if not tags.is_empty() else Color("29251d88")
	for state in ["normal","hover","pressed"]:
		add_theme_stylebox_override(state,ItemCard.style(fill.lightened(0.15) if state == "hover" or _hover else fill,border,2 if not tags.is_empty() else 1))
	tooltip_text = text.replace("\n"," · ")

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and data.get("inventory_item_id") is String and can_treat.is_valid() and can_treat.call(StringName(data.inventory_item_id),part)
	self_modulate = Color("b6dcae") if ok else Color("e7a59c")
	return ok

func _drop_data(_at: Vector2, data: Variant) -> void:
	self_modulate = Color.WHITE
	treat.call(StringName(data.inventory_item_id),part)

func _process(_delta: float) -> void:
	if self_modulate != Color.WHITE and not get_global_rect().has_point(get_global_mouse_position()): self_modulate = Color.WHITE

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END: self_modulate = Color.WHITE
