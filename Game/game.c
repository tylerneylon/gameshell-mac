// game.c
//

#include "game.h"
#include "glhelp.h"
#include <OpenGL/gl3.h>


GLuint program;
GLuint vao, v_pos_vbo, t_pos_vbo, tex;
GLuint sampler_loc;

// The order in this enum matches the layout order in v.glsl,
// and the code depends on this.
enum {
  v_position,
  t_position
};

void game__init() {
  glClearColor(0, 0, 0.4, 1.0);
  
  program = glhelp__load_program("v.glsl", "f.glsl");
  
  glGenVertexArrays(1, &vao);
  glhelp__error_check;
  glBindVertexArray(vao);
  glhelp__error_check;
  
  
  
  // Programmatically generate raw texture data.
  
  const int w = 8;
  const int h = 8;
  unsigned char pixels[w * h * 4];
  // Generate a checkerboard pattern.
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      int base = 4 * (w * y + x);
      int level = ((x + y) % 2 == 0 ? 0 : 255);
      pixels[base + 0] = level;
      pixels[base + 1] = level;
      pixels[base + 2] = level;
      pixels[base + 3] = 255;    // Full alpha for each pixel.
    }
  }
  
  // Load in a programmatically-generated texture.
  
  glGenTextures(1, &tex);
  glhelp__error_check;
  glActiveTexture(GL_TEXTURE0);
  glhelp__error_check;
  glBindTexture(GL_TEXTURE_2D, tex);
  glhelp__error_check;
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  glhelp__error_check;

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glhelp__error_check;
  
  sampler_loc = glGetUniformLocation(program, "sampler");
  glhelp__error_check;
  
  glUniform1i(sampler_loc, 0 /*GL_TEXTURE0*/);
  glhelp__error_check;
  
  
  // Set up vertex coordinates.
  
  GLfloat vertices[] = {
    -0.5,  0.5, -1.0,
     0.5,  0.5, -1.0,
     0.5, -0.5, -1.0,
    -0.5, -0.5, -1.0
  };
  
  glGenBuffers(1, &v_pos_vbo);
  glhelp__error_check;
  glBindBuffer(GL_ARRAY_BUFFER, v_pos_vbo);
  glhelp__error_check;
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  glhelp__error_check;
  glVertexAttribPointer(v_position, 3 /* num coords */, GL_FLOAT, GL_FALSE /* normalize */, 0 /* stride */, (void *)(0) /* pointer */);
  glhelp__error_check;
  glEnableVertexAttribArray(v_position);
  glhelp__error_check;
  
  
  // Set up texture coordinates.
  
  GLfloat low = 0.0, hi = 1.0;
  GLfloat t_positions[] = {
    low, low,
    hi,  low,
    hi,  hi,
    low, hi
  };
  
  glGenBuffers(1, &t_pos_vbo);
  glhelp__error_check;
  glBindBuffer(GL_ARRAY_BUFFER, t_pos_vbo);
  glhelp__error_check;
  glBufferData(GL_ARRAY_BUFFER, sizeof(t_positions), t_positions, GL_STATIC_DRAW);
  glhelp__error_check;
  glVertexAttribPointer(t_position, 2 /* num coords */, GL_FLOAT, GL_FALSE /* normalize */, 0 /* stride */, (void *)(0) /* pointer */);
  glhelp__error_check;
  glEnableVertexAttribArray(t_position);
  glhelp__error_check;
}

void game__main_loop() {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

void game__mouse_at(int x, int y) {
  
}

void game__mouse_down(int x, int y) {
  
}

void game__mouse_moved(float dx, float dy) {
  
}

void game__key_down(int code, const char *str) {
  
}

void game__key_up(int code) {
  
}

void game__key_clear() {
  
}

void game__resize(int w, int h) {
  
}

