extends RefCounted
## Silver-birch candidate v2.1: continuous root collar, independent art seed.
const BASE := "res://assets/environment/"
var rng := RandomNumberGenerator.new()
var wood := SurfaceTool.new()
var foliage := SurfaceTool.new()
var leaf_count := 0

func _save(resource: Resource,path: String) -> void:
	var full := BASE+path
	assert(ResourceSaver.save(resource,full)==OK,"Save birch asset "+full)
	resource.take_over_path(full)

func _vertex(st: SurfaceTool,p: Vector3,n: Vector3,uv: Vector2,color: Color) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.set_color(color)
	st.add_vertex(p)

func _tube(points: Array[Vector3],start_radius: float,end_radius: float,sides: int,white: float = 1.0,root_collar: bool = false) -> void:
	var rings: Array = []
	var distance := 0.0
	for j in range(points.size()):
		if j>0:
			distance += points[j].distance_to(points[j-1])
		var tangent := (points[mini(j+1,points.size()-1)]-points[maxi(j-1,0)]).normalized()
		var u := tangent.cross(Vector3.FORWARD).normalized()
		if u.length_squared()<0.2:
			u = tangent.cross(Vector3.RIGHT).normalized()
		var v := tangent.cross(u).normalized()
		var t := float(j)/(points.size()-1)
		if root_collar:
			t = clampf(points[j].y/11.5,0.0,1.0)
		var radius := lerpf(start_radius,end_radius,pow(t,0.83))
		var ring: Array = []
		for i in range(sides+1):
			var angle := i*TAU/sides
			var normal := u*cos(angle)+v*sin(angle)
			var irregularity := 1.0+0.035*sin(angle*3.0+distance*1.6)
			var section_radius := radius*irregularity
			if root_collar:
				var y := maxf(points[j].y,0.0)
				# A gradual root collar, with low asymmetric structural-root
				# shoulders in the SAME surface. The lowest ring is buried.
				section_radius += 0.035*exp(-y/0.24)
				for root in [[0.3,0.075,0.34],[1.9,0.045,0.43],[3.65,0.09,0.31],[5.2,0.035,0.47]]:
					var delta := wrapf(angle-root[0],-PI,PI)
					section_radius += root[1]*exp(-pow(delta/root[2],2.0))*exp(-y/0.12)
			ring.append([points[j]+normal*section_radius,normal,Vector2(float(i)/sides,distance)])
		rings.append(ring)
	if root_collar:
		# Normals follow the actual widening so the collar shades smoothly
		# into the trunk rather than looking like a vertical cylinder skirt.
		for j in range(rings.size()):
			for i in range(sides+1):
				var across: Vector3 = rings[j][(i+1)%sides][0]-rings[j][(i-1+sides)%sides][0]
				var along: Vector3 = rings[mini(j+1,rings.size()-1)][i][0]-rings[maxi(j-1,0)][i][0]
				rings[j][i][1] = across.cross(along).normalized()
	for j in range(rings.size()-1):
		for i in range(sides):
			var a: Array = rings[j][i]
			var b: Array = rings[j][i+1]
			var c: Array = rings[j+1][i]
			var d: Array = rings[j+1][i+1]
			for vertex in [a,c,b,b,c,d]:
				_vertex(wood,vertex[0],vertex[1],vertex[2],Color(white,white,white))

func _curve(a: Vector3,b: Vector3,c: Vector3,steps: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for i in range(steps+1):
		var t := float(i)/steps
		result.append(a*(1-t)*(1-t)+b*2*t*(1-t)+c*t*t)
	return result

func _leaf(at: Vector3,length: float) -> void:
	var basis := Basis.from_euler(Vector3(rng.randf_range(-1.1,1.1),rng.randf()*TAU,rng.randf_range(-0.9,0.9)))
	var width := length*0.72
	var local := [Vector3(-width*0.5,0,0),Vector3(width*0.5,0,0),Vector3(width*0.5,0,length),Vector3(-width*0.5,0,length),Vector3(0,length*0.12,length*0.5)]
	var uv := [Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0.5,0.5)]
	var tint := Color(0.68,0.78,0.57).lerp(Color(1.0,1.0,0.88),rng.randf())
	# Four gently folded triangles support the generated alpha-cutout leaf skin.
	for indices in [[0,4,1],[1,4,2],[2,4,3],[3,4,0]]:
		var a: Vector3 = basis*local[indices[0]]+at
		var b: Vector3 = basis*local[indices[1]]+at
		var c: Vector3 = basis*local[indices[2]]+at
		var normal := (c-a).cross(b-a).normalized()
		for index in indices:
			_vertex(foliage,basis*local[index]+at,normal,uv[index],tint)
	leaf_count += 1

