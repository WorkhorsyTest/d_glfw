

import std.stdio : stdout, stderr;
import std.conv : to;
import std.concurrency;
import core.thread;
import std.variant : Variant;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import global;
import helpers;
import sprite;
import timer;


Tid _thread_id_manager;
__gshared GLFWwindow* g_thread_window;
__gshared Sprite g_sprite1 = null;
__gshared Sprite g_sprite2 = null;

void managerWorker(Tid parent_tid) {
	import std.string : format;
	import core.thread.osthread : Thread;

	glfwMakeContextCurrent(g_thread_window);
	//glewInit();

	Thread.sleep( dur!("seconds")( 5 ) );
	g_sprite1.init1();

	Thread.sleep( dur!("seconds")( 5 ) );
	g_sprite2.init1();

	//bool is_running = true;

	//while (is_running) {

	//	Thread.sleep( dur!("seconds")( 1 ) );
	//}
}

extern (C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow {
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, true);
	}
}

int main() {
	import std.string : format, toStringz;

	InitDerelict();

	// Init GLFW
	if (! glfwInit()) {
		return 1;
	}

	// Set all the required options for GLFW
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

	glfwWindowHint(GLFW_VISIBLE, GL_FALSE);
	g_thread_window = glfwCreateWindow(1, 1, "Thread Window", null, null);
	if (! g_thread_window) {
		glfwTerminate();
		return 1;
	}

	// Create a windowed mode window and its OpenGL context
	glfwWindowHint(GLFW_VISIBLE, GL_TRUE);
	GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE.toStringz, null, g_thread_window);
	if (! window) {
		glfwTerminate();
		return 1;
	}

	// Make the window's context current
	glfwMakeContextCurrent(window);
	_thread_id_manager = spawn(&managerWorker, thisTid);

	glfwSetKeyCallback(window, &key_callback);

	// Reload to get new OpenGL functions
	DerelictGL3.reload();

	stdout.writefln("Vendor:   %s",   to!string(glGetString(GL_VENDOR)));
	stdout.writefln("Renderer: %s",   to!string(glGetString(GL_RENDERER)));
	stdout.writefln("Version:  %s",   to!string(glGetString(GL_VERSION)));
	stdout.writefln("GLSL:     %s", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));

	// Define the viewport dimensions
	glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

	g_sprite1 = new Sprite("../../../container.jpg");
	g_sprite2 = new Sprite("../../../awesomeface.png");

	// Game loop
	auto stop_watch = new Stopwatch(1000);
	auto fps_timer = new Stopwatch(1000);
	int fps_counter;
	while (! glfwWindowShouldClose(window)) {
		stop_watch.reset();
		fps_counter++;
		// Check if any events have been activiated (key pressed, mouse moved etc.) and call corresponding response functions
		glfwPollEvents();

		// Render
		// Clear the colorbuffer
		//glfwMakeContextCurrent(window);
		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		if (g_sprite1 && g_sprite1._load_level == 3) {
			g_sprite1.init3();
		}
		if (g_sprite2 && g_sprite2._load_level == 3) {
			g_sprite2.init3();
		}

		if (g_sprite1 && g_sprite1._load_level == 4) {
			//stdout.writefln("!!! g_sprite1 w:%s, h:%s, len:%s", g_sprite1._surface_w, g_sprite1._surface_h, g_sprite1._surface_pixels.length); stdout.flush();
			g_sprite1.render();
		}

		if (g_sprite2 && g_sprite2._load_level == 4) {
			g_sprite2.render();
		}

		// Swap the screen buffers
		glfwSwapBuffers(window);

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
		SDL_Delay(1000 / 60);
	}

	glfwTerminate();

	return 0;
}
