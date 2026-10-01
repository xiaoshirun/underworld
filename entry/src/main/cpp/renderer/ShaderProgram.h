// entry/src/main/cpp/renderer/ShaderProgram.h
#pragma once

#include <GLES2/gl2.h>
#include <string>

class ShaderProgram {
public:
    ShaderProgram();
    ~ShaderProgram();

    bool compile(const char* vertexSrc, const char* fragmentSrc);
    void use();

    GLint getAttribLocation(const char* name);
    GLint getUniformLocation(const char* name);

    void setMat4(const char* name, const float* mat);
    void setFloat(const char* name, float value);
    void setInt(const char* name, int value);

    GLuint programId() const { return program_; }

private:
    GLuint program_ = 0;

    GLuint compileShader(GLenum type, const char* source);
};
