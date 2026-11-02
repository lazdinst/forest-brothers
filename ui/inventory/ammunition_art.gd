extends Control
## Original UI-only atlas. Magazine attachment is a separately drawn component.
const ATLAS = preload("res://ui/assets/ammunition_icons_v1.png")
var kind := "magazine"
var inserted := false
var status := "Unknown"
static var _textures := {}

static func texture_for(item_kind: String) -> AtlasTexture:
	if _textures.has(item_kind): return _textures[item_kind]
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = {"rifle":Rect2(16,170,1010,220),"magazine":Rect2(1100,105,300,365),"rounds":Rect2(130,505,530,490)}.get(item_kind,Rect2(1100,105,300,365))
	_textures[item_kind] = texture
	return texture

func _draw() -> void:
	var texture := texture_for(kind)
	var factor := minf(size.x/texture.get_width(),size.y/texture.get_height())
	var dimensions := texture.get_size()*factor
	var at := (size-dimensions)*0.5
	draw_texture_rect(texture,Rect2(at,dimensions),false)
	if kind == "rifle" and inserted:
		var magazine := texture_for("magazine")
		var magazine_size := Vector2(dimensions.x*0.047,dimensions.y*0.28)
		draw_texture_rect(magazine,Rect2(at+Vector2(dimensions.x*0.425,dimensions.y*0.50),magazine_size),false)
	if kind == "magazine":
		# Categorical stamps only. Never an exact fill bar or a percentage.
		var color := Color("766c5a") if status.begins_with("Unknown") else (Color("713e35") if status in ["Empty","Almost empty"] else Color("3c5740"))
		var stamp := Vector2(size.x-5,6)
		if status == "Empty":
			draw_line(stamp-Vector2(3,3),stamp+Vector2(3,3),color,2,true)
			draw_line(stamp+Vector2(-3,3),stamp+Vector2(3,-3),color,2,true)
		else:
			if status == "Almost full": draw_circle(stamp,4,color)
			else: draw_circle(stamp,4,color,false,1.5,true)
