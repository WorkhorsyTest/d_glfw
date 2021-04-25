

import std.stdio : stdout, stderr;
import std.conv : to;
import std.concurrency;
import core.thread;
import std.variant : Variant;

import bindbc.opengl.gl;
import bindbc.sdl;
import bindbc.sdl.image;

import global;
import helpers;
import sprite;
import timer;

Tid _thread_id_manager;
__gshared Sprite g_temp_sprite = null;

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

void managerWorker(Tid parent_tid) {
	import std.string : format;

	if (SDL_GL_MakeCurrent(g_window, g_thread_context) != 0) {
		stderr.writefln("Failed to make context current! SDL Error: %s", GetSDLError());
		return;
	}

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
