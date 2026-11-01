shader_type canvas_item;

/*
 * Info: can use any BBCode for comments
 */

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

// Info: could not make this work
//float sdRhombus(in vec2 p, in vec2 b) { 
	//b.y = -b.y;
	//p =abs(p);
	//float h =clamp( (dot(b,p)+b.y*b.y)/dot(b,b),0.0,1.0);
	//p -= b*vec2(h,h-1.0);
	//return length(p)*sign(p.x);
//}

void fragment() {
	// compute the values of the shape
	vec2 shape_uv = (UV - vec2(0.5)) * uv_scale + vec2(0.5) - uv_position;
	// x : 0 on the left to white on the right (0 to 1)
	// y : 0 on the top to white on the bottom (0 to 1)
	//COLOR = vec4(shape_uv.y, shape_uv.y, shape_uv.y, 1.0);
	vec2 ratio = abs(shape_uv - vec2(0.5));
	// x : 0 in the center to grey on the left/right (a line)
	// y : 0 in the center to grey on the bottom/top (a line)
	//COLOR = vec4(p.y, p.y, p.y, 1.0);
	// this is somewhat a pseudo diamond
	//COLOR = vec4(p.x, p.y, 0.0, 1.0);

	// border_width * grow_outer: allows to control whether or not it grow out
	float expand = 1.0 + border_width * grow_outer;
	vec2 outer_size = half_size * expand;
	// x: grey
	// y: grey
	//COLOR = vec4(outer_size.y, outer_size.y, outer_size.y, 1.0);
	float outer = ratio.x / outer_size.x + ratio.y / outer_size.y;
	// 0 in the center to grey inside the shape to 1 outside
	// it is a diamond
	//COLOR = vec4(outer, outer, outer, 1.0);
	
	vec2 inner_size = half_size * (1.0 - border_width * grow_inner);
	// same, will be a fixed value
	float inner = ratio.x / inner_size.x + ratio.y / inner_size.y;
	// 0 in the center, to grey inside the shape to 1 outside
	// it is a diamond
	//COLOR = vec4(inner, inner, inner, 1.0);
	
	// TODO: find a way to multiply instead

	// Can modify the 1.0s to have a similar effect to the other variables
	// increasing 1.0 makes the outer shape bigger
	if (outer > 1.0) {
		COLOR = vec4(0.0);
	// decreasing 1.0 makes the inner shape bigger
	} else if (inner > 1.0) {
		COLOR = border_color;
	} else {
		COLOR = fill_color;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
