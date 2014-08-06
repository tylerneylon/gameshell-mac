// glhelp.c
//

#include "glhelp.h"

// The following files are available from:
// https://github.com/tylerneylon/oswrap
// Please add the appropriate (win or mac) oswrap directory to your project.
#include "cbit.h"
#include "oswrap/oswrap.h"

#ifdef _WIN32
#include <windows.h>
#include <malloc.h>
#define size_t_fmt_str "%Iu"
#else
#include <libgen.h>
#include <OpenGL/gl3.h>
#define size_t_fmt_str "%zu"
#endif

#include <stdio.h>


// Internal functions.

static void print_shader_log_if_nonempty(GLuint shader) {
  GLint log_length;
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &log_length);
  if (log_length > 1) {
    GLchar *log = alloca(log_length + 1);
    glGetShaderInfoLog(shader, log_length, &log_length, log);
    dbg__printf("Shader log:\n%s\n", log);
  }
}

static bit load_shader(const char *filename, GLenum shader_type, GLuint program) {

  char *path = file__get_path(filename);

  if (path == NULL) {
    dbg__printf("Error: couldn't find the file %s.\n", filename);
    return false;
  }

  size_t file_size;
  const char *file_contents = file__contents(path, &file_size);

  if (file_contents == NULL) { return false; }

  GLuint shader = glCreateShader(shader_type);
  GLint gl_file_size = (GLint)file_size;
  glShaderSource(shader, 1 /* count */, &file_contents, &gl_file_size);
  glCompileShader(shader);
  
  print_shader_log_if_nonempty(shader);

  GLint compiled;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
  if (!compiled) {
    const char *shader_type_name = "unknown";
    if (shader_type == GL_VERTEX_SHADER)   shader_type_name = "vertex";
    if (shader_type == GL_FRAGMENT_SHADER) shader_type_name = "fragment";
    dbg__printf("Shader didn't compile (type=%s).\n", shader_type_name);
    return false;
  }

  glAttachShader(program, shader);
  
  return true;
}

// Public functions.

// Returns a program name or zero if there was an error. If an error
// occurs, a message will be printed about it.
GLuint glhelp__load_program(const char *v_shader_name, const char *f_shader_name) {

  GLuint program = glCreateProgram();
  if (program == 0) {
    dbg__printf("glCreateProgram returned 0.\n");
    return 0;
  }

  // load_shader prints out its own error messages, so we don't have to.
  if (!load_shader(v_shader_name, GL_VERTEX_SHADER,   program)) return 0;
  if (!load_shader(f_shader_name, GL_FRAGMENT_SHADER, program)) return 0;
  
  // Link the program.
  glLinkProgram(program);
  GLint linked;
  glGetProgramiv(program, GL_LINK_STATUS, &linked);
  if (!linked) {
    dbg__printf("Program didn't link.\n");
    return 0;
  }

  glUseProgram(program);

  return program;
}

void gl_error_check_(const char *file, int line, const char *func) {
  GLenum err;
  while ((err = glGetError()) != GL_NO_ERROR) {
    dbg__printf("%s:%d (%s) OpenGL error: 0x%04X.\n",
      basename((char *)file), line, func, err);
  }
}
