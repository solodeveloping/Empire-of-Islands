shader_type canvas_item;

// Info: this was rendering a grid
// grid

uniform sampler2D noise_texture: repeat_enable, filter_nearest;
uniform float scale = 1.0;

varying vec2 world_position;

void vertex() {
	// Called for every vertex the material is visible on.
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ivec2 texture_size = textureSize(noise_texture, 0);
	
	vec2 adjusted_world_position = vec2(
		world_position.x * (1.0 / float(texture_size.x)),
		world_position.y * (1.0 / float(texture_size.y))
	);
	
	vec4 overlay_color = texture(
		noise_texture,
		adjusted_world_position * scale
	);
	
	vec3 rgb = mix(
		COLOR.rgb,
		overlay_color.rgb,
		1.0 - COLOR.a
	);
	COLOR = vec4(rgb, COLOR.a);
	//COLOR = vec4(1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
