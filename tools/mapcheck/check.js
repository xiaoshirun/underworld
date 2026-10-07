'use strict';

/**
 * check.js — 用真实游戏代码离线验证"地图是否正常加载"。
 *
 * 原理：
 *   1. 转译引擎核心（World/Entity/System…）与游戏侧
 *      WorldGenerator / ChunkLoadSystem / PlayerMovementSystem / factories / TileRenderer
 *      到 CommonJS，@qiuyu/engine 用 node_modules 垫片指向转译产物。
 *   2. 模拟游戏帧循环：玩家按摇杆输入游走（卡墙自动换向），
 *      每帧跑 PlayerMovementSystem + ChunkLoadSystem + CameraSystem——
 *      与真机完全同一套加载代码（含每帧最多 2 个区块的限流）。
 *   3. 结构校验：
 *      A. 出生点区域已清空且可达（BFS 连通面积）
 *      B. 区块数量按限流增长、沿路径持续加载
 *      C. 相邻区块边界瓦片一致性（噪声按世界坐标采样，应 100% 对齐）
 *      D. 敌人/宝箱/陷阱/机关/Boss 实体在区块范围内生成
 *      E. 用游戏同款 TileRenderer 渲染多个视口出 PNG 报告
 *
 * 用法：node check.js   （产物写入 tools/mapcheck/report.html）
 */

const fs = require('fs');
const path = require('path');
const ts = require('typescript');
const { createCanvas } = require('@napi-rs/canvas');

const ROOT = path.resolve(__dirname, '..', '..');
const GAME = path.join(ROOT, 'entry', 'src', 'main', 'ets', 'game');
const ENGINE = path.join(ROOT, 'Engine', 'src', 'main', 'ets');
const DIST = path.join(__dirname, 'dist');
const OUT = path.join(__dirname, 'out');

// ---------- 1. 转译 ----------

const ENGINE_SOURCES = ['Component.ets', 'Entity.ets', 'System.ets', 'Scene.ets', 'World.ets', 'SpatialGrid.ets'];
const GAME_SOURCES = [
  'GameConstants.ets',
  'WorldGenerator.ets',
  'interfaces/IAudioService.ets',
  'components/CameraComponent.ets',
  'components/EnemyAIComponent.ets',
  'components/TrapComponent.ets',
  'components/MechanismComponent.ets',
  'components/ChestComponent.ets',
  'components/BossAIComponent.ets',
  'components/MovementComponent.ets',
  'components/CombatComponent.ets',
  'components/TransformComponent.ets',
  'components/InventoryComponent.ets',
  'components/XpComponent.ets',
  'components/EvolutionComponent.ets',
  'components/LevelComponent.ets',
  'components/SkillComponent.ets',
  'components/DevourComponent.ets',
  'components/HumanFormComponent.ets',
  'factories/EnemyFactory.ets',
  'factories/WorldEntityFactory.ets',
  'factories/BossFactory.ets',
  'factories/PlayerFactory.ets',
  'systems/MonsterLevelSystem.ets',
  'systems/HumanoidBeastSystem.ets',
  'systems/ChunkLoadSystem.ets',
  'systems/PlayerMovementSystem.ets',
  'systems/CameraSystem.ets',
  'helpers/SystemHelpers.ets',
  'renderers/TileRenderer.ets'
];

function transpile(absPath, relOut) {
  const source = fs.readFileSync(absPath, 'utf8');
  const out = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
    fileName: absPath.replace(/\.ets$/, '.ts')
  }).outputText;
  const dest = path.join(DIST, relOut.replace(/\.ets$/, '.js'));
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, out);
}

