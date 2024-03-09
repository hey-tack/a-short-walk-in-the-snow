shader_type spatial;

uniform sampler2D albedo_texture : hint_default_black;
uniform sampler2D albedo_snow : hint_default_white;

uniform float snow_amount = 1.0;
uniform float snow_uv_scale = 1.0;

void fragment() {
	vec3 c = texture(albedo_texture, UV).rgb;
	
	vec3 vs_up = mat3(INV_VIEW_MATRIX) * vec3(0.0, 1.0, 0.0);
	float snow_mask = clamp(dot(NORMAL, vs_up * snow_amount), 0.0, 1.0);
	
	vec3 ws_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 ws_uv = ws_pos.xz * snow_uv_scale;
	
	vec3 snow_c = texture(albedo_snow, ws_uv).rgb;
	
	ALBEDO = mix(c, snow_c, snow_mask);
}
