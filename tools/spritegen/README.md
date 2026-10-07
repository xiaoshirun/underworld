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

产物（`entry/src/main/resources/rawfile/sprites/`，共 16 张）：

| 文件 | 尺寸 | 帧布局 |
| --- | --- | --- |
| `enemy_0..5_*.png` | 256×256 | 4×4，64px/帧，16 帧（0-7 弹跳，8-15 状态变体） |
| `enemy_6_humanoid_beast.png` | 256×256 | 4×4，64px/帧，16 帧（0-7 弹跳，8-15 白闪） |
| `boss_0..4_*.png` | 512×384 | 4×3，128px/帧，12 帧（11 游戏帧/精灵帧） |
| `player_human.png` | 256×192 | 4×3，64px/帧，10 帧（idle R/L + walk 4相位×2方向，行主序） |
| `player_slime.png` | 256×256 | 4×4，64px/帧，16 帧（8 相位 × 朝向 2 行组） |
| `weapons.png` | 192×128 | 3×2，64px/帧，6 帧（WeaponForm 行主序） |
| `attack_fx.png` | 384×384 | 6×6，64px/帧，36 帧（form × 6 进度步，`form * 6 + step`） |

同时生成 `preview.html`（base64 内嵌预览，可直接在浏览器打开检查）。

## 工作原理

1. `typescript@5` 把 `entry/src/main/ets/game` 下的源码转译为 CommonJS（不做类型检查）。
2. 用 `@napi-rs/canvas` 垫片替换 `OffscreenCanvas`，直接调用游戏同款绘制函数：
   - `generateEnemyAtlas` / `generateBossAtlas`（含 `drawHumanoidBeast` 共享模块）
   - `generatePlayerCache`（人形态逐帧）
   - `drawPlayerSlimeBody` / `drawWeaponIcon` / `drawAttackSlash`（共享绘制模块）
3. `BossAIComponent` 打桩（boss 绘制函数不读取 `ai` 参数），避免引入 engine HAR 依赖。

## 运行时接入

`SpriteManager.generateAll(harmonyContext)` 在程序化生成之后尝试用 rawfile PNG
覆盖 atlas；任何一张缺失/解码失败都会保留该图的程序化结果（逐张 fallback）。
文件名改动需同步 `SpriteManager.ets` 顶部的 `*_SHEET_FILE` 常量。

当前消费情况：
- 敌人 7 张 + Boss 5 张 → `EnemyRenderer` / `BossRenderer` 经 atlas 直接消费
- `player_human.png` → 切片进 `playerCache`（逐帧 SpriteCache，key 与生成器一致）
- `player_slime.png` / `weapons.png` / `attack_fx.png` → `getPlayerSlimeAtlas` /
  `getWeaponAtlas` / `getAttackFxAtlas` 就绪；游戏内玩家史莱姆与武器走
  **同源程序化共享模块**（`PlayerSlimeSprite` / `AttackFxSprite` 等），
  `WeaponRenderer.renderWeaponAttackEffect` 已叠加 `drawAttackSlash` 挥砍月牙，
  动态表情/朝向耦合部分不适合静态表，PNG 作为素材库存保留。

## 修改了绘制代码？

重新 `npm run generate` 即可刷新素材——素材永远跟随源码。
