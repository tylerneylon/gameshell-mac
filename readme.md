# gameshell-mac

*A basic shell for mac OpenGL games.*

This is meant to act as a starting point for mac OpenGL games.
It is designed to work will with the
companion repo [gameshell-win](https://github.com/tylerneylon/gameshell-win).
Essentially, you can develop one set of C/C++ files with portable code
that will run on both systems. This shell takes care of setting up input and OpenGL
for you, along with a few other things.

This low-level shell includes:

* A basic vertex / fragment shader pair.
* Placeholder functions for initializing and running a render cycle.
* Placeholder functions for working with user input.
* The GLM math library to easily work with vectors and matrices.
* The `oswrap` library to provide a cross-platform interface for common game operations.

To use it, just download and modify to your heart's content. You're
free to release and sell - or give away - what you make with it.
This is open source under [the MIT license](http://opensource.org/licenses/MIT).
