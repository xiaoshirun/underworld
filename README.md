# 地下世界 (Underworld)

一款基于 HarmonyOS 的 2D 像素风格地牢探索游戏，使用 Canvas2D 全程序化渲染，无外部图片资源。采用自研 ECS（实体-组件-系统）架构引擎。

## 游戏特性

- **程序化世界生成** — 基于 Value Noise + FBM 的无限地牢，6 种生物群落（普通、水晶、蘑菇、水域、熔岩、暗影）
- **6 种史莱姆敌人** — 灰、紫、红、蓝、黄、幽灵，各有独特 AI 行为（巡逻、追击、吞噬、充能）
- **5 类 Boss** — 水晶守护者、蘑菇王、熔岩兽、深渊海妖、虚空裂隙，双阶段战斗
- **武器进化系统** — 6 种武器形态（刀刃、鞭、锤、法杖、双刃、巨斧），5 条进化路线（水晶、火焰、暗影、毒素、潮汐）
- **变身系统** — 4 种变身形态（史莱姆、幽灵、铠甲、钢铁侠），能量管理机制
- **陷阱与机关** — 6 种陷阱（地刺、落石、毒孢子、熔岩喷泉、虚空裂缝、水漩涡），6 种机关（压力板、拉杆、推块、水晶反射器、可破坏墙壁、传送符文）
- **宝箱系统** — 普通、精英、Boss 三种宝箱，精英宝箱需击败守卫
- **自动存档** — 基于 Preferences 的序列化存档，支持完整状态恢复

## 技术架构

### ECS 引擎

游戏构建在自研 ECS 引擎 (`@qiuyu/engine` HAR 模块) 之上：

```
Engine HAR（通用引擎）
  Engine → SceneManager → Scene → World → System[] → Entity[] + Component[]

Entry（游戏专用）
  Index.ets → Engine + GameScene
  GameScene → World + 19 Systems + 6 Renderers
  Factories → Entity + Component[]
```

**核心组件：**

| 模块 | 职责 |
|------|------|
| `World` | 实体管理、系统调度、空间索引 |
| `Entity` | 带 tag 标识的实体，组件容器 |
| `System` | 抽象基类，接收 SystemContext |
| `Scene` / `SceneManager` | 场景栈管理，BaseContext 上下文 |
| `SpatialGrid` | 空间哈希网格，碰撞查询加速 |
| `ResourceManager` | 异步资源加载、缓存、精灵表 |

### 游戏层

**19 个系统（按执行顺序）：**

1. SpatialRebuildSystem — 重建空间索引
2. ChunkLoadSystem — 区块加载/卸载
3. PlayerMovementSystem — 玩家移动、跳跃、冲刺、钻孔
4. PlayerCombatSystem — 攻击判定、武器形态
5. EnemyAISystem — 6 种史莱姆 AI
6. BossSystem — Boss AI + 阶段切换
7. TransformSystem — 变身逻辑
8. TrapSystem — 陷阱伤害
9. MechanismSystem — 机关交互
10. ChestSystem — 开箱
11. MaterialDropSystem — 材料拾取
12. XpLevelSystem — 经验升级
13. DamageSystem — 死亡检测
14. EvolutionSystem — 武器进化
15. CameraSystem — 相机跟随 + 震动
16. ParticleSystem — 粒子实体更新
17. AmbientParticleSystem — 环境粒子
18. SaveLoadSystem — 自动存档
19. CleanupSystem — 清理死亡实体

**6 个渲染器：** TileRenderer、EffectRenderer、EnemyRenderer、BossRenderer、PlayerRenderer、UIRenderer

**17 个游戏组件：** Movement、Combat、Transform、Inventory、Xp、Evolution、EnemyAI、BossAI、XpPickup、MaterialPickup、TransformCorePickup、Trap、Mechanism、Chest、Particle、Camera、GameState

