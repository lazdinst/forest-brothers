extends GridContainer
## Read-only stock presentation shared by training HUD and workshop panels.
const Symbol = preload("res://ui/inventory/item_symbol.gd")
const TITLES = {&"food":"Food", &"water":"Water", &"medicine":"Medicine", &"meals":"Meals", &"timber":"Timber", &"parts":"Parts", &"cloth":"Cloth", &"rounds":"Cartridges", &"rubles":"Rubles", &"lats":"Lats"}
var labels: Dictionary = {}
var ink := Color("efe6cf")
var outlined := true

func _ready() -> void:
	columns = 4
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 16)
	add_theme_constant_override("v_separation", 4)
	for id in TITLES:
		var cell := HBoxContainer.new()
		cell.custom_minimum_size.x = 128
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cell)
		var icon := Symbol.new()
		icon.kind = String(id)
		icon.ink = ink
		icon.custom_minimum_size = Vector2(28,28)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		var label := Label.new()
		label.add_theme_color_override("font_color",ink)
		label.add_theme_font_size_override("font_size",15)
		if outlined:
			label.add_theme_color_override("font_outline_color",Color.BLACK)
			label.add_theme_constant_override("outline_size",4)
		cell.add_child(label)
		labels[id] = label

func show_stock(quantities: Dictionary) -> void:
	for id in labels:
		labels[id].text = "%s %d" % [TITLES[id], quantities.get(id,0)]
