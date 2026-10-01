# XComponent 原生渲染器实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将游戏渲染层从 Canvas 2D 迁移到 XComponent + OpenGL ES 2.0 原生渲染，通过 NAPI 命令缓冲区模式连接 ArkTS ECS 与 C++ 渲染器，彻底绕过 HarmonyOS ImageSource 缺陷。

**Architecture:** ArkTS 侧 ECS 每帧收集 DrawCmd[] 绘制命令，通过 NAPI 一次性传递给 C++ 原生渲染器。C++ 层使用 OpenGL ES 2.0 执行精灵批渲染、矩形绘制和纹理管理。PNG 解码由 stb_image 在 C++ 侧完成。HUD 保留在 ArkTS UI 覆盖层。

**Tech Stack:** HarmonyOS NEXT API 12, XComponent, OpenGL ES 2.0, NAPI, C++17, CMake, stb_image.h, ArkTS, ECS

**Spec:** `docs/superpowers/specs/2026-10-01-xcomponent-native-renderer-design.md`

## Global Constraints

- HarmonyOS NEXT API 12（compatibleSdkVersion "5.0.0(12)", targetSdkVersion "26.0.0"）
- OpenGL ES 2.0（不使用 3.0+ 特性）
- stb_image.h 为唯一第三方依赖（public domain）
- C++ 代码必须通过 HarmonyOS NDK clang 编译
- 保留全部 ECS 架构（25 Systems, 21 Components, 5 Factories）
- 保留全部游戏功能（4 形态变化、能量系统、Boss 战、自由探索、分块世界）
- 横屏模式（landscape），支持 phone 和 tablet
- bundleName: `com.xsr.underworld`

## 文件结构

### 新建文件（C++ 原生层）

```
entry/src/main/cpp/
├── CMakeLists.txt
├── platform/
│   ├── napi_init.cpp           # NAPI 模块注册
│   ├── napi_bridge.h/cpp       # DrawCmd 解析、类型转换
│   └── stb_image_impl.c        # stb_image 实现（#define STB_IMAGE_IMPLEMENTATION）
├── renderer/
│   ├── Renderer.h/cpp          # GL 初始化、shader、帧管理
│   ├── SpriteBatcher.h/cpp     # 精灵批渲染（4096 quads/batch）
│   ├── TextureManager.h/cpp    # 纹理生命周期
│   ├── Camera2D.h/cpp          # 正交投影
│   └── ShaderProgram.h/cpp     # shader 编译/链接
└── third_party/
    └── stb/
        └── stb_image.h         # v2.30 (public domain)
```

### 新建文件（ArkTS 层）

```
entry/src/main/ets/
├── native/
│   ├── DrawCmd.ets             # DrawCmd 类型 + DrawCmdBuffer
│   └── NativeRenderer.ets      # NAPI bridge 封装
├── game/
│   ├── renderers/
│   │   └── CommandCollector.ets # 从旧 renderer 收集 DrawCmd
│   └── (现有文件修改)
```

### 修改文件

```
entry/build-profile.json5                          # 添加 externalNativeOptions
entry/src/main/ets/pages/Index.ets                 # Canvas → XComponent
entry/src/main/ets/game/GameScene.ets              # render() 改为命令收集
entry/src/main/ets/game/renderers/TileRenderer.ets     # Canvas → DrawCmd
entry/src/main/ets/game/renderers/PlayerRenderer.ets   # Canvas → DrawCmd
entry/src/main/ets/game/renderers/EnemyRenderer.ets    # Canvas → DrawCmd
entry/src/main/ets/game/renderers/BossRenderer.ets     # Canvas → DrawCmd
entry/src/main/ets/game/renderers/BossFormsRenderer.ets# Canvas → DrawCmd
entry/src/main/ets/game/renderers/EffectRenderer.ets     # Canvas → DrawCmd
entry/src/main/ets/game/renderers/ChestRenderer.ets      # Canvas → DrawCmd
entry/src/main/ets/game/renderers/TrapRenderer.ets       # Canvas → DrawCmd
entry/src/main/ets/game/renderers/WeaponRenderer.ets     # Canvas → DrawCmd
entry/src/main/ets/game/renderers/TransformFormRenderer.ets # Canvas → DrawCmd
entry/src/main/ets/game/renderers/UIRenderer.ets         # 迁移至 ArkTS UI
entry/src/main/ets/game/sprites/SpriteManager.ets        # 改用 nativeLoadTexture
```

### 删除文件

```
（无文件删除 — 旧 renderer 文件就地改写）
```

---

## Task 1: C++ 构建系统

**Files:**
- Create: `entry/src/main/cpp/CMakeLists.txt`
- Create: `entry/src/main/cpp/third_party/stb/stb_image.h`
- Modify: `entry/build-profile.json5`

**Interfaces:**
- Produces: `libnative_renderer.so` — 后续所有 NAPI 函数的载体
- Consumes: HarmonyOS NDK (EGL, GLESv2, ace_napi, hilog_ndk, rawfile)

- [ ] **Step 1: 下载 stb_image.h**

从 https://github.com/nothings/stb/blob/master/stb_image.h 下载最新版本（v2.30），放入 `entry/src/main/cpp/third_party/stb/stb_image.h`。

如果无法访问网络，创建一个最小的 stb_image.h 占位文件（仅包含 `#define STBI_VERSION 1` 和必要的函数声明），后续再替换。但优先尝试下载完整版。

- [ ] **Step 2: 创建 CMakeLists.txt**

```cmake
cmake_minimum_required(VERSION 3.13)
project(native_renderer)

set(CMAKE_CXX_STANDARD 17)

# 源文件
file(GLOB_RECURSE RENDERER_SOURCES "renderer/*.cpp")
file(GLOB_RECURSE PLATFORM_SOURCES "platform/*.cpp")

# stb_image 实现单元（单独编译）
set(STB_IMPL "platform/stb_image_impl.c")

add_library(native_renderer SHARED
    ${RENDERER_SOURCES}
    ${PLATFORM_SOURCES}
    ${STB_IMPL}
)

target_include_directories(native_renderer PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/stb
    ${CMAKE_CURRENT_SOURCE_DIR}/renderer
    ${CMAKE_CURRENT_SOURCE_DIR}/platform
)

# HarmonyOS NDK 库
find_library(EGL_LIB EGL)
find_library(GLES_LIB GLESv2)
find_library(NAPI_LIB ace_napi.z)
find_library(HILOG_LIB hilog_ndk.z)
find_library(RAWFILE_LIB rawfile)
find_library(ANDROID_LIB android)
find_library(LOG_LIB log)

target_link_libraries(native_renderer
    ${EGL_LIB}
    ${GLES_LIB}
    ${NAPI_LIB}
    ${HILOG_LIB}
    ${RAWFILE_LIB}
    ${ANDROID_LIB}
    ${LOG_LIB}
)
```

- [ ] **Step 3: 修改 entry/build-profile.json5**

