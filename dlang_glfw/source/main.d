

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
__gshared Sprite g_temp_sprite = null;

Sprite[] g_sprites;

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
					g_temp_sprite.load();
					print("??? 1 load_image done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager load_image");
					break;
				case ManagerRequest.compile_shader:
					print("??? 2 compile_shader");
					g_temp_sprite.load();
					print("??? 2 compile_shader done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager compile_shader");
					break;
				case ManagerRequest.init_arrays:
					print("??? 3 init_arrays");
					g_temp_sprite.load();
					print("??? 3 init_arrays done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager init_arrays");
					send(parent_tid, LoadingStatus.a_done);
					break;
				case ManagerRequest.init_buffers:
					print("??? 4 init_buffers");
//					g_temp_sprite.load();
					print("??? 4 init_buffers done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager init_buffers");
					send(parent_tid, LoadingStatus.b_done);
					break;
				case ManagerRequest.load_texture:
					print("??? 5 load_texture");
					g_temp_sprite.load();
					print("??? 5 load_texture done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager load_texture");
					break;
				case ManagerRequest.load_final:
					print("??? 6 load_final");
					g_temp_sprite.load();
					print("??? 6 load_final done");
					//send(parent_tid, ManagerResponse.print, "!!! Manager load_final");
					send(parent_tid, LoadingStatus.c_done);
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
				Manager.loadSprite("../../../container.jpg");
				break;
			case GLFW_KEY_X:
				Manager.loadSprite("../../../awesomeface.png");
				break;
			default:
				break;
		}
	} catch (Throwable e) {
		printf("!!! threw exception");
	}
}

enum LoadingStatus {
	idle,
	inited,
	a_started,
	a_done,
	b_started,
	b_done,
	c_started,
	c_done,
}

class Manager {
	static LoadingStatus _loading_status;

	static void SetLoadingStatus(LoadingStatus value) {
		_loading_status = value;
		print("############### _loading_status; %s", _loading_status);
	}

	static void start() {
		_thread_id_manager = spawn(&managerWorker, thisTid);
	}

	static void stop() {
		send(_thread_id_manager, ManagerRequest.stop);
	}

	static void loadSprite(string file_name) {
		g_temp_sprite = new Sprite(file_name);
		SetLoadingStatus(LoadingStatus.inited);
		loadA();
	}

	static void loadA() {
		SetLoadingStatus(LoadingStatus.a_started);
		send(_thread_id_manager, ManagerRequest.load_image);
		send(_thread_id_manager, ManagerRequest.compile_shader);
		send(_thread_id_manager, ManagerRequest.init_arrays);
	}

	static void loadB() {
		SetLoadingStatus(LoadingStatus.b_started);
		g_temp_sprite.load();
		send(_thread_id_manager, ManagerRequest.init_buffers);
		SetLoadingStatus(LoadingStatus.b_done);
	}

	static void loadC() {
		SetLoadingStatus(LoadingStatus.c_started);
		send(_thread_id_manager, ManagerRequest.load_texture);
		send(_thread_id_manager, ManagerRequest.load_final);
	}

	static void processResponses() {
		receiveTimeout(0.msecs,
			(LoadingStatus status) {
				SetLoadingStatus(status);

				final switch (_loading_status) {
					case LoadingStatus.idle:
						break;
					case LoadingStatus.inited:
						break;
					case LoadingStatus.a_started:
						break;
					case LoadingStatus.a_done:
						loadB();
						break;
					case LoadingStatus.b_started:
						break;
					case LoadingStatus.b_done:
						loadC();
						break;
					case LoadingStatus.c_started:
						break;
					case LoadingStatus.c_done:
						g_sprites ~= g_temp_sprite;
						g_temp_sprite = null;
						SetLoadingStatus(LoadingStatus.idle);
						break;
				}
			},
			(ManagerResponse response, string data) {
				final switch (response) {
					case ManagerResponse.print:
						print("%s", data);
						break;
				}
			},
			(Variant data) {
				print("?????????? unexpected response %s", data);
			}
		);
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

		// Render
		// Clear the colorbuffer
		//glfwMakeContextCurrent(window);
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
