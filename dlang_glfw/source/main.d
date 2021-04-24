

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
import GC;


Tid _thread_id_manager;
__gshared GLFWwindow* g_thread_window;
__gshared Sprite g_sprite1 = null;
__gshared Sprite g_sprite2 = null;
__gshared Sprite[] g_to_load;
__gshared bool g_start_loading_1 = false;

void managerWorker(Tid parent_tid) {
	import std.string : format;

	glfwMakeContextCurrent(g_thread_window);
	bool is_running = true;

	while (is_running) {
		receive((ManagerRequest request) {
			final switch (request) {
				case ManagerRequest.stop:
					is_running = false;
					break;
				case ManagerRequest.load_image:
					print("??? 1 load_image");
					g_sprite1.load();
					print("??? 1 load_image done");
					//g_sprite2.load();
					//send(parent_tid, ManagerResponse.print, "!!! Manager load_image");
					break;
				case ManagerRequest.compile_shader:
					print("??? 2 compile_shader");
					g_sprite1.load();
					//g_sprite2.load();
					print("??? 2 compile_shader done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager compile_shader");
					break;
				case ManagerRequest.init_arrays:
					print("??? 3 init_arrays");
					g_sprite1.load();
					//g_sprite2.load();
					print("??? 3 init_arrays done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager init_arrays");
					break;
				case ManagerRequest.init_buffers:
					print("??? 4 init_buffers");
					g_sprite1.load();
					//g_sprite2.load();
					print("??? 4 init_buffers done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager init_buffers");
					break;
				case ManagerRequest.load_texture:
					print("??? 5 load_texture");
					g_sprite1.load();
					//g_sprite2.load();
					print("??? 5 load_texture done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager load_texture");
					break;
				case ManagerRequest.load_final:
					print("??? 6 load_final");
					g_sprite1.load();
					//g_sprite2.load();
					print("??? 6 load_final done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager load_final");
					break;
			}
		}, (Variant data) {
			print("?????????? unexpected request %s", data);
			send(parent_tid, ManagerResponse.print, "!!! Manager unexpected request %s".format(data));
		});
	}
}

enum ManagerResponse {
	print
}

enum ManagerRequest {
	stop,
	load_image,
	compile_shader,
	init_arrays,
	init_buffers,
	load_texture,
	load_final,
}

extern (C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow {
	import core.stdc.stdio : printf;

	if (action != GLFW_PRESS) return;

	try {
		switch (key) {
			case GLFW_KEY_ESCAPE:
				glfwSetWindowShouldClose(window, true);
				break;
			case GLFW_KEY_Z:
				send(_thread_id_manager, ManagerRequest.load_image);
				break;
			case GLFW_KEY_X:
				send(_thread_id_manager, ManagerRequest.compile_shader);
				break;
			case GLFW_KEY_C:
				send(_thread_id_manager, ManagerRequest.init_arrays);
				break;
			case GLFW_KEY_V:
				g_sprite1.load();
				//send(_thread_id_manager, ManagerRequest.init_buffers);
				break;
			case GLFW_KEY_B:
				send(_thread_id_manager, ManagerRequest.load_texture);
				break;
			case GLFW_KEY_N:
				send(_thread_id_manager, ManagerRequest.load_final);
				break;
			default:
				break;
		}
	} catch (Throwable e) {
		printf("!!! threw exception");
	}
}

void processResponses() {
	bool has_response = true;
		while (has_response) {
			has_response = receiveTimeout(0.msecs, (ManagerResponse response, string data) {
			final switch (response) {
				case ManagerResponse.print:
					print("%s", data);
					break;
			}
		}, (Variant data) {
			print("?????????? unexpected response %s", data);
		});
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
	g_thread_window = glfwCreateWindow(1, 1, "", null, null);
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
//	g_to_load = [g_sprite1, g_sprite2];

	_thread_id_manager = spawn(&managerWorker, thisTid);
	GC.Disable();

	// Game loop
	auto stop_watch = new Stopwatch(1000);
	auto fps_timer = new Stopwatch(1000);
	auto load_timer = new Stopwatch(1000);
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

		if (g_sprite1 && g_sprite1.is_loaded()) {
			//stdout.writefln("!!! g_sprite1 w:%s, h:%s, len:%s", g_sprite1._surface_w, g_sprite1._surface_h, g_sprite1._surface_pixels.length); stdout.flush();
			g_sprite1.render();
		}

		if (g_sprite2 && g_sprite2.is_loaded()) {
			g_sprite2.render();
		}

		// Swap the screen buffers
		glfwSwapBuffers(window);

		processResponses();
/*
		if (load_timer.is_time() && g_start_loading_1 && g_to_load.length > 0) {
			load_timer.reset();
			auto a = SDL_GetTicks();
			//print("  ??? looping ...");
			auto sprite = g_to_load[0];
			if (! sprite.is_loaded()) {
				//print("    ??? sprite loading ...");
				sprite.load();
			}
			if (sprite.is_loaded()) {
				//print("        ??? sprite done loading");
				g_to_load = g_to_load[1 .. $];
			}
			print("    ??? loaded sprite for %s", SDL_GetTicks() - a);
		}
*/
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

	send(_thread_id_manager, ManagerRequest.stop);
	glfwTerminate();

	GC.Enable();

	return 0;
}
