extends CanvasLayer
## Placeholder loader below the crosshair while a treatment runs, until dedicated treatment
## animations exist: a filling ring, the supply and body part, and the seconds left. Shows the
## player's own treatment (on themself or a teammate) and a teammate reviving or treating them.
## Read-only: it never changes health.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const PlayerHealth = preload("res://scripts/health/player_health.gd")
const PAPER := Color("dfc49b")
const SHADE := Color(0.08, 0.07, 0.06, 0.55)
const RADIUS := 20.0
const BELOW_CENTRE := 92.0
var player: Node3D
var _canvas: Control
var _status := {}

func attach(owner_player: Node3D) -> void:
	player = owner_player
	layer = 6
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_loader)
	add_child(_canvas)

## What the loader shows now: empty when hidden, else {title, progress, seconds}.
func status() -> Dictionary:
	if player == null or not is_instance_valid(player): return {}
	var body = player.body
	if not body.treatment.is_empty():
		var record: Dictionary = body.treatment
		var title: String = SupplyCatalog.get_def(record.supply_id).get("name","Treatment")
		var own: bool = body.treatment_patient() == body
		if record.revive: title = "Reviving teammate · " + title.to_lower()
		elif not own: title = "Treating teammate · " + title.to_lower()
		if SupplyCatalog.get_def(record.supply_id).get("targets_part",false):
			title += " · " + PlayerHealth.LABELS.get(record.part,"").to_lower()
		return {"title":title,"progress":body.treatment_progress(),"seconds":maxf(0.0,record.left)}
	# A teammate working on this player.
	for teammate in player.get_tree().get_nodes_in_group(&"mission_players") if player.is_inside_tree() else []:
		if teammate == player or teammate.get("body") == null: continue
		if teammate.body.treatment_patient() == body:
			var reviving: bool = teammate.body.treatment.revive
			return {"title":"Being revived" if reviving else "Teammate treating you","progress":teammate.body.treatment_progress(),"seconds":maxf(0.0,teammate.body.treatment.left)}
	return {}

func _process(_delta: float) -> void:
	var now := status()
	if now.is_empty() and _status.is_empty(): return
	_status = now
	_canvas.queue_redraw()

func _draw_loader() -> void:
	if _status.is_empty(): return
	var centre := _canvas.size * 0.5 + Vector2(0.0, BELOW_CENTRE)
	var font := ThemeDB.fallback_font
	_canvas.draw_circle(centre, RADIUS + 7.0, SHADE)
	_canvas.draw_arc(centre, RADIUS, 0.0, TAU, 48, Color(PAPER, 0.25), 4.0, true)
	var progress: float = clampf(_status.progress, 0.0, 1.0)
	if progress > 0.0:
		_canvas.draw_arc(centre, RADIUS, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, PAPER, 4.0, true)
	var seconds := "%.1f" % _status.seconds
	var seconds_size := font.get_string_size(seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	_canvas.draw_string(font, centre + Vector2(-seconds_size.x * 0.5, 5.0), seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PAPER)
	var title: String = _status.title
	var title_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	var title_at := centre + Vector2(-title_size.x * 0.5, RADIUS + 28.0)
	_canvas.draw_rect(Rect2(title_at + Vector2(-8.0, -16.0), Vector2(title_size.x + 16.0, 22.0)), SHADE)
	_canvas.draw_string(font, title_at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PAPER)
