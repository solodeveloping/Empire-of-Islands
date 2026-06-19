shader_type spatial;
render_mode blend_mix, cull_front, unshaded;

// CC0 https://creativecommons.org/publicdomain/zero/1.0/
// https://godotshaders.com/shader/the-simplest-outline-shader-via-material/

// does not work for planes

uniform vec4 color : source_color = vec4(1,0,0,1);
uniform float size : hint_range(1.0, 1.5, 0.01) = 1.05;

void vertex() {
	VERTEX *= size;
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
