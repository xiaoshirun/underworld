'use strict';

/**
 * generate.js — 把游戏内的 .ets 程序化绘制代码渲染成 PNG 精灵图表。
 *
 * 原理：
 *   1. 用 TypeScript 编译器把 entry/src/main/ets/game 下的生成器源码转译成 CommonJS
 *      （只做语法降级、不做类型检查，所以 .ets 与 .ts 语法差异不影响）。
 *   2. 提供 OffscreenCanvas 垫片（映射到 @napi-rs/canvas），
 *      直接调用游戏同款 generateEnemyAtlas / generateBossAtlas。
 *   3. 把每个 atlas 的画布编码为 PNG 写入 rawfile/sprites/。
 *
 * 因此生成的素材与游戏内程序化渲染逐像素同源（帧布局、动画相位完全一致）。
 *
 * 用法：node generate.js   （或 npm run generate）
 */

const fs = require('fs');
const path = require('path');
const ts = require('typescript');
const { createCanvas } = require('@napi-rs/canvas');

const ROOT = path.resolve(__dirname, '..', '..');
const GAME = path.join(ROOT, 'entry', 'src', 'main', 'ets', 'game');
const DIST = path.join(__dirname, 'dist');
const OUT = path.join(ROOT, 'entry', 'src', 'main', 'resources', 'rawfile', 'sprites');

// ---------- 1. 转译 .ets → .js（保持相对导入结构） ----------

const SOURCES = [
  'GameConstants.ets',
  'sprites/SpriteAtlas.ets',
  'sprites/SpriteCache.ets',
  'sprites/TileSprite.ets',
  'sprites/EnemySpriteGenerator.ets',
  'sprites/BossSpriteGenerator.ets',
  'sprites/PlayerSpriteGenerator.ets'
];

function transpile(rel) {
  const srcPath = path.join(GAME, rel);
  const source = fs.readFileSync(srcPath, 'utf8');
  const out = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020
    },
    fileName: srcPath.replace(/\.ets$/, '.ts')
  }).outputText;
  const dest = path.join(DIST, 'game', rel.replace(/\.ets$/, '.js'));
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, out);
  console.log('[transpile]', rel, '->', path.relative(ROOT, dest));
}

SOURCES.forEach(transpile);

// BossAIComponent 依赖 engine HAR，打桩即可（boss 绘制函数不读取 ai 参数）
const stubDir = path.join(DIST, 'game', 'components');
fs.mkdirSync(stubDir, { recursive: true });
fs.writeFileSync(
  path.join(stubDir, 'BossAIComponent.js'),
  'class BossAIComponent {\n  constructor() {\n    this.bossType = 0;\n    this.phase = 0;\n  }\n}\nexports.BossAIComponent = BossAIComponent;\n'
);

// ---------- 2. OffscreenCanvas 垫片 ----------

globalThis.OffscreenCanvas = class OffscreenCanvas {
  constructor(w, h) {
    this.width = w;
    this.height = h;
    this._canvas = createCanvas(w, h);
  }
  getContext(type) {
    return this._canvas.getContext(type);
  }
  transferToImageBitmap() {
    // Keep the drawable canvas reachable so sheet assembly can
    // drawImage(bitmap._canvas, ...) like the runtime ImageBitmap path.
    return { width: this.width, height: this.height, _canvas: this._canvas };
  }
  toBuffer(mime) {
    return this._canvas.toBuffer(mime);
  }
};

const { generateEnemyAtlas } = require(path.join(DIST, 'game', 'sprites', 'EnemySpriteGenerator.js'));
const { generateBossAtlas } = require(path.join(DIST, 'game', 'sprites', 'BossSpriteGenerator.js'));
const { generatePlayerCache } = require(path.join(DIST, 'game', 'sprites', 'PlayerSpriteGenerator.js'));
const {
  drawWallBase, drawWallOre, drawWallGrassEdge, drawWallVines,
  drawFloorBase, drawFloorDirtEdge, drawFloorStalactites, drawFloorStalagmites,
  drawBrokenWallTile, drawGlowStoneTile, drawPlantTile, drawCrystalTile,
  drawMushroomTile, drawWaterTile, drawLavaTile
} = require(path.join(DIST, 'game', 'sprites', 'TileSprite.js'));

