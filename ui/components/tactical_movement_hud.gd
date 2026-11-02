extends Control
## Read-only presentation. All stance/stamina/movement rules remain on the player.
const ART = preload("res://ui/assets/partisan_stances_source.png")
const CHALK = preload("res://ui/components/stance_chalk.gdshader")
const PAPER := Color("d8d7c3")
const INACTIVE := Color(0.57, 0.58, 0.53, 0.4)
const FOOTPRINT := Vector2(130, 102)
const EDGE := 24.0
var player
var icon: TextureRect
var prone_hint: Label
var stance_ticks: Control
var pace_ticks: Control
var leg_bar: Control
var arm_bar: Control
var _icons: Array[AtlasTexture] = []
var _level := -1
var _pace := -1
var _prone := false
var _legs := 1.0
var _arms := 1.0
var _exhausted := false
var _initialized := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	get_viewport().size_changed.connect(_fit)
	for region in [Rect2(145,65,470,650), Rect2(700,165,530,550), Rect2(1340,300,530,415)]:
		var atlas := AtlasTexture.new()
		atlas.atlas = ART
		atlas.region = region
		_icons.append(atlas)
	icon = TextureRect.new()
	icon.name = "StanceSilhouette"
	icon.position = Vector2(12,0)
	icon.size = Vector2(118,76)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chalk := ShaderMaterial.new()
	chalk.shader = CHALK
	icon.material = chalk
	icon.modulate = PAPER
	add_child(icon)
	# Source artwork contains no prone pose. Keep its existing explicit indication,
	# now only a tiny temporary word in place of the silhouette, never a crouch icon.
	prone_hint = Label.new()
	prone_hint.name = "PronePlaceholder"
	prone_hint.text = "PRONE"
	prone_hint.position = Vector2(12,52)
	prone_hint.add_theme_font_size_override("font_size",10)
	prone_hint.modulate = PAPER
	prone_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prone_hint)
	stance_ticks = _group("StanceHeightTicks",Vector2(0,6),Vector2(3,70),_draw_stance)
	pace_ticks = _group("WalkSpeedTicks",Vector2(0,82),Vector2(110,3),_draw_pace)
	leg_bar = _group("LegStaminaBar",Vector2(0,91),Vector2(110,2),_draw_legs)
	arm_bar = _group("ArmStaminaBar",Vector2(0,97),Vector2(110,1),_draw_arms)
	_fit()
	_refresh(0.0)

func _group(title: String, at: Vector2, dimensions: Vector2, paint: Callable) -> Control:
	var control := Control.new()
	control.name = title
	control.position = at
	control.size = dimensions
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.draw.connect(paint)
	add_child(control)
	return control

func _fit() -> void:
	var logical_height := get_viewport_rect().size.y
	var pixel_height := float(get_viewport().get_texture().get_height())
	# Keep the small outline legible at 720p, without enlarging the 1080p design.
	var factor := maxf(0.85, pixel_height / 1080.0) * logical_height / pixel_height
	scale = Vector2.ONE * factor
	size = FOOTPRINT
	offset_left = EDGE * factor
	offset_top = -(FOOTPRINT.y + EDGE) * factor
	offset_right = offset_left + FOOTPRINT.x
	offset_bottom = offset_top + FOOTPRINT.y

func _process(delta: float) -> void:
	_refresh(delta)

func _refresh(delta: float) -> void:
	if player == null or player.locomotion == null: return
	var state = player.locomotion
	# Existing rules supply the physical height fraction; rounding only selects UI ticks/art.
	var level := clampi(roundi(state.height_fraction(player.body_shape.shape.height) * 6.0) + 1,1,7)
	if not _initialized or level != _level or player.is_prone != _prone:
		_level = level
		_prone = player.is_prone
		icon.texture = _icons[0 if level >= 6 else (1 if level >= 3 else 2)]
		icon.visible = not _prone
		prone_hint.visible = _prone
		stance_ticks.queue_redraw()
	if not _initialized or _pace != state.speed_setting:
		_pace = state.speed_setting
		pace_ticks.queue_redraw()
	var legs: float = state.leg_fraction()
	var arms: float = state.arm_fraction()
	var next_legs := move_toward(_legs,legs,delta * 2.0) if _initialized else legs
	var next_arms := move_toward(_arms,arms,delta * 2.0) if _initialized else arms
	if not _initialized or next_legs != _legs or _exhausted != state.exhausted:
		_legs = next_legs
		_exhausted = state.exhausted
		leg_bar.queue_redraw()
	if not _initialized or next_arms != _arms:
		_arms = next_arms
		arm_bar.queue_redraw()
	_initialized = true

func _draw_stance() -> void:
	for index in range(7):
		stance_ticks.draw_rect(Rect2(0,60-index*10,3,6),PAPER if not _prone and index < _level else INACTIVE)

func _draw_pace() -> void:
	for index in range(10):
		pace_ticks.draw_rect(Rect2(index*11.5,0,6,3),PAPER if index < _pace else INACTIVE)

func _draw_legs() -> void:
	leg_bar.draw_rect(Rect2(0,0,110,2),Color(0.38,0.43,0.38,0.3))
	var tint := Color("7b9585") if not _exhausted else Color("776f60")
	leg_bar.draw_rect(Rect2(0,0,110*_legs,2),tint)

func _draw_arms() -> void:
	arm_bar.draw_rect(Rect2(0,0,110,1),Color(0.38,0.43,0.38,0.2))
	arm_bar.draw_rect(Rect2(0,0,110*_arms,1),Color(0.57,0.66,0.6,0.6))
