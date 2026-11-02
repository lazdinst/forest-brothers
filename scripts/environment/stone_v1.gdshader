shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D stone_texture : source_color, filter_nearest_mipmap, repeat_enable;
varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	// Object-space triplanar color: no stretched latitude UVs or baked light.
	vec3 weights = pow(abs(normalize(local_normal)), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec3 p = local_position * 0.8;
	vec3 albedo = texture(stone_texture, p.yz).rgb * weights.x;
	albedo += texture(stone_texture, p.xz).rgb * weights.y;
	albedo += texture(stone_texture, p.xy).rgb * weights.z;
	float mottling = texture(stone_texture, p.xz * 0.53).r;
	float moss = smoothstep(0.65, 1.25, local_position.y + mottling * 0.9);
	ALBEDO = mix(albedo, albedo * vec3(0.63, 0.76, 0.43), moss);
	ROUGHNESS = 1.0;
}
