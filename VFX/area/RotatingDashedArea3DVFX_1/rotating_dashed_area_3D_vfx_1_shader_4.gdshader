shader_type spatial;
render_mode cull_disabled;

// Credits: https://godotshaders.com/shader/animated-dotted-rectangle-outline/
// License: CC0 1.0

// TODO: clean those up / indicate what it's doing
// I think, one of the shaders did not had the correct rotation
// And for the other one, I don't remember

uniform vec4 color: source_color = vec4(1.0);
uniform float direction: hint_range(-1.0, 1.0, 1.0) = -1.0;
// the number of dotted lines
uniform float frequency: hint_range(0.1, 30.0, 0.1) = 15.0;
// rotation speed
uniform float speed: hint_range(0.5, 20, 0.5) = 3.0;
uniform float radius: hint_range(0.01, 1.0, 0.01) = 1.0;
uniform float line_thickness: hint_range(0.0, 0.5, 0.01) = 0.03;

varying vec3 vert;

float remap(float value, float input_b, float input_e, float output_b, float output_e) {
	return(value - input_b) / (input_e - input_b) * (output_e - output_b) + output_b;
}

void vertex() {
	vert = VERTEX;
}

void fragment() {
	// this makes a square at the center
	//float abs_x = abs(vert.x);
	//float abs_z = abs(vert.z);
	//float x_dist = 2.0 - abs(vert.x);
	//float z_dist = 2.0 - abs(vert.z);
	//float edge_dist = min(
		//x_dist,
		//z_dist
	//);
	//if (edge_dist > line_thickness) {
		//discard;
	//}
	
	// this makes a circle
	float edge_dist = 2.5 - distance(
		vec3(0.0),
		vert
	);
	if (edge_dist > line_thickness) {
		discard;
	}
	//if (vert.y > 0.001) {
		//discard;
	//}
	
	vec4 circle_outline;
	// vec2 pos = UV - vec2(0.5);
	// gives a cross and weird result
	//vec2 pos = vec2(abs(vert.x), abs(vert.z)) - vec2(0.5);
	// just weird result
	//vec2 pos = vec2(abs(vert.x), abs(vert.z));// - vec2(0.5);
	// just weird
	//vec2 pos = vec2(vert.x, vert.z);// - vec2(0.5);
	vec2 pos = vec2(vert.x, vert.z) + vec2(0.5);
	float circle = step(length(pos), radius);
	float angle = atan(pos.y, pos.x);

	float wave = 0.5 * sin(direction * frequency * angle + TIME * speed) + 0.5;

	circle *= step(0.5, wave);
	circle_outline = vec4(color.rgb, circle * color.a);

	float rect_alpha = 1.0 - step(abs(pos.x), (0.5-line_thickness)) * step(abs(pos.y), (0.5-line_thickness));
	
	ALBEDO = circle_outline.rgb;
	//ALPHA = rect_alpha * circle_outline.a;
	// funny result with cylinder and vec2 pos = vec2(vert.x, vert.z) + vec2(0.5);
	ALPHA = wave;
	ALPHA_SCISSOR_THRESHOLD = 0.9;
}