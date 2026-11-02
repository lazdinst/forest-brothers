extends RefCounted
## Four painted walk frames per view. Source silhouettes are preserved as atlases.
const ATLASES = [
	preload("res://assets/characters/training_guard/walking_v1/walk_0_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_45_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_90_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_135_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_180_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_225_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_270_v1.png"),
	preload("res://assets/characters/training_guard/walking_v1/walk_315_v1.png"),
]
const REGIONS = [
	[Rect2(428, 4, 280, 498), Rect2(893, 4, 276, 496), Rect2(424, 510, 291, 494), Rect2(892, 510, 288, 487)],
	[Rect2(226, 7, 367, 584), Rect2(802, 7, 347, 588), Rect2(228, 612, 367, 582), Rect2(812, 614, 345, 585)],
	[Rect2(122, 14, 458, 612), Rect2(809, 14, 337, 612), Rect2(116, 654, 464, 599), Rect2(815, 658, 331, 599)],
	[Rect2(383, 4, 345, 503), Rect2(977, 4, 280, 506), Rect2(363, 515, 366, 483), Rect2(975, 515, 297, 495)],
	[Rect2(60, 27, 393, 695), Rect2(545, 27, 378, 698), Rect2(61, 790, 390, 700), Rect2(569, 790, 381, 708)],
	[Rect2(288, 7, 369, 491), Rect2(867, 7, 326, 492), Rect2(288, 512, 368, 495), Rect2(865, 513, 349, 493)],
	[Rect2(162, 29, 420, 590), Rect2(700, 31, 403, 590), Rect2(161, 650, 444, 588), Rect2(697, 651, 391, 590)],
	[Rect2(316, 9, 286, 543), Rect2(850, 9, 275, 556), Rect2(307, 557, 302, 543), Rect2(870, 557, 272, 546)],
]
# Measured head/cap center keeps body position independent of the moving feet/rifle.
const CENTERS = [
	[533.5, 1003.5, 534.5, 1003.5],
	[384.5, 934.5, 383, 946.5],
	[341.5, 913, 340, 915.5],
	[524.5, 1074.5, 525, 1074.5],
	[301, 775, 296.5, 795.5],
	[481, 1052, 485.5, 1054.5],
	[379.5, 917, 376, 914],
	[425.5, 940.5, 437.5, 960.5],
]
