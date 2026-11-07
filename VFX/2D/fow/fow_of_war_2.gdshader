shader_type canvas_item;

// TODO: something prettier than a black fow

// TODO: rename this maybe
/**
 * This is the smaller size texture for already seen places
 */
uniform sampler2D small_tex : filter_nearest;

// Gives    0 if on surface
// Gives    < 0 if inside
// Gives    > 0 if outside
float sdCircle(vec2 p, float r)
{
	return length(p) - r;
}

float sdSegment(in vec2 p, in vec2 a, in vec2 b)
{
	vec2 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}

uniform int object_count = 0;
// xy/z = position, w = radius
uniform vec4 objects[512];

// the size of the visible/game world
uniform vec2 world_size;
// origin of the world
uniform vec2 world_origin = vec2(0.0);

uniform vec2 viewport_size;
uniform vec2 camera_position;
uniform vec2 camera_zoom;

uniform vec2 screen_to_world_origin;
uniform vec2 screen_to_world_x;
uniform vec2 screen_to_world_y;

float remap(float value, float input_b, float input_e, float output_b, float output_e) {
	return(value - input_b) / (input_e - input_b) * (output_e - output_b) + output_b;
}

void vertex() {
	//mat4 canvas_matrix = CANVAS_MATRIX;
	//vec2 target_position;
	//vec2 local_position = (CANVAS_MATRIX * vec4(target_position, 0.0, 1.0)).xy;
}

// Math works because the TextureRect is Full Rect
// We would need to adapt the math otherwise

void fragment() {
	// viewport_size can be 1600.0, 900.0 for instance
	// SCREEN_UV is the UV for the screen, will be 0 to 1
	// so screen_position range from 0,0 to 1600,900
	vec2 screen_position = SCREEN_UV * viewport_size;
	// substract half screen
	// so -800,-450 to 800, 450
	vec2 offset_from_screen_center = screen_position - (viewport_size * 0.5);
	// adapt for zoom
	// camera position is assumed to be centered
	// gives the world position of the pixel
	vec2 world_position = camera_position + offset_from_screen_center / camera_zoom;

	// then we can compare to other world positions

	// <= 0 if inside
	// step: 0 if < and 1 if >
	float color = 0.0;
	float max_radius = 0.0;
	for (int i = 0; i < object_count; i++) {
		// Gives    0 if on surface
		// Gives    < 0 if inside
		// Gives    > 0 if outside
		// Use objects[i]
		float sdfVal = sdCircle(
			objects[i].xy - world_position,
			// a stores the radius
			objects[i].a
		);
		if (objects[i].a > max_radius) {
			max_radius = objects[i].a;
		}
		// Info: only divergent paths are slow, I think
		// normal "if"s are okay to use
		// float result = sdfVal <= 0 ? 1.0 : 0.0;
		
		// min selects the most "inside" value
		color = min(
			color,
			sdfVal
		);
	}
	color = -color;
	
	// before that, will be 1 and above
	//color = color / 255.0;
	color = color / max_radius;

	float small_color = 0.0;
	
	// FIXME: there is probably a better way to do this
	// SCREEN_PIXEL_SIZE is:
	// Size of individual pixels. Equal to inverse of resolution.
	vec2 screen_px = SCREEN_UV / SCREEN_PIXEL_SIZE;
	vec2 world_pos = screen_to_world_origin
		+ screen_to_world_x * screen_px.x
		+ screen_to_world_y * screen_px.y;
	vec2 mask_uv = (world_pos - world_origin) / world_size;
	
	if (any(lessThan(mask_uv, vec2(0.0))) ||
		any(greaterThan(mask_uv, vec2(1.0)))) {
		// pass
		small_color = 0.0;
	} else {
		// Info: this is when the orthographic projection has already
		// been applied to the history texture
		// because we only write from 0.25 to 0.75 in the y dir
		// in this case
		float remapped_y = remap(
			mask_uv.y,
			0,
			1,
			0.25,
			0.75
		);
		mask_uv.y = remapped_y;
		
		small_color = texture(small_tex, mask_uv).r;
		
		// FIXME: do this properly
		
		// Info: can use bilinear sampling instead
		// filter_linear or filter_linear_mipmap
		
		// attempt 1 for a blur
		small_color += texture(small_tex, mask_uv + screen_px).r;
		small_color += texture(small_tex, mask_uv - screen_px).r;
		small_color = small_color / 3.0;
		
		// attempt for a blur
		// funny results if the radius is big
		//float radius_ = 5.0;
		//vec2 offset1 = vec2(-1, 0) * SCREEN_PIXEL_SIZE * radius_;
		//vec2 offset2 = vec2(0, -1) * SCREEN_PIXEL_SIZE * radius_;
		//vec2 offset3 = vec2(1, 0) * SCREEN_PIXEL_SIZE * radius_;
		//vec2 offset4 = vec2(0, 1) * SCREEN_PIXEL_SIZE * radius_;
		//small_color += texture(small_tex, mask_uv + offset1).r;
		//small_color += texture(small_tex, mask_uv + offset2).r;
		//small_color += texture(small_tex, mask_uv + offset3).r;
		//small_color += texture(small_tex, mask_uv + offset4).r;
		//small_color = small_color / 5.0;
	}
	
	// This is doing the same as sharp edges
	//small_color = step(0.1, small_color);
	small_color = smoothstep(
		0.0,
		// 0.3 gives the feeling it's not the same circle sizes
		// but it looks kind of better
		0.1,
		small_color
	);
	
	// that's a merge
	//color = max(
		//small_color,
		//color
	//);
	// float alpha = 1.0 - color;
	float alpha = 1.0;
	if (color > 0.0) {
		// not sure if still the case
		// FIXME: there is a weird disconnection
		// like a wavefront
		// maybe because the circles are not centered
		
		// Info: this make sure we don't have the weird black circle
		// and it works properly when it's already explored
		color = smoothstep(
			0.0,
			0.3,
			color
		);
		color = max(
			color, small_color
		);
		alpha = 1.0 - color;
	} else if (small_color > 0.0) {
		//alpha = 0.5;
		// / 2.0 to target 0.5
		alpha = (1.0 - small_color / 2.0);
	} else {
		alpha = 1.0;
	}
	
	COLOR = vec4(vec3(0.0), alpha);
	// the others are here to debug
	//COLOR = vec4(vec3(color), color);
	//COLOR = vec4(vec3(small_color), 0.5);
	
}