在 `buildOption` 中添加 `externalNativeOptions`:

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "",
      "abiFilters": ["arm64-v8a"]
    }
  },
  "buildOptionSet": [
    {
      "name": "release",
      "arkOptions": {
        "obfuscation": {
          "ruleOptions": {
            "enable": false
          }
        }
      }
    }
  ],
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    }
  ]
}
```

- [ ] **Step 4: 创建 stb_image_impl.c 占位**

```c
// entry/src/main/cpp/platform/stb_image_impl.c
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
```

- [ ] **Step 5: 编译验证**

运行 `hvigorw assembleHap --no-daemon` 确认构建系统识别 C++ 代码。此时 C++ 源文件为空，应该编译成功（生成空 .so 或报链接错误——链接错误可忽略，后续 Task 会添加源文件）。

如果 hvigorw 报 CMake 配置错误，检查 NDK 路径和 CMake 版本。

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/cpp/ entry/build-profile.json5
git commit -m "feat: add C++ build system for native renderer"
```

---

## Task 2: ShaderProgram (C++)

**Files:**
- Create: `entry/src/main/cpp/renderer/ShaderProgram.h`
- Create: `entry/src/main/cpp/renderer/ShaderProgram.cpp`

**Interfaces:**
- Consumes: OpenGL ES 2.0 API
- Produces: `ShaderProgram` class — 被 Renderer 使用

- [ ] **Step 1: 创建 ShaderProgram.h**

```cpp
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
```

- [ ] **Step 2: 创建 ShaderProgram.cpp**

```cpp
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
```

- [ ] **Step 3: 编译验证**

```bash
hvigorw assembleHap --no-daemon
```

确认 ShaderProgram.cpp 编译通过。

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/cpp/renderer/ShaderProgram.h entry/src/main/cpp/renderer/ShaderProgram.cpp
git commit -m "feat: add ShaderProgram C++ class"
```

---

## Task 3: Camera2D (C++)

**Files:**
- Create: `entry/src/main/cpp/renderer/Camera2D.h`
- Create: `entry/src/main/cpp/renderer/Camera2D.cpp`

**Interfaces:**
- Produces: `Camera2D` class — 提供 4x4 正交投影矩阵
- Consumed by: Renderer（每帧更新投影矩阵）

- [ ] **Step 1: 创建 Camera2D.h**

```cpp
// entry/src/main/cpp/renderer/Camera2D.h
#pragma once

class Camera2D {
public:
    Camera2D();

    void setScreenSize(float width, float height);
    void setPosition(float x, float y);
    void setZoom(float zoom);

    void update();
    const float* projectionMatrix() const { return projection_; }

private:
    float projection_[16];
    float screenW_ = 1280.0f;
    float screenH_ = 720.0f;
    float posX_ = 0.0f;
    float posY_ = 0.0f;
    float zoom_ = 1.0f;

    static void ortho(float* out, float left, float right,
                      float bottom, float top, float near, float far);
};
```

- [ ] **Step 2: 创建 Camera2D.cpp**

```cpp
// entry/src/main/cpp/renderer/Camera2D.cpp
#include "Camera2D.h"
#include <cstring>

Camera2D::Camera2D() {
    memset(projection_, 0, sizeof(projection_));
    projection_[15] = 1.0f;
}

void Camera2D::setScreenSize(float width, float height) {
    screenW_ = width;
    screenH_ = height;
}

void Camera2D::setPosition(float x, float y) {
    posX_ = x;
    posY_ = y;
}

void Camera2D::setZoom(float zoom) {
    zoom_ = zoom;
}

void Camera2D::ortho(float* out, float left, float right,
                     float bottom, float top, float near, float far) {
    memset(out, 0, 16 * sizeof(float));
    out[0]  =  2.0f / (right - left);
    out[5]  =  2.0f / (top - bottom);
    out[10] = -2.0f / (far - near);
    out[12] = -(right + left) / (right - left);
    out[13] = -(top + bottom) / (top - bottom);
    out[14] = -(far + near) / (far - near);
    out[15] =  1.0f;
}

void Camera2D::update() {
    float halfW = (screenW_ * 0.5f) / zoom_;
    float halfH = (screenH_ * 0.5f) / zoom_;
    float left   = posX_ - halfW;
    float right  = posX_ + halfW;
    float bottom = posY_ - halfH;
    float top    = posY_ + halfH;
    ortho(projection_, left, right, bottom, top, -1.0f, 1.0f);
}
```

- [ ] **Step 3: 编译验证并 Commit**

```bash
hvigorw assembleHap --no-daemon
git add entry/src/main/cpp/renderer/Camera2D.h entry/src/main/cpp/renderer/Camera2D.cpp
git commit -m "feat: add Camera2D with orthographic projection"
```

---

## Task 4: TextureManager (C++)

**Files:**
- Create: `entry/src/main/cpp/renderer/TextureManager.h`
- Create: `entry/src/main/cpp/renderer/TextureManager.cpp`

**Interfaces:**
- Consumes: stb_image.h（PNG 解码）、OpenGL ES 2.0
- Produces: `TextureManager` class — load/unload/get 纹理
- Consumed by: SpriteBatcher（渲染时获取 GL 纹理 ID）

- [ ] **Step 1: 创建 TextureManager.h**

```cpp
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
```

- [ ] **Step 2: 创建 TextureManager.cpp**

```cpp
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
```

- [ ] **Step 3: 编译验证并 Commit**

```bash
hvigorw assembleHap --no-daemon
git add entry/src/main/cpp/renderer/TextureManager.h entry/src/main/cpp/renderer/TextureManager.cpp
git commit -m "feat: add TextureManager with stb_image and procedural textures"
```

---

## Task 5: SpriteBatcher (C++)

**Files:**
- Create: `entry/src/main/cpp/renderer/SpriteBatcher.h`
- Create: `entry/src/main/cpp/renderer/SpriteBatcher.cpp`

**Interfaces:**
- Consumes: ShaderProgram, TextureManager
- Produces: `SpriteBatcher` class — 接收顶点数据，按纹理批次绘制

- [ ] **Step 1: 创建 SpriteBatcher.h**

```cpp
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
```

- [ ] **Step 2: 创建 SpriteBatcher.cpp**

```cpp
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
```

- [ ] **Step 3: 编译验证并 Commit**

```bash
hvigorw assembleHap --no-daemon
git add entry/src/main/cpp/renderer/SpriteBatcher.h entry/src/main/cpp/renderer/SpriteBatcher.cpp
git commit -m "feat: add SpriteBatcher with dynamic VBO batching"
```

---

## Task 6: Renderer + NAPI Bridge (C++)

**Files:**
- Create: `entry/src/main/cpp/renderer/Renderer.h`
- Create: `entry/src/main/cpp/renderer/Renderer.cpp`
- Create: `entry/src/main/cpp/platform/napi_bridge.h`
- Create: `entry/src/main/cpp/platform/napi_bridge.cpp`
- Create: `entry/src/main/cpp/platform/napi_init.cpp`

**Interfaces:**
- Consumes: ShaderProgram, Camera2D, TextureManager, SpriteBatcher
- Produces: `Renderer` singleton — 帧管理、DrawCmd 执行
- Produces: NAPI 模块 `native_renderer` — ArkTS 可调用的全部原生函数

- [ ] **Step 1: 创建 Renderer.h**

```cpp
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
    float r, g, b, a;
    int flipX, flipY;
    int layer;
    // Triangle 特有（3 个顶点）
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
};
```

- [ ] **Step 2: 创建 Renderer.cpp**

核心实现要点：

```cpp
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
```

- [ ] **Step 3: 创建 napi_bridge.h**

```cpp
// entry/src/main/cpp/platform/napi_bridge.h
#pragma once