fs.rmSync(DIST, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

ENGINE_SOURCES.forEach((rel) => transpile(path.join(ENGINE, rel), path.join('engine', rel)));
GAME_SOURCES.forEach((rel) => transpile(path.join(GAME, rel), path.join('game', rel)));

// ResourceManager 依赖 @kit.ImageKit，引擎垫片用不到 → 打桩
fs.writeFileSync(
  path.join(DIST, 'engine', 'ResourceManager.js'),
  'class ResourceManager {}\nclass SpriteSheet {}\nclass RawFileProvider {}\n' +
  'module.exports = { ResourceManager, SpriteSheet, RawFileProvider };\n'
);

// @qiuyu/engine 垫片：指向转译后的引擎产物。
// 注意用绝对路径——mapcheck 的 node_modules 是指向 spritegen 的 junction，
// 相对路径会落错目录。
const shimDir = path.join(__dirname, 'node_modules', '@qiuyu', 'engine');
fs.mkdirSync(shimDir, { recursive: true });
fs.writeFileSync(path.join(shimDir, 'package.json'), JSON.stringify({ name: '@qiuyu/engine', main: 'index.js' }));
const engineParts = ['Component', 'Entity', 'System', 'Scene', 'World', 'SpatialGrid', 'ResourceManager'];
fs.writeFileSync(path.join(shimDir, 'index.js'),
  'module.exports = Object.assign({},\n' +
  engineParts.map((p) => '  require(' + JSON.stringify(path.join(DIST, 'engine', p + '.js')) + ')')
    .join(',\n') + '\n);\n');

console.log('[transpile] engine x' + ENGINE_SOURCES.length + ', game x' + GAME_SOURCES.length);

// ---------- 2. 模拟游戏帧循环 ----------

const {
  World, Entity, PositionComponent,
} = require('@qiuyu/engine');
const {
  TILE_SIZE, CHUNK_SIZE, CHUNK_LOAD_RADIUS, TileType,
} = require(path.join(DIST, 'game', 'GameConstants.js'));
const { WorldGenerator } = require(path.join(DIST, 'game', 'WorldGenerator.js'));
const { PlayerFactory } = require(path.join(DIST, 'game', 'factories', 'PlayerFactory.js'));
const { PlayerMovementSystem } = require(path.join(DIST, 'game', 'systems', 'PlayerMovementSystem.js'));
const { ChunkLoadSystem } = require(path.join(DIST, 'game', 'systems', 'ChunkLoadSystem.js'));
const { CameraSystem } = require(path.join(DIST, 'game', 'systems', 'CameraSystem.js'));
const { TileRenderer } = require(path.join(DIST, 'game', 'renderers', 'TileRenderer.js'));

const SCREEN_W = 780;
const SCREEN_H = 360; // 横屏锁定后的尺寸（与 Index.ets 修复一致）
const DT = 33;
const SIM_FRAMES = 900;

// 无音频副作用
const audioStub = new Proxy({}, { get: () => () => {} });

const world = new World();
const worldGen = new WorldGenerator();
world.worldGen = worldGen;

const startX = (CHUNK_SIZE * TILE_SIZE) / 2;
const startY = (CHUNK_SIZE * TILE_SIZE) / 2;
world.addEntity(PlayerFactory.create(startX, startY));

const cameraEntity = new Entity('camera');
world.addEntity(cameraEntity);
const cameraComp = new (require(path.join(DIST, 'game', 'components', 'CameraComponent.js')).CameraComponent)();
cameraEntity.addComponent(cameraComp);

const movementSystem = new PlayerMovementSystem();
const chunkLoadSystem = new ChunkLoadSystem();
const cameraSystem = new CameraSystem();
const tileRenderer = new TileRenderer();

// 随机游走：卡住（30 帧位移 < 1px）就换向
let seed = 20261001;
function rand() {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x7fffffff;
}
function newDirection() {
  const a = rand() * Math.PI * 2;
  return { dx: Math.cos(a), dy: Math.sin(a) };
}
let dir = newDirection();

const input = {
  joyActive: true, joyDx: dir.dx, joyDy: dir.dy,
  jumpPressed: false, attackPressed: false,
  dashPressed: false, attackHeld: false, toolPressed: false
};

let lastX = startX, lastY = startY, stuckFrames = 0;
const samples = []; // 每 30 帧：{frame, px, py, chunks, entities}
let maxGrowthPerFrame = 0, prevChunks = 0;

const t0 = Date.now();
for (let fc = 0; fc < SIM_FRAMES; fc++) {
  input.joyDx = dir.dx;
  input.joyDy = dir.dy;
  const ctx = {
    world, screenW: SCREEN_W, screenH: SCREEN_H,
    input, audio: audioStub, frameCount: fc, dt: DT
  };
  movementSystem.update(world.getEntities(), ctx);
  chunkLoadSystem.update(world.getEntities(), ctx);
  cameraSystem.update(world.getEntities(), ctx);

  const growth = world.chunks.size - prevChunks;
  if (growth > maxGrowthPerFrame) maxGrowthPerFrame = growth;
  prevChunks = world.chunks.size;

  const player = world.findEntityByTag('player');
  const pos = player.getComponent('Position');
  if (fc % 30 === 29) {
    const moved = Math.hypot(pos.x - lastX, pos.y - lastY);
    if (moved < 1.0) {
      stuckFrames++;
      dir = newDirection(); // 卡墙 → 换向
    }
    lastX = pos.x; lastY = pos.y;
    samples.push({ frame: fc, px: pos.x, py: pos.y, chunks: world.chunks.size, entities: world.getEntities().length });
  }
}
const simMs = Date.now() - t0;

// ---------- 3. 结构校验 ----------

const results = [];
function check(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log((ok ? '[PASS] ' : '[FAIL] ') + name + ' — ' + detail);
}

function getTile(chunks, worldX, worldY) {
  const tx = Math.floor(worldX / TILE_SIZE);
  const ty = Math.floor(worldY / TILE_SIZE);
  const cx = Math.floor(tx / CHUNK_SIZE);
  const cy = Math.floor(ty / CHUNK_SIZE);
  const chunk = chunks.get(cx + ',' + cy);
  if (chunk === undefined) return null;
  return chunk.tiles[ty - cy * CHUNK_SIZE][tx - cx * CHUNK_SIZE];
}

// A. 出生点区域
const spawnTile = getTile(world.chunks, startX, startY);
const spawnChunk = world.chunks.get('0,0');
const center = CHUNK_SIZE / 2;
let cleared = 0;
if (spawnChunk) {
  for (let dy = -6; dy <= 6; dy++)
    for (let dx = -6; dx <= 6; dx++)
      if (dx * dx + dy * dy <= 36 && spawnChunk.tiles[center + dy][center + dx] !== TileType.WALL) cleared++;
}
check('A1 出生点所在瓦片可行走', spawnTile !== TileType.WALL && spawnTile !== null,
  'tile=' + spawnTile + ' (FLOOR=' + TileType.FLOOR + ')');
check('A2 出生区域已清空（半径6）', cleared === 113, 'cleared=' + cleared + '/113');

// A3. BFS 连通可达面积（从出生点，仅已加载区块内的非墙瓦片）
{
  const seen = new Set();
  const queue = [[center, center]];
  seen.add(center + ',' + center);
  while (queue.length > 0) {
    const [qx, qy] = queue.shift();
    const nb = [[qx + 1, qy], [qx - 1, qy], [qx, qy + 1], [qx, qy - 1]];
    for (const [nx, ny] of nb) {
      if (nx < 0 || ny < 0 || nx >= CHUNK_SIZE || ny >= CHUNK_SIZE) continue;
      const key = nx + ',' + ny;
      if (seen.has(key)) continue;
      if (spawnChunk.tiles[ny][nx] === TileType.WALL) continue;
      seen.add(key);
      queue.push([nx, ny]);
    }
  }
  check('A3 出生区块连通面积', seen.size >= 200, 'reachable=' + seen.size + ' tiles (阈值 200)');
}

// B. 区块加载
const minExpected = (2 * CHUNK_LOAD_RADIUS + 1) ** 2; // 49 起步圈
check('B1 区块数量达到加载半径要求', world.chunks.size >= minExpected,
  'loaded=' + world.chunks.size + ' 预期>=' + minExpected + '（游走 ' + SIM_FRAMES + ' 帧, 卡墙换向 ' + stuckFrames + ' 次）');
check('B2 每帧限流生效', maxGrowthPerFrame <= 2, 'maxGrowthPerFrame=' + maxGrowthPerFrame + ' (上限 2)');

// C. 区块接缝检测（统计学判据）
// 相邻列瓦片相等本就不是不变量——噪声地形里相邻两列一墙一地板是常态。
// 真正的“接缝”是：区块级阈值偏移会让边界处出现笔直的人工墙线，
// 表现为边界列的不匹配率显著高于区块内部相邻列的基线不匹配率。
// 判据：boundaryMismatchRate <= baselineRate * 1.5 + 0.02（噪声正常波动容差）。
{
  let boundaryPairs = 0, boundaryMismatched = 0;
  for (const key of world.chunks.keys()) {
    const [cx, cy] = key.split(',').map(Number);
    const right = world.chunks.get((cx + 1) + ',' + cy);
    const down = world.chunks.get(cx + ',' + (cy + 1));
    if (right) {
      for (let y = 0; y < CHUNK_SIZE; y++) {
        boundaryPairs++;
        if (world.chunks.get(key).tiles[y][CHUNK_SIZE - 1] !== right.tiles[y][0]) boundaryMismatched++;
      }
    }
    if (down) {
      for (let x = 0; x < CHUNK_SIZE; x++) {
        boundaryPairs++;
        if (world.chunks.get(key).tiles[CHUNK_SIZE - 1][x] !== down.tiles[0][x]) boundaryMismatched++;
      }
    }
  }
  // 基线：区块内部相邻列（避开边缘 2 列）的不匹配率
  let baselinePairs = 0, baselineMismatched = 0;
  for (const key of world.chunks.keys()) {
    const chunk = world.chunks.get(key);
    for (let y = 0; y < CHUNK_SIZE; y++) {
      for (let x = 2; x < CHUNK_SIZE - 2; x++) {
        baselinePairs++;
        if (chunk.tiles[y][x] !== chunk.tiles[y][x + 1]) baselineMismatched++;
      }
    }
  }
  const boundaryRate = boundaryMismatched / Math.max(1, boundaryPairs);
  const baselineRate = baselineMismatched / Math.max(1, baselinePairs);
  const limit = baselineRate * 1.5 + 0.02;
  check('C1 区块无接缝（边界不匹配率≈内部基线）', boundaryRate <= limit,
    'boundary=' + (boundaryRate * 100).toFixed(1) + '% (' + boundaryMismatched + '/' + boundaryPairs +
    ') baseline=' + (baselineRate * 100).toFixed(1) + '% limit=' + (limit * 100).toFixed(1) + '%');
}

// D. 实体生成
{
  const counts = { enemies: 0, traps: 0, mechanisms: 0, chests: 0, bosses: 0 };
  let outOfChunk = 0;
  for (const e of world.getEntities()) {
    if (e.tag === 'player' || e.tag === 'camera') continue;
    const pos = e.getComponent('Position');
    if (pos === null) continue;
    if (e.hasComponent('enemyAI')) counts.enemies++;
    else if (e.hasComponent('trap')) counts.traps++;
    else if (e.hasComponent('mechanism')) counts.mechanisms++;
    else if (e.hasComponent('chest')) counts.chests++;
    else if (e.hasComponent('bossAI')) counts.bosses++;
    const tcx = Math.floor(pos.x / (CHUNK_SIZE * TILE_SIZE));
    const tcy = Math.floor(pos.y / (CHUNK_SIZE * TILE_SIZE));
    if (!world.chunks.has(tcx + ',' + tcy)) outOfChunk++;
  }
  const totalSpawns = counts.enemies + counts.traps + counts.mechanisms + counts.chests + counts.bosses;
  check('D1 世界实体已生成', totalSpawns > 0,
    'enemies=' + counts.enemies + ' traps=' + counts.traps + ' chests=' + counts.chests +
    ' mechanisms=' + counts.mechanisms + ' bosses=' + counts.bosses);
  check('D2 实体都在已加载区块内', outOfChunk === 0, 'outOfChunk=' + outOfChunk);
}

// E. TileRenderer 实际渲染多个视口
const settings = { soundEnabled: false, effectsEnabled: true };
const viewports = [];
// 全区块小地图总览（4px/瓦片，含玩家游走轨迹）
{
  const PXS = 4;
  const xs = [...world.chunks.keys()].map((k) => Number(k.split(',')[0]));
  const ys = [...world.chunks.keys()].map((k) => Number(k.split(',')[1]));
  const minCx = Math.min(...xs), maxCx = Math.max(...xs);
  const minCy = Math.min(...ys), maxCy = Math.max(...ys);
  const W = (maxCx - minCx + 1) * CHUNK_SIZE * PXS;
  const H = (maxCy - minCy + 1) * CHUNK_SIZE * PXS;
  const canvas = createCanvas(W, H);
  const c = canvas.getContext('2d');
  c.fillStyle = '#05050c';
  c.fillRect(0, 0, W, H);
  const TILE_COLORS = {
    0: '#05050c', 1: '#3f3f56', 2: '#1e293b', 3: '#facc15',
    4: '#22c55e', 5: '#0ea5e9', 6: '#a78bfa', 7: '#f472b6', 8: '#ef4444', 9: '#57534e'
  };
  for (const key of world.chunks.keys()) {
    const [cx, cy] = key.split(',').map(Number);
    const chunk = world.chunks.get(key);
    for (let ly = 0; ly < CHUNK_SIZE; ly++) {
      for (let lx = 0; lx < CHUNK_SIZE; lx++) {
        c.fillStyle = TILE_COLORS[chunk.tiles[ly][lx]] || '#ff00ff';
        c.fillRect((cx - minCx) * CHUNK_SIZE * PXS + lx * PXS, (cy - minCy) * CHUNK_SIZE * PXS + ly * PXS, PXS, PXS);
      }
    }
  }
  // 玩家轨迹
  c.strokeStyle = '#f97316';
  c.lineWidth = 2;
  c.beginPath();
  samples.forEach((s, i) => {
    const px = (s.px / TILE_SIZE - minCx * CHUNK_SIZE) * PXS;
    const py = (s.py / TILE_SIZE - minCy * CHUNK_SIZE) * PXS;
    if (i === 0) c.moveTo(px, py); else c.lineTo(px, py);
  });
  c.stroke();
  const file = path.join(OUT, 'overview.png');
  fs.writeFileSync(file, canvas.toBuffer('image/png'));
  viewports.unshift({ name: 'overview_' + (maxCx - minCx + 1) + 'x' + (maxCy - minCy + 1) + '_chunks', file });
  console.log('[render] overview ' + W + 'x' + H + ', chunks=' + world.chunks.size);
}

{
  const player = world.findEntityByTag('player');
  const pp = player.getComponent('Position');
  const spots = [
    { name: 'spawn', cx: startX, cy: startY },
    { name: 'player_final', cx: pp.x, cy: pp.y },
    { name: 'far_east', cx: startX + 8 * CHUNK_SIZE * TILE_SIZE, cy: startY },
    { name: 'far_north', cx: startX, cy: startY - 6 * CHUNK_SIZE * TILE_SIZE }
  ];
  for (const spot of spots) {
    const canvas = createCanvas(SCREEN_W, SCREEN_H);
    const c = canvas.getContext('2d');
    try {
      tileRenderer.render(world, c, spot.cx - SCREEN_W / 2, spot.cy - SCREEN_H / 2,
        SCREEN_W, SCREEN_H, settings, 120);
      const file = path.join(OUT, 'view_' + spot.name + '.png');
      fs.writeFileSync(file, canvas.toBuffer('image/png'));
      // 非背景像素统计：数一下非纯背景色的像素占比，验证地图真的画出来了
      const img = c.getImageData(0, 0, SCREEN_W, SCREEN_H).data;
      let varied = 0;
      for (let i = 0; i < img.length; i += 40) {
        if (img[i + 3] > 0 && (img[i] > 18 || img[i + 1] > 18 || img[i + 2] > 24)) varied++;
      }
      viewports.push({ name: spot.name, file, variedRatio: varied / (img.length / 40) });
      console.log('[render]', spot.name, 'varied=' + (varied / (img.length / 40) * 100).toFixed(1) + '%');
    } catch (e) {
      console.error('[render FAIL]', spot.name, String(e), e.stack);
      viewports.push({ name: spot.name, file: null, error: String(e) });
    }
  }
}
check('E1 TileRenderer 渲染无异常', viewports.every((v) => !v.error),
  viewports.map((v) => v.name + (v.error ? ':ERROR' : ':' + (v.variedRatio * 100).toFixed(0) + '%')).join(', '));
check('E2 视口内容非空', viewports.filter((v) => !v.error && v.variedRatio !== undefined).every((v) => v.variedRatio > 0.02),
  '所有视口非背景像素 > 2%');

// ---------- 4. HTML 报告 ----------

const passCount = results.filter((r) => r.ok).length;
const rows = results.map((r) =>
  '<tr class="' + (r.ok ? 'ok' : 'bad') + '"><td>' + (r.ok ? 'PASS' : 'FAIL') + '</td><td>' +
  r.name + '</td><td>' + r.detail + '</td></tr>').join('\n');
const sampleRows = samples.filter((_, i) => i % 3 === 0).map((s) =>
  '<tr><td>' + s.frame + '</td><td>' + s.px.toFixed(0) + '</td><td>' + s.py.toFixed(0) +
  '</td><td>' + s.chunks + '</td><td>' + s.entities + '</td></tr>').join('\n');
const pngCards = viewports.filter((v) => v.file).map((v) => {
  const b64 = fs.readFileSync(v.file).toString('base64');
  return '<div class="card"><img src="data:image/png;base64,' + b64 +
    '"><div class="cap">' + v.name + ' · 非背景像素 ' + (v.variedRatio * 100).toFixed(1) + '%</div></div>';
}).join('\n');

const html = `<!DOCTYPE html>
<html lang="zh"><head><meta charset="utf-8"><title>地图加载检查报告</title>
<style>
  body { background:#12121f; color:#e2e8f0; font-family:monospace; margin:20px; }
  h1 { font-size:18px; } h2 { font-size:14px; color:#7dd3fc; margin-top:24px; }
  table { border-collapse:collapse; width:100%; font-size:12px; }
  td, th { border:1px solid #334155; padding:5px 8px; text-align:left; }
  tr.ok td:first-child { color:#22c55e; font-weight:bold; }
  tr.bad td:first-child { color:#ef4444; font-weight:bold; }
  tr.bad td { background:#2a1215; }
  .card { display:inline-block; margin:8px; background:#0f172a; border:1px solid #334155; border-radius:6px; padding:8px; }
  .card img { display:block; width:780px; image-rendering:pixelated; }
  .cap { font-size:11px; color:#94a3b8; margin-top:4px; text-align:center; }
  .summary { font-size:14px; margin:10px 0; }
</style></head><body>
<h1>地图加载检查报告（真实游戏代码模拟）</h1>
<div class="summary">${passCount}/${results.length} 项通过 · 模拟 ${SIM_FRAMES} 帧（${(SIM_FRAMES * DT / 1000).toFixed(0)}s 游戏时间）耗时 ${simMs}ms · 卡墙换向 ${stuckFrames} 次</div>
<table><tr><th>结果</th><th>检查项</th><th>详情</th></tr>
${rows}
</table>
<h2>TileRenderer 实际渲染（780×360 横屏视口）</h2>
${pngCards}
<h2>采样日志（每 90 帧）</h2>
<table><tr><th>帧</th><th>玩家x</th><th>玩家y</th><th>区块数</th><th>实体数</th></tr>
${sampleRows}
</table>
</body></html>`;

const reportFile = path.join(__dirname, 'report.html');
fs.writeFileSync(reportFile, html);
console.log('[report]', path.relative(ROOT, reportFile));

process.exit(passCount === results.length ? 0 : 1);
