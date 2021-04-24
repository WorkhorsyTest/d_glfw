



import std.conv : to;
import std.string : format, toStringz;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import global;
import helpers;
import sprite_shader : SpriteShader;
import settings : Settings;


class Sprite {
	int _load_level = 0;

	bool is_loaded() {
		return _load_level == 6;
	}

	this(string image_path) {
		_image_path = image_path;
	}

	void load0() {
		// Load the image using a SDL surface, and save the pixels, w, and h
		{
			SDL_Surface* surface = LoadSurface(_image_path);
			scope(exit) SDL_FreeSurface(surface);
			_surface_w = surface.w;
			_surface_h = surface.h;
			_surface_pixels = new Uint32[_surface_w * _surface_h];
			Uint32* pixels = cast(Uint32*) surface.pixels;
			for (int x=0; x<surface.w; x++) {
				for (int y=0; y<surface.h; y++) {
					size_t i = (y * surface.w) + x;
					_surface_pixels[i] = pixels[i];
				}
			}
		}
	}

	void load1() {
		// Build and compile the shaders
		_shader = SpriteShader(Settings.vertex_shader, Settings.fragment_shader);
	}

	void load2() {
		_translation = [
			1.0f, 0.0f, 0.0f, 0.0f,
			0.0f, 1.0f, 0.0f, 0.0f,
			0.0f, 0.0f, 1.0f, 0.0f,
			0.0f, 0.0f, 0.0f, 0.5f,
		];

		// Set up vertex data (and buffer(s)) and attribute pointers
		float w = _surface_w / SCREEN_WIDTH.to!float;
		float h = _surface_h / SCREEN_HEIGHT.to!float;
		float tr_x = w/2;
		float tr_y = h/2;
		float br_y = -(h/2);
		float br_x = w/2;
		float bl_x = -(w/2);
		float bl_y = -(h/2);
		float tl_x = -(w/2);
		float tl_y = h/2;
		_vertices = [
			// Positions          // Colors           // Texture Coords
			 tr_x,  tr_y,  0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f, // Top Right
			 br_x,  br_y,  0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f, // Bottom Right
			 bl_x,  bl_y,  0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f, // Bottom Left
			 tl_x,  tl_y,  0.0f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f  // Top Left
		];

		// Use 2 triangle indexes to make a square
		_indices = [
			0, 1, 3,
			1, 2, 3
		];
	}

	void load3() {
		u32 a;

		a = SDL_GetTicks();
		// Create VA0, VBO, and EBO
		glGenVertexArrays(1, &_VAO);
		glGenBuffers(1, &_VBO);
		glGenBuffers(1, &_EBO);

		// Setup VAO
		glBindVertexArray(_VAO);

		// Setup VBO
		glBindBuffer(GL_ARRAY_BUFFER, _VBO);
		glBufferData(GL_ARRAY_BUFFER, cast(long)SizeOfArray(_vertices), _vertices.ptr, GL_STATIC_DRAW);

		// Setup EBO
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _EBO);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, cast(long)SizeOfArray(_indices), _indices.ptr, GL_STATIC_DRAW);

		// Setup Position attribute
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(GLvoid*)0);
		glEnableVertexAttribArray(0);

		// Setup Color attribute
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(GLvoid*)(3 * GLfloat.sizeof));
		glEnableVertexAttribArray(1);

		// Setup TexCoord attribute
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(GLvoid*)(6 * GLfloat.sizeof));
		glEnableVertexAttribArray(2);

		// Unbind all operations from this VAO
		glBindVertexArray(0);
		glFinish();
		print("        #### created VA0, VBO, and EBO for %s", SDL_GetTicks() - a);
	}

	void load4() {
		u32 a;

		// Setup the texture and bind all operations to this texture
		a = SDL_GetTicks();
		glGenTextures(1, &_texture);
		glBindTexture(GL_TEXTURE_2D, _texture);
		print("        #### gen and bind texture for %s", SDL_GetTicks() - a);

		// Set texture parameters
		a = SDL_GetTicks();
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		print("        #### set texture param for %s", SDL_GetTicks() - a);

		// Set texture filtering
		a = SDL_GetTicks();
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		print("        #### set texture param for %s", SDL_GetTicks() - a);

		// Enable transparent textures
		a = SDL_GetTicks();
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		print("        #### set blend for %s", SDL_GetTicks() - a);

		// Load the texture and convert it to RGBA8888 if needed
		a = SDL_GetTicks();
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _surface_w, _surface_h, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, cast(void*) _surface_pixels);
		print("        #### load texture for %s", SDL_GetTicks() - a);

		// Generate mipmaps
		a = SDL_GetTicks();
		glGenerateMipmap(GL_TEXTURE_2D);
		print("        #### gen mipmaps for %s", SDL_GetTicks() - a);

		// Unbind all operations from this texture
		a = SDL_GetTicks();
		glBindTexture(GL_TEXTURE_2D, 0);
		glFinish();
		print("        #### unbind texture for %s", SDL_GetTicks() - a);
	}

	void load5() {
		u32 a;

	}

	void load() {
		final switch (_load_level) {
			case 0:
				load0();
				break;
			case 1:
				load1();
				break;
			case 2:
				load2();
				break;
			case 3:
				load3();
				break;
			case 4:
				load4();
				break;
			case 5:
				load5();
				break;
		}
		_load_level++;
	}

	void render() {
		// Bind all operations to this texture
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, _texture);

		// Use the shader
		_shader.use();

		// Set the texture
		//stdout.writefln("!!! location: %s", location);
		GLint location = glGetUniformLocation(_shader.program, "Texture");
		glUniform1i(location, 0);

		// Set the translation
		location = glGetUniformLocation(_shader.program, "translation");
		//stdout.writefln("!!! location: %s", location);
		glUniformMatrix4fv(location, 1, GL_TRUE, _translation.ptr);

		// Draw the texture
		glBindVertexArray(_VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
		glBindVertexArray(0);
	}

	~this() {
		glDeleteVertexArrays(1, &_VAO);
		glDeleteBuffers(1, &_VBO);
		glDeleteBuffers(1, &_EBO);
		_shader.destroy();
	}

private:
	int _surface_w;
	int _surface_h;
	Uint32[] _surface_pixels;
	string _image_path = null;
	GLuint _VBO;
	GLuint _VAO;
	GLuint _EBO;
	SpriteShader _shader;
	GLfloat[] _translation;
	GLfloat[] _vertices;
	GLuint[] _indices;
	GLuint _texture;
}
