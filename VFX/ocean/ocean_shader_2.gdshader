//credit:  https://www.reddit.com/r/godot/comments/11j1sh8/need_help_with_orthographic_water_shaders/
//credit:  https://godotshaders.com/shader/cheap-water-shader/
//credit:  https://godotshaders.com/shader/water-shader-for-realistic-look/
//cobbled together by dangerz for SpecFreq, https://www.specfreq.com

// https://godotshaders.com/shader/orthogonal-camera-view-water-shader/

shader_type spatial;
// https://github.com/godotengine/godot/issues/63673
//render_mode specular_schlick_ggx, unshaded, cull_back, async_visible; // don't know what any of these do
render_mode specular_schlick_ggx, unshaded, cull_back; // don't know what any of these do

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4( 0.3, 0.4, 0.45, 1.0);
uniform sampler2D caustics : hint_default_white;
uniform float slowdown : hint_range( 0.1, 10.0, 0.1 ) = 5.0;
uniform float time_caust : hint_range( 0.01, 1.0, 0.01 ) = 0.13;
uniform float caust_form : hint_range( 0.01, 1.0, 0.01 ) = 0.15;
uniform float tile: hint_range( 0.1, 16.0, 0.1 ) = 4.0;
uniform float height_scale = 0.5;
uniform sampler2D noise;
uniform sampler2D normalmap;
varying vec2 tex_position;
const float wave_pow = 0.65; //yes, waves power
const float wave_pow2 = 4.0; //so much wave power that aquaman is jealous
const float wave_scale = 0.4; //maybe related to fish scales?
const float wave_scale2 = 0.3;
const float wave_scale3 = 0.5;
const float wave_scale4 = 0.6;

uniform vec4 intersection_color : source_color;
uniform vec4 main_color : source_color;
uniform float intersection_max_threshold = 0.5;

float getDepth(vec2 screen_uv, float raw_depth, mat4 inv_projection_matrix){
//	Credit: https://godotshaders.com/shader/depth-modulated-pixel-outline-in-screen-space/
	vec3 normalized_device_coordinates = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_space = inv_projection_matrix * vec4(normalized_device_coordinates, 1.0);	
	view_space.xyz /= view_space.w;	 //wut
	return -view_space.z;
}

float wave(vec2 position){ //hello *wave back*
  position += texture(noise, position / 64.0).x * 2.0 - 1.0;
  vec2 wv = 1.0 - abs(sin(position));
  return pow(1.0 - pow(wv.x * wv.y, wave_pow), wave_pow2);
}

float height(vec2 position, float time) { //time, yeah, definitely that
  float d = wave((position + time) * wave_scale) * 0.3;
  d += wave((position - time) * wave_scale2) * 0.3; //so friendly with all the waving.. is it too much tho??
  d += wave((position + time) * wave_scale3) * 0.2;
  d += wave((position - time) * wave_scale4) * 0.2;
  return d;
}

void vertex() { //so many good comments in here, none are mine
  // Get the current vertex position
  vec3 pos = VERTEX;

  // Get the height of the terrain at this position
  float k = height(pos.xz, TIME);

  // Set the Y position of the vertex to the terrain height
  VERTEX.y = k * height_scale;

  // Calculate the normal vector using nearby terrain heights
  NORMAL = normalize(vec3(
    k - height(pos.xz + vec2(0.1, 0.0), TIME),
    0.1,
    k - height(pos.xz + vec2(0.0, 0.1), TIME)
  ));

  // Apply the normal map to the normal vector
  //NORMAL = normalize(texture(normalmap, tex_position).rgb * 2.0 - 1.0 + NORMAL);
  NORMAL = normalize(texture(normalmap, UV).rgb * 2.0 - 1.0 + NORMAL);
} // how does any of this work.  just like the tide, no one truly knows

void fragment() { //fragment means its just a small part of something.  *science*
	float caustics_form = texture(caustics , UV * (tile + sin(TIME / slowdown) * time_caust )).r;//
	vec2 caustics_uv =  UV * (tile + cos(TIME / slowdown) * time_caust ) + caustics_form * caust_form ;
	float caustics_final = texture(caustics, caustics_uv).r; //whats a caustic lol no idea
	
	float base_depth = getDepth(SCREEN_UV, FRAGCOORD.z, INV_PROJECTION_MATRIX);
	float surface_depth = getDepth(SCREEN_UV, texture(DEPTH_TEXTURE, SCREEN_UV).x, INV_PROJECTION_MATRIX);
	float diff = surface_depth - base_depth; //probably at least 4?  3?  honestly no idea

	vec4 foam = mix(intersection_color, main_color, step(intersection_max_threshold, diff)); //i renamed this from col to foam.  I am smart.

	ALBEDO = (1.0-SCREEN_UV.y) * caustics_final * tint_color.rgb + foam.rgb; //i didn't know what to do with foam, just tried multiplying, dividing, then adding worked so I kept that
	ALPHA = min(SCREEN_UV.y + 0.5, 1.0 ) * tint_color.a + foam.r; //this shader is the alpha shader
}