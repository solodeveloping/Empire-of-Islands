#[compute]
#version 450

// This is workgroup size
// Not warp/wavefronts
// 8*8 = 64 invocations
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// r8: 8 bit per channel, 1 channel
// rgba8: 8 bit per channel, 4 channels
// r8ui, r32f, R8_UINT, R32_UINT, rgba8
layout(rgba8, set = 0, binding = 0) uniform image2D previous_texture;
layout(rgba8, set = 0, binding = 1) uniform image2D current_texture;
layout(rgba8, set = 0, binding = 2) uniform writeonly image2D output_texture;

// Has to be a multiple of 16 in size
// vec4 has to be on it's own 16 aligned range
struct Node2D {
  int id;
  uint type;
  float radius;
  float padding;
  // vec2 data_padding;
  vec4 position;
};

layout(set = 0, binding = 3, std430) readonly buffer Node2Ds {
    Node2D node_2ds[];
} node_2ds;

layout(push_constant, std430) uniform Parameters {
  // texture size
  int texture_width;
  int texture_height;
  // real size in world units
  int map_width;
  int map_height;
  ivec2 map_origin;
  int object_count;
} params;

void _do_double_store(ivec2 position, vec4 new_color) {
  imageStore(current_texture, position, new_color);
  imageStore(output_texture, position, new_color);
}

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float remap(float value, float input_b, float input_e, float output_b, float output_e) {
	return(value - input_b) / (input_e - input_b) * (output_e - output_b) + output_b;
}

const float EPSILON = 0.0001;

bool isEqual(float value_a, float value_b) {
  return abs(value_a - value_b) < EPSILON;
}

void main() {
  ivec2 position = ivec2(gl_GlobalInvocationID.xy);

  if (position.x >= params.texture_width ||
      position.y >= params.texture_height) {
      return;
  }

  // Info: this is to have a orthographic projection
  // otherwise we occupy the whole texture in the y coord
  // which is causing problems elsewhere
  float y = remap(
    float(position.y),
    float(0),
    float(params.texture_height),
    // 0.25 to 0.75, 0.5 in size
    float(params.texture_height) / 4,
    float(params.texture_height) - float(params.texture_height) / 4
  );
  int int_y = int(y);

  ivec2 resized_pos = ivec2(
    position.x,
    int_y
  );

  // position = resized_pos;

  // We have to write the value, otherwise they don't synchronize
  // float existing_value = imageLoad(previous_texture, position).r;
  float existing_value = imageLoad(previous_texture, resized_pos).r;
  // if (existing_value > (EPSILON)) {
    // _do_double_store(position, vec4(existing_value, existing_value, 0.0, 1.0));
    // return;
  // }

  float pixel_world_pos_x = remap(
    position.x,
    0,
    params.texture_width,
    params.map_origin.x,
    params.map_origin.x + params.map_width
  );
  float pixel_world_pos_y = remap(
    position.y,
    0,
    params.texture_height,
    params.map_origin.y,
    params.map_origin.y + params.map_height
  );
  vec2 world_pos = vec2(
    pixel_world_pos_x,
    pixel_world_pos_y
  );

  float color = 0.0;
  // Can go up to the largest radius: 250
  float max_d = 0.0;
  float max_radius = 0.0;
  // uint count = node_2ds.node_2ds.length();
  // for (int i = 0; i < params.object_count; i++) {
  for (int i = 0; i < params.object_count; i++) {
    vec2 object_position = vec2(
      node_2ds.node_2ds[i].position.x,
      node_2ds.node_2ds[i].position.y
    );

    vec2 dist = world_pos - object_position;

    // Gives    0 if on surface
    // Gives    < 0 if inside
    // Gives    > 0 if outside
    // "-" => inverses it
    float d = -sdCircle(
      dist,
      node_2ds.node_2ds[i].radius
    );

    if (node_2ds.node_2ds[i].radius > max_radius) {
      max_radius = node_2ds.node_2ds[i].radius;
    }

    if (d > 0) {
      // inside
      if (d > max_d) {
        max_d = d;
      }
      // color = d;
      color = max(
        color,
        d
      );
    } else {
      continue;
    }
  }
  // gives stranges wavy results
  // max_d = 10;
  // was working okay
  // color = color / 255;
  color = clamp(color / max_radius, 0.0, 1.0);
  // color = clamp(log(1.0 + color) / log(1.0 + max_d), 0.0, 1.0);
  // version if we don't store at the start
  // color = max(color, existing_value);

  // FIXME: we always restore but I don't see another way
  // If we don't, the current_texture does not sync with previous_texture

  // original version if we store at the beginning
  // if (color > (EPSILON) && color > existing_value) {

  if (color > existing_value) {
    // _do_double_store(position, vec4(color, max_d / 255, color, 1.0));

    // normal texture writing
    // _do_double_store(position, vec4(color, 0.0, color, 1.0));
    _do_double_store(resized_pos, vec4(color, 0.0, color, 1.0));
  } else if (existing_value > EPSILON) {
    // normal texture writing
    // _do_double_store(position, vec4(existing_value, existing_value, 0.0, 1.0));
    _do_double_store(resized_pos, vec4(existing_value, existing_value, 0.0, 1.0));
  }

}
