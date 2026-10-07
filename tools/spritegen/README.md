# spritegen — 从游戏源码渲染 PNG 精灵图

ImageGen 不可用时的素材生成方案：直接**转译游戏内的 `.ets` 程序化绘制代码**在 Node 里渲染，
因此产出的 PNG 与游戏内程序化渲染**逐像素同源**（帧布局、动画相位、配色完全一致）。

## 用法

```bash
cd tools/spritegen
npm install        # 首次
npm run generate   # 生成全部精灵图表
node typecheck.js  # 对改动过的游戏源码做真类型检查（TS 全量诊断）
```

产物（`entry/src/main/resources/rawfile/sprites/`，共 13 张）：

| 文件 | 尺寸 | 帧布局 |
| --- | --- | --- |
| `tiles.png` | 256×256 | 8×8，32px/格 = 1 游戏瓦片，60 格：砖墙（含 4 矿种×双主题）、藤蔓、草边、地板（素/土边/钟乳石/石笋）、碎石墙、荧光石、植物、水晶、蘑菇、水/熔岩各 6 相位（深/表层） |
| `enemy_0..5_*.png` | 256×256 | 4×4，64px/帧，16 帧（0-7 弹跳，8-15 状态变体） |
| `boss_0..4_*.png` | 512×384 | 4×3，128px/帧，12 帧（11 游戏帧/精灵帧） |
| `player_human.png` | 256×192 | 4×3，64px/帧，10 帧（idle R/L + walk 4相位×2方向，行主序） |

同时生成 `preview.html`（base64 内嵌预览，可直接在浏览器打开检查）。

## tiles.png 布局

| 行 | 内容 |
| --- | --- |
| 0 | 砖墙 ×8（普通 hash0-3 / 暗影 hash0-3） |
| 1 | 矿石墙 ×8（铜/铁/银/金 × 普通/暗影） |
| 2 | 悬挂藤蔓 v0-v4 普通（c0-4）+ v0-v2 暗影（c5-7） |
| 3 | 藤蔓 v3-v4 暗影、草边墙 N/S、素地板 N/S、土边地板 N/S |
| 4 | 钟乳石 st0-4（c0-4）+ 石笋 sm0-2（c5-7） |
| 5 | 石笋 sm3-4、碎石墙、荧光石×2 相位、植物、水晶、蘑菇 |
| 6 | 水 ×6（深水 p0-2 / 表面 p0-2） |
| 7 | 熔岩 ×6（深层 p0-2 / 表面 p0-2） |

每个绘制函数对应 `sprites/TileSprite.ets` 的一个导出，绘制指令与
`GameEngine.renderChunkStaticLayer` / `renderWorld` 的瓦片分支逐条一致。

## 工作原理

1. `typescript@5` 把 `entry/src/main/ets/game` 下的源码转译为 CommonJS（不做类型检查）。
2. 用 `@napi-rs/canvas` 垫片替换 `OffscreenCanvas`（`transferToImageBitmap` 保留可绘制
   canvas 供拼表），直接调用游戏同款绘制函数：
   `generateEnemyAtlas` / `generateBossAtlas` / `generatePlayerCache` / `TileSprite.*`。
3. `BossAIComponent` 打桩（boss 绘制函数不读取 `ai` 参数），避免引入 engine HAR 依赖。

## 运行时接入

当前 GameEngine 的瓦片渲染走 **chunkCanvasCache 烘焙路径**
（`renderChunkStaticLayer` 以 fillRect 色块把静态瓦片烘焙成每区块一张
ImageBitmap，动态瓦片水/熔岩/水晶等逐帧绘制），性能上无需贴图。
`tiles.png` 与 `TileSprite.ets` 作为同源素材库存备用；若未来要接入贴图，
应替换的是烘焙层内部的绘制（保持 ImageBitmap 缓存结构不变），而不是改成逐帧贴图。

其它消费情况：
- 敌人 6 张 + Boss 5 张 → atlas 格式，接入方式见 `SpriteManager`
- `player_human.png` → 10 帧，key 约定见 `PlayerSpriteGenerator`

## 修改了绘制代码？

重新 `npm run generate` 即可刷新素材——素材永远跟随源码。
