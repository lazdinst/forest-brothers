shader_type canvas_item;
render_mode unshaded;

uniform vec2 muzzle_uv = vec2(0.42, 0.24);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = COLOR; // CanvasItem fragment COLOR already includes the texture.
	// Relight the original painted sprite without changing its silhouette/alignment.
	float light = flash_strength * exp(-distance(UV, muzzle_uv) * 3.5);
	vec3 warm = base.rgb * vec3(1.65, 1.18, 0.78) + vec3(0.34, 0.13, 0.015);
	COLOR = vec4(mix(base.rgb, warm, light), base.a);
}
