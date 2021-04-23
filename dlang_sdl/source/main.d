

import std.stdio : stdout, stderr;

import std.conv : to;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;

import sprite;
import helpers;

// Window dimensions
const GLuint WIDTH = 1280, HEIGHT = 800;

int main() {
	import std.string : format;

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

	int flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN;
	SDL_Window* window = SDL_CreateWindow("SDL2 OpenGL Texture Example", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WIDTH, HEIGHT, flags);
	if (window == null) {
		stderr.writefln("Failed to create window: %s", GetSDLError());
		return 1;
	}

	SDL_GLContext gContext = SDL_GL_CreateContext(window);
	if(gContext == null) {
		stderr.writefln("OpenGL context could not be created! SDL Error: %s", GetSDLError());
		return 1;
	}

	// Reload to get new OpenGL functions
	DerelictGL3.reload();

	stdout.writefln("Vendor:   %s", glGetString(GL_VENDOR).to!string);
	stdout.writefln("Renderer: %s", glGetString(GL_RENDERER).to!string);
	stdout.writefln("Version:  %s", glGetString(GL_VERSION).to!string);
	stdout.writefln("GLSL:     %s", glGetString(GL_SHADING_LANGUAGE_VERSION).to!string);

	// Define the viewport dimensions
	glViewport(0, 0, WIDTH, HEIGHT);

	auto sprite = new Sprite("../../../container.jpg");//width, height, 0x00FF00FF);//"two.png");
	sprite.init();

	auto sprite2 = new Sprite("../../../awesomeface.png");//width, height, 0x00FF00FF);//"two.png");
	sprite2.init();

	// Game loop
	bool is_running = true;
	while (is_running) {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				is_running = false;
			}

			if (event.type == SDL_KEYDOWN) {
				switch (event.key.keysym.sym) {
					case SDLK_ESCAPE:
						is_running = false;
						break;
					case SDLK_LEFT:
						sprite.x = sprite.x - 1;
						sprite2.x = sprite2.x + 1;
						break;
					case SDLK_RIGHT:
						sprite.x = sprite.x + 1;
						sprite2.x = sprite2.x - 1;
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

		sprite.render();
		sprite2.render();

		// Swap the screen buffers
		SDL_GL_SwapWindow(window);

		SDL_Delay(1000 / 60);
	}

	// Terminate
	SDL_Quit();

	return 0;
}
