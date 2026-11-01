shader_type canvas_item;

bool equal_approx2(vec4 vec1_, vec4 vec2_, float epsilon) {
	return (length(abs(vec1_ - vec2_)) < epsilon);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	if (equal_approx2(COLOR, vec4(0.0, 0.0, 0.0, 1.0), 0.5)) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