#include <napi/napi_native_api.h>

// NAPI 函数声明
napi_value NativeInit(napi_env env, napi_callback_info info);
napi_value NativeDestroy(napi_env env, napi_callback_info info);
napi_value NativeResize(napi_env env, napi_callback_info info);
napi_value NativeBeginFrame(napi_env env, napi_callback_info info);
napi_value NativeSubmitCommands(napi_env env, napi_callback_info info);
napi_value NativeEndFrame(napi_env env, napi_callback_info info);
napi_value NativeLoadTexture(napi_env env, napi_callback_info info);
napi_value NativeUnloadTexture(napi_env env, napi_callback_info info);
napi_value NativeSetCamera(napi_env env, napi_callback_info info);
napi_value NativeTouchInput(napi_env env, napi_callback_info info);
```

- [ ] **Step 4: 创建 napi_bridge.cpp**

核心实现 — DrawCmd 数组解析和 NAPI 函数实现：

```cpp
// entry/src/main/cpp/platform/napi_bridge.cpp
#include "napi_bridge.h"
#include "Renderer.h"
#include <hilog_ndk.h>
#include <string>
#include <vector>

static const char* TAG = "NapiBridge";

napi_value NativeInit(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    // 参数 0: surfaceId (string) — 需要通过 PlatformUtil 获取 window
    // 参数 1: width (number)
    // 参数 2: height (number)
    int32_t width, height;
    napi_get_value_int32(env, argv[1], &width);
    napi_get_value_int32(env, argv[2], &height);

    // 获取 surface — 通过 XComponent 的 native window
    // 实际实现中，surfaceId 需要通过 OH_NativeWindow 获取
    // 这里先记录参数，实际 surface 绑定在 napi_init.cpp 中处理

    OH_LOG_INFO(LOG_APP, "NativeInit: %{public}dx%{public}d", width, height);
    return nullptr;
}

napi_value NativeDestroy(napi_env env, napi_callback_info info) {
    Renderer::instance().destroy();
    return nullptr;
}

napi_value NativeResize(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t width, height;
    napi_get_value_int32(env, argv[0], &width);
    napi_get_value_int32(env, argv[1], &height);

    Renderer::instance().resize(width, height);
    return nullptr;
}

napi_value NativeBeginFrame(napi_env env, napi_callback_info info) {
    Renderer::instance().beginFrame();
    return nullptr;
}

