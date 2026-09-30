# Sprite Sheet Rendering Design

## Overview

Replace per-frame procedural Canvas2D drawing for all character entities with pre-rendered sprite sheets. At startup, generate all character frames into OffscreenCanvas objects. At runtime, use `drawImage` to blit cached frames, reducing draw calls from hundreds per frame to a few per character.

## Design Decisions

**Cache Strategy**: Pre-generate all frames at startup. Accept 1-2 second startup delay for optimal runtime performance.

**Scope**: All character entities — player, 6 enemy types, 5 boss types. Dynamic effects (particles, lighting, damage numbers, health bars) remain real-time drawn.

**Architecture**: Hybrid approach
- **Enemies + Bosses**: Sprite atlas (single OffscreenCanvas per entity type, frames in grid)
- **Player**: Key-value cache (Map<string, OffscreenCanvas>, string key encodes full state)

**Weapon + Transform Rendering**: Keep real-time. Weapon attack animations (1024 lines) and transform form animations are tightly coupled to combat state and attack direction. Pre-rendering adds complexity with limited benefit since only one player exists.

## Architecture

### Core Data Structures

**SpriteAtlas** (for enemies and bosses)

```typescript
class SpriteAtlas {
  readonly canvas: OffscreenCanvas;  // Entire atlas
  readonly cellW: number;            // Frame width
  readonly cellH: number;            // Frame height
  readonly cols: number;             // Columns in grid
  
  getFrame(index: number): { sx: number, sy: number } {
    const col = index % this.cols;
    const row = Math.floor(index / this.cols);
    return { sx: col * this.cellW, sy: row * this.cellH };
  }
}
```

**SpriteCache** (for player)

```typescript
class SpriteCache {
  private frames: Map<string, OffscreenCanvas>;
  
  get(key: string): OffscreenCanvas | undefined;
  set(key: string, canvas: OffscreenCanvas): void;
  has(key: string): boolean;
}
```

**SpriteManager** (unified coordinator)

```typescript
class SpriteManager {
  private enemyAtlases: Map<EnemyType, SpriteAtlas>;
  private bossAtlases: Map<BossType, SpriteAtlas>;
  private playerCache: SpriteCache;
  
  async generateAll(): Promise<void>;
  getEnemyAtlas(type: EnemyType): SpriteAtlas;
  getBossAtlas(type: BossType): SpriteAtlas;
  getPlayerFrame(key: string): OffscreenCanvas | undefined;
}
```

### File Structure

```
entry/src/main/ets/game/sprites/
├── SpriteAtlas.ets
├── SpriteCache.ets
├── SpriteManager.ets
├── generators/
│   ├── EnemySpriteGenerator.ets
│   ├── BossSpriteGenerator.ets
│   └── PlayerSpriteGenerator.ets
```

## Generation Pipeline

### Refactoring Strategy: Extract Drawing Primitives

Split each renderer into two layers:

1. **Drawing layer** (pure functions) — Accept `ctx` + state parameters, draw character at origin. Called by SpriteGenerator at startup.
2. **Runtime layer** (thin wrapper) — Lookup cache + `drawImage` + overlay dynamic effects.

```typescript
// Before: EnemyRenderer.render() queries entities, computes animation, draws
// After:

// Drawing layer — pure function, reusable by SpriteGenerator
function drawGraySlime(ctx: CanvasRenderingContext2D, bouncePhase: number, size: number): void

// Runtime layer — lookup cache + drawImage
class EnemyRenderer {
  render(ctx, world, camera, spriteManager) {
    for each enemy:
      const frameIndex = computeFrameIndex(enemy)
      const atlas = spriteManager.getEnemyAtlas(enemy.type)
      const frame = atlas.getFrame(frameIndex)
      ctx.drawImage(atlas.canvas, frame.sx, frame.sy, cellW, cellH, screenX, screenY, cellW, cellH)
      // Dynamic effects still real-time
      if (enemy.health < maxHealth) drawHealthBar(ctx, ...)
  }
}
```

### Frame Enumeration

| Entity | Dimensions | Estimated Frames |
|--------|-----------|------------------|
| 6 enemy types | Bounce phase × facing | ~6×8 = 48 |
| 5 boss types | Phase × attack animation | ~5×12 = 60 |
| Player base | Walk frames × facing | 8×2 = 16 |
| Player weapons | 6 weapons × attack frames | 6×6 = 36 |
| Player transforms | 4 forms × animation | 4×4 = 16 |
| Player special | Jump/drill/engulfed | ~6 |
| **Total** | | **~180 frames** |

