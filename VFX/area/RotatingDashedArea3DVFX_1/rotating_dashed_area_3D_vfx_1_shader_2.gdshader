shader_type spatial;

// Info: modified version of different shaders

// Credits: https://godotshaders.com/shader/animated-3d-grid-outline/
// License: CC0 1.0

// Editable parameters in the inspector
instance uniform vec3 center = vec3(0.0, 0.0, 0.0);
uniform float border_thickness : hint_range(0.01, 1.0) = 0.05;
uniform float dot_spacing : hint_range(5.0, 100.0) = 10.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0; // Controls the opacity of lines
uniform vec3 line_color : source_color = vec3(1.0, 1.0, 1.0); // Color of the lines
uniform float rotation_speed : hint_range(0.0, 5.0) = 1.0; // Rotation speed

varying vec3 world_position;
varying vec3 model_position;

// from https://godotshaders.com/shader/animated-dotted-rectangle-outline/
// License: CC0 1.0
uniform float direction: hint_range(-1.0, 1.0, 1.0) = -1.0;
uniform float radius: hint_range(0.01, 1.0, 0.01) = 1.0;
uniform float frequency: hint_range(0.1, 30.0, 0.1) = 15.0;
uniform float speed: hint_range(0.5, 20, 0.5) = 3.0;

// from https://godotshaders.com/shader/procedural-cyclic-slash/
// License: CC0 1.0
uniform float zoom : hint_range(0.0, 2.0, 0.01) = 0.6;
uniform float rotate_all : hint_range(0.0, 360.0, 0.1) = 0.0;
vec2 polar_coordinates(vec2 uv, vec2 center_, float zoomm, float repeat) {
	vec2 dir = uv - center_;
	float radius_ = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius_ * zoomm, angle * repeat), 1.0);
}

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	model_position = VERTEX;
}

void fragment() {
    // Use the time to shift the lines clockwise
    float time_offset = -TIME * rotation_speed;

    // Calculate edge distance with UV
    //float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	
	// gives a cross for a quad
	// gives a cross + border for a plane
	//float edge_dist = min(
		//min(abs(model_position.x), 1.0 - abs(model_position.x)),
		//min(abs(model_position.z), 1.0 - abs(model_position.z))
	//);
	
	float abs_x = abs(model_position.x);
	float abs_z = abs(model_position.z);
	float x_dist = 1.0 - abs(model_position.x);
	float z_dist = 1.0 - abs(model_position.z);
	float edge_dist = min(
		x_dist,
		z_dist
	);
	// does not work for either
	//float edge_dist = min(
		//min(model_position.x, 1.0 - (model_position.x)),
		//min(model_position.z, 1.0 - (model_position.z))
	//);
	
	// gives a circle
	//float edge_dist = distance(center, model_position);
	//edge_dist = 1.0 - edge_dist;

    // Apply the effect to the edges only
	// gives lines on each side
    //if (x_dist < border_thickness) {
    if (edge_dist < border_thickness) {
        // Dotted pattern with a time shift to simulate rotation
		// This put dots moving away from the center of line
		//float dotted_pattern = step(
			//0.5,
			//0.5 + 0.5 * sin(dot_spacing * (abs_x + abs_z + time_offset))
		//);
		// this is the same as the original
        //float dotted_pattern = step(
			//0.5,
			//0.5 + 0.5 * sin(dot_spacing * (model_position.x + model_position.z + time_offset))
		//);
		
		// rotates correctly but is not dashed properly
		//vec2 aUV = polar_coordinates(
			//rotate(
				//UV,
				//vec2(0.5),
				//radians(rotate_all)
			//),
			//vec2(0.5),
			//zoom,1.0
		//);
		//float dotted_pattern = step(
			//0.5,
			//0.5 + 0.5 * sin(dot_spacing * (aUV.x + aUV.y + time_offset))
		//);
		vec2 pos = UV - vec2(0.5);
		float circle = step(length(pos), radius);
		float angle = atan(pos.y, pos.x);

		float wave = 0.5 * sin(direction * frequency * angle + TIME * speed) + 0.5;

		circle *= step(0.5, wave);
		vec4 circle_outline = vec4(line_color.rgb, circle);

        // Apply colour and opacity to points
        //ALBEDO = line_color * circle_outline;
        ALBEDO = circle_outline.rgb;
        //ALPHA = opacity * dotted_pattern;
        ALPHA = circle_outline.a;
    } else {
        discard; // Total transparency outside the edges
    }
}