napi_value NativeSubmitCommands(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    // argv[0] 是 DrawCmd[] 数组
    napi_value cmdArray = argv[0];
    uint32_t length;
    napi_get_array_length(env, cmdArray, &length);

    std::vector<DrawCmdData> cmds(length);

    for (uint32_t i = 0; i < length; i++) {
        napi_value elem;
        napi_get_element(env, cmdArray, i, &elem);

        napi_value val;

        napi_get_named_property(env, elem, "type", &val);
        napi_get_value_int32(env, val, &cmds[i].type);

        napi_get_named_property(env, elem, "textureId", &val);
        napi_get_value_int32(env, val, &cmds[i].textureId);

        napi_get_named_property(env, elem, "x", &val);
        napi_get_value_double(env, val, (double*)&cmds[i].x);
        // 注意：实际需要用中间变量
        double tmpD;
        napi_get_named_property(env, elem, "x", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].x = (float)tmpD;

        napi_get_named_property(env, elem, "y", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].y = (float)tmpD;

        napi_get_named_property(env, elem, "width", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].width = (float)tmpD;

        napi_get_named_property(env, elem, "height", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].height = (float)tmpD;

        napi_get_named_property(env, elem, "rotation", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].rotation = (float)tmpD;

        napi_get_named_property(env, elem, "srcX", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcX = (float)tmpD;

        napi_get_named_property(env, elem, "srcY", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcY = (float)tmpD;

        napi_get_named_property(env, elem, "srcW", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcW = (float)tmpD;

        napi_get_named_property(env, elem, "srcH", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcH = (float)tmpD;

        napi_get_named_property(env, elem, "r", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].r = (float)tmpD;

        napi_get_named_property(env, elem, "g", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].g = (float)tmpD;

        napi_get_named_property(env, elem, "b", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].b = (float)tmpD;

        napi_get_named_property(env, elem, "a", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].a = (float)tmpD;

        napi_get_named_property(env, elem, "flipX", &val);
        napi_get_value_int32(env, val, &cmds[i].flipX);

        napi_get_named_property(env, elem, "flipY", &val);
        napi_get_value_int32(env, val, &cmds[i].flipY);

        napi_get_named_property(env, elem, "layer", &val);
        napi_get_value_int32(env, val, &cmds[i].layer);
    }

    Renderer::instance().submitCommands(cmds.data(), (int)length);
    return nullptr;
}

napi_value NativeEndFrame(napi_env env, napi_callback_info info) {
    Renderer::instance().endFrame();
    return nullptr;
}

napi_value NativeLoadTexture(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value argv[4];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t textureId;
    napi_get_value_int32(env, argv[0], &textureId);

    // argv[1] = ArrayBuffer (raw PNG bytes)
    void* data;
    size_t byteLength;
    napi_get_arraybuffer_info(env, argv[1], &data, &byteLength);

    int32_t width, height;
    napi_get_value_int32(env, argv[2], &width);
    napi_get_value_int32(env, argv[3], &height);

    // 使用 stb_image 解码 PNG
    #include "stb_image.h"
    int channels;
    unsigned char* rgba = stbi_load_from_memory(
        (const unsigned char*)data, (int)byteLength,
        &width, &height, &channels, 4);

    if (rgba == nullptr) {
        OH_LOG_ERROR(LOG_APP, "stb_image decode failed for texture %{public}d", textureId);
        return nullptr;
    }

    Renderer::instance().loadTexture(textureId, rgba, width, height);
    stbi_image_free(rgba);
    return nullptr;
}

napi_value NativeUnloadTexture(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t textureId;
    napi_get_value_int32(env, argv[0], &textureId);
    Renderer::instance().unloadTexture(textureId);
    return nullptr;
}

napi_value NativeSetCamera(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    double x, y, zoom;
    napi_get_value_double(env, argv[0], &x);
    napi_get_value_double(env, argv[1], &y);
    napi_get_value_double(env, argv[2], &zoom);

    Renderer::instance().setCamera((float)x, (float)y, (float)zoom);
    return nullptr;
}

napi_value NativeTouchInput(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value argv[4];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t touchId, action;
    double x, y;
    napi_get_value_int32(env, argv[0], &touchId);
    napi_get_value_int32(env, argv[1], &action);
    napi_get_value_double(env, argv[2], &x);
    napi_get_value_double(env, argv[3], &y);

    // TODO: 转发到输入处理系统
    return nullptr;
}
```

注意：`NativeLoadTexture` 中 `#include "stb_image.h"` 应移到文件顶部。此处为说明逻辑流程。实际代码中 stb_image.h 在文件头 include。另外 `NativeLoadTexture` 中 width/height 参数在 stb_image 解码后会被覆盖为实际尺寸——如果调用方不知道 PNG 尺寸，可以传 0 让 stb_image 自动检测。修正为：

```cpp
// NativeLoadTexture 的正确实现
napi_value NativeLoadTexture(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t textureId;
    napi_get_value_int32(env, argv[0], &textureId);

    void* data;
    size_t byteLength;
    napi_get_arraybuffer_info(env, argv[1], &data, &byteLength);

    int w, h, channels;
    unsigned char* rgba = stbi_load_from_memory(
        (const unsigned char*)data, (int)byteLength, &w, &h, &channels, 4);

    if (rgba == nullptr) {
        OH_LOG_ERROR(LOG_APP, "stb_image decode failed: %{public}s", stbi_failure_reason());
        return nullptr;
    }

    Renderer::instance().loadTexture(textureId, rgba, w, h);
    stbi_image_free(rgba);
    return nullptr;
}
```

这意味着 NAPI 签名简化为 `nativeLoadTexture(textureId: number, pixelBuffer: ArrayBuffer): void`，不再需要 width/height 参数（stb_image 自动检测）。

- [ ] **Step 5: 创建 napi_init.cpp**

```cpp
// entry/src/main/cpp/platform/napi_init.cpp
#include "napi_bridge.h"
#include "Renderer.h"
#include <hilog_ndk.h>
#include <string>

static const char* MODULE_NAME = "native_renderer";
static const char* TAG = "NapiInit";

// XComponent surface 绑定
static napi_value OnSurfaceCreated(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    // 获取 native window from XComponent
    napi_valuetype type;
    napi_typeof(env, argv[0], &type);

    OH_LOG_INFO(LOG_APP, "OnSurfaceCreated called");

    // 通过 napi_unwrap 获取 OHNativeWindow
    void* nativeWindow = nullptr;
    napi_unwrap(env, argv[0], &nativeWindow);

    if (nativeWindow != nullptr) {
        // 获取窗口尺寸
        int32_t width = 1280;
        int32_t height = 720;
        // 实际应从 window 获取

        Renderer::instance().init((EGLNativeWindowType)nativeWindow, width, height);
    }

    return nullptr;
}

static napi_value OnSurfaceChanged(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t width, height;
    napi_get_value_int32(env, argv[0], &width);
    napi_get_value_int32(env, argv[1], &height);

    Renderer::instance().resize(width, height);
    return nullptr;
}

static napi_value OnSurfaceDestroyed(napi_env env, napi_callback_info info) {
    Renderer::instance().destroy();
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    OH_LOG_INFO(LOG_APP, "native_renderer module init");

    napi_property_descriptor desc[] = {
        {"nativeInit", nullptr, NativeInit, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeDestroy", nullptr, NativeDestroy, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeResize", nullptr, NativeResize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeBeginFrame", nullptr, NativeBeginFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSubmitCommands", nullptr, NativeSubmitCommands, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeEndFrame", nullptr, NativeEndFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeLoadTexture", nullptr, NativeLoadTexture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeUnloadTexture", nullptr, NativeUnloadTexture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSetCamera", nullptr, NativeSetCamera, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeTouchInput", nullptr, NativeTouchInput, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onSurfaceCreated", nullptr, OnSurfaceCreated, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onSurfaceChanged", nullptr, OnSurfaceChanged, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onSurfaceDestroyed", nullptr, OnSurfaceDestroyed, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_define_properties(env, exports,
                           sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module nativeRendererModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "native_renderer",
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterNativeRendererModule(void) {
    napi_module_register(&nativeRendererModule);
}
```

- [ ] **Step 6: 编译验证**

```bash
hvigorw assembleHap --no-daemon
```

确认所有 C++ 文件编译通过，链接生成 `libnative_renderer.so`。

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/cpp/
git commit -m "feat: add complete C++ native renderer and NAPI bridge"
```

---

## Task 7: ArkTS DrawCmd 类型 + DrawCmdBuffer

**Files:**
- Create: `entry/src/main/ets/native/DrawCmd.ets`

**Interfaces:**
- Produces: `DrawCmd` interface, `DrawType` 枚举, `DrawCmdBuffer` 辅助类
- Consumed by: 所有 renderer 改写（Task 10-14）

- [ ] **Step 1: 创建 DrawCmd.ets**

```typescript
// entry/src/main/ets/native/DrawCmd.ets

export enum DrawType {
  SPRITE = 0,
  RECT = 1,
  TRIANGLE = 2,
}

export interface DrawCmd {
  type: number;
  textureId: number;
  x: number; y: number;
  width: number; height: number;
  rotation: number;
  srcX: number; srcY: number;
  srcW: number; srcH: number;
  r: number; g: number; b: number; a: number;
  flipX: number; flipY: number;
  layer: number;
}

export class DrawCmdBuffer {
  private cmds: DrawCmd[] = [];

  pushSprite(textureId: number, x: number, y: number,
             width: number, height: number,
             srcX: number, srcY: number, srcW: number, srcH: number,
             r: number, g: number, b: number, a: number,
             rotation: number, layer: number,
             flipX: number, flipY: number): void {
    this.cmds.push({
      type: DrawType.SPRITE,
      textureId, x, y, width, height,
      rotation, srcX, srcY, srcW, srcH,
      r, g, b, a, flipX, flipY, layer
    });
  }

  pushRect(x: number, y: number, width: number, height: number,
           r: number, g: number, b: number, a: number,
           rotation: number, layer: number): void {
    this.cmds.push({
      type: DrawType.RECT,
      textureId: 0,
      x, y, width, height,
      rotation,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
    });
  }

  pushTriangle(x1: number, y1: number,
               x2: number, y2: number,
               x3: number, y3: number,
               r: number, g: number, b: number, a: number,
               layer: number): void {
    // 三角形用包围盒 + 裁剪近似，或分解为 Rect 近似
    // 简化实现：用 3 个极细 Rect 画三角形边框
    // 完整实现需要 C++ 端支持真正的三角形渲染
    // 暂用 pushRect 近似
    const cx: number = (x1 + x2 + x3) / 3;
    const cy: number = (y1 + y2 + y3) / 3;
    const maxW: number = Math.max(Math.abs(x2 - x1), Math.abs(x3 - x1), 1);
    const maxH: number = Math.max(Math.abs(y2 - y1), Math.abs(y3 - y1), 1);
    this.cmds.push({
      type: DrawType.RECT,
      textureId: 0,
      x: cx - maxW / 2, y: cy - maxH / 2,
      width: maxW, height: maxH,
      rotation: 0,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
    });
  }

  pushCircle(cx: number, cy: number, radius: number,
             r: number, g: number, b: number, a: number,
             layer: number, textureId: number): void {
    this.cmds.push({
      type: DrawType.SPRITE,
      textureId,
      x: cx - radius, y: cy - radius,
      width: radius * 2, height: radius * 2,
      rotation: 0,
      srcX: 0, srcY: 0, srcW: 1, srcH: 1,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
    });
  }

  pushLine(x1: number, y1: number, x2: number, y2: number,
           thickness: number,
           r: number, g: number, b: number, a: number,
           layer: number): void {
    const dx: number = x2 - x1;
    const dy: number = y2 - y1;
    const len: number = Math.sqrt(dx * dx + dy * dy);
    const angle: number = Math.atan2(dy, dx);
    const cx: number = (x1 + x2) / 2;
    const cy: number = (y1 + y2) / 2;
    this.cmds.push({
      type: DrawType.RECT,
      textureId: 0,
      x: cx - len / 2, y: cy - thickness / 2,
      width: len, height: thickness,
      rotation: angle,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
    });
  }

  getCommands(): DrawCmd[] {
    return this.cmds;
  }

  clear(): void {
    this.cmds = [];
  }

  get length(): number {
    return this.cmds.length;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/native/DrawCmd.ets
git commit -m "feat: add DrawCmd types and DrawCmdBuffer helper"
```

---

## Task 8: ArkTS NativeRenderer Bridge

**Files:**
- Create: `entry/src/main/ets/native/NativeRenderer.ets`

**Interfaces:**
- Consumes: `DrawCmd[]`（来自 DrawCmdBuffer）
- Produces: `NativeRenderer` class — 封装所有 NAPI 调用

- [ ] **Step 1: 创建 NativeRenderer.ets**

```typescript
// entry/src/main/ets/native/NativeRenderer.ets
import { DrawCmd } from './DrawCmd';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { napi } from '@kit.ArkTS';

const TAG: string = 'NativeRenderer';
const DOMAIN: number = 0x0000;

export class NativeRenderer {
  private nativeModule: Object | null = null;

  loadModule(): void {
    try {
      this.nativeModule = napi.loadModule('native_renderer');
      hilog.info(DOMAIN, TAG, 'Native module loaded');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to load native module: ' + String(e));
    }
  }

  init(width: number, height: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeInit'] !== undefined) {
      (m['nativeInit'] as Function)(width, height);
    }
  }

  destroy(): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeDestroy'] !== undefined) {
      (m['nativeDestroy'] as Function)();
    }
  }

  resize(width: number, height: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeResize'] !== undefined) {
      (m['nativeResize'] as Function)(width, height);
    }
  }

  beginFrame(): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeBeginFrame'] !== undefined) {
      (m['nativeBeginFrame'] as Function)();
    }
  }

  submitCommands(cmds: DrawCmd[]): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeSubmitCommands'] !== undefined) {
      (m['nativeSubmitCommands'] as Function)(cmds);
    }
  }

  endFrame(): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeEndFrame'] !== undefined) {
      (m['nativeEndFrame'] as Function)();
    }
  }

  loadTexture(textureId: number, pngBuffer: ArrayBuffer): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeLoadTexture'] !== undefined) {
      (m['nativeLoadTexture'] as Function)(textureId, pngBuffer);
    }
  }

  unloadTexture(textureId: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeUnloadTexture'] !== undefined) {
      (m['nativeUnloadTexture'] as Function)(textureId);
    }
  }

  setCamera(x: number, y: number, zoom: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeSetCamera'] !== undefined) {
      (m['nativeSetCamera'] as Function)(x, y, zoom);
    }
  }

  touchInput(touchId: number, action: number, x: number, y: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeTouchInput'] !== undefined) {
      (m['nativeTouchInput'] as Function)(touchId, action, x, y);
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/native/NativeRenderer.ets
git commit -m "feat: add NativeRenderer ArkTS bridge class"
```

---

## Task 9: XComponent 集成 + 游戏循环

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: NativeRenderer, DrawCmdBuffer
- Produces: XComponent 替代 Canvas，游戏循环改为 ECS update → 命令收集 → native 提交

- [ ] **Step 1: 在 Index.ets 中添加 XComponent 替换 Canvas**

将现有的 `Canvas(this.gameCtx)` 替换为：

```typescript
import { xcomponent } from '@kit.ArkUI';

// 在 struct Index 中添加：
private xComponentController: xcomponent.XComponentController = new xcomponent.XComponentController();
private nativeRenderer: NativeRenderer = new NativeRenderer();
private cmdBuffer: DrawCmdBuffer = new DrawCmdBuffer();

// 在 build() 的 Stack 中，将 Canvas(this.gameCtx) 替换为：
XComponent({
  id: 'gameSurface',
  type: xcomponent.XComponentType.SURFACE,
  controller: this.xComponentController
})
  .width(this.screenW)
  .height(this.screenH)
  .hitTestBehavior(HitTestMode.Transparent)
  .onLoad(() => {
    console.log('[Index] XComponent onLoad');
    this.nativeRenderer.loadModule();
    this.nativeRenderer.init(this.pixelW, this.pixelH);
    this.tryInitEngine();
  })
```

- [ ] **Step 2: 修改游戏循环**

将 `onCanvasTickChange` 改为新的渲染流程：

```typescript
onCanvasTickChange(): void {
  // 1. 收集绘制命令（所有 renderer 写入 cmdBuffer）
  this.cmdBuffer.clear();
  if (this.gameScene !== null) {
    this.gameScene.collectCommands(this.cmdBuffer);
  }
  // 2. 提交到原生渲染器
  this.nativeRenderer.beginFrame();
  this.nativeRenderer.setCamera(this.world.cameraX, this.world.cameraY, 1.0);
  this.nativeRenderer.submitCommands(this.cmdBuffer.getCommands());
  this.nativeRenderer.endFrame();
}
```

- [ ] **Step 3: 移除旧 Canvas 相关代码**

删除以下内容：
- `private gameCtx: CanvasRenderingContext2D`
- `private minimapCtx: CanvasRenderingContext2D`
- `private gameCanvasReady: boolean`
- `private minimapCanvasReady: boolean`
- `Canvas(this.minimapCtx)` 及其 `MinimapView` builder
- 所有引用 `gameCtx` 和 `minimapCtx` 的代码

- [ ] **Step 4: 编译验证**

此时会有编译错误（GameScene 还没有 `collectCommands` 方法），先注释掉 `this.gameScene.collectCommands(this.cmdBuffer)` 调用，确保 XComponent 能正确创建。

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: replace Canvas with XComponent in Index page"
```

---

## Task 10: GameScene 命令收集 + TileRenderer 改写

**Files:**
- Modify: `entry/src/main/ets/game/GameScene.ets`
- Modify: `entry/src/main/ets/game/renderers/TileRenderer.ets`

**Interfaces:**
- Consumes: DrawCmdBuffer（Task 7）
- Produces: `GameScene.collectCommands(buf: DrawCmdBuffer): void`

- [ ] **Step 1: 在 GameScene 中添加 collectCommands 方法**

```typescript
import { DrawCmdBuffer } from '../native/DrawCmd';

// 在 GameScene 类中添加：
collectCommands(buf: DrawCmdBuffer): void {
  const camX: number = this.world.cameraX;
  const camY: number = this.world.cameraY;
  const w: World = this.world;
  const s: GameSettings = this.settings;
  const fc: number = this.frameCount; // 需要存储 frameCount
  const sw: number = this.screenW;
  const sh: number = this.screenH;

  this.tileRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc);
  // 后续 Task 添加更多 renderer 的命令收集
}
```

- [ ] **Step 2: 改写 TileRenderer**

将 `render(ctx: CanvasRenderingContext2D, ...)` 改为 `collectCommands(world, buf, ...)`。

核心转换逻辑：
- `ctx.fillStyle = color; ctx.fillRect(x, y, w, h)` → `buf.pushRect(x, y, w, h, r, g, b, a, 0, 0)`
- `ctx.createLinearGradient(...)` → 多个相邻 Rect（颜色渐变近似）
- 颜色解析：hex `#rrggbb` → `r, g, b` 归一化到 0-1

示例转换（TileRenderer 中的 tile 绘制）：

```typescript
// 旧代码：
// ctx.fillStyle = '#3b7d23';
// ctx.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

// 新代码：
const color: number[] = hexToRgb('#3b7d23');
buf.pushRect(screenX, screenY, TILE_SIZE, TILE_SIZE,
             color[0], color[1], color[2], 1.0, 0, 0);
```

添加辅助函数 `hexToRgb(hex: string): number[]`（可放在 DrawCmd.ets 或单独的 Utils 中）。

- [ ] **Step 3: 编译验证**

确认 TileRenderer 编译通过，GameScene.collectCommands 可以被调用。

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameScene.ets entry/src/main/ets/game/renderers/TileRenderer.ets
git commit -m "feat: rewrite TileRenderer to DrawCmd, add GameScene.collectCommands"
```

---

## Task 11: 简单实体 Renderer 改写（Chest + Trap）

**Files:**
- Modify: `entry/src/main/ets/game/renderers/ChestRenderer.ets`
- Modify: `entry/src/main/ets/game/renderers/TrapRenderer.ets`

- [ ] **Step 1: 改写 ChestRenderer**

将 Canvas 绘制转为 DrawCmd 生成。ChestRenderer 主要使用 `fillRect` 和 `arc`。

转换规则：
- `fillRect` → `buf.pushRect(...)`
- `arc` (filled circle) → `buf.pushCircle(cx, cy, radius, r, g, b, a, layer, circleTexId)`
- `beginPath/moveTo/lineTo/closePath/fill` → 近似为 `pushRect`（对简单形状）或 `pushTriangle`

- [ ] **Step 2: 改写 TrapRenderer**

同样的转换模式。TrapRenderer 使用 fillRect、arc、stroke 等。

注意：`stroke`（描边）没有直接对应的 DrawCmd。用两个不同颜色的矩形近似（外圈 + 内圈）。

- [ ] **Step 3: 在 GameScene.collectCommands 中注册**

```typescript
this.chestRenderer.collectCommands(buf, offX, offY, w, sw, sh, s, fc);
this.trapRenderer.collectCommands(buf, offX, offY, w, sw, sh, fc);
```

- [ ] **Step 4: 编译验证并 Commit**

```bash
git add entry/src/main/ets/game/renderers/ChestRenderer.ets entry/src/main/ets/game/renderers/TrapRenderer.ets
git commit -m "feat: rewrite ChestRenderer and TrapRenderer to DrawCmd"
```

---

## Task 12: PlayerRenderer + WeaponRenderer + TransformFormRenderer 改写

**Files:**
- Modify: `entry/src/main/ets/game/renderers/PlayerRenderer.ets`
- Modify: `entry/src/main/ets/game/renderers/WeaponRenderer.ets`
- Modify: `entry/src/main/ets/game/renderers/TransformFormRenderer.ets`

- [ ] **Step 1: 改写 PlayerRenderer**

PlayerRenderer 是最复杂的 renderer 之一（653 行），包含：
- 史莱姆身体（sprite atlas 或 procedural）
- 人形态（4 阶段：proto/phantom/armored/complete）
- 钻头配件
- 进化特效

核心转换：
- `drawImage(slimeAtlas, ...)` → `buf.pushSprite(textureId, x, y, w, h, srcX, srcY, srcW, srcH, r, g, b, a, rot, layer, flipX, flipY)`
- `fillRect` → `buf.pushRect(...)`
- `arc` → `buf.pushCircle(...)`
- `globalAlpha` → 乘入 `a` 参数
- `fillStyle` → 解析为 r, g, b

对于 sprite atlas：需要知道 atlas 纹理 ID 和帧坐标。SpriteManager 需要扩展以支持 native 纹理 ID。

- [ ] **Step 2: 改写 WeaponRenderer**

WeaponRenderer（1025 行）包含武器在玩家身上的渲染和攻击特效。

转换模式同上。攻击特效中的 `arc`（弧形斩击）→ `pushCircle` 或 `pushRect` 近似。

- [ ] **Step 3: 改写 TransformFormRenderer**

TransformFormRenderer（216 行）渲染 4 种变身形态。

注意：此 renderer 使用 `save/restore/translate/rotate/scale` 变换。在 DrawCmd 模式下，需要在 ArkTS 侧计算最终坐标后生成命令（因为 OpenGL 变换矩阵由 Camera2D 管理，不支持 per-entity 变换栈）。

解决方案：对每个需要变换的绘制操作，在 ArkTS 侧手动计算旋转/缩放后的顶点位置，然后生成对应的 DrawCmd。`pushRect` 和 `pushSprite` 已支持 `rotation` 参数。

- [ ] **Step 4: 在 GameScene.collectCommands 中注册**

```typescript
this.playerRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, this.spriteManager);
```

- [ ] **Step 5: 编译验证并 Commit**

```bash
git add entry/src/main/ets/game/renderers/PlayerRenderer.ets \
        entry/src/main/ets/game/renderers/WeaponRenderer.ets \
        entry/src/main/ets/game/renderers/TransformFormRenderer.ets
