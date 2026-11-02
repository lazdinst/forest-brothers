shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform bool rotten=false;
void fragment() {
	vec2 p=(UV-0.5)*2.0;
	float rings=sin(length(p)*65.0+sin(p.x*15.0)*1.5+cos(p.y*19.0)*0.7)*0.5+0.5;
	float fibers=fract(sin(dot(floor(p*130.0),vec2(127.1,311.7)))*43758.5453);
	vec3 light=rotten?vec3(0.20,0.17,0.115):vec3(0.33,0.26,0.16);
	vec3 dark=rotten?vec3(0.065,0.058,0.04):vec3(0.14,0.10,0.055);
	float cracks=pow(abs(sin(atan(p.y,p.x)*7.0+length(p)*2.0)),35.0)*smoothstep(0.1,0.8,length(p));
	ALBEDO=mix(light,dark,rings*0.10+cracks*0.42+fibers*0.2)*COLOR.rgb;
	ROUGHNESS=1.0;
}
