shader_type canvas_item;

uniform vec2 zoom_center;
uniform float zoom_amount;
uniform bool keep_within_bounds;

void fragment() {
	// Credits: https://godotshaders.com/shader/innovative-zoom-shader/
	// License CC0
	// not good
	
    // Coordinate UV dell'immagine originale
    vec2 uv = SCREEN_UV;
    
    // Calcolo delle coordinate UV traslate rispetto al centro dello zoom
    vec2 zoomed_uv = (uv - zoom_center) * zoom_amount + zoom_center;
    
    // Se keep_within_bounds è abilitato, limita le coordinate UV all'intervallo (0-1)
    if (keep_within_bounds) {
        zoomed_uv = clamp(zoomed_uv, vec2(0.0), vec2(1.0));
    }
    
    // Se le coordinate UV traslate sono fuori dai limiti (0-1), imposta il colore del pixel trasparente
    if (zoomed_uv.x < 0.0 || zoomed_uv.x > 1.0 || zoomed_uv.y < 0.0 || zoomed_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        // Altrimenti, leggi il colore dell'immagine originale alle coordinate UV traslate
        vec2 tex_uv = vec2(zoomed_uv.x, 1.0 - zoomed_uv.y);
        //COLOR = textureLod(texture, tex_uv, 0.0);
        COLOR = textureLod(TEXTURE, tex_uv, 0.0);
    }
}

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

//void fragment() {
	//// 0 to 1, top left : 0
	//vec2 uv = UV;
	////uv += vec2(0.5, 0.5);
	////uv = uv / 2.0;
	//uv = uv * 2.0;
	////COLOR = texture(TEXTURE, uv);
	////COLOR = vec4(uv.x, uv.y, 1.0, 1.0);
	////COLOR = vec4(uv.x, uv.x, uv.x, 1.0);
	////COLOR = vec4(uv.y, uv.y, uv.y, 1.0);
	//
//}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
