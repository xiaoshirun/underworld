// entry/src/main/cpp/renderer/TextureManager.cpp
#include "TextureManager.h"
#include <hilog_ndk.h>
#include <cmath>

static const char* TAG = "TextureManager";

TextureManager::TextureManager() {}

TextureManager::~TextureManager() {
    unloadAll();
}

bool TextureManager::loadFromPixels(int textureId, const unsigned char* rgbaPixels,
                                    int width, int height) {
    GLuint glTex;
    glGenTextures(1, &glTex);
    glBindTexture(GL_TEXTURE_2D, glTex);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, rgbaPixels);

    textures_[textureId] = {glTex, width, height};
    OH_LOG_INFO(LOG_APP, "Texture loaded: id=%{public}d gl=%{public}u %{public}dx%{public}d",
                textureId, glTex, width, height);
    return true;
}

void TextureManager::unload(int textureId) {
    auto it = textures_.find(textureId);
    if (it != textures_.end()) {
        glDeleteTextures(1, &it->second.glId);
        textures_.erase(it);
    }
}

GLuint TextureManager::getGLTexture(int textureId) const {
    auto it = textures_.find(textureId);
    if (it == textures_.end()) return 0;
    return it->second.glId;
}

bool TextureManager::hasTexture(int textureId) const {
    return textures_.count(textureId) > 0;
}

void TextureManager::unloadAll() {
    for (auto& pair : textures_) {
        glDeleteTextures(1, &pair.second.glId);
    }
    textures_.clear();
}

int TextureManager::createSolidTexture(int width, int height,
                                       unsigned char r, unsigned char g,
                                       unsigned char b, unsigned char a) {
    int size = width * height;
    unsigned char* pixels = new unsigned char[size * 4];
    for (int i = 0; i < size; i++) {
        pixels[i * 4 + 0] = r;
        pixels[i * 4 + 1] = g;
        pixels[i * 4 + 2] = b;
        pixels[i * 4 + 3] = a;
    }
    int id = nextInternalId_++;
    loadFromPixels(id, pixels, width, height);
    delete[] pixels;
    return id;
}

int TextureManager::createCircleTexture(int size) {
    unsigned char* pixels = new unsigned char[size * size * 4];
    float center = size / 2.0f;
    float radius = size / 2.0f - 1.0f;

    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            float dx = x - center + 0.5f;
            float dy = y - center + 0.5f;
            float dist = sqrtf(dx * dx + dy * dy);
            int idx = (y * size + x) * 4;
            if (dist <= radius) {
                float edge = radius - dist;
                unsigned char alpha = (unsigned char)(255.0f * (edge < 1.5f ? edge / 1.5f : 1.0f));
                pixels[idx + 0] = 255;
                pixels[idx + 1] = 255;
                pixels[idx + 2] = 255;
                pixels[idx + 3] = alpha;
            } else {
                pixels[idx + 0] = 0;
                pixels[idx + 1] = 0;
                pixels[idx + 2] = 0;
                pixels[idx + 3] = 0;
            }
        }
    }

    int id = nextInternalId_++;
    loadFromPixels(id, pixels, size, size);
    delete[] pixels;
    return id;
}