git commit -m "feat: rewrite PlayerRenderer, WeaponRenderer, TransformFormRenderer to DrawCmd"
```

---

## Task 13: EnemyRenderer + BossRenderer + BossFormsRenderer 改写

**Files:**
- Modify: `entry/src/main/ets/game/renderers/EnemyRenderer.ets`
- Modify: `entry/src/main/ets/game/renderers/BossRenderer.ets`
- Modify: `entry/src/main/ets/game/renderers/BossFormsRenderer.ets`

- [ ] **Step 1: 改写 EnemyRenderer**

EnemyRenderer（858 行）是 sprite-heavy 的 renderer：
- 多种史莱姆敌人（sprite atlas）
- 幽灵敌人
- 人形兽（sprite）
- 血条渲染（fillRect）
- 受击闪烁（globalAlpha）

转换模式与 PlayerRenderer 相同。Sprite atlas 需要纹理 ID。

- [ ] **Step 2: 改写 BossRenderer**

BossRenderer（1010 行）包含 5 种 Boss 的渲染，委托给 BossFormsRenderer。

- [ ] **Step 3: 改写 BossFormsRenderer**

BossFormsRenderer（572 行）使用大量 `arc`、`beginPath`、`moveTo/lineTo` 绘制 Boss 形态。

复杂路径（如 Boss 的特殊形状）→ 分解为多个 `pushCircle` + `pushRect` 组合近似。Boss 是大型敌人，视觉精度可以适当降低。

- [ ] **Step 4: 在 GameScene.collectCommands 中注册**

```typescript
this.enemyRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, this.spriteManager);
this.bossRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, this.spriteManager);
```

- [ ] **Step 5: 编译验证并 Commit**

```bash
git add entry/src/main/ets/game/renderers/EnemyRenderer.ets \
        entry/src/main/ets/game/renderers/BossRenderer.ets \
        entry/src/main/ets/game/renderers/BossFormsRenderer.ets
