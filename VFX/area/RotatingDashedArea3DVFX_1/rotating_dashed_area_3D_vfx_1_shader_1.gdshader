shader_type spatial;

// Info: is not rotating correctly

// Credits: https://godotshaders.com/shader/animated-3d-grid-outline/
// License: CC0 1.0

// Editable parameters in the inspector
uniform float border_thickness : hint_range(0.01, 0.1) = 0.05;
uniform float dot_spacing : hint_range(5.0, 100.0) = 10.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0; // Controls the opacity of lines
uniform vec3 line_color : source_color = vec3(1.0, 1.0, 1.0); // Color of the lines
uniform float rotation_speed : hint_range(0.0, 5.0) = 1.0; // Rotation speed

void fragment() {
    // Use the time to shift the lines clockwise
    float time_offset = -TIME * rotation_speed;

    // Calculate edge distance with UV
    float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));

    // Apply the effect to the edges only
    if (edge_dist < border_thickness) {
        // Dotted pattern with a time shift to simulate rotation
        float dotted_pattern = step(0.5, 0.5 + 0.5 * sin(dot_spacing * (UV.x + UV.y + time_offset)));

        // Apply colour and opacity to points
        ALBEDO = line_color * dotted_pattern;
        ALPHA = opacity * dotted_pattern;
    } else {
        discard; // Total transparency outside the edges
    }
}
