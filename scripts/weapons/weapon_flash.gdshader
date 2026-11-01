shader_type canvas_item;
render_mode unshaded;

uniform vec2 muzzle_uv = vec2(0.42, 0.24);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform bool hide_magazine = false;
uniform vec2 mag_polygon[8];
uniform int mag_count = 0;

float edge(vec2 a, vec2 b, vec2 p) {
	return (b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x);
}

void fragment() {
	vec4 base = COLOR; // CanvasItem fragment COLOR already includes the texture.
	bool inside = mag_count >= 3;
	for (int i = 0; i < 8; i++) {
		if (i < mag_count && edge(mag_polygon[i], mag_polygon[(i+1)%mag_count], UV) < 0.0) { inside = false; }
	}
	if (hide_magazine && inside) { base.a = 0.0; }
	// Relight the original painted sprite without changing its silhouette/alignment.
	float light = flash_strength * exp(-distance(UV, muzzle_uv) * 3.5);
	vec3 warm = base.rgb * vec3(1.65, 1.18, 0.78) + vec3(0.34, 0.13, 0.015);
	COLOR = vec4(mix(base.rgb, warm, light), base.a);
}
