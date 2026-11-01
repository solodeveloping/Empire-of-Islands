shader_type spatial;

instance uniform vec3 center = vec3(0.0, 0.0, 0.0);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dist = distance(center, world_position);
	dist = clamp(
		dist,
		0,
		1
	);
	ALBEDO = vec3(dist);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
