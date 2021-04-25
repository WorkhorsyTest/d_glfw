

import derelict.sdl2.sdl;
import sprite;

import std.stdint;

alias int8_t    s8;
alias int16_t   s16;
alias int32_t   s32;
alias int64_t   s64;

alias uint8_t   u8;
alias uint16_t  u16;
alias uint32_t  u32;
alias uint64_t  u64;

debug {
immutable bool IS_RELEASE = false;
} else {
immutable bool IS_RELEASE = true;
}

immutable int FPS = 60;
immutable int SCREEN_WIDTH = 1280;
immutable int SCREEN_HEIGHT = 800;
immutable string TITLE = "Dlang SDL2 Example";

int _fps = 0;
bool _is_running = false;
Sprite[] g_sprites;
SDL_GLContext g_thread_context;
SDL_Window* g_window;