### Memory Estimate

- Player cache: ~100 frames × 32×64 px × 4 bytes ≈ 800KB
- Enemy atlases: 6 × 8 frames × 64×64 px ≈ 800KB
- Boss atlases: 5 × 12 frames × 128×128 px ≈ 2MB
- **Total: ~3MB** (well within mobile app limits)

## Startup Flow

### Integration with GameScene

```typescript
class GameScene {
  private spriteManager: SpriteManager | null = null;

  async init(): Promise<void> {
    this.spriteManager = new SpriteManager();
    await this.spriteManager.generateAll();  // Async generation, avoid blocking UI
    // ... initialize entities and systems
  }

  render(baseCtx: BaseContext): void {
    // Pass spriteManager to renderers in render loop
    this.enemyRenderer.render(ctx, world, camera, this.spriteManager);
    this.bossRenderer.render(ctx, world, camera, this.spriteManager);
    this.playerRenderer.render(ctx, world, camera, this.spriteManager);
    // Effect renderer unchanged, still real-time
    this.effectRenderer.render(ctx, world, camera);
  }
}
```

### Startup Sequence

```
Index.ets → onInit()
  ├── Create GameScene
  ├── Create SpriteManager
  ├── Show loading screen ("Generating sprites...")
  ├── Call SpriteManager.generateAll()
  │     ├── Create temporary OffscreenCanvas for generation
  │     ├── EnemySpriteGenerator.generate(atlases)
  │     ├── BossSpriteGenerator.generate(atlases)
  │     └── PlayerSpriteGenerator.generate(cache)
  ├── Sprite generation complete, hide loading screen
  └── Start game main loop
```

### Async Generation

`generateAll()` uses `setTimeout` to yield main thread between batches, avoiding frame drops:

```typescript
async generateAll(): Promise<void> {
  await this.generateEnemyAtlases();
  await this.generateBossAtlases();
  await this.generatePlayerCache();
}
```

## Rendering Pipeline Changes

### Renderer Modification Summary

| Renderer | Change | Notes |
|----------|--------|-------|
| PlayerRenderer | Major | Base character from cache drawImage, weapon/transform/effects still real-time |
| EnemyRenderer | Medium | 6 enemy types all from atlas drawImage, health bars real-time |
| BossRenderer | Medium | 5 boss types from atlas drawImage, health bars and phase effects real-time |
| WeaponRenderer | Keep | Weapon attack animations complex and tightly coupled to combat state, keep real-time |
| TransformFormRenderer | Keep | Transform form animations tightly coupled to energy/state, keep real-time |
| EffectRenderer | Unchanged | Particles, lighting, traps all real-time |

### Player Rendering Flow (After Refactor)

```
PlayerRenderer.render():
  1. If transformed → call TransformFormRenderer (real-time)
  2. Otherwise:
     a. Get base character frame from SpriteCache → drawImage
     b. Real-time draw weapon (WeaponRenderer)
     c. Real-time draw equipment/evolution effects
  3. Always real-time: health bar, damage numbers, jump shadow
```

### Enemy Rendering Flow (After Refactor)

```
EnemyRenderer.render():
  for each enemy:
    1. Get frame from SpriteAtlas → drawImage (includes bounce animation frame index)
    2. If damaged → real-time draw health bar
    3. If hit flash → overlay semi-transparent white rectangle
```

### Boss Rendering Flow (After Refactor)

```
BossRenderer.render():
  1. Get current phase frame from SpriteAtlas → drawImage
  2. Real-time draw: phase effects (aura, particles), health bar, phase divider
```

## Implementation Notes

### HarmonyOS Canvas2D API

- Use `OffscreenCanvas` for pre-rendering (verify HarmonyOS support)
- `ctx.drawImage(offscreenCanvas, sx, sy, sw, sh, dx, dy, dw, dh)` for atlas cropping
- `ctx.drawImage(offscreenCanvas, dx, dy)` for player cache (full frame)

### Backward Compatibility

- Existing procedural drawing code refactored into pure functions, not deleted
- SpriteGenerator calls these functions during startup
- If sprite generation fails (e.g., OffscreenCanvas unsupported), fall back to real-time rendering

### Performance Monitoring

- Log sprite generation time at startup
- Monitor frame rate before/after refactor to verify improvement
- Track memory usage of sprite caches

## Testing Strategy

- Visual parity: compare screenshots before/after refactor for each entity type
- Performance: measure FPS on low-end HarmonyOS device
- Memory: verify sprite cache memory within acceptable limits
- Fallback: test real-time rendering fallback if sprite generation fails
