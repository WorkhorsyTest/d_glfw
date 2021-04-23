

import std.stdio : stdout, stderr;
import std.conv : to;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
//import derelict.sdl2.gfx.gfx;
//import derelict.sdl2.gfx.primitives;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;



immutable Uint32 MASK_R = 0xFF000000;
immutable Uint32 MASK_G = 0x00FF0000;
immutable Uint32 MASK_B = 0x0000FF00;
immutable Uint32 MASK_A = 0x000000FF;

void InitDerelict() {
	import std.file : chdir, getcwd;

	// Change to the directory with the Windows libraries
	string original_dir = getcwd();
	stdout.writefln(original_dir);
	stdout.flush();
	version (Windows) {
		chdir("../lib/windows/x86_64");
	}

	string[] errors;

	try {
		DerelictSDL2.load(SharedLibVersion(2, 0, 2));
	} catch (Throwable) {
		errors ~= "Failed to find the library SDL2.";
	}

	try {
		DerelictSDL2Image.load();
	} catch (Throwable) {
		errors ~= "Failed to find the library SDL2 Image.";
	}

	try {
		DerelictGL3.load();
	} catch (Throwable) {
		errors ~= "Failed to find the library OpenGL3.";
	}

	try {
		DerelictGLFW3.load();
	} catch (Throwable) {
		errors ~= "Failed to find the library GLFW3.";
	}

	//chdir(original_dir);

	foreach (error ; errors) {
		stderr.writeln(error);
	}
	if (errors.length > 0) {
		import std.array : join;
		throw new Exception(join(errors, "\r\n"));
	}
}

@safe @nogc pure nothrow Uint8 toRed(Uint32 color) {
	return cast(Uint8) ((color << 0) >> 24);
}

@safe @nogc pure nothrow Uint8 toGreen(Uint32 color) {
	return cast(Uint8) ((color << 8) >> 24);
}

@safe @nogc pure nothrow Uint8 toBlue(Uint32 color) {
	return cast(Uint8) ((color << 16) >> 24);
}

@safe @nogc pure nothrow Uint8 toAlpha(Uint32 color) {
	return cast(Uint8) ((color << 24) >> 24);
}

size_t sizeOfArray(T)(T[] array) {
	return array.length * T.sizeof;
}

string getSDLError() {
	import std.string : fromStringz;
	return cast(string) fromStringz(SDL_GetError());
}

bool isSurfaceRGBA8888(const SDL_Surface* surface) {
	return (surface.format.Rmask == 0xFF000000 &&
			surface.format.Gmask == 0x00FF0000 &&
			surface.format.Bmask == 0x0000FF00 &&
			surface.format.Amask == 0x000000FF);
}

SDL_Surface* ensureSurfaceRGBA8888(SDL_Surface* surface) {
	import std.string : format;

	// Just return if it is already RGBA8888
	if (isSurfaceRGBA8888(surface)) {
		return surface;
	}

	// Convert the surface into a new one that is RGBA8888
	SDL_Surface* new_surface = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA8888, 0);
	if (new_surface == null) {
		throw new Exception("Failed to convert surface to RGBA8888 format: %s".format(getSDLError()));
	}
	SDL_FreeSurface(surface);

	// Make sure the new surface is RGBA8888
	if (! isSurfaceRGBA8888(new_surface)) {
		throw new Exception("Failed to convert surface to RGBA8888 format: %s".format(getSDLError()));
	}
	return new_surface;
}

SDL_Surface* loadSurface(const string file_name) {
	import std.file : exists;
	import std.string : toStringz, format;

	if (! exists(file_name)) {
		throw new Exception("File does not exist: %s".format(file_name));
	}

	SDL_Surface* surface = IMG_Load(file_name.toStringz);
	if (surface == null) {
		throw new Exception("Failed to load surface \"%s\": %s".format(file_name, getSDLError()));
	}
/*
	if (surface.format.BitsPerPixel < 32) {
		throw new Exception("Image has no alpha channel \"%s\"".format(file_name));
	}
*/
	surface = ensureSurfaceRGBA8888(surface);

	return surface;
}

SDL_Surface* createSurface(int w, int h, Uint32 color) {
	import std.string : format, toStringz;

	SDL_Surface* surface = SDL_CreateRGBSurface(0, w, h, 32, MASK_R, MASK_G, MASK_B, MASK_A);
	if (surface == null) {
		throw new Exception("Failed to create surface: %s".format(getSDLError()));
	}
	surface = ensureSurfaceRGBA8888(surface);

	// Fill the surface with the color
	SDL_Rect rect = { 0, 0, surface.w, surface.h };
	if (SDL_FillRect(surface, &rect, color) != 0) {
		throw new Exception("Failed to fill surface with color: %s".format(getSDLError()));
	}

	return surface;
}
