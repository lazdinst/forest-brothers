extends RefCounted
## Original procedural rig/mesh source. Meters, Y up, character faces +Z.
var rig: Skeleton3D
var bones: Dictionary = {}
var rests: Dictionary = {}
var data: Dictionary = {}
var variant: StringName
var triangles: int = 0

func build(style: StringName = &"civilian") -> Node3D:
	bones.clear()
	rests.clear()
	data.clear()
	triangles = 0
	variant = style
	var root := Node3D.new()
	root.name = "Humanoid"
	rig = Skeleton3D.new()
	rig.name = "Skeleton3D"
	root.add_child(rig)
	_bone("Root","",Vector3.ZERO)
	_bone("Hips","Root",Vector3(0,0.93,0))
	_bone("Spine","Hips",Vector3(0,1.13,0))
	_bone("Chest","Spine",Vector3(0,1.35,0))
	_bone("Neck","Chest",Vector3(0,1.53,0))
	_bone("Head","Neck",Vector3(0,1.64,0))
	for side in ["L","R"]:
		var sign_x: float = 1 if side=="L" else -1
		_bone("Shoulder_"+side,"Chest",Vector3(sign_x*0.20,1.45,0))
		_bone("UpperArm_"+side,"Shoulder_"+side,Vector3(sign_x*0.255,1.41,0))
		_bone("LowerArm_"+side,"UpperArm_"+side,Vector3(sign_x*0.305,1.13,0))
		_bone("Hand_"+side,"LowerArm_"+side,Vector3(sign_x*0.315,0.88,0.015))
		_bone("Thigh_"+side,"Hips",Vector3(sign_x*0.105,0.91,0))
		_bone("Shin_"+side,"Thigh_"+side,Vector3(sign_x*0.105,0.5,0))
		_bone("Foot_"+side,"Shin_"+side,Vector3(sign_x*0.105,0.10,0.035))
		_bone("Toe_"+side,"Foot_"+side,Vector3(sign_x*0.105,0.06,0.175))
		for finger in range(5):
			_bone("Finger%d_%s" % [finger,side],"Hand_"+side,(Vector3(sign_x*0.352,0.865,0.032) if finger==4 else Vector3(sign_x*0.315+(finger-1.5)*0.018,0.835,0.025)))
	rig.reset_bone_poses()
	for group in ["LegsMesh","TorsoMesh","UpperMesh"]:
		data[group] = {"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"colors":PackedColorArray(),"bones":PackedInt32Array(),"weights":PackedFloat32Array()}
	_geometry()
	for group in data:
		var mesh := ArrayMesh.new()
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data[group].vertices
		arrays[Mesh.ARRAY_NORMAL] = data[group].normals
		arrays[Mesh.ARRAY_COLOR] = data[group].colors
		arrays[Mesh.ARRAY_BONES] = data[group].bones
		arrays[Mesh.ARRAY_WEIGHTS] = data[group].weights
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.93
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(0,material)
		var instance := MeshInstance3D.new()
		instance.name = group
		instance.mesh = mesh
		instance.skin = rig.create_skin_from_rest_transforms()
		instance.skeleton = NodePath("..")
		rig.add_child(instance)
	for side in ["L","R"]:
		var attachment := BoneAttachment3D.new()
		attachment.name = "HandAttachment_"+side
		attachment.bone_name = "Hand_"+side
		rig.add_child(attachment)
		var socket := Node3D.new()
		socket.name = "HandSocket_"+side
		attachment.add_child(socket)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root.add_child(player)
	var library := AnimationLibrary.new()
	for name in ["idle","walk","run","crouch","aim","reload","interact","die"]:
		library.add_animation(name,_animation(name))
	player.add_animation_library("",library)
	root.set_meta("triangle_count",triangles)
	root.set_meta("source","Original procedural humanoid; not a historical character model")
	_owner(root,root)
	return root

func _owner(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_owner(child,root)

func _bone(name: String, parent: String, at: Vector3) -> void:
	var index := rig.add_bone(name)
	bones[name] = index
	rests[name] = at
	if parent != "":
		rig.set_bone_parent(index,bones[parent])
	rig.set_bone_rest(index,Transform3D(Basis.IDENTITY,at-(rests[parent] if parent!="" else Vector3.ZERO)))

func _tri(a: Vector3,b: Vector3,c: Vector3, bone_ids: Array, color: Color) -> void:
	var bone_name: String = bone_ids[0]
	var upper := bone_name in ["Head","Neck"] or "Arm" in bone_name or "Hand" in bone_name or "Shoulder" in bone_name or "Finger" in bone_name
	var leg: bool = "Thigh" in bone_name or "Shin" in bone_name or "Foot" in bone_name or "Toe" in bone_name
	var group: Dictionary = data["UpperMesh" if upper else ("LegsMesh" if leg else "TorsoMesh")]
	var normal := (b-a).cross(c-a).normalized()
	var tint := 0.94+float(triangles%7)*0.018
	for i in range(3):
		group.vertices.append([a,b,c][i])
		group.normals.append(normal)
		group.colors.append(Color(color.r*tint,color.g*tint,color.b*tint))
		group.bones.append_array(PackedInt32Array([bones[bone_ids[i]],0,0,0]))
		group.weights.append_array(PackedFloat32Array([1,0,0,0]))
	triangles += 1

func _rings(centers: Array, widths: Array, depths: Array, ids: Array, color: Color, sides: int = 10) -> void:
	var rings: Array = []
	for row in range(centers.size()):
		var ring: Array[Vector3] = []
		for i in range(sides):
			var angle := TAU*float(i)/sides
			ring.append(centers[row]+Vector3(cos(angle)*widths[row],0,sin(angle)*depths[row]))
		rings.append(ring)
	for row in range(rings.size()-1):
		for i in range(sides):
			var j := (i+1)%sides
			_tri(rings[row][i],rings[row+1][j],rings[row][j],[ids[row],ids[row+1],ids[row]],color)
			_tri(rings[row][i],rings[row+1][i],rings[row+1][j],[ids[row],ids[row+1],ids[row+1]],color)
	for i in range(sides):
		var j := (i+1)%sides
		_tri(centers[0],rings[0][i],rings[0][j],[ids[0],ids[0],ids[0]],color)
		_tri(centers[-1],rings[-1][j],rings[-1][i],[ids[-1],ids[-1],ids[-1]],color)

func _box(at: Vector3,size: Vector3,id: String,color: Color) -> void:
	var vertices: Array[Vector3] = []
	for y in [-1,1]:
		for z in [-1,1]:
			for x in [-1,1]:
				vertices.append(at+Vector3(x,y,z)*size*0.5)
	for face in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
		_tri(vertices[face[0]],vertices[face[1]],vertices[face[2]],[id,id,id],color)
		_tri(vertices[face[0]],vertices[face[2]],vertices[face[3]],[id,id,id],color)

func _geometry() -> void:
	var coat := Color(0.28,0.22,0.16) if variant==&"civilian" else Color(0.24,0.26,0.17)
	var pants := Color(0.19,0.20,0.18)
	var skin := Color(0.62,0.47,0.35)
	var leather := Color(0.14,0.11,0.085)
	_rings([Vector3(0,0.88,0),Vector3(0,1.04,0),Vector3(0,1.28,0),Vector3(0,1.44,0)],[0.185,0.18,0.235,0.235],[0.135,0.14,0.14,0.12],["Hips","Spine","Chest","Chest"],coat,12)
	_rings([Vector3(0,1.44,0),Vector3(0,1.53,0)],[0.13,0.065],[0.09,0.06],["Chest","Neck"],coat)
	_rings([Vector3(0,1.50,0),Vector3(0,1.59,0)],[0.052,0.055],[0.053,0.055],["Neck","Head"],skin)
	_rings([Vector3(0,1.57,0.008),Vector3(0,1.63,0),Vector3(0,1.72,0),Vector3(0,1.79,-0.005),Vector3(0,1.835,-0.005)],[0.07,0.101,0.111,0.105,0.06],[0.065,0.085,0.095,0.085,0.055],["Head","Head","Head","Head","Head"],skin,12)
	_rings([Vector3(0,1.78,-0.005),Vector3(0,1.825,-0.01),Vector3(0,1.86,-0.015)],[0.115,0.115,0.08],[0.10,0.10,0.075],["Head","Head","Head"],coat.darkened(0.28),12)
	_box(Vector3(0,1.795,0.104),Vector3(0.22,0.018,0.12),"Head",coat.darkened(0.35))
	_box(Vector3(0,1.685,0.099),Vector3(0.026,0.055,0.04),"Head",skin.darkened(0.07))
	_box(Vector3(0,1.633,0.086),Vector3(0.041,0.009,0.013),"Head",skin.darkened(0.45))
	if variant==&"civilian":
		_box(Vector3(0,1.663,0.105),Vector3(0.063,0.014,0.013),"Head",Color(0.4,0.4,0.37))
	for sign_x in [-1,1]:
		_box(Vector3(sign_x*0.043,1.718,0.087),Vector3(0.027,0.012,0.013),"Head",Color(0.085,0.08,0.07))
		_box(Vector3(sign_x*0.044,1.735,0.084),Vector3(0.038,0.01,0.015),"Head",leather)
		_rings([Vector3(sign_x*0.11,1.665,0),Vector3(sign_x*0.116,1.71,0),Vector3(sign_x*0.11,1.74,0)],[0.015,0.021,0.012],[0.021,0.025,0.018],["Head","Head","Head"],skin,6)
	for y in [1.06,1.15,1.24,1.33,1.4]:
		_box(Vector3(0,y,0.143),Vector3(0.013,0.014,0.01),"Chest" if y>1.2 else "Spine",leather)
	for sign_x in [-1,1]:
		_box(Vector3(sign_x*0.115,1.15,0.138),Vector3(0.115,0.13,0.014),"Spine",coat.lightened(0.03))
	_box(Vector3(0,1.04,0),Vector3(0.365,0.045,0.285),"Spine",leather)
	_box(Vector3(0,1.04,0.148),Vector3(0.035,0.033,0.012),"Spine",Color(0.35,0.32,0.23))
	for side in ["L","R"]:
		var sx: float = 1 if side=="L" else -1
		_rings([Vector3(sx*0.105,0.91,0),Vector3(sx*0.105,0.70,0),Vector3(sx*0.105,0.50,0),Vector3(sx*0.105,0.30,0),Vector3(sx*0.105,0.15,0)],[0.105,0.098,0.085,0.07,0.065],[0.115,0.095,0.085,0.07,0.065],["Thigh_"+side,"Thigh_"+side,"Shin_"+side,"Shin_"+side,"Foot_"+side],pants)
		_box(Vector3(sx*0.105,0.025,0.065),Vector3(0.16,0.05,0.30),"Foot_"+side,leather.darkened(0.1))
		_rings([Vector3(sx*0.105,0.04,0.065),Vector3(sx*0.105,0.12,0.06),Vector3(sx*0.105,0.25,0)],[0.078,0.077,0.067],[0.15,0.15,0.067],["Foot_"+side,"Foot_"+side,"Shin_"+side],leather)
		_rings([Vector3(sx*0.245,1.44,0),Vector3(sx*0.27,1.31,0),Vector3(sx*0.305,1.13,0),Vector3(sx*0.31,0.99,0.01),Vector3(sx*0.315,0.91,0.015)],[0.10,0.096,0.083,0.069,0.062],[0.11,0.095,0.083,0.068,0.06],["UpperArm_"+side,"UpperArm_"+side,"LowerArm_"+side,"LowerArm_"+side,"Hand_"+side],coat)
		_box(Vector3(sx*0.315,0.866,0.025),Vector3(0.081,0.09,0.045),"Hand_"+side,skin)
		for finger in range(4):
			var x: float = sx*0.315+(finger-1.5)*0.018
			var length: float = 0.055 if finger in [1,2] else 0.045
			_rings([Vector3(x,0.83-length,0.025),Vector3(x,0.835,0.025)],[0.007,0.009],[0.009,0.011],["Finger%d_%s" % [finger,side],"Finger%d_%s" % [finger,side]],skin,6)
		_box(Vector3(sx*0.365,0.855,0.032),Vector3(0.032,0.05,0.027),"Finger4_"+side,skin)

func _pose(name: String,phase: float) -> Dictionary:
	var pose: Dictionary = {}
	var wave := sin(phase*TAU)
	if name in ["walk","run"]:
		var amplitude := 0.48 if name=="walk" else 0.8
		for side in ["L","R"]:
			var sign_side: float = 1 if side=="L" else -1
			pose["Thigh_"+side] = Vector3(wave*amplitude*sign_side,0,0)
			pose["Shin_"+side] = Vector3(maxf(0,-wave*sign_side)*0.8,0,0)
			pose["UpperArm_"+side] = Vector3(-wave*amplitude*0.7*sign_side,0,0)
			pose["LowerArm_"+side] = Vector3(-0.2,0,0)
		pose["Chest"] = Vector3(0.1 if name=="run" else 0,0,wave*0.035)
	elif name=="crouch":
		pose = {"Spine":Vector3(0.7,0,0),"Chest":Vector3(0.4,0,0),"Neck":Vector3(-0.5,0,0),"Head":Vector3(-0.3,0,0)}
		for side in ["L","R"]:
			pose["Thigh_"+side] = Vector3(-1.1,0,0)
			pose["Shin_"+side] = Vector3(2,0,0)
			pose["Foot_"+side] = Vector3(-0.9,0,0)
	elif name in ["aim","reload"]:
		pose = {"UpperArm_L":Vector3(-1.2,0,-0.5),"UpperArm_R":Vector3(-1.2,0,0.5),"LowerArm_L":Vector3(-0.5,0,0),"LowerArm_R":Vector3(-0.7,0,0)}
		if name=="reload":
			var reach := sin(phase*PI)
			pose.UpperArm_L.x += reach*0.9
			pose.LowerArm_L.x += reach*0.4
			pose.Hand_L = Vector3(0,reach*0.4,0)
	elif name=="interact":
		pose.UpperArm_R = Vector3(-sin(phase*PI)*1.15,0,0.15)
		pose.LowerArm_R = Vector3(-sin(phase*PI)*0.5,0,0)
	elif name=="die":
		pose.Hips = Vector3(-smoothstep(0.15,1.0,phase)*PI/2,0,0)
		pose.Thigh_L = Vector3(-sin(phase*PI)*0.6,0,0)
		pose.Shin_L = Vector3(sin(phase*PI)*1.1,0,0)
		pose.UpperArm_L = Vector3(0,0,-phase*0.6)
		pose.UpperArm_R = Vector3(0,0,phase*0.4)
	else:
		pose.Chest = Vector3(sin(phase*TAU)*0.015,0,0)
	return pose

func _animation(name: String) -> Animation:
	var animation := Animation.new()
	animation.length = {"idle":2.5,"walk":1.0,"run":0.65,"crouch":1.0,"aim":1.0,"reload":1.4,"interact":1.2,"die":0.9}[name]
	animation.loop_mode = Animation.LOOP_LINEAR if name in ["idle","walk","run","crouch","aim"] else Animation.LOOP_NONE
	var samples := 16
	for bone in bones:
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track,NodePath("Skeleton3D:"+bone))
		for i in range(samples+1):
			var phase := float(i)/samples
			var rotations := _pose(name,phase)
			animation.rotation_track_insert_key(track,phase*animation.length,Quaternion.from_euler(rotations.get(bone,Vector3.ZERO)))
	var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(position_track,NodePath("Skeleton3D:Hips"))
	for i in range(samples+1):
		var phase := float(i)/samples
		var at: Vector3 = rests.Hips
		if name in ["walk","run"]:
			at.y += absf(sin(phase*TAU))*0.018
		elif name=="crouch":
			at.y = 0.52
		elif name=="die":
			at.y = lerpf(0.93,0.2,smoothstep(0,1,phase))
		animation.position_track_insert_key(position_track,phase*animation.length,at)
	return animation
