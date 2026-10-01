# XComponent 原生渲染架构设计

## 概述

将游戏渲染层从 Canvas/OffscreenCanvas 迁移到 XComponent + OpenGL ES 原生渲染，解决 HarmonyOS ImageSource/Canvas API 在 rawfile 资源加载上的不稳定性问题。

## 背景与动机

### 问题

Canvas 渲染方案在 HarmonyOS NEXT 上存在三个已确认的资源加载缺陷：

1. **ArrayBuffer 路径失败**: `getRawFileContent()` 返回的 ArrayBuffer 不被 `image.createImageSource()` 识别，报 `fail to get arraybufferinfo`
2. **文件描述符路径失败**: `getRawFileDescriptor()` 返回的 fd 不被图像解码器识别，报 `failed to create decoder object`
3. **缓存文件中转路径未验证**: 通过 fd 读取内容写入缓存文件再用路径解码，理论上可行但用户决定放弃整个 Canvas 方案

三次修复尝试均失败或未验证，根本原因是 HarmonyOS Canvas/ImageSource API 对 HAP 内部资源的支持不完整。

### 目标

- 完全绕过 HarmonyOS ImageSource / Canvas 2D 的图像解码管线
- 用 OpenGL ES 原生渲染替代 Canvas 绘制
- 保留全部游戏功能（4 形态变化、能量系统、Boss 战、自由探索、分块世界）
- 保留 ECS 架构（World/System/Entity/Component）

## 架构总览

采用**命令缓冲区模式**：ArkTS 侧 ECS 收集绘制命令（DrawCmd[]），通过 NAPI 每帧一次传递给 C++ 原生渲染器执行。

```
ArkTS 层                          NAPI 桥接                     C++ 原生层
┌─────────────────┐                                           ┌─────────────────────┐
│  ECS World      │                                           │  OpenGL ES Renderer │
│  ├─ 25 Systems  │──→ RenderSystem 收集命令 ──→ NAPI ──→    │  ├─ SpriteBatcher   │
│  ├─ Components  │    DrawCmd[] (纹理/坐标/                   │  ├─ TextureManager  │
│  └─ Entities    │    颜色/变换)         每帧一次调用          │  ├─ Camera2D        │
│                 │                                           │  ├─ TileRenderer    │
│  GameScene      │←── 输入事件 ←────────────── NAPI ←──     │  └─ ShaderProgram   │
│  XComponent     │    触摸/按键                               │                     │
└─────────────────┘                                           └─────────────────────┘
```

## 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 渲染 API | OpenGL ES 2.0 | 稳定、兼容性好、2D 游戏足够 |
| 架构模式 | 命令缓冲区 | ArkTS/C++ 边界清晰，ECS 逻辑不动 |
| PNG 解码 | C++ 侧 stb_image | 完全绕过 ImageSource 不稳定问题 |
| HUD 渲染 | ArkTS UI 覆盖层 | 文本/进度条/按钮用标准组件，比 OpenGL 画文字简单 10 倍 |
| ECS | 完整保留 | 25 个 System 中仅 4 个 Renderer 需改写 |
| 输入传递 | XComponent 触摸 → NAPI → C++ | 低延迟，原生层直接处理 |

## NAPI 桥接接口

### DrawCmd 结构

```typescript
interface DrawCmd {
  type: number;          // 0=Sprite, 1=Rect, 2=Line
  textureId: number;     // Sprite: 纹理ID; Rect/Line: 忽略
  x: number; y: number; // 世界坐标位置
  width: number; height: number;
  rotation: number;      // 弧度
  srcX: number; srcY: number;   // 纹理源矩形（Sprite 特有）
  srcW: number; srcH: number;
  r: number; g: number; b: number; a: number;  // 颜色/透明度
  flipX: number; flipY: number;  // 0 或 1（避免 boolean 在 NAPI 传递的歧义）
  layer: number;         // 渲染排序层 (0=地形, 1=实体, 2=特效, 3=天空)
}
```

### NAPI 函数清单

```
// 生命周期
nativeInit(surfaceId: string, width: number, height: number): void
nativeDestroy(): void
nativeResize(width: number, height: number): void

// 每帧渲染
nativeBeginFrame(): void
nativeSubmitCommands(cmds: DrawCmd[]): void
nativeEndFrame(): void

// 纹理管理
nativeLoadTexture(textureId: number, pixelBuffer: ArrayBuffer,
                  width: number, height: number): void
nativeUnloadTexture(textureId: number): void

// 相机
nativeSetCamera(x: number, y: number, zoom: number): void

// 输入（ArkTS 触摸事件转发到 C++）
nativeTouchInput(touchId: number, action: number, x: number, y: number): void
// action: 0=down, 1=move, 2=up

// 输入回调（C++ → ArkTS 方向，用于游戏菜单等交互）
nativeSetInputCallback(callback: Function): void
```

### 每帧数据流

```
ArkTS                              C++
  │                                  │
  ├─ ECS update (所有System)          │
  ├─ RenderSystem 收集 DrawCmd[]      │
  ├─ nativeBeginFrame()             ├─ glClear
  ├─ nativeSubmitCommands(cmds)  ──→ ├─ 按 textureId 排序
  │                                  ├─ 批渲染 quads
  ├─ nativeSetCamera(...)        ──→ ├─ 更新 MVP 矩阵
  ├─ nativeEndFrame()            ──→ ├─ eglSwapBuffers
  │                                  │
```

## C++ 原生渲染器

### 文件结构

