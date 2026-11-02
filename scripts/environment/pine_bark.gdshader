shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D lower_bark : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D upper_bark : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 growth_axis=vec3(0,1,0);
uniform float growth_offset=0.0;
uniform float deadness=0.0;
varying float growth_height;
vec2 mirror_uv(vec2 p) {return abs(fract(p*0.5)*2.0-1.0);}
void vertex() {growth_height=dot(VERTEX,growth_axis)+growth_offset;}
vec3 bark_sample(vec2 p,float upper) {return mix(texture(lower_bark,mirror_uv(p)).rgb,texture(upper_bark,mirror_uv(p*vec2(1.0,0.8))).rgb,upper);}
void fragment() {
	vec2 uv=UV*vec2(2.0,0.72);
	float upper=smoothstep(5.0,12.8,growth_height);
	vec3 color=bark_sample(uv,upper);
	float dry=max(deadness,1.0-smoothstep(0.2,0.8,COLOR.r));
	float grey=dot(color,vec3(0.299,0.587,0.114));
	ALBEDO=mix(color,vec3(grey*0.72,grey*0.65,grey*0.55),dry*0.75);
	float dx=dot(bark_sample(uv+vec2(0.002,0),upper)-bark_sample(uv-vec2(0.002,0),upper),vec3(0.333));
	float dy=dot(bark_sample(uv+vec2(0,0.002),upper)-bark_sample(uv-vec2(0,0.002),upper),vec3(0.333));
	NORMAL_MAP=vec3(0.5-dx*0.4,0.5-dy*0.4,1.0);
	NORMAL_MAP_DEPTH=0.4;
	ROUGHNESS=1.0;
}
