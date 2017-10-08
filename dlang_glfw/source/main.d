

import std.stdio : stdout, stderr;

import std.conv : to;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import shader;

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

size_t sizeof_array(T)(T[] array) {
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

extern (C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow {
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, true);
	}
}

// Window dimensions
const GLuint WIDTH = 1208, HEIGHT = 800;

int main() {
	import std.string : format;

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

	// Create a windowed mode window and its OpenGL context
	GLFWwindow* window = glfwCreateWindow(WIDTH, HEIGHT, "GLFW OpenGL Texture Example", null, null);
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
	glViewport(0, 0, WIDTH, HEIGHT);

	// Build and compile our shader program
	Shader ourShader = Shader("../../../texture.vs", "../../../texture.frag");

	// Set up vertex data (and buffer(s)) and attribute pointers
	GLfloat[] vertices = [
		// Positions          // Colors           // Texture Coords
		 0.5f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f, // Top Right
		 0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f, // Bottom Right
		-0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f, // Bottom Left
		-0.5f,  0.5f, 0.0f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f  // Top Left
	];
	GLuint[] indices = [  // Note that we start from 0!
		0, 1, 3, // First Triangle
		1, 2, 3  // Second Triangle
	];
	GLuint VBO, VAO, EBO;
	glGenVertexArrays(1, &VAO);
	glGenBuffers(1, &VBO);
	glGenBuffers(1, &EBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, cast(long)sizeof_array(vertices), vertices.ptr, GL_STATIC_DRAW);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, cast(long)sizeof_array(indices), indices.ptr, GL_STATIC_DRAW);

	// Position attribute
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(GLvoid*)0);
	glEnableVertexAttribArray(0);
	// Color attribute
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(GLvoid*)(3 * GLfloat.sizeof));
	glEnableVertexAttribArray(1);
	// TexCoord attribute
	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(GLvoid*)(6 * GLfloat.sizeof));
	glEnableVertexAttribArray(2);

	glBindVertexArray(0); // Unbind VAO


	// ====================
	// Texture 1
	// ====================
	GLuint texture1;
	glGenTextures(1, &texture1);
	glBindTexture(GL_TEXTURE_2D, texture1); // All upcoming GL_TEXTURE_2D operations now have effect on our texture object
	// Set our texture parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	// Set texture wrapping to GL_REPEAT
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	// Set texture filtering
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// Load, create texture and generate mipmaps
	SDL_Surface* surface1 = IMG_Load("../../../container.jpg");
	if (! surface1) {
		throw new Exception("Failed to load image: %s".format(GetSDLError()));
	}
	surface1 = EnsureSurfaceRGBA8888(surface1);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, surface1.w, surface1.h, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, surface1.pixels);
	glGenerateMipmap(GL_TEXTURE_2D);
	SDL_FreeSurface(surface1);
	surface1 = null;
	glBindTexture(GL_TEXTURE_2D, 0);

	// ===================
	// Texture 2
	// ===================
	GLuint texture2;
	glGenTextures(1, &texture2);
	glBindTexture(GL_TEXTURE_2D, texture2);
	// Set our texture parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	// Set texture filtering
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// Load, create texture and generate mipmaps
	SDL_Surface* surface2 = IMG_Load("../../../awesomeface.png");
	if (! surface2) {
		throw new Exception("Failed to load image: %s".format(GetSDLError()));
	}
	surface2 = EnsureSurfaceRGBA8888(surface2);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, surface2.w, surface2.h, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, surface2.pixels);
	glGenerateMipmap(GL_TEXTURE_2D);
	SDL_FreeSurface(surface2);
	surface1 = null;
	glBindTexture(GL_TEXTURE_2D, 0);


	// Game loop
	while (! glfwWindowShouldClose(window)) {
		// Check if any events have been activiated (key pressed, mouse moved etc.) and call corresponding response functions
		glfwPollEvents();

		// Render
		// Clear the colorbuffer
		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		// Bind Textures using texture units
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture1);
		glUniform1i(glGetUniformLocation(ourShader.Program, "ourTexture1"), 0);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, texture2);
		glUniform1i(glGetUniformLocation(ourShader.Program, "ourTexture2"), 1);

		// Activate shader
		ourShader.Use();

		// Draw container
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
		glBindVertexArray(0);

		// Swap the screen buffers
		glfwSwapBuffers(window);
	}

	// Properly de-allocate all resources once they've outlived their purpose
	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteBuffers(1, &EBO);

	// Terminate GLFW, clearing any resources allocated by GLFW.
	glfwTerminate();

	return 0;
}
