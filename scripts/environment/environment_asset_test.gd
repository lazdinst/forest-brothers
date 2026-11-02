extends Node3D
## Isolated nature review lane. Uses the actual current asset resources at 1:1 scale.
const Catalog = preload("res://scripts/environment/nature_asset_catalog.gd")
const AISLE_Z := 7.0
var stations: Array[Node3D] = []
var selected := 0
var lane_length := 0.0
var information: Label
@onready var player = $Player

func _ready() -> void:
	_lighting()
	_build_line()
	_hud()
	visit(0)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	return instance

func _lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.40,0.46,0.44)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72,0.76,0.70)
	environment.ambient_light_energy = 0.7
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_color = Color(0.95,0.93,0.85)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)
	player.camera.far = 350.0

func _build_line() -> void:
	var displays := Node3D.new()
	displays.name = "Displays"
	add_child(displays)
	var border := _material(Color(0.38,0.42,0.36))
	var cursor := -6.0
	for i in range(Catalog.ITEMS.size()):
		var item: Dictionary = Catalog.ITEMS[i]
		var asset := Catalog.instantiate_item(item)
		asset.name = "Asset"
		var bounds := Catalog.bounds(asset)
		var width := maxf(4.5,bounds.size.x+3.0)
		var station := Node3D.new()
		station.name = "Station%02d" % (i+1)
		station.position.x = cursor+width*0.5
		station.set_meta("asset_id",item.id)
		station.set_meta("source",Catalog.resource_path(item))
		station.set_meta("width",width)
		station.set_meta("title",item.name)
		station.set_meta("status",item.status)
		displays.add_child(station)
		station.add_child(asset)
		# Front edge stays behind the label/aisle, irrespective of source pivot.
		asset.position = Vector3(-bounds.get_center().x,-bounds.position.y,-1.0-bounds.end.z)
		station.set_meta("focus",Vector3(0,maxf(0.3,bounds.size.y*0.4),asset.position.z+bounds.get_center().z))
		_box(station,Vector3(0,-0.014,-1.0-bounds.size.z*0.5),Vector3(width-0.4,0.012,maxf(2.0,bounds.size.z+0.4)),border)
		_box(station,Vector3(-width*0.5+0.1,0.008,4.3),Vector3(0.035,0.015,3.0),border)
		var label := Label3D.new()
		label.name = "AssetLabel"
		label.position = Vector3(0,1.25,2.0)
		label.text = "%02d  %s\n%s" % [i+1,item.name,item.status]
		label.font_size = 36
		label.pixel_size = 0.005
		label.modulate = Color(0.94,0.92,0.81)
		label.outline_modulate = Color(0.06,0.08,0.06)
		label.outline_size = 9
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		station.add_child(label)
		stations.append(station)
		cursor += width
	lane_length = cursor+6.0
	var ground := StaticBody3D.new()
	ground.name = "GalleryGround"
	ground.collision_layer = 1
	ground.collision_mask = 2
	add_child(ground)
	var size := Vector3(lane_length+24.0,0.4,64.0)
	var center := Vector3(lane_length*0.5-6.0,-0.21,-12.0)
	_box(ground,center,size,_material(Color(0.22,0.26,0.22)))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = center
	ground.add_child(collision)
	_box(self,Vector3(lane_length*0.5-6.0,-0.003,AISLE_Z),Vector3(lane_length+12.0,0.01,4.0),_material(Color(0.37,0.37,0.30)))

func _hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "GalleryHUD"
	add_child(hud)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 20
	panel.offset_top = -140
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05,0.075,0.06,0.9)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	hud.add_child(panel)
	information = Label.new()
	information.name = "Information"
	information.add_theme_font_size_override("font_size",18)
	information.add_theme_color_override("font_color",Color(0.94,0.92,0.81))
	panel.add_child(information)

func visit(index: int) -> void:
	selected = clampi(index,0,stations.size()-1)
	player.global_position = Vector3(stations[selected].global_position.x,0.03,AISLE_Z)
	player.velocity = Vector3.ZERO
	player.is_vaulting = false
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.camera.look_at(stations[selected].global_position+stations[selected].get_meta("focus"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_PAGEDOWN or event.keycode == KEY_PAGEUP:
			visit(selected+(1 if event.keycode == KEY_PAGEDOWN else -1))
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	var nearest := 0
	var distance := INF
	for i in range(stations.size()):
		var next_distance: float = absf(player.global_position.x-stations[i].global_position.x)
		if next_distance < distance:
			distance = next_distance
			nearest = i
	selected = nearest
	var station := stations[selected]
	information.text = "ENVIRONMENT / NATURE ASSET LINEUP\n%02d / %02d  %s  |  %s\nWASD + mouse: inspect  ·  Shift: run  ·  Page Up / Down: previous / next\nP: return to start  ·  Esc: release mouse  ·  Click: capture" % [selected+1,stations.size(),station.get_meta("title"),station.get_meta("status")]