**5 个实体工厂：** PlayerFactory、EnemyFactory、BossFactory、DropFactory、WorldEntityFactory

### 渲染与音频

- **Canvas2D 程序化渲染** — 所有角色、特效、地形均用 Canvas API 绘制，无外部图片依赖
- **程序化音频合成** — 10 种音效通过 Web Audio 合成，6 个 pooled AudioRenderer
- **粒子系统** — 5 种粒子形状，支持伤害、钻孔、拾取、环境等效果

## 技术栈

- **平台：** HarmonyOS (SDK 5.0.0+ / API 12+)
- **语言：** ArkTS strict mode (.ets)
- **渲染：** Canvas2D API
- **音频：** AudioKit (AudioRenderer)
- **存储：** Preferences API
- **构建：** hvigorw / DevEco Studio

## 项目结构

```
underworld/
├── Engine/                          # 通用 ECS 引擎 (HAR 模块)
│   └── src/main/ets/
│       ├── Engine.ets               # 引擎入口 + 主循环
│       ├── World.ets                # 实体管理 + 系统调度
│       ├── Entity.ets               # 实体类 (tag + components)
│       ├── Component.ets            # 基础组件 (Position, Velocity, Health...)
│       ├── System.ets               # System 基类 + SystemContext
│       ├── Scene.ets                # Scene 基类 + BaseContext
│       ├── SceneManager.ets         # 场景栈管理
│       ├── SpatialGrid.ets          # 空间哈希网格
│       ├── ResourceManager.ets      # 资源加载管理
│       └── index.ets                # 模块导出
│
├── entry/                           # 游戏入口模块
│   └── src/main/ets/
│       ├── pages/
│       │   ├── Index.ets            # 游戏主页面
│       │   ├── LoginPage.ets        # 登录页
│       │   └── CharacterSelectPage.ets  # 角色选择
│       └── game/
│           ├── GameScene.ets        # 游戏场景 (World + Systems + Renderers)
│           ├── GameConstants.ets    # 常量、枚举、类型定义
│           ├── WorldGenerator.ets   # 世界生成器
│           ├── PhysicsEngine.ets    # 物理引擎工具类
│           ├── ParticleSystem.ets   # 粒子管理器
│           ├── AudioManager.ets     # 音频合成服务
│           ├── SaveManager.ets      # 存档管理
│           ├── components/          # 17 个游戏组件
│           ├── systems/             # 19 个游戏系统
│           ├── factories/           # 5 个实体工厂
│           └── renderers/           # 6 个渲染器
│
├── docs/                            # 设计文档
│   └── superpowers/
│       ├── specs/                   # 设计规格
│       └── plans/                   # 实现计划
│
└── design/                          # 设计资源
```

## 构建与运行

### 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK 5.0.0 (API 12)
- HarmonyOS 设备或模拟器

### 构建步骤

1. 使用 DevEco Studio 打开项目
2. 等待依赖同步完成
3. 选择目标设备，点击 Run 运行

或使用命令行：

```bash
# 构建 HAP
hvigorw assembleHap --no-daemon

# 构建 Engine HAR
cd Engine
hvigorw assembleHar --no-daemon
```

## 开发状态

当前处于活跃开发阶段。核心 ECS 架构已完成迁移，游戏功能基本完整。

### 已完成

- ECS 引擎基础设施 (World/Entity/System/Component)
- 19 个游戏系统全部迁移至 ECS 架构
- 17 个游戏组件实现 Serializable 接口
- 5 个实体工厂
- 6 个渲染器改造为 World 查询模式
- 程序化世界生成 (6 生物群落)
- 6 种敌人 AI + 5 类 Boss
- 武器进化系统 (6 形态 × 5 路线)
- 变身系统 (4 种形态)
- 陷阱/机关/宝箱系统
- 自动存档

### 待完成

- 性能优化 (大量实体时的查询效率)
- 音效丰富度
- 更多生物群落和内容
- UI 美化
