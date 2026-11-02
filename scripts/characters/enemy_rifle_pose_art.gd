extends RefCounted
## Immutable painted content only; weapon/ammunition rules remain in enemy_actor.
const HOLD_ATLAS = preload("res://assets/characters/training_guard/rifle_poses_v1/holding_8way_v1.png")
const AIM_ATLAS = preload("res://assets/characters/training_guard/rifle_poses_v1/aiming_8way_v1.png")
const FIRE_ATLAS = preload("res://assets/characters/training_guard/firing_v1/firing_8way_v1.png")
# Same cap/sole bounds as aiming to avoid scale jumps; widened for flash tips.
const FIRE_REGIONS = [
	Rect2(84, 12, 199, 491), Rect2(426, 12, 382, 492),
	Rect2(833, 12, 353, 492), Rect2(1221, 12, 314, 491),
	Rect2(79, 513, 203, 488), Rect2(326, 510, 334, 492),
	Rect2(727, 511, 344, 494), Rect2(1132, 512, 312, 493),
]
# Each tight silhouette has four pixels of padding. Weapon overhang means these
# regions cannot be centered on the actor or cut as equal-width source cells.
const HOLD_REGIONS = [
	Rect2(133, 4, 277, 498), Rect2(489, 4, 288, 498),
	Rect2(873, 5, 232, 497), Rect2(1195, 5, 264, 496),
	Rect2(55, 509, 293, 499), Rect2(400, 509, 287, 499),
	Rect2(765, 510, 238, 500), Rect2(1202, 510, 260, 502),
]
const AIM_REGIONS = [
	Rect2(84, 12, 198, 491), Rect2(427, 12, 358, 492),
	Rect2(833, 12, 323, 492), Rect2(1221, 12, 305, 491),
	Rect2(79, 513, 201, 488), Rect2(351, 510, 308, 492),
	Rect2(756, 511, 315, 494), Rect2(1165, 512, 276, 493),
]
const HOLD_CENTERS = [242.0, 595.5, 939.5, 1281.5, 236.5, 577.5, 934.5, 1291.0]
const AIM_CENTERS = [182.5, 531.0, 910.0, 1316.5, 175.5, 553.0, 987.5, 1344.0]
# Painted muzzle tips in source-atlas pixels; the straight back view is occluded.
const AIM_MUZZLES = [
	Vector2(210, 78), Vector2(777, 78), Vector2(1148, 78), Vector2(1518, 78),
	Vector2(220, 565), Vector2(359, 572), Vector2(764, 572), Vector2(1173, 572),
]
