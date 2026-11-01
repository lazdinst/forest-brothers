shader_type canvas_item;
render_mode unshaded;
uniform vec2 mag_polygon[8];
uniform int mag_count = 0;
float edge(vec2 a, vec2 b, vec2 p) {
	return (b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x);
}
void fragment() {
	vec4 base = COLOR;
	bool inside = mag_count >= 3;
	for (int i = 0; i < 8; i++) {
		if (i < mag_count && edge(mag_polygon[i], mag_polygon[(i+1)%mag_count], UV) < 0.0) { inside = false; }
	}
	COLOR = vec4(base.rgb, base.a * (inside ? 1.0 : 0.0));
}
