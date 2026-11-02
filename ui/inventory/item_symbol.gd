extends Control
## Original UI ink sketches. These are category marks, not historical item art.
var kind := "parts"
var ink := Color("493a29")

func _draw() -> void:
	var s := minf(size.x, size.y)
	var origin := (size - Vector2.ONE * s) * 0.5
	draw_set_transform(origin, 0, Vector2.ONE * s / 64.0)
	match kind:
		"rifle":
			draw_polyline(PackedVector2Array([Vector2(5,42),Vector2(22,34),Vector2(41,29),Vector2(60,23)]), ink, 4, true)
			draw_line(Vector2(22,34),Vector2(37,36),ink,5,true)
			draw_line(Vector2(36,35),Vector2(40,43),ink,4,true)
		"rounds":
			for x in [18,30,42]:
				draw_polyline(PackedVector2Array([Vector2(x,49),Vector2(x,24),Vector2(x+4,15),Vector2(x+8,24),Vector2(x+8,49),Vector2(x,49)]),ink,2,true)
		"magazine":
			draw_polyline(PackedVector2Array([Vector2(19,17),Vector2(43,17),Vector2(40,48),Vector2(24,51),Vector2(19,17)]),ink,3,true)
			for y in [26,34,42]: draw_line(Vector2(25,y),Vector2(37,y),ink,1,true)
		"water":
			draw_rect(Rect2(27,9,12,9),ink,false,2)
			draw_style_box(_outline(),Rect2(18,18,30,36))
			draw_line(Vector2(20,39),Vector2(46,39),ink,2,true)
		"food":
			draw_arc(Vector2(32,34),20,PI,TAU,24,ink,3,true)
			draw_polyline(PackedVector2Array([Vector2(12,34),Vector2(12,47),Vector2(52,47),Vector2(52,34)]),ink,3,true)
			for x in [23,33,43]: draw_line(Vector2(x,23),Vector2(x-4,32),ink,2,true)
		"meals":
			draw_arc(Vector2(32,33),21,0,PI,24,ink,3,true)
			draw_line(Vector2(11,33),Vector2(53,33),ink,3,true)
			for x in [23,33,43]:
				draw_polyline(PackedVector2Array([Vector2(x,26),Vector2(x-3,20),Vector2(x,13)]),ink,2,true)
		"medicine":
			draw_rect(Rect2(24,10,16,8),ink,false,2)
			draw_style_box(_outline(),Rect2(19,19,26,35))
			draw_line(Vector2(32,28),Vector2(32,44),ink,3,true)
			draw_line(Vector2(25,36),Vector2(39,36),ink,3,true)
		"document":
			draw_rect(Rect2(13,18,38,28),ink,false,2)
			draw_polyline(PackedVector2Array([Vector2(13,18),Vector2(32,33),Vector2(51,18)]),ink,2,true)
			draw_circle(Vector2(32,35),4,ink)
		"cloth":
			draw_rect(Rect2(12,21,40,28),ink,false,2)
			draw_line(Vector2(17,25),Vector2(46,44),ink,1,true)
			draw_line(Vector2(46,25),Vector2(17,44),ink,1,true)
		"timber":
			for y in [22,34,46]:
				draw_line(Vector2(15,y),Vector2(49,y-6),ink,7,true)
				draw_circle(Vector2(14,y),4,ink,false,1,true)
		_:
			draw_arc(Vector2(22,22),10,0,PI*1.7,20,ink,4,true)
			draw_line(Vector2(28,29),Vector2(47,49),ink,5,true)

func _outline() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = ink
	box.set_border_width_all(2)
	box.set_corner_radius_all(9)
	return box
