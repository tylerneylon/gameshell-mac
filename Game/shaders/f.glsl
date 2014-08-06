// f.glsl
//

#version 330 core

in vec2 t_position;

out vec4 out_color;

uniform sampler2D sampler;

void main() {
  out_color = texture(sampler, t_position);
}