// ---------- 3. 渲染并写 PNG ----------

const ENEMY_NAMES = ['gray_slime', 'purple_slime', 'red_slime', 'blue_slime', 'yellow_slime', 'ghost_slime'];
const BOSS_NAMES = ['crystal_guardian', 'mushroom_king', 'lava_beast', 'abyss_siren', 'void_rift'];

function pngSize(buf) {
  // IHDR: width @16..19, height @20..23 (big-endian)
  return {
    w: buf.readUInt32BE(16),
    h: buf.readUInt32BE(20)
  };
}

function writeSheet(file, atlas) {
  const buf = atlas.canvas.toBuffer('image/png');
  fs.writeFileSync(file, buf);
  const s = pngSize(buf);
  console.log(
    '[png]',
    path.relative(ROOT, file),
    `${s.w}x${s.h}`,
    `${atlas.frameCount} frames (${atlas.cellW}x${atlas.cellH} cell)`,
    `${(buf.length / 1024).toFixed(1)} KB`
  );
}

fs.mkdirSync(OUT, { recursive: true });

const t0 = Date.now();

for (let t = 0; t < ENEMY_NAMES.length; t++) {
  const atlas = generateEnemyAtlas(t);
  writeSheet(path.join(OUT, `enemy_${t}_${ENEMY_NAMES[t]}.png`), atlas);
}

for (let t = 0; t < BOSS_NAMES.length; t++) {
  const atlas = generateBossAtlas(t);
  writeSheet(path.join(OUT, `boss_${t}_${BOSS_NAMES[t]}.png`), atlas);
}

// Player human-form sheet: 10 frames, 4 cols x 3 rows, 64px cells.
// Row-major order must match SpriteManager.PLAYER_SHEET_KEYS.
const PLAYER_KEYS = [
  'body_idle_R', 'body_idle_L',
  'body_walk_R_0', 'body_walk_R_1', 'body_walk_R_2', 'body_walk_R_3',
  'body_walk_L_0', 'body_walk_L_1', 'body_walk_L_2', 'body_walk_L_3'
];
const P_CELL = 64;
const P_COLS = 4;
const P_ROWS = Math.ceil(PLAYER_KEYS.length / P_COLS);
const playerCache = generatePlayerCache();
const playerSheet = createCanvas(P_COLS * P_CELL, P_ROWS * P_CELL);
const pctx = playerSheet.getContext('2d');
PLAYER_KEYS.forEach((key, i) => {
  const frame = playerCache.get(key);
  if (frame === undefined) throw new Error('missing player frame: ' + key);
  pctx.drawImage(frame._canvas, (i % P_COLS) * P_CELL, Math.floor(i / P_COLS) * P_CELL);
});
const playerBuf = playerSheet.toBuffer('image/png');
const playerFile = path.join(OUT, 'player_human.png');
fs.writeFileSync(playerFile, playerBuf);
console.log(
  '[png]', path.relative(ROOT, playerFile),
  `${P_COLS * P_CELL}x${P_ROWS * P_CELL}`,
  `${PLAYER_KEYS.length} frames (${P_CELL}x${P_CELL} cell)`,
  `${(playerBuf.length / 1024).toFixed(1)} KB`
);

// Tile sheet: 8x8 grid, 32px cells (1 cell = 1 in-game tile), mirrors GameEngine's
// static-layer + dynamic-tile recipes via TileSprite.ets:
//   row 0: wall plain brick — normal hash0-3 (c0-3) / shadow hash0-3 (c4-7)
//   row 1: wall ore veins — copper/iron/silver/gold normal (c0-3) / shadow (c4-7)
//   row 2: hanging vines — v0-v4 normal (c0-4) / v0-v2 shadow (c5-7)
//   row 3: vines v3-v4 shadow (c0-1), grass edge N/S (c2-3), plain floor N/S (c4-5), dirt-edge floor N/S (c6-7)
//   row 4: floor stalactites st0-4 (c0-4), stalagmites sm0-2 (c5-7)
//   row 5: stalagmites sm3-4 (c0-1), broken wall, glow stone x2 phases, plant, crystal, mushroom (c2-7)
//   row 6: water — deep p0-2 (c0-2), surface p0-2 (c3-5)
//   row 7: lava — deep p0-2 (c0-2), surface p0-2 (c3-5)
const T_CELL = 32;
const tileSheet = createCanvas(8 * T_CELL, 8 * T_CELL);
const tctx = tileSheet.getContext('2d');

