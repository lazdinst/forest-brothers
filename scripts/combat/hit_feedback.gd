extends CanvasLayer
## Local presentation of hits the player takes: a red arc pointing toward the source and a zone sound.
## Reads player signals only; it never changes health.
const HitSounds = preload("res://scripts/combat/hit_sounds.gd")
const SHOW_SECONDS := 1.4
const RADIUS := 130.0
const SPAN := 0.55
var player: Node3D
var indicators: Array[Dictionary] = []
var _canvas: Control
var _sound: AudioStreamPlayer

func attach(owner_player: Node3D) -> void:
	player = owner_player
	layer = 5
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_indicators)
	add_child(_canvas)
	_sound = AudioStreamPlayer.new()
	_sound.volume_db = -10.0
	add_child(_sound)
	player.hit_taken.connect(on_hit)

## Angle of a world point around the player: 0 ahead, positive to the right, ±PI behind.
func bearing_to(world_position: Vector3) -> float:
	var local: Vector3 = player.global_basis.inverse() * (world_position - player.global_position)
	return atan2(local.x, -local.z)

func on_hit(zone: StringName, from: Vector3) -> void:
	indicators.append({"bearing": bearing_to(from), "from": from, "zone": zone, "left": SHOW_SECONDS})
	if DisplayServer.get_name() != "headless":
		_sound.stream = HitSounds.stream(zone)
		_sound.play()
	_canvas.queue_redraw()

func _process(delta: float) -> void:
	if indicators.is_empty():
		return
	for indicator in indicators:
		indicator.left -= delta
		# Keep pointing at the source while the player turns.
		indicator.bearing = bearing_to(indicator.from)
	indicators = indicators.filter(func(i): return i.left > 0.0)
	_canvas.queue_redraw()

func _draw_indicators() -> void:
	var centre := _canvas.size / 2.0
	for indicator in indicators:
		var alpha: float = clampf(indicator.left / SHOW_SECONDS, 0.0, 1.0)
		var width := 12.0 if indicator.zone == &"head" else 8.0
		# Screen angles start at +x and grow clockwise; bearing 0 is straight up.
		var angle: float = indicator.bearing - PI / 2.0
		_canvas.draw_arc(centre, RADIUS, angle - SPAN / 2.0, angle + SPAN / 2.0, 16, Color(0.75, 0.05, 0.03, alpha * 0.85), width)
