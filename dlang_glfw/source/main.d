

import std.stdio : stdout, stderr;
import std.string : format, toStringz;
import std.conv : to;
import std.concurrency;
import core.thread;
import std.variant : Variant;

import bindbc.opengl;
import bindbc.glfw;
import bindbc.sdl;

import global;
import helpers;
import sprite;
import timer;
import manager;
import GC;


extern (C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow {
	import core.stdc.stdio : printf;

	if (action != GLFW_PRESS) return;

	try {
		switch (key) {
			case GLFW_KEY_ESCAPE:
				glfwSetWindowShouldClose(window, true);
				break;
			case GLFW_KEY_Z:
				Manager.loadSprite("container.jpg");
				break;
			case GLFW_KEY_X:
				Manager.loadSprite("awesomeface.png");
				break;
			case GLFW_KEY_W:
				g_sprites[0]._origin.y -= 0.1f;
				g_sprites[1]._origin.y += 0.1f;
				break;
			case GLFW_KEY_S:
				g_sprites[0]._origin.y += 0.1f;
				g_sprites[1]._origin.y -= 0.1f;
				break;
			case GLFW_KEY_A:
				g_sprites[0]._origin.x += 0.1f;
				g_sprites[1]._origin.x -= 0.1f;
				break;
			case GLFW_KEY_D:
				g_sprites[0]._origin.x -= 0.1f;
				g_sprites[1]._origin.x += 0.1f;
				break;
			default:
				break;
		}
	} catch (Throwable e) {
		printf("!!! threw exception");
	}
}

int main() {
	InitSDL();
	InitGTFW();

	// Init GLFW
	if (! glfwInit()) {
		stderr.writefln("Could not initialize GLFW: %s", glfwGetError(null));
		return 1;
	}

	// Set all the required options for GLFW
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

	glfwWindowHint(GLFW_VISIBLE, GL_FALSE);
	g_thread_window = glfwCreateWindow(1, 1, "", null, null);
	if (! g_thread_window) {
		stderr.writefln("Could not create GLFW window: %s", glfwGetError(null));
		glfwTerminate();
		return 1;
	}

	// Create a windowed mode window and its OpenGL context
	glfwWindowHint(GLFW_VISIBLE, GL_TRUE);
	GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE.toStringz, null, g_thread_window);
	if (! window) {
		stderr.writefln("Could not create GLFW window: %s", glfwGetError(null));
		glfwTerminate();
		return 1;
	}

	// Make the window's context current
	glfwMakeContextCurrent(window);

	glfwSetKeyCallback(window, &key_callback);

	// Reload to get new OpenGL functions
	InitOpenGL();
	//DerelictGL3.reload(); // FIXME: Do we need to update OpenGL extensions?

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
	while (! glfwWindowShouldClose(window)) {
		stop_watch.reset();
		fps_counter++;
		// Check if any events have been activiated (key pressed, mouse moved etc.) and call corresponding response functions
		glfwPollEvents();

		// Clear the colorbuffer
		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		foreach (sprite ; g_sprites) {
			if (sprite.is_loaded()) {
				sprite.render();
			}
		}

		// Swap the screen buffers
		glfwSwapBuffers(window);

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
			glfwSetWindowTitle(window, "%s FPS: %s".format(TITLE, _fps).toStringz);
		}

		auto frame_time = stop_watch.ticks_since_reset();
		if (frame_time > 1) {
			print("!!!! frame_time: %s", frame_time);
		}
		SDL_Delay(1000 / FPS);
	}

	Manager.stop();
	glfwTerminate();

	GC.Enable();

	return 0;
}
