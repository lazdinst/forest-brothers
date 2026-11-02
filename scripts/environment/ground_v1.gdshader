shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D ground_texture : source_color, filter_nearest_mipmap, repeat_enable;
varying vec3 world_position;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	// Quantized pigment variation over multiple scales, without diagonal stripes.
	vec2 q=floor(p*24.0)/24.0;
	float macro=noise(q*0.19)+0.35*noise(q*0.63);
	float fine=noise(q*8.0);
	float fleck=hash(floor(p*43.0));
	float moss_mask=smoothstep(0.38,0.78,macro);
	vec3 soil=mix(vec3(0.105,0.084,0.056),vec3(0.22,0.17,0.103),fine);
	vec3 moss=mix(vec3(0.095,0.13,0.065),vec3(0.205,0.255,0.119),fine);
	vec3 ground=mix(soil,moss,moss_mask);
	// Sparse leaf/needle pigments, sand on the low rise, mud in the hollow.
	ground=mix(ground,vec3(0.26,0.205,0.12),step(0.97,fleck)*(1.0-moss_mask)*0.65);
	float sand=exp(-dot(p-vec2(-28,-25),p-vec2(-28,-25))/110.0)*0.65;
	ground=mix(ground,vec3(0.30,0.265,0.18)*(0.8+fine*0.3),sand);
	float wet=exp(-dot(p-vec2(-27,17),p-vec2(-27,17))/60.0);
	ground=mix(ground,soil*0.55,wet*0.8);
	float trail_x=2.0*sin(p.y*0.12)-0.025*max(p.y-17.0,0.0);
	float path=1.0-smoothstep(0.65,1.5,abs(p.x-trail_x)+(noise(p*2.0)-0.5)*0.5);
	ALBEDO=mix(ground,soil*1.15,path);
	ROUGHNESS = 1.0;
}
