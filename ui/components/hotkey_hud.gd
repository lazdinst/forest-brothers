extends CanvasLayer
## The quick-use bar along the bottom of the screen: keys 1 to 0, each with what is on it (the
## rifle on 1, bound items on 2 to 0) and how much is left. A key flashes when pressed. Read-only:
## the player's hotkeys and inventory are the rules; this only shows them.
const Symbol = preload("res://ui/inventory/item_symbol.gd")
const Hotkeys = preload("res://scripts/player/hotkeys.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const PAPER := Color("dfc49b")
const SHADE := Color(0.08, 0.07, 0.06, 0.6)
const CELL := Vector2(64, 58)
var player: Node3D
var bar: HBoxContainer
## Slot -> {"frame", "icon", "name", "count"}.
var cells := {}
var _flash := {}

func attach(owner_player: Node3D) -> void:
	player = owner_player
	layer = 5
	bar = HBoxContainer.new()
	bar.name = "Hotkeys"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 4)
	add_child(bar)
	for slot in range(1, Hotkeys.LAST_SLOT + 1):
		var frame := Panel.new()
		frame.custom_minimum_size = CELL
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = SHADE
		style.border_color = Color(PAPER, 0.35)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		frame.add_theme_stylebox_override("panel", style)
		bar.add_child(frame)
		var key := _label(frame, Hotkeys.key_label(slot), Vector2(4, 1), 13)
		key.add_theme_color_override("font_color", PAPER)
		var icon := Symbol.new()
		icon.ink = PAPER
		icon.position = Vector2(18, 6)
		icon.size = Vector2(28, 28)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		var title := _label(frame, "", Vector2(2, 36), 10)
		title.size = Vector2(CELL.x - 4, 14)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var count := _label(frame, "", Vector2(36, 1), 11)
		count.size = Vector2(25, 14)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cells[slot] = {"frame": frame, "icon": icon, "name": title, "count": count, "style": style}
	# Centred along the bottom edge of the screen, whatever its size.
	var width := CELL.x * cells.size() + 4.0 * (cells.size() - 1)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -width / 2.0
	bar.offset_right = width / 2.0
	bar.offset_top = -CELL.y - 14.0
	bar.offset_bottom = -14.0

## What a slot shows: {"title", "kind", "count"}; empty when nothing is on it.
func slot_view(slot: int) -> Dictionary:
	if player == null or not is_instance_valid(player): return {}
	var inventory = player.weapon.state.inventory
	var item = inventory.weapon() if slot == 1 else player.hotkeys.item_on(slot, inventory)
	if item == null or not inventory.carried(item): return {}
	if item is Inventory.WeaponInstance: return {"title": "Rifle", "kind": "rifle", "count": ""}
	if item is Inventory.MagazineInstance: return {"title": item.label, "kind": "magazine", "count": ""}
	var def := SupplyCatalog.get_def(item.supply_id)
	return {"title": def.name, "kind": def.icon, "count": str(item.uses) if int(def.uses) > 1 else ""}

func flash(slot: int) -> void:
	_flash[slot] = 0.25

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player): return
	for slot in cells:
		var view := slot_view(slot)
		var cell: Dictionary = cells[slot]
		cell.icon.visible = not view.is_empty()
		if not view.is_empty() and cell.icon.kind != view.kind:
			cell.icon.kind = view.kind
			cell.icon.queue_redraw()
		cell.name.text = view.get("title", "")
		cell.count.text = view.get("count", "")
		var left: float = maxf(0.0, _flash.get(slot, 0.0) - delta)
		_flash[slot] = left
		cell.style.border_color = Color(PAPER, 0.35 + left * 2.6)
		cell.frame.modulate.a = 1.0 if not view.is_empty() else 0.55

func _label(parent: Control, text: String, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", PAPER)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	parent.add_child(label)
	return label
