shader_type spatial;

// affects color
void vertex() { 
}

void fragment() {
 	ALBEDO = vec3(COLOR.r,COLOR.g,COLOR.b);
}
