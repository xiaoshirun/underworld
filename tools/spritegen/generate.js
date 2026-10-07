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
  'sprites/ColorUtils.ets',
  'sprites/SpriteAtlas.ets',
  'sprites/SpriteCache.ets',
  'sprites/PlayerSlimeSprite.ets',
  'sprites/HumanoidBeastSprite.ets',
  'sprites/WeaponSprite.ets',
  'sprites/AttackFxSprite.ets',
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
const { drawPlayerSlimeBody } = require(path.join(DIST, 'game', 'sprites', 'PlayerSlimeSprite.js'));
const { drawWeaponIcon } = require(path.join(DIST, 'game', 'sprites', 'WeaponSprite.js'));
const { drawAttackSlash } = require(path.join(DIST, 'game', 'sprites', 'AttackFxSprite.js'));

// ---------- 3. 渲染并写 PNG ----------

const ENEMY_NAMES = ['gray_slime', 'purple_slime', 'red_slime', 'blue_slime', 'yellow_slime', 'ghost_slime', 'humanoid_beast'];
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

// Player blue-slime sheet: 16 frames, 4 cols x 4 rows, 64px cells.
// Frames 0-7 face right, 8-15 face left (native mirrored face, no flip needed).
const S_CELL = 64;
const slimeSheet = createCanvas(4 * S_CELL, 4 * S_CELL);
const sctx = slimeSheet.getContext('2d');
for (let i = 0; i < 16; i++) {
  const facingRight = i < 8;
  const phase = (i % 8) * (Math.PI * 2 / 8);
  const cx = (i % 4) * S_CELL + S_CELL / 2;
  const cy = Math.floor(i / 4) * S_CELL + S_CELL / 2;
  const squish = Math.sin(phase) * 0.8;
  const bodyW = 12 + squish;
  const bodyH = 10 - squish * 0.5;
  const bob = Math.cos(phase) * 1.5;
  // Shadow — mirrors PlayerRenderer.renderSlimeBody
  sctx.globalAlpha = 0.25;
  sctx.fillStyle = '#000000';
  sctx.beginPath();
  sctx.ellipse(cx, cy + bodyH * 0.5 + bob, bodyW * 0.6, 3, 0, 0, Math.PI * 2);
  sctx.fill();
  sctx.globalAlpha = 1.0;
  drawPlayerSlimeBody(sctx, cx, cy + bob, bodyW, bodyH, facingRight);
}
const slimeBuf = slimeSheet.toBuffer('image/png');
fs.writeFileSync(path.join(OUT, 'player_slime.png'), slimeBuf);
console.log('[png]', path.relative(ROOT, path.join(OUT, 'player_slime.png')),
  '256x256', `16 frames (${S_CELL}x${S_CELL} cell)`, `${(slimeBuf.length / 1024).toFixed(1)} KB`);

// Weapon icons: 6 frames, 3 cols x 2 rows (SpriteAtlas grid formula), row-major by WeaponForm
const W_CELL = 64;
const weaponSheet = createCanvas(3 * W_CELL, 2 * W_CELL);
const wctx = weaponSheet.getContext('2d');
for (let form = 0; form < 6; form++) {
  const col = form % 3;
  const row = Math.floor(form / 3);
  drawWeaponIcon(wctx, form, col * W_CELL + W_CELL / 2, row * W_CELL + W_CELL / 2, 1.15);
}
const weaponBuf = weaponSheet.toBuffer('image/png');
fs.writeFileSync(path.join(OUT, 'weapons.png'), weaponBuf);
console.log('[png]', path.relative(ROOT, path.join(OUT, 'weapons.png')),
  '192x128', '6 frames (64x64 cell)', `${(weaponBuf.length / 1024).toFixed(1)} KB`);

// Attack slash fx: 36 frames = 6 forms x 6 progress steps, 6x6 grid
const F_CELL = 64;
const fxSheet = createCanvas(6 * F_CELL, 6 * F_CELL);
const fctx = fxSheet.getContext('2d');
for (let form = 0; form < 6; form++) {
  for (let step = 0; step < 6; step++) {
    const idx = form * 6 + step;
    const col = idx % 6;
    const row = Math.floor(idx / 6);
    drawAttackSlash(fctx, form, (step + 0.5) / 6,
      col * F_CELL + F_CELL / 2, row * F_CELL + F_CELL / 2, 1);
  }
}
const fxBuf = fxSheet.toBuffer('image/png');
fs.writeFileSync(path.join(OUT, 'attack_fx.png'), fxBuf);
console.log('[png]', path.relative(ROOT, path.join(OUT, 'attack_fx.png')),
  '384x384', '36 frames (64x64 cell)', `${(fxBuf.length / 1024).toFixed(1)} KB`);

console.log(`[done] ${ENEMY_NAMES.length + BOSS_NAMES.length + 4} sheets in ${Date.now() - t0}ms -> ${path.relative(ROOT, OUT)}`);

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
const playerSlimeCard = card('s', path.join(OUT, 'player_slime.png'), 'player_slime · 16 帧（0-7 朝右 / 8-15 朝左弹跳）');
const weaponCard = card('w', path.join(OUT, 'weapons.png'), 'weapons · 6 帧（WeaponForm 行主序）');
const attackFxCard = card('f', path.join(OUT, 'attack_fx.png'), 'attack_fx · 36 帧（6 武器 × 6 进度，每行一种武器）');

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
  .s img { width:256px; height:256px; }
  .w img { width:384px; height:256px; }
  .f img { width:384px; height:384px; }
</style></head><body>
<h1>rawfile/sprites 生成结果</h1>
<h2>玩家（1 张 · 256×192 · 4×3 · 64px/帧 · 10 帧）</h2>
<div class="row">${playerCard}</div>
<h2>玩家史莱姆（1 张 · 256×256 · 4×4 · 64px/帧 · 16 帧）</h2>
<div class="row">${playerSlimeCard}</div>
<h2>武器（1 张 · 192×128 · 3×2 · 64px/帧 · 6 帧）</h2>
<div class="row">${weaponCard}</div>
<h2>攻击特效（1 张 · 384×384 · 6×6 · 64px/帧 · 36 帧 = 6 武器 × 6 进度）</h2>
<div class="row">${attackFxCard}</div>
<h2>敌人（7 张 · 256×256 · 4×4 · 64px/帧 · 16 帧：0-7 弹跳 / 8-15 状态变体）</h2>
<div class="row">${enemyCards}</div>
<h2>Boss（5 张 · 512×384 · 4×3 · 128px/帧 · 12 帧动画）</h2>
<div class="row">${bossCards}</div>
</body></html>`;

const previewFile = path.join(__dirname, 'preview.html');
fs.writeFileSync(previewFile, html);
console.log('[preview]', path.relative(ROOT, previewFile));
