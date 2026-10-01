// entry/src/main/cpp/renderer/ShaderProgram.cpp
#include "ShaderProgram.h"
#include <hilog_ndk.h>

static const char* TAG = "ShaderProgram";

ShaderProgram::ShaderProgram() {}

ShaderProgram::~ShaderProgram() {
    if (program_ != 0) {
        glDeleteProgram(program_);
    }
}

GLuint ShaderProgram::compileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);

    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char log[512];
        glGetShaderInfoLog(shader, 512, nullptr, log);
        OH_LOG_ERROR(LOG_APP, "Shader compile error: %{public}s", log);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

bool ShaderProgram::compile(const char* vertexSrc, const char* fragmentSrc) {
    GLuint vs = compileShader(GL_VERTEX_SHADER, vertexSrc);
    GLuint fs = compileShader(GL_FRAGMENT_SHADER, fragmentSrc);
    if (vs == 0 || fs == 0) return false;

    program_ = glCreateProgram();
    glAttachShader(program_, vs);
    glAttachShader(program_, fs);
    glLinkProgram(program_);

    GLint success;
    glGetProgramiv(program_, GL_LINK_STATUS, &success);
    if (!success) {
        char log[512];
        glGetProgramInfoLog(program_, 512, nullptr, log);
        OH_LOG_ERROR(LOG_APP, "Shader link error: %{public}s", log);
        glDeleteProgram(program_);
        program_ = 0;
    }

    glDeleteShader(vs);
    glDeleteShader(fs);
    return program_ != 0;
}

void ShaderProgram::use() {
    glUseProgram(program_);
}

GLint ShaderProgram::getAttribLocation(const char* name) {
    return glGetAttribLocation(program_, name);
}

GLint ShaderProgram::getUniformLocation(const char* name) {
    return glGetUniformLocation(program_, name);
}

void ShaderProgram::setMat4(const char* name, const float* mat) {
    glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, mat);
}

void ShaderProgram::setFloat(const char* name, float value) {
    glUniform1f(getUniformLocation(name), value);
}

void ShaderProgram::setInt(const char* name, int value) {
    glUniform1i(getUniformLocation(name), value);
}
