extends "res://scripts/environment/birch_recipe.gd"
## Original Scots-pine candidates. Reuses tube/curve/vertex authoring primitives.
var breaks := SurfaceTool.new()
var moss := SurfaceTool.new()
var bark_material: ShaderMaterial
var needles_material: StandardMaterial3D
var break_material: ShaderMaterial
var decay_material: ShaderMaterial
var moss_material: ShaderMaterial

func _reset(seed_value: int) -> void:
	rng.seed=seed_value
	wood=SurfaceTool.new()
	foliage=SurfaceTool.new()
	breaks=SurfaceTool.new()
	moss=SurfaceTool.new()
	for st in [wood,foliage,breaks,moss]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

func _materials() -> void:
	bark_material=ShaderMaterial.new()
	bark_material.shader=load("res://scripts/environment/pine_bark.gdshader")
	bark_material.set_shader_parameter("lower_bark",load(BASE+"textures/pine_bark_lower_v2.png"))
	bark_material.set_shader_parameter("upper_bark",load(BASE+"textures/pine_bark_upper_v2.png"))
	_save(bark_material,"materials/pine_bark_v2.tres")
	needles_material=StandardMaterial3D.new()
	needles_material.albedo_texture=load(BASE+"textures/pine_needles_v2.png")
	needles_material.vertex_color_use_as_albedo=true
	needles_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	needles_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	needles_material.alpha_scissor_threshold=0.45
	needles_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	needles_material.roughness=1.0
	_save(needles_material,"materials/pine_needles_v2.tres")
	break_material=ShaderMaterial.new()
	break_material.shader=load("res://scripts/environment/pine_endgrain.gdshader")
	_save(break_material,"materials/pine_endgrain_v2.tres")
	decay_material=ShaderMaterial.new()
	decay_material.shader=load("res://scripts/environment/pine_decay.gdshader")
	decay_material.set_shader_parameter("decay_texture",load(BASE+"textures/pine_decay_moss_v2.png"))
	decay_material.set_shader_parameter("bark_texture",load(BASE+"textures/pine_bark_lower_v2.png"))
	_save(decay_material,"materials/pine_decay_v2.tres")
	moss_material=decay_material.duplicate()
	moss_material.set_shader_parameter("moss_only",true)
	_save(moss_material,"materials/pine_moss_v2.tres")

func _face(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,uv_a: Vector2,uv_b: Vector2,uv_c: Vector2,color: Color=Color.WHITE) -> void:
	var n: Vector3=(c-a).cross(b-a).normalized()
	_vertex(st,a,n,uv_a,color)
	_vertex(st,b,n,uv_b,color)
	_vertex(st,c,n,uv_c,color)

func _broken_end(at: Vector3,direction: Vector3,radius: float,rotten: bool=false) -> void:
	var axis:=direction.normalized()
	var u:=axis.cross(Vector3.FORWARD).normalized()
	if u.length_squared()<0.1:
		u=axis.cross(Vector3.UP).normalized()
	var v:=axis.cross(u).normalized()
	for i in range(16):
		var a:=i*TAU/16.0
		var b:=(i+1)*TAU/16.0
		var pa:=at+(u*cos(a)+v*sin(a))*radius+axis*sin(i*7.1)*radius*0.22
		var pb:=at+(u*cos(b)+v*sin(b))*radius+axis*sin((i+1)*7.1)*radius*0.22
		var color:=Color(0.45,0.42,0.34) if rotten else Color.WHITE
		_face(breaks,at-axis*radius*0.08,pa,pb,Vector2(0.5,0.5),Vector2(cos(a),sin(a))*0.5+Vector2.ONE*0.5,Vector2(cos(b),sin(b))*0.5+Vector2.ONE*0.5,color)
		if i%3==0:
			var tip:=pa+axis*radius*rng.randf_range(0.35,1.0)
			var side_a:=pa+u*radius*0.14
			var side_b:=pa+v*radius*0.12
			_face(breaks,pa,tip,side_a,Vector2(0,0),Vector2(0.5,1),Vector2(1,0),color)
			_face(breaks,side_a,tip,side_b,Vector2(0,0),Vector2(0.5,1),Vector2(1,0),color)
			_face(breaks,side_b,tip,pa,Vector2(0,0),Vector2(0.5,1),Vector2(1,0),color)