```
cpp/
├── renderer/
│   ├── Renderer.h/cpp          # OpenGL 初始化、shader 编译、帧管理
│   ├── SpriteBatcher.h/cpp     # 精灵批渲染（动态 VBO，最大 4096 quads/批）
│   ├── TextureManager.h/cpp    # 纹理生命周期管理（load/unload/get）
│   ├── Camera2D.h/cpp          # 正交投影 + 视口变换
│   └── ShaderProgram.h/cpp     # shader 编译/链接/uniform 设置
├── platform/
│   ├── napi_init.cpp           # NAPI 模块注册、函数绑定
│   ├── napi_bridge.cpp         # DrawCmd 解析、ArkTS↔C++ 类型转换
│   └── stb_image.h             # PNG 解码（单头文件库，零依赖）
├── CMakeLists.txt
└── oh-package.json5
```

### SpriteBatcher 工作原理

1. 接收 DrawCmd 数组，按 `textureId` 排序
2. 每个 Sprite cmd → 4 个顶点（position + texcoord + color）写入 VBO
3. 纹理切换时 flush 一次 `glDrawElements`（画当前批次所有 quad）
4. 同一纹理的多个 sprite = 一次 OpenGL 调用
5. 最大 4096 quads/batch，超出自动分批

### Shader

```glsl
// Vertex Shader
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

// Fragment Shader
precision mediump float;
varying vec2 v_texCoord;
varying vec4 v_color;
uniform sampler2D u_texture;
uniform float u_useTexture;  // 0=纯色, 1=纹理采样

void main() {
  vec4 texColor = u_useTexture > 0.5 ? texture2D(u_texture, v_texCoord) : vec4(1.0);
  gl_FragColor = texColor * v_color;
}
```

### 纹理加载流程

```
ArkTS:
  1. getRawFileDescriptor("sprites/enemy_slime.png")
  2. fileIo.readSync(fd, buffer)        // 读入 ArrayBuffer
  3. nativeLoadTexture(id, buffer, w, h) // 通过 NAPI 传递

C++:
  4. stbi_load_from_memory(buffer)      // stb_image 解码 PNG → RGBA 像素
  5. glGenTextures → glBindTexture
  6. glTexImage2D(GL_TEXTURE_2D, ..., rgbaPixels)  // 上传到 GPU
  7. 设置过滤/环绕参数
```

## ArkTS 侧改动

### GameScene 重构

```typescript
Stack {                          // 层叠布局
  XComponent({                    // 底层：原生渲染
    type: 'surface',
    controller: xComponentController
  })

  HudOverlay() {                  // 顶层：ArkTS UI 覆盖层
    HealthBar()
    EnergyBar()
    Minimap()
    SkillButtons()
  }
}
```

### RenderSystem 改造

- 移除所有 Canvas/OffscreenCanvas 绘制代码
- 改为遍历渲染相关 Component（SpriteComp、TransformComp），生成 DrawCmd[]
- 每帧调用 `nativeSubmitCommands(cmds)`

### 现有 System 影响分析

| 类别 | System | 改动 |
|------|--------|------|
| 不变 | MovementSystem, CollisionSystem, EnemyAISystem, ChunkLoadSystem, DamageSystem, XpLevelSystem, EvolutionSystem, SaveLoadSystem, ChestSystem, MaterialDropSystem, TrapSystem, MechanismSystem, PlayerCombatSystem, BossSystem 等 (20+) | 纯逻辑，不涉及渲染 |
| 需改写 | PlayerRenderer, EnemyRenderer, BossRenderer | 从 Canvas 绘制改为生成 DrawCmd |
| 移除 | UIRenderer, 旧 Canvas 初始化代码 | HUD 移到 ArkTS UI 层 |

## 构建系统

### CMakeLists.txt 关键配置

- 目标：`libnative_renderer.so`（动态库）
- 链接库：`libEGL`, `libGLESv2`, `libace_napi.z`, `libhilog_ndk.z`
- stb_image 作为 header-only 包含
- C++ 标准：C++17

### 项目结构

```
entry/
├── src/main/
│   ├── ets/                     # ArkTS 代码
│   ├── cpp/                     # C++ 原生渲染层
│   │   ├── CMakeLists.txt
│   │   ├── renderer/
│   │   ├── platform/
│   │   └── third_party/stb/
│   └── rawfile/sprites/         # 精灵图（不变）
├── build-profile.json5          # 添加 cpp 构建配置
└── oh-package.json5

Engine/                          # HAR（大部分不变）
├── src/main/ets/
│   ├── ecs/                     # World, Entity, System, Component
│   ├── components/              # 21 个组件
│   ├── systems/                 # 内置系统
│   └── ...
└── oh-package.json5
```

## 测试策略

HarmonyOS 游戏无法跑传统单元测试，验证方式：

1. **编译验证**: `hvigorw assembleHap` 通过（ArkTS + C++ 编译成功）
2. **运行验证**: 部署到设备/模拟器，确认：
   - XComponent 正确创建 EGL 上下文
   - 清屏颜色可见（证明 OpenGL 工作）
   - 纹理加载成功（sprite 可见）
   - 帧率稳定 60fps
   - 触摸输入响应正常

## 技术约束

- HarmonyOS NEXT API 12（compatibleSdkVersion "5.0.0(12)"）
- OpenGL ES 2.0（不使用 3.0+ 特性，保证最大兼容性）
- stb_image.h 为唯一第三方依赖（public domain，零许可问题）
- C++ 代码必须通过 HarmonyOS NDK 编译（clang toolchain）
