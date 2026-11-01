shader_type canvas_item;

// FIXME: what does this do?
// I don't remember

//uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D mask_texture;

uniform vec2 polygon_center = vec2(2048.0, 1024.0);

void vertex() {
	//VERTEX = UV * vec2(4096.0*2.0, 4096.0);
	//VERTEX = polygon_center + (VERTEX - polygon_center) * size;
	//VERTEX = UV * vec2(4096.0*2.0, 4096.0) + polygon_center;
	//VERTEX = SCREEN_UV;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 color = texture(mask_texture, UV);
	
	//color = mix(
		//COLOR,
		//color,
		//color.r
	//);
	
	//COLOR = color;
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	COLOR.a = step(0.5, color.r);
	
	vec2 test = vec2(950, 505);
	float dist = distance(FRAGCOORD.xy, test);
	COLOR.a = dist;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
