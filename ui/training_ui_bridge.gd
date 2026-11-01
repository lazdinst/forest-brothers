extends Node
## UI-only compatibility adapter. Existing camp callbacks/layout references survive.
## Remove this adapter when the training owner adopts the components directly.
const MenuPanel = preload("res://ui/components/menu_panel.gd")
const MenuActions = preload("res://ui/components/menu_actions.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
var training_root: Node
var _annex: Node

func _ready() -> void:
	get_tree().node_added.connect(_node_added)

func _process(_delta: float) -> void:
	if is_instance_valid(_annex) or not is_instance_valid(training_root):
		return
	_annex = training_root.get_node_or_null("SystemsAnnex")
	if _annex != null:
		_adopt_legacy_panel()
		if _annex != null:
			set_process(false)

func _adopt_legacy_panel() -> void:
	var overlay: Control = _annex.get("_overlay")
	if overlay == null:
		_annex = null
		return
	overlay.theme = JournalTheme.create()
	if overlay is ColorRect:
		overlay.color = JournalTheme.SCRIM
	var layout := overlay.get_child(0) as MarginContainer
	if layout != null:
		var inset := MarginContainer.new()
		inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for edge in ["left", "right", "top", "bottom"]:
			inset.add_theme_constant_override("margin_" + edge, 32)
			layout.add_theme_constant_override("margin_" + edge, 0)
		overlay.add_child(inset)
		var frame := MenuPanel.new()
		inset.add_child(frame)
		layout.reparent(frame)
	for button in overlay.find_children("*", "Button", true, false):
		MenuActions.style_existing_button(button)

func _node_added(node: Node) -> void:
	if node is Button and is_instance_valid(training_root) and training_root.is_ancestor_of(node):
		MenuActions.style_existing_button(node)

func has_active_context() -> bool:
	if not is_instance_valid(_annex):
		return false
	var overlay: Control = _annex.get("_overlay")
	return (overlay != null and overlay.is_visible_in_tree()) or bool(_annex.get("planning"))
