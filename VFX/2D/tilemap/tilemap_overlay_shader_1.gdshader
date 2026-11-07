shader_type canvas_item;

// Info: just an attempt to introduce variation on the normal texture

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
	
	//vec2 world_uv = fract(world_position * noise_scale * 0.01);
	
	vec2 adjusted_world_position = vec2(
		world_position.x * (1.0 / float(texture_size.x)),
		world_position.y * (1.0 / float(texture_size.y))
	);
	
	vec4 overlay_color = texture(
		noise_texture,
		adjusted_world_position * scale
	);
	
	//float mix_ = min(
		//overlay_color.r,
		//COLOR.a
	//);
	
	// mix(color, vec4(0,0,0,1), mix_);
	
	float mix_amount = 1.0 - step(0.2, COLOR.b);
	             	//* (1.0 - step(0.1, COLOR.r));
	             	//* (1.0 - step(0.5, COLOR.b));
	             	//* step(0.0, COLOR.a);
	
	//vec3 rgb = mix(
		//COLOR.rgb,
		//overlay_color.rgb,
		//mix_
	//);
	//vec3 rgb = mix(
		//COLOR.rgb,
		//vec3(0,0,0),
		//clamp(0, 1, (overlay_color.r - COLOR.b * 5.0)) * 0.2
	//);
	float darken_ = 0.1;
	//vec3 rgb = mix(
		//COLOR.rgb,
		//vec3(darken_),
		////vec3(0,0,0),
		//mix_amount * overlay_color.r * 2.0
	//);
	vec3 rgb = COLOR.rgb - overlay_color.r * mix_amount * 0.2;
	
	//COLOR = vec4(rgb, COLOR.a);
	//COLOR = vec4(COLOR.rgb, COLOR.a);
	//COLOR = vec4(1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
