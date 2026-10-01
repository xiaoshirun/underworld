// entry/src/main/cpp/renderer/TextureManager.h
#pragma once

#include <GLES2/gl2.h>
#include <unordered_map>

class TextureManager {
public:
    TextureManager();
    ~TextureManager();

    bool loadFromPixels(int textureId, const unsigned char* rgbaPixels,
                        int width, int height);
    void unload(int textureId);
    GLuint getGLTexture(int textureId) const;
    bool hasTexture(int textureId) const;
    void unloadAll();

    int createSolidTexture(int width, int height,
                           unsigned char r, unsigned char g,
                           unsigned char b, unsigned char a);
    int createCircleTexture(int size);

private:
    struct TextureEntry {
        GLuint glId = 0;
        int width = 0;
        int height = 0;
    };
    std::unordered_map<int, TextureEntry> textures_;
    int nextInternalId_ = 100000;
};
