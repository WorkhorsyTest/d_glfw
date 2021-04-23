

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;


abstract class BaseSettings {
	static const string vertex_shader;

	static const string fragment_shader;

	static const SDL_GLattr GL_MAJOR_VERSION;
	static const SDL_GLattr GL_MINOR_VERSION;
	static const SDL_GLattr GL_PROFILE_MASK;
}

static class Settings330Core : BaseSettings {
	static const string vertex_shader = q{
		#version 330 core
		layout (location = 0) in vec3 position;
		layout (location = 1) in vec3 color;
		layout (location = 2) in vec2 texCoord;

		uniform mat4 translation;

		out vec3 ourColor;
		out vec2 TexCoord;

		void main() {
			gl_Position = translation * vec4(position, 1.0f);
			ourColor = color;
			// Flip Y so texture is not up side down
			TexCoord = vec2(texCoord.x, 1.0 - texCoord.y);
		}

	};

	static const string fragment_shader = q{
		#version 330 core
		in lowp vec3 ourColor;
		in lowp vec2 TexCoord;

		out lowp vec4 color;

		uniform sampler2D Texture;

		void main() {
			color = texture(Texture, TexCoord);
		}

	};

	static const SDL_GLattr GL_MAJOR_VERSION = 3;
	static const SDL_GLattr GL_MINOR_VERSION = 3;
	static const SDL_GLattr GL_PROFILE_MASK = SDL_GL_CONTEXT_PROFILE_CORE;
}

static class Settings300ES : BaseSettings {
	static const string vertex_shader = q{
		#version 300 es
		layout (location = 0) in vec3 position;
		layout (location = 1) in vec3 color;
		layout (location = 2) in vec2 texCoord;

		uniform mat4 translation;

		out vec3 ourColor;
		out vec2 TexCoord;

		void main() {
			gl_Position = translation * vec4(position, 1.0f);
			ourColor = color;
			// Flip Y so texture is not up side down
			TexCoord = vec2(texCoord.x, 1.0 - texCoord.y);
		}

	};

	static const string fragment_shader = q{
		#version 300 es
		in lowp vec3 ourColor;
		in lowp vec2 TexCoord;

		out lowp vec4 color;

		uniform sampler2D Texture;

		void main() {
			color = texture(Texture, TexCoord);
		}

	};

	static const SDL_GLattr GL_MAJOR_VERSION = 3;
	static const SDL_GLattr GL_MINOR_VERSION = 0;
	static const SDL_GLattr GL_PROFILE_MASK = SDL_GL_CONTEXT_PROFILE_ES;
}

//alias Settings = Settings300ES;
alias Settings = Settings330Core;
