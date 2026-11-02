extends Resource
## Reversible local training balance. Metres, kilograms, seconds, stamina points.
@export_group("Pace")
@export var minimum_walk_speed := 0.33
@export var maximum_walk_speed := 3.3
@export_range(2, 30) var speed_increments := 10
@export var default_speed_setting := 10
@export var acceleration := 9.0
@export var deceleration := 12.0
@export var backward_multiplier := 0.75
@export var strafe_multiplier := 0.9
@export var sprint_speed := 5.2
@export var sprint_acceleration := 7.0
@export var exhausted_speed_multiplier := 0.7
@export_group("Stance")
@export var stance_heights := PackedFloat32Array([1.1, 1.2, 1.32, 1.44, 1.56, 1.68, 1.8])
@export var stance_speed_limits := PackedFloat32Array([0.35, 0.42, 0.5, 0.65, 0.8, 0.9, 1.0])
@export var height_change_speed := 3.0
@export var prone_height := 0.6
@export var prone_speed_limit := 0.15
@export var ads_speed_multiplier := 0.65
@export_group("Leg stamina")
@export var leg_maximum := 100.0
@export var sprint_drain := 12.0
@export var walking_recovery := 8.0
@export var stationary_recovery := 14.0
@export var recovery_delay := 1.2
@export var exhaustion_threshold := 0.0
@export var sprint_reactivation_threshold := 25.0
@export var jump_cost := 18.0
@export var vault_cost := 22.0
@export_group("Arm stamina - provisional")
@export var arm_maximum := 100.0
@export var ads_drain := 5.0
@export var arm_recovery := 12.0
@export var arm_recovery_delay := 0.6
@export var fatigue_sway_radians := 0.006
@export_group("Load - provisional")
@export var unpenalized_weight := 12.0
@export var heavy_weight := 35.0
@export var heavy_speed_multiplier := 0.55
@export var heavy_stamina_multiplier := 1.8
@export var magazine_weight := 0.25
@export var cartridge_weight := 0.025
@export var additional_equipment_weight := 0.0
@export_group("Noise - provisional")
@export var walking_noise := 0.3
@export var sprint_noise := 0.6
@export var crouch_noise_multiplier := 0.45
@export var prone_noise_multiplier := 0.2
