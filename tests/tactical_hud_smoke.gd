extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _run() -> void:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	await frames(12)
	var player = world.player
	var hud = world.get_node("HUD/TacticalMovement")
	var overlay = world.debug_overlay
	for title in ["Title","Subtitle","Status","Controls","MovementState","WeaponStatus"]:
		check(not world.get_node("HUD/"+title).visible,"Normal play hides "+title)
	check(not world.resource_strip.visible and not overlay.enabled,"Resource diagnostics are hidden by default")
	var annex = world.get_node("SystemsAnnex")
	check(not annex._entry_hint.visible and not annex._summary.visible,"Annex diagnostics hidden")
	check(world.get_node("HUD/Prompt").visible,"Contextual interaction prompts retained")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		root.size = resolution
		await frames(2)
		var rect: Rect2 = hud.get_global_rect()
		var physical_scale: float = resolution.y / root.get_visible_rect().size.y
		rect = Rect2(rect.position * physical_scale, rect.size * physical_scale)
		var factor: float = maxf(0.85,resolution.y / 1080.0)
		check(absf(rect.position.x-24*factor)<1 and absf(resolution.y-rect.end.y-24*factor)<1,"Anchored lower left at "+str(resolution))
		check(absf(rect.size.x-130*factor)<1 and absf(rect.size.y-102*factor)<1,"Compact scaled footprint at "+str(resolution))
		check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE,"HUD cannot consume input")
	player.set_physics_process(false)
	for level in range(1,8):
		player.body_shape.shape.height = player.movement_tuning.stance_heights[level-1]
		hud._refresh(0)
		check(hud._level==level,"Physical stance tick mapping %d" % level)
		check(hud.icon.texture==hud._icons[0 if level>=6 else (1 if level>=3 else 2)],"Approved silhouette category %d" % level)
	player.locomotion.stance_level = 7
	player.body_shape.shape.height = 1.2
	hud._refresh(0)
	check(hud._level==2,"Blocked physical height overrides requested standing")
	player.locomotion.speed_setting = 4
	player.is_sprinting = true
	hud._refresh(0)
	check(hud._pace==4,"Sprint preserves selected pace indicator")
	player.is_prone = true
	hud._refresh(0)
	check(not hud.icon.visible and hud.prone_hint.visible,"Prone never masquerades as crouch")
	player.locomotion.legs = 0
	player.locomotion.arms = 0
	player.locomotion.exhausted = true
	hud._refresh(0.1)
	check(hud._legs>0 and hud._legs<1,"Stamina depletion interpolates")
	hud._refresh(1)
	check(hud._legs==0 and hud._arms==0 and hud._exhausted,"Empty stamina is visibly empty")
	var debug_key := InputEventKey.new()
	debug_key.physical_keycode = KEY_F3
	debug_key.pressed = true
	overlay._unhandled_key_input(debug_key)
	await frames(2)
	check(overlay.enabled and world.resource_strip.visible and annex.debug_diagnostics_visible,"F3 exposes diagnostics separately")
	check(overlay.details.text.contains("Pace") and overlay.details.text.contains("Load"),"Useful detailed diagnostics retained")
	overlay._unhandled_key_input(debug_key)
	await frames(2)
	check(not overlay.enabled and not annex._entry_hint.visible,"F3 hides all persistent diagnostics")
	overlay.allowed = false
	overlay._unhandled_key_input(debug_key)
	check(not overlay.enabled,"Production guard rejects shortcut")
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("PASS: compact HUD scaling, physical stance/art, sprint pace, smoothed stamina, contextual prompts and gated debug overlay")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