func _trunk(t: float) -> Vector3:
	return Vector3(0.09*sin(t*4.1)+t*t*0.15,t*11.5,0.08*sin(t*5.0)-t*t*0.13)

func bake() -> PackedScene:
	rng.seed = 194611013
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk: Array[Vector3] = []
	# Extra rings concentrate detail at the collar; the lowest rim extends
	# below the ground rather than leaving visible root tips sitting on it.
	for y in [-0.24,0.0,0.035,0.09,0.18,0.30,0.48,0.72,1.0]:
		trunk.append(_trunk(y/11.5))
	for i in range(3,33):
		trunk.append(_trunk(float(i)/32.0))
	_tube(trunk,0.24,0.012,32,1.0,true)
	# An uneven spiral of ascending forks; fine twigs bend downward at the tips.
	for branch in range(25):
		var t := 0.31+float(branch)/25.0*0.65+rng.randf_range(-0.015,0.015)
		var start := _trunk(t)
		var angle := branch*2.39996+rng.randf_range(-0.3,0.3)
		var d := Vector3(cos(angle),0,sin(angle))
		var side := Vector3(-d.z,0,d.x)
		var span := (1.0-pow(t,2.5))*3.6*rng.randf_range(0.7,1.18)
		var end := start+d*span+Vector3.UP*rng.randf_range(0.15,0.8)
		var primary := _curve(start,start+d*span*0.45+Vector3.UP*0.8,end,7)
		_tube(primary,lerpf(0.065,0.023,t),0.009,9,0.8)
		for twig in range(12):
			var u := 0.16+float(twig)/12.0*0.82
			var attachment := primary[clampi(roundi(u*7),1,7)]
			var sign_value := -1.0 if twig%2==0 else 1.0
			var tip := attachment+d*rng.randf_range(0.25,0.7)+side*sign_value*rng.randf_range(0.3,0.85)-Vector3.UP*rng.randf_range(0.3,1.2)
			var points := _curve(attachment,attachment+d*0.3+side*sign_value*0.35+Vector3.UP*0.15,tip,5)
			_tube(points,0.013,0.002,5,0.05)
			for leaf_index in range(56):
				var along := rng.randf_range(0.18,1.0)*5.0
				var base: Vector3 = points[mini(int(along),4)].lerp(points[mini(int(along)+1,5)],fmod(along,1.0))
				var offset := Vector3(rng.randf_range(-0.18,0.18),rng.randf_range(-0.12,0.15),rng.randf_range(-0.18,0.18))
				_leaf(base+offset,rng.randf_range(0.085,0.125))
	var bark := ShaderMaterial.new()
	bark.shader = load("res://scripts/environment/birch_bark.gdshader")
	bark.set_shader_parameter("bark_texture",load(BASE+"textures/birch_bark_v2.png"))
	_save(bark,"materials/birch_bark_v1.tres")
	var leaves := StandardMaterial3D.new()
	leaves.albedo_texture = load(BASE+"textures/birch_leaf_v2.png")
	leaves.vertex_color_use_as_albedo = true
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaves.alpha_scissor_threshold = 0.4
	leaves.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaves.roughness = 0.9
	_save(leaves,"materials/birch_leaves_v2.tres")
	var root_node := Node3D.new()
	root_node.name = "Birch"
	for pair in [[wood,bark,"wood","Trunk"],[foliage,leaves,"crown","Crown"]]:
		var st: SurfaceTool = pair[0]
		st.set_material(pair[1])
		st.generate_tangents()
		var mesh := st.commit()
		_save(mesh,"meshes/forest_birch_"+pair[2]+"_v1.res")
		var visual := MeshInstance3D.new()
		visual.name = pair[3]
		visual.mesh = mesh
		root_node.add_child(visual)
		visual.owner = root_node
	var packed := PackedScene.new()
	assert(packed.pack(root_node)==OK)
	_save(packed,"scenes/forest_birch_v1.tscn")
	root_node.free()
	print("BIRCH BAKE: textured curved trunk/forks and ",leaf_count," folded alpha-cutout leaves; world placement unchanged")
	return packed
