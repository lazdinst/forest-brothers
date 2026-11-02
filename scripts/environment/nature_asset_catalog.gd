extends RefCounted
## Explicit review inventory. Composite forests and the man-made crate are excluded.
const BASE := "res://assets/environment/"
const ITEMS := [
	{"id":"spruce_v1", "name":"Spruce / first proof", "status":"Earlier mesh", "kind":"scene"},
	{"id":"forest_spruce_v1", "name":"Spruce / forest variant", "status":"Earlier mesh", "kind":"scene"},
	{"id":"forest_pine_v1", "name":"Scots pine", "status":"Detailed bark + needles", "kind":"scene"},
	{"id":"forest_birch_v1", "name":"Silver birch", "status":"Detailed skin + root collar", "kind":"scene"},
	{"id":"fallen_log_v1", "name":"Fallen log / original", "status":"Earlier mesh", "kind":"scene"},
	{"id":"decayed_stump_v1", "name":"Decayed stump", "status":"Earlier mesh", "kind":"scene"},
	{"id":"pine_fallen_v2", "name":"Fallen pine", "status":"Detailed bark + broken limbs", "kind":"scene"},
	{"id":"pine_rotten_v2", "name":"Rotten pine / moss", "status":"Hollow wood + moss", "kind":"scene"},
	{"id":"pine_snag_v2", "name":"Broken pine snag", "status":"Standing deadwood", "kind":"scene"},
	{"id":"pine_branch_dead_v2", "name":"Dead pine branch", "status":"Ground debris", "kind":"scene"},
	{"id":"pine_branch_broken_v2", "name":"Broken pine branch", "status":"Splintered ground debris", "kind":"scene"},
	{"id":"boulder_v1", "name":"Forest boulder", "status":"Earlier mesh", "kind":"scene"},
	{"id":"fern_v1", "name":"Fern", "status":"Earlier mesh", "kind":"scene"},
	{"id":"grass_tuft_v1", "name":"Grass tuft", "status":"Earlier ground cover", "kind":"mesh"},
	{"id":"leaf_litter_v1", "name":"Leaf litter", "status":"Earlier ground cover", "kind":"mesh"},
	{"id":"moss_clump_v1", "name":"Moss clump", "status":"Earlier ground cover", "kind":"material_mesh"},
	{"id":"moss_ground_v1", "name":"Moss / dirt ground", "status":"Original 24 m surface", "kind":"scene"},
]

static func resource_path(item: Dictionary) -> String:
	if item.kind == "scene":
		return BASE + "scenes/" + item.id + ".tscn"
	return BASE + "meshes/" + item.id + (".tres" if item.kind == "material_mesh" else ".res")

static func instantiate_item(item: Dictionary) -> Node3D:
	if item.kind == "scene":
		return load(resource_path(item)).instantiate()
	var node := MeshInstance3D.new()
	node.mesh = load(resource_path(item))
	return node

static func bounds(node: Node3D) -> AABB:
	var result := AABB()
	var found := false
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh_node in meshes:
		var transform := Transform3D.IDENTITY
		var current: Node3D = mesh_node
		while current != node:
			transform = current.transform * transform
			current = current.get_parent()
		var box: AABB = transform * mesh_node.get_aabb()
		result = result.merge(box) if found else box
		found = true
	return result