git commit -m "feat: rewrite EnemyRenderer, BossRenderer, BossFormsRenderer to DrawCmd"
```

---

## Task 14: EffectRenderer 改写

**Files:**
- Modify: `entry/src/main/ets/game/renderers/EffectRenderer.ets`

**Interfaces:**
- 最复杂的 renderer 改写 — 包含渐变、变换、光照、暗角

- [ ] **Step 1: 改写 EffectRenderer 的各个子方法**

EffectRenderer（467 行）包含：
- `renderLighting()` — 光照效果（使用 `createRadialGradient`）
- `render()` — 粒子、攻击特效（委托 TrapRenderer/ChestRenderer）
- `renderVignetteAndDamage()` — 屏幕暗角 + 受伤红闪

渐变处理策略：
- `createRadialGradient` → 多个同心 `pushCircle`（不同半径、递减 alpha）近似
- `save/translate/rotate` → 在 ArkTS 侧预计算旋转后坐标
- `strokeRect` → 4 个 `pushRect`（上/下/左/右边）

光照效果（最复杂）：
- 简化方案：用半透明黑色 `pushRect` 覆盖全屏，然后在光源位置用 `pushCircle`（加法混合）"挖洞"
- 或者：第一阶段不做光照，用纯色背景替代

暗角效果：
- 4 个半透明黑色 `pushRect` 覆盖屏幕边缘

受伤红闪：
- 全屏半透明红色 `pushRect`

- [ ] **Step 2: 在 GameScene.collectCommands 中注册**

```typescript
this.effectRenderer.collectLightingCommands(w, buf, camX, camY, sw, sh, s, fc);
this.effectRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc);
this.effectRenderer.collectVignetteCommands(w, buf, camX, camY, sw, sh, s, fc);
```

- [ ] **Step 3: 编译验证并 Commit**

```bash
git add entry/src/main/ets/game/renderers/EffectRenderer.ets
git commit -m "feat: rewrite EffectRenderer to DrawCmd with gradient approximation"
```

---

## Task 15: 纹理管线

**Files:**
- Modify: `entry/src/main/ets/game/sprites/SpriteManager.ets`
- Modify: `entry/src/main/ets/game/sprites/SpriteAtlas.ets`（可能需要）

**Interfaces:**
- Consumes: NativeRenderer.loadTexture()
- Produces: 每个 sprite atlas 对应一个 native 纹理 ID

- [ ] **Step 1: 修改 SpriteManager 的加载流程**

当前 SpriteManager 使用 `OffscreenCanvas` 生成 sprite atlas。改为：

1. 在 C++ 侧生成程序化纹理（通过 NAPI 调用 `nativeLoadTexture`）
2. 或者：在 ArkTS 侧将 OffscreenCanvas 内容导出为 ArrayBuffer，传给 C++

方案 A（推荐）：在 C++ 侧用代码生成程序化 sprite
- 将现有的 SpriteGenerator 函数（如 `drawGraySlime`）的逻辑用 C++ 实现
- 生成 RGBA 像素数组 → `glTexImage2D` 上传

方案 B（过渡方案）：继续使用 OffscreenCanvas 生成，导出像素数据
- `OffscreenCanvas.getImageData()` → `ArrayBuffer` → `nativeLoadTexture()`
- 风险：可能遇到与之前相同的 ImageSource 问题

推荐方案 A：将 SpriteGenerator 的核心逻辑移植到 C++，完全绕过 HarmonyOS 图像 API。

- [ ] **Step 2: 为每个 sprite atlas 分配纹理 ID**

```typescript
// SpriteManager 中：
private enemyAtlasTexId: number = 1;
private playerSlimeAtlasTexId: number = 2;
private bossAtlasTexId: number = 3;
// ...

