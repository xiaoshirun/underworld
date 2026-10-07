// entry/src/main/cpp/renderer/SpriteBatcher.h
#pragma once

#include <GLES2/gl2.h>

static const int MAX_QUADS = 4096;
static const int MAX_VERTICES = MAX_QUADS * 4;
static const int MAX_INDICES = MAX_QUADS * 6;

struct Vertex {
    float x, y;
    float u, v;
    unsigned char r, g, b, a;
};

class SpriteBatcher {
public:
    SpriteBatcher();
    ~SpriteBatcher();

    void init();
    void begin();
    void flush(GLuint textureId);
    void end();

    void addQuad(const Vertex& tl, const Vertex& tr,
                 const Vertex& br, const Vertex& bl);
    int quadCount() const { return quadCount_; }

private:
    GLuint vbo_ = 0;
    GLuint ibo_ = 0;
    Vertex vertices_[MAX_VERTICES];
    int quadCount_ = 0;
    GLuint currentTexture_ = 0;
    bool initialized_ = false;
};
