extends "res://scripts/environment/bake_visual_proof.gd"
## Explicit offline baker. Writes resources and GeneratedForest only; manual props
## remain in training_environment.tscn. No regeneration or random rolls in play.
const Layout = preload("res://scripts/environment/forest_layout.gd")
var batches: Dictionary = {}
var occupied: Array[Vector2] = []
var forest: Node3D
var forest_seed: int = Layout.SEED
var tree_spacing: int = 5
var undergrowth_attempts: int = 6500
var counts: Dictionary = {"trees":0,"logs":0,"stumps":0,"ferns":0,"grass":0,"litter":0,"moss":0,"rocks":0}

func _initialize() -> void:
	# Dummy headless rendering drops MultiMesh instance buffers during save.
	# Fail before touching outputs rather than producing an invisible forest.
	if DisplayServer.get_name() == "headless":
		push_error("Forest baking requires the real Compatibility renderer. Omit --headless; ordinary physics checks may still run headless.")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			forest_seed = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--tree-spacing="):
			tree_spacing = clampi(arg.trim_prefix("--tree-spacing=").to_int(),3,12)
		elif arg.begins_with("--undergrowth="):
			undergrowth_attempts = clampi(arg.trim_prefix("--undergrowth=").to_int(),0,30000)
	call_deferred("_build_forest")

func _segment(st: SurfaceTool, a: Vector3, b: Vector3, radius_a: float, radius_b: float) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.radial_segments = 7
	cylinder.rings = 1
	cylinder.bottom_radius = radius_a
	cylinder.top_radius = radius_b
	cylinder.height = a.distance_to(b)
	var direction := (b-a).normalized()
	var right := direction.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.1:
		right = direction.cross(Vector3.RIGHT).normalized()
	var basis := Basis(right, direction, right.cross(direction))
	st.append_from(cylinder, 0, Transform3D(basis, (a+b)*0.5))

func _tree(kind: String) -> PackedScene:
	var root_node := Node3D.new()
	root_node.name = kind.to_pascal_case()
	var stems := SurfaceTool.new()
	stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height_value := 15.5 if kind == "pine" else (11.5 if kind == "birch" else 12.0)
	_segment(stems, Vector3.ZERO, Vector3(0.12,height_value,0), 0.22 if kind != "birch" else 0.14, 0.025)
	var tiers := 10 if kind == "spruce" else (5 if kind == "pine" else 4)
	for tier in range(tiers):
		var y := 1.8 + tier * 1.08 if kind == "spruce" else (7.0+tier*1.8 if kind == "pine" else height_value*0.53+tier*1.5)
		var width := 2.9 * (1.0 - float(tier)/10.5) if kind == "spruce" else (2.5 + sin(tier*1.4)*0.8)
		var offset := rng.randf()*TAU
		for branch in range(7):
			var angle := branch*TAU/7.0+offset
			var d := Vector3(cos(angle),0,sin(angle))
			var side := Vector3(-d.z,0,d.x)
			var end := d*width*rng.randf_range(0.7,1.15)+Vector3(0,y+rng.randf_range(-0.18,0.18)+(0.5 if kind != "spruce" else -0.35),0)
			_segment(stems,Vector3(0,y,0),end,0.045,0.009)
			for section in range(1,6):
				var t := float(section)/6.0
				var center := Vector3(0,y,0).lerp(end,t)
				for side_sign in [-1.0,1.0]:
					for twig in range(3):
						var q := float(twig+1)/3.0
						var tip: Vector3 = center+side*side_sign*(1.0-t)*q*0.65-d*q*0.1
						var color := Color(0.78,0.90,0.68).lerp(Color(1.1,1.07,0.9),rng.randf())
						if kind == "birch":
							_triangle(leaves,tip-side*0.13,tip+d*0.22+Vector3.UP*0.06,tip+side*0.13,color)
							_triangle(leaves,tip-side*0.1,tip+d*0.17-Vector3.UP*0.12,tip+side*0.1,color)
						else:
							var spread := 0.10 if kind == "spruce" else 0.15
							_triangle(leaves,tip-side*spread,tip+d*0.36+Vector3.UP*0.05,tip+side*spread,color)
							_triangle(leaves,tip-Vector3.UP*spread,tip+d*0.31,tip+Vector3.UP*spread,color)
	if kind == "birch":
		# Preserve this legacy recipe's random draws above, so improving one
		# species never reshuffles the forest/terrain/deadwood placement stream.
		root_node.free()
		return preload("res://scripts/environment/birch_recipe.gd").new().bake()
	if kind == "pine":
		# Preserve the existing world-placement random stream, as with birch.
		root_node.free()
		return preload("res://scripts/environment/pine_recipe.gd").new().bake()
	var trunk_mat: Material = bark
	if kind == "birch":
		var birch := ShaderMaterial.new()
		birch.shader = load("res://scripts/environment/birch_bark.gdshader")
		_save(birch,"materials/birch_bark_v1.tres")
		trunk_mat = birch
	_visual(root_node,_finish(stems,trunk_mat,"forest_"+kind+"_wood_v1"),"Trunk")
	var leaf_mat := fern_material if kind == "birch" else needles
	_visual(root_node,_finish(leaves,leaf_mat,"forest_"+kind+"_crown_v1"),"Crown")
	return _pack(root_node,"forest_"+kind+"_v1")

