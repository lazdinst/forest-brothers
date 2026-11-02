extends RefCounted
## Per-character local rules; no input, scene, presentation or network authority.
const Tuning = preload("res://scripts/player/movement_tuning.gd")
var tuning: Resource
var speed_setting: int
var previous_speed: int
var stance_level := 7
var previous_stance := 7
var prone := false
var legs: float
var arms: float
var exhausted := false
var carried_weight := 0.0
var _leg_delay := 0.0
var _arm_delay := 0.0

func _init(settings: Resource = null) -> void:
	tuning = settings if settings != null else Tuning.new()
	speed_setting = clampi(tuning.default_speed_setting, 1, tuning.speed_increments)
	previous_speed = maxi(2, speed_setting)
	legs = tuning.leg_maximum
	arms = tuning.arm_maximum

func adjust_speed(steps: int) -> void:
	speed_setting = clampi(speed_setting + steps, 1, tuning.speed_increments)
	if speed_setting > 1: previous_speed = speed_setting

func toggle_slow() -> void:
	if speed_setting == 1:
		speed_setting = clampi(previous_speed, 2, tuning.speed_increments)
	else:
		previous_speed = speed_setting
		speed_setting = 1

func leg_fraction() -> float: return clampf(legs / tuning.leg_maximum, 0.0, 1.0)
func arm_fraction() -> float: return clampf(arms / tuning.arm_maximum, 0.0, 1.0)
func load_fraction() -> float:
	return clampf((carried_weight - tuning.unpenalized_weight) / maxf(0.01, tuning.heavy_weight - tuning.unpenalized_weight), 0.0, 1.0)
func load_speed() -> float: return lerpf(1.0, tuning.heavy_speed_multiplier, load_fraction())
func load_drain() -> float: return lerpf(1.0, tuning.heavy_stamina_multiplier, load_fraction())
func can_sprint() -> bool: return not prone and not exhausted and legs > tuning.exhaustion_threshold
func target_height() -> float: return tuning.prone_height if prone else tuning.stance_heights[stance_level - 1]

func height_fraction(height: float) -> float:
	return clampf((height - tuning.stance_heights[0]) / (tuning.stance_heights[6] - tuning.stance_heights[0]), 0.0, 1.0)

func stance_limit(height: float) -> float:
	if prone: return tuning.prone_speed_limit
	var level := height_fraction(height) * 6.0
	var index := mini(int(level), 5)
	return lerpf(tuning.stance_speed_limits[index], tuning.stance_speed_limits[index + 1], level - index)

func walking_speed(height: float, aiming: bool) -> float:
	var selected := lerpf(tuning.minimum_walk_speed, tuning.maximum_walk_speed, float(speed_setting - 1) / (tuning.speed_increments - 1))
	return minf(selected, tuning.maximum_walk_speed * stance_limit(height)) * load_speed() * (tuning.exhausted_speed_multiplier if exhausted else 1.0) * (tuning.ads_speed_multiplier if aiming else 1.0)

func spend_legs(cost: float) -> bool:
	var amount := cost * load_drain()
	if legs < amount or exhausted: return false
	legs = maxf(0.0, legs - amount)
	_leg_delay = tuning.recovery_delay
	_update_exhaustion()
	return true

func _update_exhaustion() -> void:
	if legs <= tuning.exhaustion_threshold: exhausted = true
	elif legs >= tuning.sprint_reactivation_threshold: exhausted = false

func advance(delta: float, sprinting: bool, moving: bool, aiming: bool, weapon_weight: float, strenuous := false) -> void:
	if sprinting:
		legs = maxf(0.0, legs - tuning.sprint_drain * load_drain() * delta)
		_leg_delay = tuning.recovery_delay
	elif strenuous:
		_leg_delay = tuning.recovery_delay
	else:
		var recovery_time := maxf(0.0, delta - _leg_delay)
		_leg_delay = maxf(0.0, _leg_delay - delta)
		legs = minf(tuning.leg_maximum, legs + recovery_time * (tuning.walking_recovery if moving else tuning.stationary_recovery))
	if aiming:
		arms = maxf(0.0, arms - tuning.ads_drain * maxf(0.25, weapon_weight / 4.0) * delta)
		_arm_delay = tuning.arm_recovery_delay
	else:
		var recovery_time := maxf(0.0, delta - _arm_delay)
		_arm_delay = maxf(0.0, _arm_delay - delta)
		arms = minf(tuning.arm_maximum, arms + recovery_time * tuning.arm_recovery)
	_update_exhaustion()
