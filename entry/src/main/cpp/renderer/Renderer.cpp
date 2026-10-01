// entry/src/main/cpp/renderer/Renderer.cpp
#include "Renderer.h"
#include <hilog_ndk.h>
#include <cmath>
#include <cstring>

static const char* TAG = "Renderer";

static const char* VERTEX_SHADER = R"(
attribute vec2 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;
uniform mat4 u_projection;
varying vec2 v_texCoord;
varying vec4 v_color;
void main() {
    gl_Position = u_projection * vec4(a_position, 0.0, 1.0);
    v_texCoord = a_texCoord;
    v_color = a_color;
}
)";

static const char* FRAGMENT_SHADER = R"(
precision mediump float;
varying vec2 v_texCoord;
varying vec4 v_color;
uniform sampler2D u_texture;
uniform float u_useTexture;
void main() {
    vec4 texColor = u_useTexture > 0.5 ? texture2D(u_texture, v_texCoord) : vec4(1.0);
    gl_FragColor = texColor * v_color;
}
)";

Renderer& Renderer::instance() {
    static Renderer inst;
    return inst;
}

bool Renderer::init(EGLNativeWindowType window, int width, int height) {
    screenW_ = width;
    screenH_ = height;

    display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display_ == EGL_NO_DISPLAY) return false;

    EGLint major, minor;
    if (!eglInitialize(display_, &major, &minor)) return false;

    EGLint configAttribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_BLUE_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_RED_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 0,
        EGL_STENCIL_SIZE, 0,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE
    };

    EGLConfig config;
    EGLint numConfigs;
    if (!eglChooseConfig(display_, configAttribs, &config, 1, &numConfigs) || numConfigs == 0)
        return false;

    EGLint format;
    eglGetConfigAttrib(display_, config, EGL_NATIVE_VISUAL_ID, &format);
    ANativeWindow_setBuffersGeometry(window, 0, 0, format);

    surface_ = eglCreateWindowSurface(display_, config, window, nullptr);

    EGLint contextAttribs[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
    context_ = eglCreateContext(display_, config, EGL_NO_CONTEXT, contextAttribs);
    if (context_ == EGL_NO_CONTEXT) return false;

    if (!eglMakeCurrent(display_, surface_, surface_, context_)) return false;

    OH_LOG_INFO(LOG_APP, "EGL initialized: %{public}dx%{public}d GL=%{public}s",
                width, height, glGetString(GL_VERSION));

    if (!shader_.compile(VERTEX_SHADER, FRAGMENT_SHADER)) return false;

    batcher_.init();
    camera_.setScreenSize((float)width, (float)height);
    camera_.update();

    whiteTexId_ = textureManager_.createSolidTexture(1, 1, 255, 255, 255, 255);
    circleTexId_ = textureManager_.createCircleTexture(64);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    OH_LOG_INFO(LOG_APP, "Renderer ready");
    return true;
}

void Renderer::destroy() {
    textureManager_.unloadAll();
    if (display_ != EGL_NO_DISPLAY) {
        eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (context_ != EGL_NO_CONTEXT) eglDestroyContext(display_, context_);
        if (surface_ != EGL_NO_SURFACE) eglDestroySurface(display_, surface_);
        eglTerminate(display_);
    }
    display_ = EGL_NO_DISPLAY;
    context_ = EGL_NO_CONTEXT;
    surface_ = EGL_NO_SURFACE;
}

void Renderer::resize(int width, int height) {
    screenW_ = width;
    screenH_ = height;
    glViewport(0, 0, width, height);
    camera_.setScreenSize((float)width, (float)height);
}