func _deadwood(stump: bool) -> PackedScene:
	var node := Node3D.new()
	node.name = "Stump" if stump else "FallenLog"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if stump:
		_segment(st,Vector3.ZERO,Vector3(0.07,0.6,0.03),0.42,0.29)
		for i in range(6):
			var a := i*TAU/6.0
			_segment(st,Vector3(cos(a)*0.8,0.03,sin(a)*0.8),Vector3(0,0.25,0),0.035,0.12)
	else:
		_segment(st,Vector3(-2.6,0.30,0),Vector3(2.6,0.23,0.05),0.33,0.21)
		for i in range(7):
			var x := -2.1+i*0.65
			var side := -1.0 if i%2==0 else 1.0
			_segment(st,Vector3(x,0.28,0),Vector3(x+0.22,0.48,side*rng.randf_range(0.4,0.9)),0.08,0.015)
	var id := "decayed_stump_v1" if stump else "fallen_log_v1"
	_visual(node,_finish(st,bark,id),"Bark")
	# Broken pale endgrain makes the deadwood read at ground level.
	var ends := SurfaceTool.new()
	ends.begin(Mesh.PRIMITIVE_TRIANGLES)
	if stump:
		_segment(ends,Vector3(0.07,0.595,0.03),Vector3(0.07,0.607,0.03),0.285,0.285)
	else:
		_segment(ends,Vector3(-2.61,0.30,0),Vector3(-2.62,0.30,0),0.31,0.31)
		_segment(ends,Vector3(2.61,0.23,0.05),Vector3(2.62,0.23,0.05),0.2,0.2)
	_visual(node,_finish(ends,wood,id+"_ends"),"Endgrain")
	return _pack(node,id)

func _ground_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Half-metre grid is real relief/collision, including the excavated trench.
	for zi in range(200):
		for xi in range(200):
			var x := Layout.MIN_X+xi*0.5
			var z := Layout.MIN_Z+zi*0.5
			if x >= 27 and z > -25 and z < 25:
				continue # Keep the other agent's annex floor/stations independent.
			var a := Vector3(x,Layout.height(x,z),z)
			var b := Vector3(x+0.5,Layout.height(x+0.5,z),z)
			var c := Vector3(x,Layout.height(x,z+0.5),z+0.5)
			var d := Vector3(x+0.5,Layout.height(x+0.5,z+0.5),z+0.5)
			_triangle(st,a,b,c)
			_triangle(st,b,d,c)
	var mat: Material = load(BASE+"materials/moss_ground_v1.tres")
	var mesh := _finish(st,mat,"training_terrain_v2")
	_visual(forest,mesh,"Terrain")
	var collision := mesh.create_trimesh_shape()
	_save(collision,"meshes/training_terrain_collision_v2.res")
	_body(forest,collision,Vector3.ZERO,"TerrainBody")

func _batch(mesh: Mesh, transform: Transform3D, shadow: bool = true, tint: Color = Color.WHITE) -> void:
	var cell := Vector2i(floori(transform.origin.x/14.0),floori(transform.origin.z/14.0))
	var key := mesh.resource_path+str(cell)+str(shadow)
	if not batches.has(key):
		batches[key] = {"mesh":mesh,"transforms":[],"colors":[],"cell":cell,"shadow":shadow}
	batches[key].transforms.append(transform)
	batches[key].colors.append(tint)

