

import std.stdio : stdout, stderr;
import derelict.opengl3.gl3;

struct Shader {
public:
	GLuint Program;
	// Constructor generates the shader on the fly
	this(string vertexPath, string fragmentPath, string geometryPath = null) {
		import std.file : readText;
		import std.string : toStringz;

		// 1. Retrieve the vertex/fragment source code from filePath
		string vertexCode = null;
		string fragmentCode = null;
		string geometryCode = null;
		try {
			vertexCode = readText(vertexPath);
			fragmentCode = readText(fragmentPath);

			// If geometry shader path is present, also load a geometry shader
			if (geometryPath != null) {
				geometryCode = readText(geometryPath);
			}
		} catch (Throwable) {
			stderr.writefln("ERROR.SHADER.FILE_NOT_SUCCESFULLY_READ");
			return;
		}

		auto vShaderCode = vertexCode.toStringz;
		auto fShaderCode = fragmentCode.toStringz;

		// 2. Compile shaders
		GLuint vertex, fragment;
		//GLint success;
		//GLchar infoLog[512];
		// Vertex Shader
		vertex = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vertex, 1, &vShaderCode, null);
		glCompileShader(vertex);
		checkCompileErrors(vertex, "VERTEX");
		// Fragment Shader
		fragment = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fragment, 1, &fShaderCode, null);
		glCompileShader(fragment);
		checkCompileErrors(fragment, "FRAGMENT");
		// If geometry shader is given, compile geometry shader
		GLuint geometry = 0;
		if (geometryPath != null) {
			auto gShaderCode = geometryCode.toStringz;
			geometry = glCreateShader(GL_GEOMETRY_SHADER);
			glShaderSource(geometry, 1, &gShaderCode, null);
			glCompileShader(geometry);
			checkCompileErrors(geometry, "GEOMETRY");
		}
		// Shader Program
		this.Program = glCreateProgram();
		glAttachShader(this.Program, vertex);
		glAttachShader(this.Program, fragment);
		if (geometryPath != null)
			glAttachShader(this.Program, geometry);
		glLinkProgram(this.Program);
		checkCompileErrors(this.Program, "PROGRAM");
		// Delete the shaders as they're linked into our program now and no longer necessery
		glDeleteShader(vertex);
		glDeleteShader(fragment);
		if (geometryPath != null)
			glDeleteShader(geometry);
	}

	// Uses the current shader
	void Use() {
		glUseProgram(this.Program);
	}

private:
	void checkCompileErrors(GLuint shader, string type) {
		GLint success;
		GLchar[1024] infoLog;
		int len;
		if (type != "PROGRAM") {
			glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
			if(! success) {
				glGetShaderInfoLog(shader, 1024, &len, infoLog.ptr);
				stderr.writefln("| ERROR.SHADER-COMPILATION-ERROR of type: %s|\n%s\n| -- --------------------------------------------------- -- |", type, infoLog[0 .. len]);
			}
		} else {
			glGetProgramiv(shader, GL_LINK_STATUS, &success);
			if (! success) {
				glGetProgramInfoLog(shader, 1024, &len, infoLog.ptr);
				stderr.writefln("| ERROR.PROGRAM-LINKING-ERROR of type: %s|\n%s\n| -- --------------------------------------------------- -- |", type, infoLog[0 .. len]);
			}
		}
	}
}
