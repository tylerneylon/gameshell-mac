// game.h
//
// A place to put all your game code.
//

void game__init();
void game__main_loop();

void game__mouse_at    (int    x, int    y);
void game__mouse_down  (int    x, int    y);
void game__mouse_moved (float dx, float dy);

void game__key_down  (int code, const char *str);
void game__key_up    (int code);
void game__key_clear ();

void game__resize(int w, int h);
