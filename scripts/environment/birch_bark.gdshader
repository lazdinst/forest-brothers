shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D bark_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying float trunk_height;
void vertex() {trunk_height=VERTEX.y;}
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec2 mirror_uv(vec2 p) {return abs(fract(p*0.5)*2.0-1.0);}
float height_sample(vec2 uv) {return dot(texture(bark_texture,mirror_uv(uv)).rgb,vec3(0.299,0.587,0.114));}
void fragment() {
	// A complete mirror period around U closes the cylindrical seam exactly.
	vec2 uv=UV*vec2(2.0,0.75);
	vec3 paper=texture(bark_texture,mirror_uv(uv)).rgb;
	float grit=noise(UV*vec2(42.0,2.5));
	float old_base=(1.0-smoothstep(0.12,1.8,trunk_height))*smoothstep(0.2,0.75,grit);
	vec3 bark=mix(paper,vec3(0.12,0.115,0.095)*(0.7+grit*0.4),old_base*0.88);
	float soil_contact=1.0-smoothstep(-0.04,0.32,trunk_height);
	bark=mix(bark,vec3(0.13,0.125,0.105)*(0.85+grit*0.25),soil_contact*0.72);
	ALBEDO=mix(vec3(0.10,0.075,0.048),bark,smoothstep(0.12,0.75,COLOR.r));
	// Subtle relief inferred from albedo is a prototype bump approximation.
	float du=height_sample(uv+vec2(0.002,0))-height_sample(uv-vec2(0.002,0));
	float dv=height_sample(uv+vec2(0,0.002))-height_sample(uv-vec2(0,0.002));
	NORMAL_MAP=vec3(0.5-du*0.3,0.5-dv*0.3,1.0);
	NORMAL_MAP_DEPTH=0.35;
	ROUGHNESS = 1.0;
}
