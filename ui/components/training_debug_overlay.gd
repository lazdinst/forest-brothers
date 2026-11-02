extends Node
## Presentation-only developer switch; never enables debug actions in game rules.
@export var enable_in_production := false
var world: Node
var enabled := false
var allowed: bool
var _labels: Array[CanvasItem] = []
var details: Label

func _ready() -> void:
	allowed = OS.is_debug_build() or enable_in_production
	for title in ["Title","Subtitle","Status","Controls","MovementState","WeaponStatus"]:
		_labels.append(world.get_node("HUD/"+title))
	world.get_node("HUD/Status").offset_top = -225
	world.get_node("HUD/Controls").offset_top = -190
	_labels.append(world.resource_strip)
	details = Label.new()
	details.name = "DeveloperMovementDetails"
	details.position = Vector2(28,145)
	details.add_theme_font_size_override("font_size",15)
	details.add_theme_constant_override("outline_size",4)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.get_node("HUD").add_child(details)
	_labels.append(details)
	set_enabled(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if allowed and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		set_enabled(not enabled)
		get_viewport().set_input_as_handled()

func set_enabled(value: bool) -> void:
	enabled = value and allowed
	for label in _labels: label.visible = enabled
	var annex = world.get_node_or_null("SystemsAnnex")
	if annex != null: annex.debug_diagnostics_visible = enabled

func _process(_delta: float) -> void:
	var annex = world.get_node_or_null("SystemsAnnex")
	if annex != null and annex.debug_diagnostics_visible != enabled:
		annex.debug_diagnostics_visible = enabled
	if not enabled: return
	var player = world.player
	var state = player.locomotion
	details.text = "DEVELOPER OVERLAY [F3]\nPace %d / %d | Physical height %.2f m | Load %.1f kg\nLegs %.1f / %.1f | Arms %.1f / %.1f | Sprint locked: %s" % [state.speed_setting,state.tuning.speed_increments,player.body_shape.shape.height,state.carried_weight,state.legs,state.tuning.leg_maximum,state.arms,state.tuning.arm_maximum,str(state.exhausted)]