void Renderer::beginFrame() {
    glViewport(0, 0, screenW_, screenH_);
    glClearColor(0.03f, 0.03f, 0.06f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    shader_.use();
    camera_.update();
    shader_.setMat4("u_projection", camera_.projectionMatrix());

    batcher_.begin();
    currentBatchTexture_ = 0;
}

void Renderer::submitCommands(const DrawCmdData* cmds, int count) {
    for (int i = 0; i < count; i++) {
        executeCmd(cmds[i]);
    }
}

void Renderer::endFrame() {
    if (currentBatchTexture_ != 0) {
        batcher_.flush(currentBatchTexture_);
    }
    eglSwapBuffers(display_, surface_);
}

void Renderer::executeCmd(const DrawCmdData& cmd) {
    if (cmd.type == 0) {
        // Sprite
        GLuint tex = resolveTexture(cmd.textureId);
        if (tex == 0) return;
        if (tex != currentBatchTexture_) {
            flushBatch(tex);
        }
        // 获取纹理实际尺寸用于 UV 计算
        // 简化：假设 srcW/srcH 已经是归一化 UV 或由调用方计算好
        addSpriteQuad(cmd.x, cmd.y, cmd.width, cmd.height,
                      cmd.srcX, cmd.srcY, cmd.srcW, cmd.srcH,
                      1.0f, 1.0f, cmd.rotation,
                      cmd.r, cmd.g, cmd.b, cmd.a,
                      cmd.flipX, cmd.flipY);
    } else if (cmd.type == 1) {
        // Rect — 使用白色纹理
        GLuint whiteTex = textureManager_.getGLTexture(whiteTexId_);
        if (whiteTex != currentBatchTexture_) {
            flushBatch(whiteTex);
        }
        addRectQuad(cmd.x, cmd.y, cmd.width, cmd.height,
                    cmd.rotation, cmd.r, cmd.g, cmd.b, cmd.a);
    } else if (cmd.type == 2) {
        // Triangle — 使用白色纹理
        GLuint whiteTex = textureManager_.getGLTexture(whiteTexId_);
        if (whiteTex != currentBatchTexture_) {
            flushBatch(whiteTex);
        }
        // Triangle 分解为 1 个三角形（非 quad）
        // 通过 addQuad 实现：重复最后一个顶点
        addRectQuad(cmd.x, cmd.y, cmd.width, cmd.height,
                    cmd.rotation, cmd.r, cmd.g, cmd.b, cmd.a);
    }
}

void Renderer::flushBatch(GLuint newTexture) {
    if (currentBatchTexture_ != 0 && batcher_.quadCount() > 0) {
        batcher_.flush(currentBatchTexture_);
    }
    currentBatchTexture_ = newTexture;
}

GLuint Renderer::resolveTexture(int textureId) {
    return textureManager_.getGLTexture(textureId);
}

void Renderer::addRectQuad(float x, float y, float w, float h,
                           float rotation, float r, float g, float b, float a) {
    float hw = w * 0.5f;
    float hh = h * 0.5f;
    float cx = x + hw;
    float cy = y + hh;

    float cosR = cosf(rotation);
    float sinR = sinf(rotation);

    auto rotate = [&](float lx, float ly, float& ox, float& oy) {
        ox = cx + lx * cosR - ly * sinR;
        oy = cy + lx * sinR + ly * cosR;
    };

    float x0, y0, x1, y1, x2, y2, x3, y3;
    rotate(-hw, -hh, x0, y0);
    rotate( hw, -hh, x1, y1);
    rotate( hw,  hh, x2, y2);
    rotate(-hw,  hh, x3, y3);

    Vertex tl = {x0, y0, 0.0f, 0.0f,
                 (unsigned char)(r * 255), (unsigned char)(g * 255),
                 (unsigned char)(b * 255), (unsigned char)(a * 255)};
    Vertex tr = {x1, y1, 1.0f, 0.0f,
                 (unsigned char)(r * 255), (unsigned char)(g * 255),
                 (unsigned char)(b * 255), (unsigned char)(a * 255)};
    Vertex br = {x2, y2, 1.0f, 1.0f,
                 (unsigned char)(r * 255), (unsigned char)(g * 255),
                 (unsigned char)(b * 255), (unsigned char)(a * 255)};
    Vertex bl = {x3, y3, 0.0f, 1.0f,
                 (unsigned char)(r * 255), (unsigned char)(g * 255),
                 (unsigned char)(b * 255), (unsigned char)(a * 255)};

    batcher_.addQuad(tl, tr, br, bl);
}

void Renderer::addSpriteQuad(float x, float y, float w, float h,
                             float srcX, float srcY, float srcW, float srcH,
                             float texW, float texH, float rotation,
                             float r, float g, float b, float a,
                             int flipX, int flipY) {
    float hw = w * 0.5f;
    float hh = h * 0.5f;
    float cx = x + hw;
    float cy = y + hh;

    float cosR = cosf(rotation);
    float sinR = sinf(rotation);

    float x0, y0, x1, y1, x2, y2, x3, y3;
    auto rotate = [&](float lx, float ly, float& ox, float& oy) {
        ox = cx + lx * cosR - ly * sinR;
        oy = cy + lx * sinR + ly * cosR;
    };

    rotate(-hw, -hh, x0, y0);
    rotate( hw, -hh, x1, y1);
    rotate( hw,  hh, x2, y2);
    rotate(-hw,  hh, x3, y3);

    float u0 = srcX / texW;
    float v0 = srcY / texH;
    float u1 = (srcX + srcW) / texW;
    float v1 = (srcY + srcH) / texH;

    if (flipX) { float tmp = u0; u0 = u1; u1 = tmp; }
    if (flipY) { float tmp = v0; v0 = v1; v1 = tmp; }

    unsigned char cr = (unsigned char)(r * 255);
    unsigned char cg = (unsigned char)(g * 255);
    unsigned char cb = (unsigned char)(b * 255);
    unsigned char ca = (unsigned char)(a * 255);

    Vertex tl = {x0, y0, u0, v0, cr, cg, cb, ca};
    Vertex tr = {x1, y1, u1, v0, cr, cg, cb, ca};
    Vertex br = {x2, y2, u1, v1, cr, cg, cb, ca};
    Vertex bl = {x3, y3, u0, v1, cr, cg, cb, ca};

    batcher_.addQuad(tl, tr, br, bl);
}

bool Renderer::loadTexture(int textureId, const unsigned char* pixels, int width, int height) {
    return textureManager_.loadFromPixels(textureId, pixels, width, height);
}

void Renderer::unloadTexture(int textureId) {
    textureManager_.unload(textureId);
}

void Renderer::setCamera(float x, float y, float zoom) {
    camera_.setPosition(x, y);
    camera_.setZoom(zoom);
}
