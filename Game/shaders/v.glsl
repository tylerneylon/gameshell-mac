// v.glsl
//

#version 330 core

layout(location = 0) in vec3 v_position;
layout(location = 1) in vec2 t_position_in;

out vec2 t_position;

void main() {
  gl_Position = vec4(v_position, 1.0);
  t_position = t_position_in;
}