func _spray(at: Vector3,direction: Vector3,size: float,dry: bool=false) -> void:
	var d:=direction.normalized()
	var side:=d.cross(Vector3.UP).normalized()
	if side.length_squared()<0.1:
		side=d.cross(Vector3.RIGHT).normalized()
	var normal:=side.cross(d).normalized()
	var tint:=Color(0.60,0.63,0.45) if dry else Color(0.70,0.80,0.65).lerp(Color(1.0,1.0,0.9),rng.randf())
	for plane in range(2):
		var s:=side if plane==0 else normal
		var n:=normal if plane==0 else -side
		var points: Array[Vector3]=[at-s*size*0.37,at+s*size*0.37,at+d*size+s*size*0.37,at+d*size-s*size*0.37,at+d*size*0.5+n*size*0.07]
		var uv: Array[Vector2]=[Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0.5,0.5)]
		for tri in [[0,4,1],[1,4,2],[2,4,3],[3,4,0]]:
			_face(foliage,points[tri[0]],points[tri[1]],points[tri[2]],uv[tri[0]],uv[tri[1]],uv[tri[2]],tint)

func _commit(st: SurfaceTool,material: Material,id: String,extra: SurfaceTool=null) -> ArrayMesh:
	st.set_material(material)
	st.generate_tangents()
	var mesh:=st.commit()
	if extra!=null:
		extra.set_material(break_material)
		extra.generate_tangents()
		extra.commit(mesh)
	_save(mesh,"meshes/"+id+".res")
	return mesh

func _visual(parent: Node3D,mesh: Mesh,id: String) -> void:
	var visual:=MeshInstance3D.new()
	visual.name=id
	visual.mesh=mesh
	parent.add_child(visual)
	visual.owner=parent

func _scene(node: Node3D,id: String) -> PackedScene:
	var packed:=PackedScene.new()
	for child in node.get_children():
		child.owner=node
		for sub in child.get_children():
			sub.owner=node
	assert(packed.pack(node)==OK)
	_save(packed,"scenes/"+id+".tscn")
	node.free()
	return packed

func _collider(parent: Node3D,shape: Shape3D,at: Vector3,vaultable: bool=false) -> void:
	var body:=StaticBody3D.new()
	body.name="Body"
	body.collision_layer=1
	body.collision_mask=2
	if vaultable:
		body.add_to_group("vaultable",true)
	parent.add_child(body)
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	collision.position=at
	body.add_child(collision)

func bake() -> PackedScene:
	_reset(194611014)
	_materials()
	var trunk: Array[Vector3]=[]
	for i in range(37):
		var t:=float(i)/36.0
		trunk.append(Vector3(0.10*sin(t*4.5)+t*t*0.22,t*15.5,0.10*sin(t*3.8)))
	_tube(trunk,0.27,0.025,20)
	# Dead lower limbs and uneven snapped stubs, rather than foliage to the ground.
	for i in range(13):
		var y:=1.7+i*0.49+rng.randf_range(-0.16,0.16)
		var a:=i*2.39996
		var d:=Vector3(cos(a),0,sin(a))
		var length:=rng.randf_range(0.18,1.25)
		var end:=d*length+Vector3(0,y-0.15,0)
		_tube(_curve(Vector3(0,y,0),d*length*0.5+Vector3(0,y-0.23,0),end,4),0.055,0.018,7,0.16)
		_broken_end(end,d,0.018)
	for branch in range(25):
		var y:=9.2+branch*0.195+rng.randf_range(-0.35,0.35)
		var a:=branch*2.39996+rng.randf_range(-0.25,0.25)
		var d:=Vector3(cos(a),0,sin(a))
		var side:=Vector3(-d.z,0,d.x)
		var span:=(3.3+sin(branch*0.23)*0.65)*rng.randf_range(0.8,1.18)
		var start:=Vector3(0.1,y,0.04)
		var end:=start+d*span+Vector3.UP*rng.randf_range(0.2,1.3)
		var primary:=_curve(start,start+d*span*0.45+Vector3.UP*0.6,end,7)
		_tube(primary,0.085,0.013,9)
		for twig in range(9):
			var t:=0.3+twig*0.077
			var attachment: Vector3=primary[clampi(roundi(t*7),1,7)]
			var sign_value: float=-1.0 if twig%2==0 else 1.0
			var tip:=attachment+d*rng.randf_range(0.35,0.75)+side*sign_value*rng.randf_range(0.25,0.8)+Vector3.UP*rng.randf_range(0.1,0.45)
			var points:=_curve(attachment,attachment+d*0.3+side*sign_value*0.3,tip,4)
			_tube(points,0.022,0.0035,5)
			for shoot in range(20):
				var fraction:=rng.randf_range(0.3,0.98)*4.0
				var at:=points[mini(int(fraction),3)].lerp(points[mini(int(fraction)+1,4)],fmod(fraction,1.0))
				at+=side*rng.randf_range(-0.25,0.25)+Vector3.UP*rng.randf_range(-0.1,0.28)
				var shoot_direction: Vector3=(tip-attachment).normalized()+side*rng.randf_range(-0.75,0.75)+Vector3.UP*rng.randf_range(0.15,0.9)
				_spray(at,shoot_direction,rng.randf_range(0.27,0.43))
	var node:=Node3D.new()
	node.name="ScotsPine"
	_visual(node,_commit(wood,bark_material,"forest_pine_wood_v1",breaks),"Trunk")
	_visual(node,_commit(foliage,needles_material,"forest_pine_crown_v1"),"Crown")
	print("PINE BAKE: curved textured wood, dead limbs, irregular upper crown")
	return _scene(node,"forest_pine_v1")

