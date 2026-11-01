shader_type spatial;

// https://www.opengl-tutorial.org/beginners-tutorials/tutorial-3-matrices/
// https://old.reddit.com/r/godot/comments/16p8n2k/godot_shader_cheat_sheet_i_made_because_i_always/

instance uniform vec3 center = vec3(0.0, 0.0, 0.0);

varying vec3 model_position;

void vertex() {
	model_position = VERTEX;
}

void fragment() {
	//ALBEDO = vec3(model_position.x);
	ALBEDO = vec3(model_position.z);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
