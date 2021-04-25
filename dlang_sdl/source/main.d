

import std.stdio : stdout, stderr;
import std.string : format, toStringz;
import std.conv : to;
import std.concurrency;
import core.thread;
import std.variant : Variant;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
//import derelict.glfw3.glfw3;

import global;
import helpers;
import sprite;
import timer;
import manager;
import GC;


int main() {
	InitDerelict();

	// Initialize SDL
	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		stderr.writefln("Could not initialize SDL: %s", GetSDLError());
		return 1;
	}

	// Setup opengl
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1);

	int flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN;
	g_window = SDL_CreateWindow(TITLE.toStringz, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, flags);
	if (g_window == null) {
		stderr.writefln("Failed to create window: %s", GetSDLError());
		return 1;
	}

	SDL_GLContext gContext = SDL_GL_CreateContext(g_window);
	if(gContext == null) {
		stderr.writefln("OpenGL context could not be created! SDL Error: %s", GetSDLError());
		return 1;
	}

	g_thread_context = SDL_GL_CreateContext(g_window);
	if(g_thread_context == null) {
		stderr.writefln("OpenGL context could not be created! SDL Error: %s", GetSDLError());
		return 1;
	}

	SDL_GL_MakeCurrent(g_window, gContext);

	// Reload to get new OpenGL functions
	DerelictGL3.reload();

	stdout.writefln("Vendor:   %s", glGetString(GL_VENDOR).to!string);
	stdout.writefln("Renderer: %s", glGetString(GL_RENDERER).to!string);
	stdout.writefln("Version:  %s", glGetString(GL_VERSION).to!string);
	stdout.writefln("GLSL:     %s", glGetString(GL_SHADING_LANGUAGE_VERSION).to!string);

	// Define the viewport dimensions
	glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

	Manager.start();
	GC.Disable();

	// Game loop
	auto stop_watch = new Stopwatch(1000);
	auto fps_timer = new Stopwatch(1000);
	int fps_counter;
	bool is_running = true;
	while (is_running) {
		stop_watch.reset();
		fps_counter++;

		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				is_running = false;
			}

			if (event.type == SDL_KEYUP) {
				switch (event.key.keysym.sym) {
					case SDLK_ESCAPE:
						is_running = false;
						break;
					case SDLK_z:
						Manager.loadSprite("../../../container.jpg");
						break;
					case SDLK_x:
						Manager.loadSprite("../../../awesomeface.png");
						break;
					case SDLK_w:
						g_sprites[0]._origin.y -= 0.1f;
						g_sprites[1]._origin.y += 0.1f;
						break;
					case SDLK_s:
						g_sprites[0]._origin.y += 0.1f;
						g_sprites[1]._origin.y -= 0.1f;
						break;
					case SDLK_a:
						g_sprites[0]._origin.x += 0.1f;
						g_sprites[1]._origin.x -= 0.1f;
						break;
					case SDLK_d:
						g_sprites[0]._origin.x -= 0.1f;
						g_sprites[1]._origin.x += 0.1f;
						break;
					default:
						break;
				}
			}
		}

		// Render
		// Clear the colorbuffer
		glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		foreach (sprite ; g_sprites) {
			if (sprite.is_loaded()) {
				sprite.render();
			}
		}

		// Swap the screen buffers
		SDL_GL_SwapWindow(g_window);

		Manager.processResponses();

		// Run garbage collector
		u32 gc_time = GC.Run();
		//if (gc_time) {
		//	print("!!!! gc_time: %s", gc_time);
		//}

		// Get the FPS
		//print("!!!! _fps: %s", _fps);
		if (fps_timer.is_time()) {
			fps_timer.reset();
			_fps = fps_counter;
			fps_counter = 0;
			SDL_SetWindowTitle(g_window, "%s FPS: %s".format(TITLE, _fps).toStringz);
		}

		auto frame_time = stop_watch.ticks_since_reset();
		if (frame_time > 1) {
			print("!!!! frame_time: %s", frame_time);
		}
		SDL_Delay(1000 / FPS);
	}

	// Terminate
	Manager.stop();
	SDL_Quit();

	GC.Enable();

	return 0;
}