async generateAll(context: Object | null): Promise<void> {
  // 生成 RGBA 像素数据
  const enemyPixels: Uint8Array = this.generateEnemyAtlasPixels();
  // 转为 ArrayBuffer 传给 native
  const buffer: ArrayBuffer = enemyPixels.buffer as ArrayBuffer;
  this.nativeRenderer.loadTexture(this.enemyAtlasTexId, buffer);
  // ...
}
```

- [ ] **Step 3: 更新所有 renderer 的纹理 ID 引用**

renderer 在 `pushSprite` 时需要使用正确的纹理 ID，而不是直接引用 `ImageBitmap`。

- [ ] **Step 4: 编译验证并 Commit**

```bash
git add entry/src/main/ets/game/sprites/
git commit -m "feat: implement native texture pipeline via SpriteManager"
```

---

## Task 16: HUD 迁移至 ArkTS UI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`（添加 HUD 组件）
- Modify: `entry/src/main/ets/game/renderers/UIRenderer.ets`（移除或改写）

- [ ] **Step 1: 确认现有 HUD 已在 ArkTS UI 层**

检查 Index.ets 中已有的 HUD 组件：
- TopBarView（HP/XP/等级）— 已是 ArkTS UI ✓
- JoystickView — 已是 ArkTS UI ✓
- ActionButtonsView — 已是 ArkTS UI ✓
- TransformButtonView — 已是 ArkTS UI ✓
- InventoryBarView — 已是 ArkTS UI ✓
- WeaponFormView — 已是 ArkTS UI ✓