function tileAt(col, row) {
  tctx.save();
  tctx.translate(col * T_CELL, row * T_CELL);
  return () => tctx.restore();
}

// -- row 0: wall plain brick, 4 hash variants per theme --
for (let h = 0; h < 4; h++) {
  const tx = 3 + h * 17, ty = 11 + h * 7;
  let done = tileAt(h, 0);
  drawWallBase(tctx, tx, ty, false);
  done();
  done = tileAt(4 + h, 0);
  drawWallBase(tctx, tx, ty, true);
  done();
}
// -- row 1: wall ore veins (tx/ty = hash 0 so vein placement is deterministic) --
for (let ore = 0; ore < 4; ore++) {
  let done = tileAt(ore, 1);
  drawWallBase(tctx, 7, 13, false);
  drawWallOre(tctx, ore);
  done();
  done = tileAt(4 + ore, 1);
  drawWallBase(tctx, 7, 13, true);
  drawWallOre(tctx, ore);
  done();
}
// -- row 2 + row 3 c0-1: hanging vines (tx/ty = hash 1: no noise overlap) --
for (let v = 0; v < 5; v++) {
  const done = tileAt(v, 2);
  drawWallBase(tctx, 10, 3, false);
  drawWallVines(tctx, v, false);
  done();
}
for (let v = 0; v < 5; v++) {
  const cell = v < 3 ? [5 + v, 2] : [v - 3, 3];
  const done = tileAt(cell[0], cell[1]);
  drawWallBase(tctx, 10, 3, true);
  drawWallVines(tctx, v, true);
  done();
}
// -- row 3 c2-3: wall grass edge (floor below) --
{
  let done = tileAt(2, 3);
  drawWallBase(tctx, 13, 7, false);
  drawWallGrassEdge(tctx, false);
  done();
  done = tileAt(3, 3);
  drawWallBase(tctx, 13, 7, true);
  drawWallGrassEdge(tctx, true);
  done();
}
// -- row 3 c4-5: plain floor; c6-7: floor with dirt edge (wall above) --
{
  let done = tileAt(4, 3);
  drawFloorBase(tctx, 5, 3, false);
  done();
  done = tileAt(5, 3);
  drawFloorBase(tctx, 5, 3, true);
  done();
  done = tileAt(6, 3);
  drawFloorBase(tctx, 5, 3, false);
  drawFloorDirtEdge(tctx, false);
  done();
  done = tileAt(7, 3);
  drawFloorBase(tctx, 5, 3, true);
  drawFloorDirtEdge(tctx, true);
  done();
}
// -- row 4: stalactites st0-4 (c0-4), stalagmites sm0-2 (c5-7) --
for (let st = 0; st < 5; st++) {
  const done = tileAt(st, 4);
  drawFloorBase(tctx, 9 + st * 13, 11, false);  // hash 2: no pebbles overlap
  drawFloorStalactites(tctx, st, false);
  done();
}
for (let sm = 0; sm < 3; sm++) {
  const done = tileAt(5 + sm, 4);
  drawFloorBase(tctx, 3 + sm * 7, 5, false);
  drawFloorStalagmites(tctx, sm, false);
  done();
}
// -- row 5: stalagmites sm3-4 (c0-1) + specials (c2-7) --
for (let sm = 3; sm < 5; sm++) {
  const done = tileAt(sm - 3, 5);
  drawFloorBase(tctx, 3 + sm * 7, 5, false);
  drawFloorStalagmites(tctx, sm, false);
  done();
}
{
  const done = tileAt(2, 5);
  drawBrokenWallTile(tctx);
  done();
}
for (let ph = 0; ph < 2; ph++) {
  const done = tileAt(3 + ph, 5);
  drawGlowStoneTile(tctx, false, ph * Math.PI * 2 / 12 + 1);
  done();
}
{
  const done = tileAt(5, 5);
  drawPlantTile(tctx, false);
  done();
}
{
  const done = tileAt(6, 5);
  drawCrystalTile(tctx, 0.8);
  done();
}
{
  const done = tileAt(7, 5);
  drawMushroomTile(tctx);
  done();
}
// -- row 6: water (deep c0-2 / surface c3-5); row 7: lava (same split) --
for (let p = 0; p < 6; p++) {
  const done = tileAt(p % 8, 6);
  drawWaterTile(tctx, 5, (p % 3) * 20, p >= 3);
  done();
}
for (let p = 0; p < 6; p++) {
  const done = tileAt(p % 8, 7);
  drawLavaTile(tctx, 3, (p % 3) * 20, p >= 3);
  done();
}
const tileBuf = tileSheet.toBuffer('image/png');
fs.writeFileSync(path.join(OUT, 'tiles.png'), tileBuf);
console.log('[png]', path.relative(ROOT, path.join(OUT, 'tiles.png')),
  '256x256', '60 tiles (32x32 cell = 1 in-game tile)', `${(tileBuf.length / 1024).toFixed(1)} KB`);

