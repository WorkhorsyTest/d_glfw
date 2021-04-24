
import std.stdio : stdout, stderr;
import std.conv : to;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import global;

struct Vector3 {
	float x = 0;
	float y = 0;
	float z = 0;
}

immutable u32 MASK_R = 0xFF000000;
immutable u32 MASK_G = 0x00FF0000;
immutable u32 MASK_B = 0x0000FF00;
immutable u32 MASK_A = 0x000000FF;

void print(string message) {
	stdout.writeln(message); stdout.flush();
}

void print(alias fmt, A...)(A args)
if (isSomeString!(typeof(fmt))) {
	import std.format : checkFormatException;

	alias e = checkFormatException!(fmt, A);
	static assert(!e, e.msg);
	return print(fmt, args);
}

void print(Char, A...)(in Char[] fmt, A args) {
	stdout.writefln(fmt, args); stdout.flush();
}

float deg2rad(float degrees) {
	import std.math : PI;
	float radians = (degrees * PI) / 180.0f;
	return radians;
}

float rad2deg(float radians) {
	import std.math : PI;
	float degrees = radians * (180.0f / PI);
	return degrees;
}

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

@safe @nogc pure nothrow u8 toRed(u32 color) {
	return cast(u8) ((color << 0) >> 24);
}

@safe @nogc pure nothrow u8 toGreen(u32 color) {
	return cast(u8) ((color << 8) >> 24);
}

@safe @nogc pure nothrow u8 toBlue(u32 color) {
	return cast(u8) ((color << 16) >> 24);
}

@safe @nogc pure nothrow u8 toAlpha(u32 color) {
	return cast(u8) ((color << 24) >> 24);
}

size_t SizeOfArray(T)(T[] array) {
	return array.length * T.sizeof;
}

string GetSDLError() {
	import std.string : fromStringz;
	return cast(string) fromStringz(SDL_GetError());
}

bool IsSurfaceRGBA8888(const SDL_Surface* surface) {
	return (surface.format.Rmask == 0xFF000000 &&
			surface.format.Gmask == 0x00FF0000 &&
			surface.format.Bmask == 0x0000FF00 &&
			surface.format.Amask == 0x000000FF);
}

SDL_Surface* EnsureSurfaceRGBA8888(SDL_Surface* surface) {
	import std.string : format;

	// Just return if it is already RGBA8888
	if (IsSurfaceRGBA8888(surface)) {
		return surface;
	}

	// Convert the surface into a new one that is RGBA8888
	SDL_Surface* new_surface = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA8888, 0);
	if (new_surface == null) {
		throw new Exception("Failed to convert surface to RGBA8888 format: %s".format(GetSDLError()));
	}
	SDL_FreeSurface(surface);

	// Make sure the new surface is RGBA8888
	if (! IsSurfaceRGBA8888(new_surface)) {
		throw new Exception("Failed to convert surface to RGBA8888 format: %s".format(GetSDLError()));
	}
	return new_surface;
}

SDL_Surface* LoadSurface(const string file_name) {
	import std.file : exists;
	import std.string : toStringz, format;

	if (! exists(file_name)) {
		throw new Exception("File does not exist: %s".format(file_name));
	}

	SDL_Surface* surface = IMG_Load(file_name.toStringz);
	if (surface == null) {
		throw new Exception("Failed to load surface \"%s\": %s".format(file_name, GetSDLError()));
	}
/*
	if (surface.format.BitsPerPixel < 32) {
		throw new Exception("Image has no alpha channel \"%s\"".format(file_name));
	}
*/
	surface = EnsureSurfaceRGBA8888(surface);

	return surface;
}