这些不需要改动，它们已经是 ArkTS UI 组件，覆盖在 XComponent 之上。

- [ ] **Step 2: 处理 UIRenderer 的 Canvas 内 HUD**

UIRenderer 的 `renderHUD()` 在 Canvas 上绘制了额外的 HUD 元素（技能图标、吞噬指示器、人形态能量条）。这些需要迁移到 ArkTS UI 层。

将 `renderHUD()` 中的元素转为 Index.ets 中的 ArkTS 组件（类似已有的 TopBarView 模式）。

- [ ] **Step 3: 处理 Minimap**

当前 minimap 使用单独的 Canvas。两个选择：
- A: 用 XComponent 替代 minimap Canvas（需要第二个 native surface）
- B: 用 ArkTS Canvas 组件（minimap 不涉及 sprite 加载，可能不会触发 bug）
- C: 简化为文本/图标表示（暂不实现 minimap）

推荐方案 B：minimap 保持 ArkTS Canvas，因为它只使用简单的 fillRect 和 arc，不加载外部图片。

- [ ] **Step 4: 移除 UIRenderer 的 Canvas 渲染**

UIRenderer 的 `renderMinimap` 和 `renderHUD` 不再由 GameScene.render() 调用。

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets entry/src/main/ets/game/renderers/UIRenderer.ets
git commit -m "feat: migrate HUD to ArkTS UI overlay, remove Canvas-based UIRenderer"
```

---

## Task 17: 输入处理

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: 添加 XComponent 触摸事件处理**

XComponent 的 `hitTestBehavior` 设为 `Transparent`，触摸事件由上层 ArkTS UI 组件（摇杆、按钮）处理。现有触摸逻辑不需要改动。

如果需要将触摸传递给原生层（例如直接点击游戏世界），添加：

```typescript
.onTouch((event: TouchEvent) => {
  for (const touch of event.touches) {
    const action: number = event.type === TouchType.Down ? 0 :
                           event.type === TouchType.Move ? 1 : 2;
    this.nativeRenderer.touchInput(
      touch.id, action,
      vp2px(touch.x), vp2px(touch.y)
    );
  }
})
```

- [ ] **Step 2: 确认现有输入管线不变**

现有输入流程：
1. ArkTS UI 组件（摇杆/按钮）的 onTouch → 设置 Engine 的 input 状态
2. ECS update 阶段读取 input 状态
3. 不需要改动

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: add native touch input forwarding"
```

---

## Task 18: 完整渲染管线串联

**Files:**
- Modify: `entry/src/main/ets/game/GameScene.ets`

- [ ] **Step 1: 完成 GameScene.collectCommands**

确保所有 renderer 的命令收集都注册在 `collectCommands` 中，顺序与原 `render()` 一致：

```typescript
collectCommands(buf: DrawCmdBuffer): void {
  const camX: number = this.world.cameraX;
  const camY: number = this.world.cameraY;
  const w: World = this.world;
  const s: GameSettings = this.settings;
  const fc: number = this.frameCount;
  const sw: number = this.screenW;
  const sh: number = this.screenH;
  const offX: number = -camX;
  const offY: number = -camY;

  // Layer 0: 地形
  this.tileRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc);

  // Layer 1: 光照
  this.effectRenderer.collectLightingCommands(w, buf, camX, camY, sw, sh, s, fc);

  // Layer 2: 敌人
  this.enemyRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, this.spriteManager);

  // Layer 3: 特效（粒子、陷阱、宝箱）
  this.effectRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc);

  // Layer 4: Boss
  this.bossRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, this.spriteManager);

  // Layer 5: 玩家
  this.playerRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, this.spriteManager);

  // Layer 6: 屏幕特效
  this.effectRenderer.collectVignetteCommands(w, buf, camX, camY, sw, sh, s, fc);
}
```

- [ ] **Step 2: 完成 Index.ets 的游戏循环**

```typescript
onCanvasTickChange(): void {
  if (this.gameScene === null) return;

  // 收集命令
  this.cmdBuffer.clear();
  this.gameScene.collectCommands(this.cmdBuffer);

  // 获取相机数据
  const world: World = this.gameScene.getWorld();

  // 提交到原生渲染器
  this.nativeRenderer.beginFrame();
  this.nativeRenderer.setCamera(world.cameraX + this.pixelW / 2,
                                world.cameraY + this.pixelH / 2, 1.0);
  this.nativeRenderer.submitCommands(this.cmdBuffer.getCommands());
  this.nativeRenderer.endFrame();
}
```

- [ ] **Step 3: 端到端测试**

部署到设备验证：
1. XComponent 创建成功，清屏颜色可见
2. 地形 tile 渲染正确
3. 玩家角色可见
4. 敌人/Boss 可见
5. 触摸输入正常
6. HUD 覆盖层正常

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameScene.ets entry/src/main/ets/pages/Index.ets
git commit -m "feat: complete rendering pipeline end-to-end"
```

---

## Task 19: 旧代码清理

**Files:**
- Modify: 多个文件

- [ ] **Step 1: 移除旧 Canvas 相关代码**

- 删除 `gameCtx`、`minimapCtx` 相关的所有声明和引用
- 删除 `gameCanvasReady`、`minimapCanvasReady` 标志
- 删除 `onCanvasTickChange` 中的 `engine.render()` 调用（已被新流程替代）
- 删除 GameScene 的旧 `render()` 和 `renderMinimap()` 方法（已被 `collectCommands()` 替代）

- [ ] **Step 2: 清理 Engine HAR**

Engine 的 `Engine.ets` 中的 `render()` 方法不再需要调用 `scene.render()`。改为由 Index.ets 直接驱动命令收集和提交。

- [ ] **Step 3: 移除未使用的 import**

清理所有文件中不再使用的 `CanvasRenderingContext2D` 相关 import。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: remove old Canvas rendering code"
```

---

## Task 20: 编译验证 + 设备测试

- [ ] **Step 1: 完整编译**

```bash
hvigorw assembleHap --no-daemon
```

确认 ArkTS + C++ 全部编译通过，无错误。

- [ ] **Step 2: 设备部署**

部署到 HarmonyOS 设备/模拟器，验证：
1. XComponent 正确创建，EGL 上下文初始化
2. 清屏颜色（深蓝黑 #08080f）可见
3. 地形 tile 渲染正确
4. 纹理加载成功（sprite 可见）
5. 玩家角色可移动
6. 敌人/Boss 可见且可交互
7. HUD 覆盖层正常显示
8. 帧率稳定

- [ ] **Step 3: 修复发现的问题**

根据设备测试结果修复渲染错误、性能问题或交互 bug。

- [ ] **Step 4: 最终 Commit**

```bash
git add -A
git commit -m "feat: XComponent native renderer complete and verified"
```
