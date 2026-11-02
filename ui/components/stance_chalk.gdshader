shader_type canvas_item;
// Preserve the approved outline when its large source atlas is reduced to HUD size.
void fragment() {
	float chalk = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec3 source = texture(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * 3.0).rgb;
			chalk = max(chalk, dot(source, vec3(0.299, 0.587, 0.114)));
		}
	}
	COLOR = vec4(COLOR.rgb, COLOR.a * smoothstep(0.22, 0.46, chalk));
}