func bake_branch(broken_branch: bool) -> PackedScene:
	_reset(194611015 if broken_branch else 194611016)
	_materials()
	var end:=Vector3(1.1,0.11,0.15)
	_tube(_curve(Vector3(-1.1,0.12,0),Vector3(0,0.22,-0.08),end,8),0.075,0.025,9,0.15)
	_broken_end(Vector3(-1.1,0.12,0),Vector3.LEFT,0.075)
	_broken_end(end,Vector3.RIGHT,0.025)
	for i in range(5):
		var start:=Vector3(-0.7+i*0.33,0.15,0)
		var tip:=start+Vector3(0.2,0.06,(-1.0 if i%2==0 else 1.0)*rng.randf_range(0.3,0.65))
		_tube(_curve(start,start+Vector3(0.08,0.13,0),tip,3),0.025,0.004,5,0.08)
		if broken_branch:
			_broken_end(tip,(tip-start).normalized(),0.009)
	var node:=Node3D.new()
	node.name="BrokenPineBranch" if broken_branch else "DeadPineBranch"
	var id: String="pine_branch_broken_v2" if broken_branch else "pine_branch_dead_v2"
	_visual(node,_commit(wood,bark_material,id,breaks),"Visual")
	return _scene(node,id)

func bake_snag() -> PackedScene:
	_reset(194611017)
	_materials()
	var points:=_curve(Vector3(0,-0.08,0),Vector3(0.18,3.5,0.1),Vector3(0.25,7.0,-0.06),18)
	_tube(points,0.31,0.16,18,0.18)
	_broken_end(points[-1],Vector3.UP,0.16)
	for i in range(8):
		var y:=1.2+i*0.67
		var d:=Vector3(cos(i*2.4),0,sin(i*2.4))
		var tip:=Vector3(0,y,0)+d*rng.randf_range(0.2,0.85)-Vector3.UP*0.12
		_tube(_curve(Vector3(0,y,0),Vector3(0,y-0.1,0)+d*0.3,tip,4),0.05,0.018,6,0.1)
		_broken_end(tip,d,0.018)
	var node:=Node3D.new()
	node.name="BrokenPineSnag"
	_visual(node,_commit(wood,bark_material,"pine_snag_v2",breaks),"Visual")
	var shape:=CylinderShape3D.new()
	shape.radius=0.3
	shape.height=7.0
	_collider(node,shape,Vector3(0,3.5,0))
	return _scene(node,"pine_snag_v2")

func bake_fallen() -> PackedScene:
	_reset(194611018)
	_materials()
	var points:=_curve(Vector3(-4.5,0.38,0),Vector3(0,0.34,0.13),Vector3(4.5,0.2,0.04),24)
	_tube(points,0.36,0.095,18)
	_broken_end(points[0],Vector3.LEFT,0.36)
	for i in range(18):
		var x: float=-3.6+i*0.45
		var sign_value: float=-1.0 if i%2==0 else 1.0
		var start:=Vector3(x,0.32,0.04)
		var tip:=start+Vector3(0.3,rng.randf_range(0.1,0.55),sign_value*rng.randf_range(0.35,1.25))
		_tube(_curve(start,start+Vector3(0.1,0.2,sign_value*0.3),tip,4),0.065,0.018,7,0.4)
		_broken_end(tip,(tip-start).normalized(),0.018)
		if x>1.8:
			for twig in range(60):
				_spray(tip+Vector3(rng.randf_range(-0.4,0.8),rng.randf_range(-0.1,0.25),rng.randf_range(-0.4,0.4)),Vector3(0.6,0.15,sign_value*0.5),rng.randf_range(0.25,0.38),true)
	var node:=Node3D.new()
	node.name="FallenPine"
	var mat:=bark_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("growth_axis",Vector3(1.35,0,0))
	mat.set_shader_parameter("growth_offset",6.0)
	_save(mat,"materials/pine_fallen_bark_v2.tres")
	_visual(node,_commit(wood,mat,"pine_fallen_v2",breaks),"Trunk")
	_visual(node,_commit(foliage,needles_material,"pine_fallen_crown_v2"),"Crown")
	# Static mesh collision follows the wood instead of blocking empty space
	# around the taper/branches with a large rectangular box.
	_collider(node,node.get_node("Trunk").mesh.create_trimesh_shape(),Vector3.ZERO,true)
	return _scene(node,"pine_fallen_v2")

