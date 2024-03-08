shader_type spatial;

// Huge kudos to this fantastic tutorial by Martin Donals
// https://www.youtube.com/watch?v=BXo97H55EhA

uniform sampler2D snow_albedo : hint_default_white;
//uniform sampler2D snow_normal;
//uniform sampler2D snow_roughness;
uniform sampler2D dirt_albedo : hint_default_white;
//uniform sampler2D dirt_normal;
//uniform sampler2D dirt_roughness;
uniform sampler2D dynamic_snow_mask;
uniform float uv_scale = 1.0;
uniform float snow_height = 1.0;

void fragment() {
	vec3 snow_a = texture(snow_albedo, UV).rgb;
//	vec3 snow_n = texture(snow_normal, UV).rgb;
//	float snow_r = texture(snow_roughness, UV).r;
	vec3 dirt_a = texture(dirt_albedo, UV).rgb;
//	vec3 dirt_n = texture(dirt_normal, UV).rgb;
//	float dirt_r = texture(dirt_roughness, UV).r;
	
	float snow_mask = COLOR.r;
	snow_mask *= texture(dynamic_snow_mask, UV).r;
	
	ALBEDO = mix(dirt_a, snow_a, snow_mask);
//	NORMAL_MAP = mix(dirt_n, snow_n, snow_mask);
//	ROUGHNESS = mix(dirt_r, snow_r, snow_mask);
}

void vertex() {
	float snow_mask = COLOR.r;
	snow_mask *= texture(dynamic_snow_mask, UV).r;
	
	VERTEX.y += snow_mask * snow_height;
}