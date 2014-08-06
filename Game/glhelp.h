// glhelp.h
//
// Tools for more easily working with OpenGL.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
#define GLEW_STATIC
#include "glew/glew.h"
#else
#import <OpenGL/OpenGL.h>
#endif

// Load a pair of shaders into a program and set it as the current one.
// A zero return value indicates an error; if an error occurs, a message will
// be printed before this returns.
GLuint glhelp__load_program(const char *v_shader, const char *f_shader);

// Check for any OpenGL errors up until this point. Call this like so:
//   glhelp__error_check;  // Nothing else needed; don't use parentheses.
// Warning: this function appears to force cpu/gpu synchronization on windows.
#define glhelp__error_check gl_error_check_(__FILE__, __LINE__, __FUNCTION__)

// Implementation of the glhelp__error_check macro; use the macro above in your code.
void gl_error_check_(const char *file, int line, const char *func);

#ifdef __cplusplus
}
#endif
