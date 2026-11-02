extends SceneTree
const BodyHealth = preload("res://scripts/combat/body_health.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
func _run() -> void:
	var body = BodyHealth.new()
	_check(body.is_alive() and body.health[BodyHealth.HEAD]==35.0,"New body starts alive with placeholder maximums")
	_check(body.apply_damage(BodyHealth.HEAD,20)==BodyHealth.NONE and body.is_alive(),"Partial head damage does not kill")
	_check(body.apply_damage(BodyHealth.HEAD,20)==BodyHealth.KILLED and body.is_dead(),"Head at zero kills")
	_check(body.apply_damage(BodyHealth.TORSO,500)==BodyHealth.NONE,"Dead body ignores further hits")
	body = BodyHealth.new()
	_check(body.apply_damage(BodyHealth.TORSO,80)==BodyHealth.DOWNED and body.is_downed(),"Torso at zero downs")
	_check(body.apply_damage(BodyHealth.TORSO,0.1)==BodyHealth.KILLED and body.is_dead(),"Any hit on a downed body kills")
	body = BodyHealth.new()
	body.apply_damage(BodyHealth.TORSO,80)
	_check(body.apply_damage(BodyHealth.LEGS,1)==BodyHealth.KILLED,"Leg hit on a downed body kills once")
	body = BodyHealth.new()
	_check(body.apply_damage(BodyHealth.LEGS,70)==BodyHealth.LIMB_DISABLED and body.is_alive(),"Leg at zero disables without death")
	_check(body.apply_damage(BodyHealth.LEGS,70)==BodyHealth.NONE and body.is_alive(),"Disabled limb does not trigger twice")
	_check(body.apply_damage(BodyHealth.ARMS,60)==BodyHealth.LIMB_DISABLED and body.is_alive(),"Arm at zero disables without death")
	_check(body.apply_damage(&"tail",99)==BodyHealth.NONE and body.is_alive(),"Unknown zone is ignored")
	body = BodyHealth.new({BodyHealth.HEAD: 10.0}, {BodyHealth.HEAD: 2.0})
	_check(body.apply_damage(BodyHealth.HEAD,5)==BodyHealth.KILLED,"Configured maximum and multiplier apply")
	body = BodyHealth.new()
	_check(body.bleed_out()==BodyHealth.NONE and body.is_alive(),"Bleed-out does nothing to a standing body")
	body.apply_damage(BodyHealth.TORSO,80)
	_check(body.bleed_out()==BodyHealth.KILLED and body.is_dead(),"Bleed-out kills a downed body")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: head kills, torso downs, downed hit kills, limbs disable once, bleed-out, config")
	quit(0 if failures.is_empty() else 1)
