

import bindbc.opengl;
import bindbc.opengl.gl;

struct SpriteShader {
	this(string vertex_code, string fragment_code, string geometry_code = null) {
		import std.string : toStringz;

		// Compile the vertex shader
		GLuint vertex;
		auto vertex_code_z = vertex_code.toStringz;
		vertex = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vertex, 1, &vertex_code_z, null);
		glCompileShader(vertex);
		checkCompileErrors(vertex, "VERTEX");

		// Compile the fragment shader
		GLuint fragment;
		auto fragment_code_z = fragment_code.toStringz;
		fragment = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fragment, 1, &fragment_code_z, null);
		glCompileShader(fragment);
		checkCompileErrors(fragment, "FRAGMENT");

		// Compile the geometry shader
		GLuint geometry = 0;
		if (geometry_code != null) {
			auto geometry_code_z = geometry_code.toStringz;
			geometry = glCreateShader(GL_GEOMETRY_SHADER);
			glShaderSource(geometry, 1, &geometry_code_z, null);
			glCompileShader(geometry);
			checkCompileErrors(geometry, "GEOMETRY");
		}

		// Create the program
		_program = glCreateProgram();

		// Attach shaders to the program
		glAttachShader(_program, vertex);
		glAttachShader(_program, fragment);
		if (geometry_code != null) {
			glAttachShader(_program, geometry);
		}

		// Link the program
		glLinkProgram(_program);
		checkCompileErrors(_program, "PROGRAM");

		// Delete the shaders
		glDeleteShader(vertex);
		glDeleteShader(fragment);
		if (geometry_code != null) {
			glDeleteShader(geometry);
		}
	}

	// Uses the current shader
	void use() {
		glUseProgram(_program);
	}

	private void checkCompileErrors(GLuint shader, string type) {
		import std.string : format;

		GLint success;
		GLchar[1024] info_log;
		int len;
		if (type != "PROGRAM") {
			glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
			if(! success) {
				glGetShaderInfoLog(shader, 1024, &len, info_log.ptr);
				throw new Exception("Shader compile error type: %s\n%s\n".format(type, info_log[0 .. len]));
			}
		} else {
			glGetProgramiv(shader, GL_LINK_STATUS, &success);
			if (! success) {
				glGetProgramInfoLog(shader, 1024, &len, info_log.ptr);
				throw new Exception("Shader link error type: %s\n%s\n".format(type, info_log[0 .. len]));
			}
		}
	}

	~this() {
		_program.destroy();
	}

	GLuint program() { return _program; }

private:
	GLuint _program;
}