console.log(`[done] ${ENEMY_NAMES.length + BOSS_NAMES.length + 2} sheets in ${Date.now() - t0}ms -> ${path.relative(ROOT, OUT)}`);

// ---------- 4. 生成可视化预览（base64 内嵌，Preview 静态服务仅放行单文件） ----------

function card(cls, file, caption) {
  const b64 = fs.readFileSync(file).toString('base64');
  return `<div class="card ${cls}"><img src="data:image/png;base64,${b64}"><div class="cap">${caption}</div></div>`;
}

const enemyCards = ENEMY_NAMES.map((n, i) =>
  card('e', path.join(OUT, `enemy_${i}_${n}.png`), `${i} ${n}`)).join('\n');
const bossCards = BOSS_NAMES.map((n, i) =>
  card('b', path.join(OUT, `boss_${i}_${n}.png`), `${i} ${n}`)).join('\n');
const playerCard = card('p', path.join(OUT, 'player_human.png'), 'player_human · 10 帧（idle R/L + walk 4相位×2方向）');
const tileCard = card('t', path.join(OUT, 'tiles.png'), 'tiles · 60 格（32px = 1 游戏瓦片：砖墙/矿石/藤蔓/草边/地板/钟乳石/碎石/荧光石/水晶/蘑菇/水/熔岩）');

const html = `<!DOCTYPE html>
<html lang="zh"><head><meta charset="utf-8"><title>Sprite Sheet Preview</title>
<style>
  body { background:#1a1a2e; color:#e2e8f0; font-family:monospace; margin:16px; }
  h1 { font-size:18px; } h2 { font-size:15px; margin:18px 0 6px; color:#7dd3fc; }
  .row { display:flex; flex-wrap:wrap; gap:12px; }
  .card { background:#0f172a; border:1px solid #334155; border-radius:6px; padding:8px; }
  .card img { display:block; image-rendering:pixelated; }
  .card .cap { font-size:11px; color:#94a3b8; margin-top:6px; text-align:center; }
  .e img { width:256px; height:256px; }
  .b img { width:512px; height:384px; }
  .p img { width:512px; height:384px; }
  .t img { width:512px; height:512px; image-rendering:auto; }
</style></head><body>
<h1>rawfile/sprites 生成结果</h1>
<h2>玩家（1 张 · 256×192 · 4×3 · 64px/帧 · 10 帧）</h2>
<div class="row">${playerCard}</div>
<h2>瓦片（1 张 · 256×256 · 8×8 · 32px/格 = 1 游戏瓦片 · 60 格）</h2>
<div class="row">${tileCard}</div>
<h2>敌人（6 张 · 256×256 · 4×4 · 64px/帧 · 16 帧：0-7 弹跳 / 8-15 状态变体）</h2>
<div class="row">${enemyCards}</div>
<h2>Boss（5 张 · 512×384 · 4×3 · 128px/帧 · 12 帧动画）</h2>
<div class="row">${bossCards}</div>
</body></html>`;

const previewFile = path.join(__dirname, 'preview.html');
fs.writeFileSync(previewFile, html);
console.log('[preview]', path.relative(ROOT, previewFile));
