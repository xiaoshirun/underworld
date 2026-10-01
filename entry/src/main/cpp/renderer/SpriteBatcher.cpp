// entry/src/main/cpp/renderer/SpriteBatcher.cpp
#include "SpriteBatcher.h"
#include <hilog_ndk.h>
#include <cstring>

SpriteBatcher::SpriteBatcher() {}

SpriteBatcher::~SpriteBatcher() {
    if (vbo_) glDeleteBuffers(1, &vbo_);
    if (ibo_) glDeleteBuffers(1, &ibo_);
}

void SpriteBatcher::init() {
    glGenBuffers(1, &vbo_);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * MAX_VERTICES,
                 nullptr, GL_DYNAMIC_DRAW);

    glGenBuffers(1, &ibo_);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);

    GLuint indices[MAX_INDICES];
    for (int i = 0; i < MAX_QUADS; i++) {
        int base = i * 4;
        indices[i * 6 + 0] = base + 0;
        indices[i * 6 + 1] = base + 1;
        indices[i * 6 + 2] = base + 2;
        indices[i * 6 + 3] = base + 0;
        indices[i * 6 + 4] = base + 2;
        indices[i * 6 + 5] = base + 3;
    }
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * MAX_INDICES,
                 indices, GL_STATIC_DRAW);

    initialized_ = true;
    OH_LOG_INFO(LOG_APP, "SpriteBatcher initialized: max %{public}d quads", MAX_QUADS);
}

void SpriteBatcher::begin() {
    quadCount_ = 0;
    currentTexture_ = 0;
}

void SpriteBatcher::flush(GLuint textureId) {
    if (quadCount_ == 0) return;

    glBindTexture(GL_TEXTURE_2D, textureId);

    glBindBuffer(GL_ARRAY_BUFFER, vbo_);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(Vertex) * quadCount_ * 4, vertices_);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(2 * sizeof(float)));
    glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(Vertex),
                          (void*)(4 * sizeof(float)));

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
    glDrawElements(GL_TRIANGLES, quadCount_ * 6, GL_UNSIGNED_INT, 0);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);

    quadCount_ = 0;
}

void SpriteBatcher::end() {
    // flush any remaining quads — caller must provide final texture
}

void SpriteBatcher::addQuad(const Vertex& tl, const Vertex& tr,
                            const Vertex& br, const Vertex& bl) {
    if (quadCount_ >= MAX_QUADS) {
        OH_LOG_WARN(LOG_APP, "SpriteBatcher overflow at %{public}d quads", quadCount_);
        return;
    }
    int base = quadCount_ * 4;
    vertices_[base + 0] = tl;
    vertices_[base + 1] = tr;
    vertices_[base + 2] = br;
    vertices_[base + 3] = bl;
    quadCount_++;
}