func _place(scene: PackedScene, at: Vector3, rotation_y: float, size: float, shadow: bool = true) -> void:
	var source = scene.instantiate()
	var transform := Transform3D(Basis(Vector3.UP,rotation_y).scaled(Vector3.ONE*size),at)
	for child in source.get_children():
		if child is MeshInstance3D:
			_batch(child.mesh,transform*child.transform,shadow,Color(0.85,0.9,0.78).lerp(Color(1.08,1.03,0.95),rng.randf()))
	source.free()

func _flush_batches() -> void:
	for key in batches:
		var data: Dictionary = batches[key]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = data.mesh
		multi.instance_count = data.transforms.size()
		var offset := Vector3(data.cell.x*14,0,data.cell.y*14)
		for i in range(multi.instance_count):
			var transform: Transform3D = data.transforms[i]
			transform.origin -= offset
			multi.set_instance_transform(i,transform)
			multi.set_instance_color(i,data.colors[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Batch%03d" % forest.get_child_count()
		instance.multimesh = multi
		instance.position = offset
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if data.shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		forest.add_child(instance)

func _tree_collider(at: Vector3, size: float, id: int) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = 0.24*size
	shape.height = 10.0*size
	var body := _body(forest,shape,Vector3(0,shape.height*0.5,0),"TreeBody%03d" % id)
	body.position = at

func _small_meshes() -> Dictionary:
	var grass := SurfaceTool.new()
	grass.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(9):
		var a := rng.randf()*TAU
		var base := Vector3(rng.randf_range(-0.15,0.15),0,rng.randf_range(-0.15,0.15))
		var side := Vector3(cos(a),0,sin(a))*0.026
		_triangle(grass,base-side,base+Vector3(0.1,rng.randf_range(0.16,0.44),0.08),base+side)
	var litter := SurfaceTool.new()
	litter.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var base := Vector3(rng.randf_range(-0.5,0.5),rng.randf_range(0.01,0.03),rng.randf_range(-0.5,0.5))
		_triangle(litter,base+Vector3(-0.045,0,0),base+Vector3(0,0.018,0.12),base+Vector3(0.045,0,0),Color(0.8,0.76,0.57).lerp(Color.WHITE,rng.randf()))
	var brown := _material("leaf_litter_v1",Color(0.25,0.19,0.105),"",true)
	var moss := SphereMesh.new()
	moss.radius = 0.48
	moss.height = 0.25
	moss.radial_segments = 8
	moss.rings = 3
	moss.material = _material("moss_clump_v1",Color(0.16,0.215,0.095))
	_save(moss,"meshes/moss_clump_v1.tres")
	return {"grass":_finish(grass,fern_material,"grass_tuft_v1"),"litter":_finish(litter,brown,"leaf_litter_v1"),"moss":moss}

func _clear(p: Vector2, radius: float) -> bool:
	for other in occupied:
		if other.distance_to(p) < radius:
			return false
	return true

func _timber_trench() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Low rough revetments follow the sidewalls, with an opening at the branch.
	for z in range(23,34):
		for side in [-1.0,1.0]:
			if side < 0 and z >= 26 and z <= 28:
				continue
			_box_geometry(st,Vector3(-9+side*0.88,-0.78,z),Vector3(0.1,1.45,0.92))
			_box_geometry(st,Vector3(-9+side*0.72,-0.85,z+0.44),Vector3(0.12,1.35,0.12))
	var timber := wood.duplicate() as StandardMaterial3D
	timber.albedo_color = Color(0.65,0.59,0.47)
	_save(timber,"materials/trench_timber_v1.tres")
	var mesh := _finish(st,timber,"trench_revetment_v1")
	_visual(forest,mesh,"TrenchTimber")
	# Earth mesh owns the wall collision; timber stays decorative to avoid snags.
	var sign := Label3D.new()
	sign.name = "TrenchGuide"
	sign.position = Vector3(-8,1.8,18)
	sign.text = "Trench entrance\nWalk down the slope / side branch to the left"
	sign.font_size = 38
	sign.pixel_size = 0.0025
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	forest.add_child(sign)

func _build_forest() -> void:
	rng.seed = forest_seed
	bark = load(BASE+"materials/spruce_bark_v1.tres")
	needles = load(BASE+"materials/spruce_needles_v1.tres")
	fern_material = load(BASE+"materials/fern_v1.tres")
	wood = load(BASE+"materials/weathered_wood_v1.tres")
	var species: Array[PackedScene] = [_tree("spruce"),_tree("pine"),_tree("birch")]
	var log_scene := _deadwood(false)
	var stump_scene := _deadwood(true)
	var fern: PackedScene = load(BASE+"scenes/fern_v1.tscn")
	var rock: PackedScene = load(BASE+"scenes/boulder_v1.tscn")
	var small := _small_meshes()
	forest = Node3D.new()
	forest.name = "GeneratedForest"
	_ground_mesh()
	# Jittered strata avoid long rows; spacing/exclusions are deterministic.
	for z in range(-48,43,tree_spacing):
		for x in range(-49,40,tree_spacing):
			var p := Vector2(x+rng.randf_range(-1.6,1.6),z+rng.randf_range(-1.6,1.6))
			if Layout.reserved(p,1.4) or absf(p.x-Layout.trail_x(p.y)) < 2.2 or Layout.trench_distance(p) < 3.0 or not _clear(p,3.0):
				continue
			var size := rng.randf_range(0.78,1.28)
			var pick := 0 if p.x < -16 else (1 if rng.randf() < 0.7 else 2)
			var at := Vector3(p.x,Layout.height(p.x,p.y),p.y)
			_place(species[pick],at,rng.randf()*TAU,size)
			_tree_collider(at,size,counts.trees)
			occupied.append(p)
			counts.trees += 1
	# Deadfall and stumps in readable pockets beyond the test fixtures.
	for i in range(100):
		var p := Vector2(rng.randf_range(-44,24),rng.randf_range(-43,38))
		if Layout.reserved(p,2.0) or absf(p.x-Layout.trail_x(p.y)) < 3.5 or Layout.trench_distance(p) < 3.5 or not _clear(p,2.0):
			continue
		var at := Vector3(p.x,Layout.height(p.x,p.y),p.y)
		var angle := rng.randf()*TAU
		var size := rng.randf_range(0.7,1.2)
		var is_stump := i%3==0
		_place(stump_scene if is_stump else log_scene,at,angle,size)
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.8,0.6,0.8)*size if is_stump else Vector3(5.2,0.58,0.6)*size
		var body := _body(forest,shape,Vector3(0,0.29*size,0),"Deadwood%03d" % i)
		body.position = at
		body.rotation.y = angle
		body.add_to_group("vaultable",true)
		counts["stumps" if is_stump else "logs"] += 1
		occupied.append(p)
	# Low cover, ground clutter and small plants do not obstruct physics/rays.
	for i in range(undergrowth_attempts):
		var p := Vector2(rng.randf_range(-48,36),rng.randf_range(-47,39))
		if p.x > 25 and absf(p.y)<27 or absf(p.x-Layout.trail_x(p.y)) < 1.15 or Layout.trench_distance(p)<1.8:
			continue
		if Layout.reserved(p) and rng.randf()<0.87:
			continue
		var at := Vector3(p.x,Layout.height(p.x,p.y)+0.015,p.y)
		var scale_value := rng.randf_range(0.45,1.15)
		var transform := Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value),at)
		if i%5==0:
			_place(fern,at,rng.randf()*TAU,scale_value,false)
			counts.ferns += 1
		else:
			var id := "moss" if i%7==0 else ("grass" if i%2==0 else "litter")
			_batch(small[id],transform,false)
			counts[id] += 1
	for i in range(35):
		var p := Vector2(rng.randf_range(-43,22),rng.randf_range(-42,36))
		if Layout.reserved(p,1.5) or Layout.trench_distance(p)<3.0 or absf(p.x-Layout.trail_x(p.y))<2.0 or not _clear(p,2.0):
			continue
		var at := Vector3(p.x,Layout.height(p.x,p.y)-0.15,p.y)
		var size := rng.randf_range(0.25,0.65)
		_place(rock,at,rng.randf()*TAU,size)
		var shape := SphereShape3D.new()
		shape.radius = 0.85*size
		_body(forest,shape,at+Vector3.UP*0.4*size,"ForestRock%02d" % i)
		counts.rocks += 1
	_timber_trench()
	_flush_batches()
	forest.set_meta("seed",forest_seed)
	forest.set_meta("tree_spacing",tree_spacing)
	forest.set_meta("undergrowth_attempts",undergrowth_attempts)
	forest.set_meta("counts",counts)
	_pack(forest,"training_forest_generated")
	print("FOREST BAKE PASS ",JSON.stringify(counts),"; batches=",batches.size(),"; physical terrain + walkable trench")
	quit()
