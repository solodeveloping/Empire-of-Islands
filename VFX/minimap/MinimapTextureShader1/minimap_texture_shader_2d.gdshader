shader_type canvas_item;

// TODO: update 3D version maybe
// 2D version of the minimap shader

uniform vec2 texture_size = vec2(512, 512);
uniform vec2 map_size = vec2(512, 512);
uniform vec2 player_global_position = vec2(0, 0);
uniform vec2 map_center_global_position = vec2(0, 0);

uniform vec2 min_visible_size = vec2(64, 64);
uniform vec2 max_visible_size = vec2(512, 512);
// This is from 0 to 1
uniform float current_zoom_level = 1.0;
uniform bool clamp_zoom_level = false;
uniform float min_zoom_level = 0.0;
uniform float max_zoom_level = 1.0;

uniform vec4 outter_region_color: source_color = vec4(0.0, 0.0, 1.0, 1.0);

uniform bool clamp_to_bounds;

/**
 * This is the main mask, the circular mask
 */
uniform sampler2D mask_texture;

group_uniforms DiamondBorder;

// I tried to use another mask
// but it did not work well

/**
 * multiplied with half_size to obtain the dimensions of the shape
 */
uniform vec2 uv_scale = vec2(1.0);
/**
 * multiplied with uv_scale to obtain the dimensions of the shape
 */
uniform vec2 half_size = vec2(0.5, 0.25);
/**
 * position of the shape
 */
uniform vec2 uv_position = vec2(0.0);
/**
 * base witdth of the border
 */
uniform float border_width = 0.025;
/**
 * controls whether and how much the border grows out
 * use 0 to not grow out
 */
uniform float grow_outer = 0;
/**
 * controls whether and how much the border grows in
 * use 0 to not grow in
 */
uniform float grow_inner = 0;
uniform vec4 border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

const float EPSILON = 0.01;
const vec4 ALPHA = vec4(0.0, 0.0, 0.0, 0.0);

float remap(float value, float input_b, float input_e, float output_b, float output_e) {
	return(value - input_b) / (input_e - input_b) * (output_e - output_b) + output_b;
}

bool equal_approx(vec4 vec1_, vec4 vec2_) {
	return (length(abs(vec1_ - vec2_)) < EPSILON);
}

bool equal_approx(float a, float b) {
    return abs(a - b) < EPSILON;
}

bool equal_approx2(vec4 vec1_, vec4 vec2_, float epsilon) {
	return (length(abs(vec1_ - vec2_)) < epsilon);
}

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	// weird stuff
	//vec2 uv = SCREEN_UV;
	vec4 mask_color = texture(mask_texture, UV);
	
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
	// was working for 3d?
	//vec2 bottom_right_global_position = half_map_size;
	vec2 bottom_right_global_position = top_left_global_position + map_size;
	
	// FIXME: too difficult to code
	// maybe could compute 0 and 1, see if it's outside
	//if (clamp_to_bounds) {
		//
	//}
	
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
	
	// TODO: open issue, yellow does not show like in normal editor
	// this works for position
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
		vec4 tex_color = texture(TEXTURE, result_uv);
	    COLOR = tex_color;
		
		// there is a line on the outside because it wont match
		// we hide it with the diamond
		
		// this gives the outer color inside the square
		if (equal_approx2(COLOR, ALPHA, 0.1)) {
			COLOR = outter_region_color;
		}
		
		// FIXME: edge of the thing is bad
		// still not really working
		
		// check TestRhombus if you need to understand the code
	    vec2 shape_uv = (result_uv - vec2(0.5)) * uv_scale + vec2(0.5) - uv_position;
	    vec2 ratio = abs(shape_uv - vec2(0.5));
		float expand = 1.0 + border_width * grow_outer;
		vec2 outer_size = half_size * expand;
		float outer = ratio.x / outer_size.x + ratio.y / outer_size.y;
		vec2 inner_size = half_size * (1.0 - border_width * grow_inner);
	    float inner = ratio.x / inner_size.x + ratio.y / inner_size.y;
		
		// We still need "if outer"
	    if (outer > 1.0) {
	        ////COLOR = vec4(0.0);
	    } else if (inner > 1.0) {
	        COLOR = border_color;
	    } else {
	        ////COLOR = fill_color;
	    }
	}
	COLOR.a = 1.0 - mask_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
