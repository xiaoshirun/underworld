// entry/src/main/cpp/renderer/Renderer.h
#pragma once

#include "ShaderProgram.h"
#include "Camera2D.h"
#include "TextureManager.h"
#include "SpriteBatcher.h"
#include <EGL/egl.h>
#include <GLES2/gl2.h>

struct DrawCmdData {
    int type;          // 0=Sprite, 1=Rect, 2=Triangle
    int textureId;
    float x, y;
    float width, height;
    float rotation;
    float srcX, srcY, srcW, srcH;
    float texW, texH;
    float r, g, b, a;
    int flipX, flipY;
    int layer;
    float x2, y2, x3, y3;
};

class Renderer {
public:
    static Renderer& instance();

    bool init(EGLNativeWindowType window, int width, int height);
    void destroy();
    void resize(int width, int height);

    void beginFrame();
    void submitCommands(const DrawCmdData* cmds, int count);
    void endFrame();

    bool loadTexture(int textureId, const unsigned char* pixels, int width, int height);
    void unloadTexture(int textureId);
    void setCamera(float x, float y, float zoom);

    TextureManager& textureManager() { return textureManager_; }
    int circleTextureId() const { return circleTexId_; }
    int whiteTextureId() const { return whiteTexId_; }

    int screenWidth() const { return screenW_; }
    int screenHeight() const { return screenH_; }

private:
    Renderer() = default;

    EGLDisplay display_ = EGL_NO_DISPLAY;
    EGLSurface surface_ = EGL_NO_SURFACE;
    EGLContext context_ = EGL_NO_CONTEXT;

    ShaderProgram shader_;
    Camera2D camera_;
    TextureManager textureManager_;
    SpriteBatcher batcher_;

    int screenW_ = 0;
    int screenH_ = 0;
    int circleTexId_ = 0;
    int whiteTexId_ = 0;

    GLuint currentBatchTexture_ = 0;

    void executeCmd(const DrawCmdData& cmd);
    void flushBatch(GLuint newTexture);
    GLuint resolveTexture(int textureId);
    void addRectQuad(float x, float y, float w, float h,
                     float rotation, float r, float g, float b, float a);
    void addSpriteQuad(float x, float y, float w, float h,
                       float srcX, float srcY, float srcW, float srcH,
                       float texW, float texH, float rotation,
                       float r, float g, float b, float a,
                       int flipX, int flipY);
    void addTriangle(float x1, float y1, float x2, float y2, float x3, float y3,
                     float r, float g, float b, float a);
};
