shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D decay_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D bark_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool moss_only=false;
varying vec3 local_normal;
void vertex() {local_normal=NORMAL;}
vec2 mirror_uv(vec2 p) {return abs(fract(p*0.5)*2.0-1.0);}
void fragment() {
	vec2 uv=mirror_uv(UV*vec2(2.0,0.65));
	vec3 decay=texture(decay_texture,uv).rgb;
	vec3 dry=texture(bark_texture,uv).rgb*vec3(0.50,0.46,0.38);
	float top=smoothstep(-0.1,0.7,normalize(local_normal).y);
	ALBEDO=moss_only?decay*vec3(0.62,0.80,0.43):mix(dry,decay,top*0.92);
	if(!FRONT_FACING) {NORMAL=-NORMAL;}
	ROUGHNESS=1.0;
}
