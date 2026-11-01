shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
// uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D gradient_texture;

// TODO: not same results for ortho

float remap(float value, float input_b, float input_e, float output_b, float output_e) {
	return(value - input_b) / (input_e - input_b) * (output_e - output_b) + output_b;
}

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    float depth = texture(depth_texture, SCREEN_UV).x;
    #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z;
	
	float divided_linear_depth = linear_depth / 100.0;
	divided_linear_depth = clamp(
		divided_linear_depth,
		0.0,
		1.0
	);
	
	vec4 ramp_light = texture(
		gradient_texture,
		vec2(divided_linear_depth, divided_linear_depth)
		//vec2(0.1, 0.1)
	);
	
	// For ortho, darker (0) is closer
	//ALBEDO = vec3(divided_linear_depth);
	//ALBEDO = vec3(linear_depth);
	ALBEDO = ramp_light.rgb;
	
	//if (divided_linear_depth <= 0.0) {
		//ALBEDO = vec3(0.0, 0.0, 1.0);
	//} else if (divided_linear_depth <= 0.5) {
		//ALBEDO = vec3(0.0, 1.0, 0.0);
	//} else if (divided_linear_depth <= 1.0) {
		//ALBEDO = vec3(1.0, 0.0, 0.0);
	//} else {
		//ALBEDO = vec3(0.0, 0.0, 0.0);
	//}

	// other stuff
	//vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	//vec3 world_position = world.xyz / world.w;
	
	//// Visualize linear depth
	//ALBEDO.rgb = vec3(fract(linear_depth));

	// Visualize world coordinates
	//ALBEDO.rgb = fract(world_position).xyz;

}