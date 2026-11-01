shader_type canvas_item;

uniform vec2 texture_size = vec2(512, 512);
uniform vec2 map_size = vec2(512, 512);
uniform vec2 player_global_position = vec2(0, 0);
uniform vec2 map_center_global_position = vec2(0, 0);

uniform vec2 min_visible_size = vec2(64, 64);
uniform vec2 max_visible_size = vec2(512, 512);
// TODO: dont how to make a comment
// This is from 0 to 1
//uniform vec2 current_zoom_level = vec2(1, 1);
uniform float current_zoom_level = 1.0;
uniform bool clamp_zoom_level = false;
uniform float min_zoom_level = 0.0;
uniform float max_zoom_level = 1.0;

uniform vec4 outter_region_color: source_color = vec4(0.0, 0.0, 1.0, 1.0);

float remap(float value, float input_b, float input_e, float output_b, float output_e) {
	return(value - input_b) / (input_e - input_b) * (output_e - output_b) + output_b;
}

uniform bool clamp_to_bounds;

//void vertex() {
	//VERTEX += vec2(100.0, 100.0);
//}

void fragment() {
	// weird stuff
	//vec2 uv = SCREEN_UV;
	vec2 uv = UV;
	
	float zoom_level = current_zoom_level;
	
	if (clamp_zoom_level == true) {
		zoom_level = clamp(
			zoom_level,
			min_zoom_level,
			max_zoom_level
		);
	}
	
	vec2 visible_size = vec2(
		remap(
			zoom_level,
			0,
			1,
			min_visible_size.x,
			max_visible_size.x
		),
		remap(
			zoom_level,
			0,
			1,
			min_visible_size.y,
			max_visible_size.y
		)
	);
	
	// Are there a better way?
	vec2 uv_size = vec2(
		remap(
			visible_size.x,
			min_visible_size.x,
			max_visible_size.x,
			0,
			1
		),
		remap(
			visible_size.y,
			min_visible_size.y,
			max_visible_size.y,
			0,
			1
		)
	);
	
	vec2 half_uv_size = uv_size / 2.0;

	vec2 half_texture_size = texture_size / 2.0;
	
	vec2 half_map_size = map_size / 2.0;
	
	vec2 top_left_global_position = map_center_global_position - half_map_size;
	//vec2 bottom_right_global_position = map_center_global_position + half_map_size;
	
	// FIXME: do we need this, this is what I've fixed for the 2D version
	//vec2 bottom_right_global_position = top_left_global_position + map_size;
	vec2 bottom_right_global_position = half_map_size;
	
	vec2 player_uv_pos = vec2(
		remap(
			// 0
			player_global_position.x,
			// -256
			top_left_global_position.x,
			// 256
			bottom_right_global_position.x,
			0,
			//-1.0,
			//-1.0 * uv_size.x,
			1.0
			//1.0 * uv_size.x
		),
		remap(
			player_global_position.y,
			top_left_global_position.y,
			bottom_right_global_position.y,
			//-1.0,
			0.0,
			//-1.0 * uv_size.y,
			1.0
			//1.0 * uv_size.y
		)
	);
	
	// this works for position?
	//vec2 top_left_uv = player_uv_pos;
	//vec2 player_uv_pos_scaled = player_uv_pos * uv_size;
	
	// -1 to 1 and 0 to 1
	float start_uv_x = player_uv_pos.x - uv_size.x/2.0;
	float start_uv_y = player_uv_pos.y - uv_size.y/2.0;
	
	float end_uv_x = start_uv_x + uv_size.x;
	float end_uv_y = start_uv_y + uv_size.y;
	
	vec2 result_uv = vec2(
		remap(
			uv.x,
			0,
			1,
			//start_uv_x,
			start_uv_x,
			//end_uv_x
			end_uv_x
		),
		remap(
			uv.y,
			0,
			1,
			//start_uv_y,
			start_uv_y,
			//end_uv_y
			end_uv_y
		)
	);

	if (result_uv.x < 0.0 || result_uv.x > 1.0 || result_uv.y < 0.0 || result_uv.y > 1.0) {
	    COLOR = outter_region_color;
	} else {
	    COLOR = texture(TEXTURE, result_uv);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