func bake_rotten() -> PackedScene:
	_reset(194611019)
	_materials()
	var rings: Array=[]
	for j in range(19):
		var x: float=-3.8+j*7.6/18.0
		var radius: float=lerpf(0.42,0.30,float(j)/18.0)
		var ring: Array=[]
		for i in range(17):
			var a:=i*TAU/16.0
			var r:=radius*(1.0+0.075*sin(j*2.1+i*1.7))
			var y:=0.32+cos(a)*r*0.80
			var p:=Vector3(x+sin(i*2.1)*0.06,maxf(y,0.01),sin(a)*r)
			var n:=Vector3(0,cos(a),sin(a)).normalized()
			ring.append([p,n,Vector2(float(i)/16.0,x+3.8)])
		rings.append(ring)
	for j in range(18):
		for i in range(16):
			if j>=4 and j<=11 and (i==0 or i==15):
				continue # A collapsed upper strip opens into the dark interior.
			var a: Array=rings[j][i]
			var b: Array=rings[j][i+1]
			var c: Array=rings[j+1][i]
			var d: Array=rings[j+1][i+1]
			for point in [a,c,b,b,c,d]:
				_vertex(wood,point[0],point[1],point[2],Color.WHITE)
			# Recessed interior surface, rather than an empty single-sided shell.
			for point in [a,b,c,b,d,c]:
				var inner: Vector3=point[0]-point[1]*0.075
				_vertex(wood,inner,-point[1],point[2],Color(0.45,0.4,0.3))
	for end in [0,18]:
		for i in range(16):
			var a: Vector3=rings[end][i][0]
			var b: Vector3=rings[end][i+1][0]
			var ia: Vector3=a-rings[end][i][1]*0.075
			var ib: Vector3=b-rings[end][i+1][1]*0.075
			_face(breaks,a,b,ia,Vector2(0,0),Vector2(1,0),Vector2(0,1),Color(0.4,0.38,0.3))
			_face(breaks,b,ib,ia,Vector2(1,0),Vector2(1,1),Vector2(0,1),Color(0.4,0.38,0.3))
	for i in range(38):
		var x:=rng.randf_range(-3.6,3.5)
		var z:=rng.randf_range(-0.26,0.26)
		var radius: float=lerpf(0.42,0.30,(x+3.8)/7.6)
		var center:=Vector3(x,0.32+sqrt(maxf(radius*radius-z*z,0.0))*0.8+0.012,z)
		var cushion:=SphereMesh.new()
		cushion.radius=rng.randf_range(0.12,0.23)
		cushion.height=rng.randf_range(0.035,0.075)
		cushion.radial_segments=8
		cushion.rings=3
		var transform:=Transform3D(Basis.IDENTITY,center)
		moss.append_from(cushion,0,transform)
	for i in range(9):
		var x: float=-3.0+i*0.7
		var sign_value: float=-1.0 if i%2==0 else 1.0
		var tip:=Vector3(x+0.15,0.4,sign_value*0.65)
		_tube(_curve(Vector3(x,0.3,0),Vector3(x,0.35,sign_value*0.2),tip,3),0.07,0.02,6,0.1)
		_broken_end(tip,Vector3(0,0,sign_value),0.02,true)
	var node:=Node3D.new()
	node.name="RottenMossyPine"
	_visual(node,_commit(wood,decay_material,"pine_rotten_v2",breaks),"DecayedWood")
	_visual(node,_commit(moss,moss_material,"pine_rotten_moss_v2"),"Moss")
	# Keep the hollow/broken openings real for shot rays; no solid box filling.
	_collider(node,node.get_node("DecayedWood").mesh.create_trimesh_shape(),Vector3.ZERO,true)
	return _scene(node,"pine_rotten_v2")
