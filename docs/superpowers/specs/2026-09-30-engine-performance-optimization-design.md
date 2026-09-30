# Engine Performance Optimization Design

## Overview

Target: eliminate stuttering across four scenarios (Boss fights, large enemy counts, chunk loading, transformation animations) through four high-impact, low-risk optimizations.

Current state: `setInterval(33)` game loop unsynced to display, `World.query()` allocates new arrays every call (50-75 allocations/frame), synchronous chunk generation blocks main thread, per-tile Canvas draw calls with no caching.

Target outcome: stable 60fps on device, 70%+ reduction in frame time spikes.

## Module 1: Game Loop Display Sync

### Problem

`Engine.startLoop()` uses `setInterval(fn, 33)` (~30fps). This timer:
- Fires independently of display refresh, causing visible tearing
- Has inconsistent timing (jitter from event loop scheduling)
- Wastes display capability on 60fps screens

### Solution

Use HarmonyOS `@ohos.animator` to drive the game loop via vsync callbacks. The Engine already has `setExternalLoop(true)` — a dormant hook designed for exactly this purpose.

### Changes

**`entry/src/main/ets/pages/Index.ets`**

In `tryInitEngine()`, after creating the engine:
1. Import `@ohos.animator` and create an Animator instance via `createAnimator()`
2. Call `engine.setExternalLoop(true)` before `engine.init()`
3. In the Animator frame callback, compute `dt` from timestamps and call `engine.tick(dt)`
4. Keep `setInterval` as fallback if Animator creation fails

**`Engine/src/main/ets/Engine.ets`**

- `startLoop()`: when `externalLoop` is true, skip `setInterval` creation entirely (already implemented)
- `tick(dt)`: accept real dt from caller instead of fixed 33ms
- Remove `tickInterval` field dependency for timing (keep as minimum dt clamp)

### Key Design Decisions

- Animator callback receives a timestamp; compute dt as `currentTimestamp - lastTimestamp`
- Clamp dt to max 100ms to prevent physics tunneling after background/foreground transitions
- If `@ohos.animator` is unavailable at runtime, fall back to `setInterval` with a warning log
- The Engine's `stop()` must also stop the Animator if external loop is active

### Risk

Low. The external loop hook already exists and is tested to be a no-op when enabled. The only new code is the Animator driver in Index.ets.

---

## Module 2: World.query() Result Caching

### Problem

`World.query(componentType)` allocates a new `Entity[]` on every call. With 25 systems each calling query 2-3 times per frame, this produces 50-75 temporary arrays per frame, creating significant GC pressure. Additionally, `this.entities.filter(e => e.active)` runs unconditionally every frame even when no entities were removed.

### Solution

Cache query results in a `Map<string, Entity[]>`. Invalidate the cache only when the entity list changes (add/remove). Skip the filter when no inactive entities exist.

### Changes

**`Engine/src/main/ets/World.ets`**

New fields:
```
private queryCache: Map<string, Entity[]> = new Map()
private cacheDirty: boolean = true
private inactiveCount: number = 0
```

Modified methods:

- `addEntity()`: push entity, set `cacheDirty = true`, increment `inactiveCount` only if entity is active (it always is at creation)
- `removeEntity()`: set `entity.active = false`, set `cacheDirty = true`, increment `inactiveCount`
- `query(type)`: if `cacheDirty`, rebuild all cached results and set `cacheDirty = false`. Return cached array for the given type.
- `queryWithTag(tag)`: same caching pattern, separate cache map `tagCache: Map<string, Entity[]>`
- `update()`: replace unconditional `filter()` with conditional: only filter when `inactiveCount > 0`. After filtering, reset `inactiveCount = 0` and set `cacheDirty = true`.

Cache rebuild logic (private method `rebuildQueryCache()`):
```
1. Clear queryCache map
2. Iterate all active entities
3. For each entity, for each component type it has, push to queryCache[type]
4. Also rebuild tagCache similarly
```

**`Engine/src/main/ets/Entity.ets`**

No changes needed. Audit confirms: no system in the codebase calls `addComponent()` or `removeComponent()` on active entities at runtime. EvolutionSystem, TransformSystem, and HumanFormSystem only modify component DATA (values), not the component set. CleanupSystem only removes components from already-inactive entities.

The cache invalidation via `addEntity()` / `removeEntity()` covers all real cases. A `markDirty()` public method is added to World as a future escape hatch, but no current callers need it.

### Key Design Decisions

- Cache is invalidated per-frame at most once (dirty flag checked at start of query)
- Returning cached array references is safe because systems only read query results, never mutate them
- `markDirty()` is a public escape hatch for the rare case of mid-frame component changes
- The rebuild iterates entities once and distributes to all component type buckets — O(entities * components_per_entity), same as before but done once instead of per-query

### Risk

Low. Audit confirmed no system adds/removes components on active entities at runtime. Cache invalidation via `addEntity()` / `removeEntity()` covers all current cases. The `markDirty()` method exists as a future escape hatch if new systems are added that modify component sets.

---

## Module 3: TileRenderer Static Tile Cache

### Problem

`TileRenderer.renderWorld()` iterates all visible tiles each frame. For each tile:
- WALL: 10+ `fillRect` calls (brick pattern, ore deposits, vines, grass edges)
- FLOOR: 3-5 `fillRect` calls (variant selection, pebbles, cracks)
- Each tile changes `fillStyle` multiple times, causing Canvas state thrashing

With a typical viewport of ~30x20 tiles, that's 600 tiles * 5-15 draw calls = 3000-9000 draw calls per frame just for terrain.

### Solution

Pre-render static tiles (WALL, FLOOR, BROKEN_WALL, PLANT) to an offscreen Canvas. On subsequent frames, blit the cached canvas via a single `drawImage()` call, then render only animated tiles (WATER, LAVA, CRYSTAL, MUSHROOM, GLOW_STONE) directly.

### Changes

**`entry/src/main/ets/game/renderers/TileRenderer.ets`**

New fields:
```
private staticCache: OffscreenCanvas | null = null
private cacheCameraX: number = -1
private cacheCameraY: number = -1
private cacheScreenWidth: number = 0
private cacheScreenHeight: number = 0
```

New methods:

- `rebuildStaticCache(world, cameraX, cameraY, screenW, screenH)`: creates/resizes the offscreen canvas, iterates visible tiles, renders only static tiles (WALL, FLOOR, BROKEN_WALL, PLANT) to the offscreen canvas. Stores the camera position.

- `renderStaticFromCache(ctx, cameraX, cameraY)`: computes the offset between current camera and cached camera, calls `ctx.drawImage(staticCache, ...)` with appropriate source/dest rectangles.

Modified `render()` method:
```
1. If camera moved since last cache (or cache is null):
   a. rebuildStaticCache()
   b. store new camera position
2. renderStaticFromCache() — one drawImage() call
3. Render animated tiles (WATER, LAVA, CRYSTAL, MUSHROOM, GLOW_STONE) directly as before
```

Cache invalidation rules:
- Camera position changed (any amount) — rebuild with new viewport
- Camera moved more than screenW or screenH since last cache — full rebuild
- Small camera movements (1-2 tiles) — rebuild only the newly exposed strip edges (optimization, can defer to later)

For simplicity in the initial implementation: rebuild the entire static cache whenever the camera moves. This is still a massive improvement because:
- The offscreen render only happens when camera moves (not every frame when standing still)
- The main canvas render is reduced from 3000-9000 calls to 1 drawImage + animated tiles
- Camera typically moves in short bursts, not continuously

### Key Design Decisions

- OffscreenCanvas size matches the screen dimensions (no need for larger — we rebuild on camera move)
- Static tile types: WALL, FLOOR, BROKEN_WALL, PLANT (these never change visually per-frame)
- Animated tile types: WATER, LAVA, CRYSTAL, MUSHROOM, GLOW_STONE (rendered every frame on top of cache)
- The background renderer (`renderBackground`) is unchanged — it already uses its own parallax logic
- If `OffscreenCanvas` is unavailable, fall back to current per-tile rendering (same pattern as SpriteManager)

### Risk

Medium. The offscreen canvas allocation and rebuild has its own cost. If the camera moves every frame (which it usually does when the player is moving), we're creating a new offscreen render each frame. Mitigation:
- The offscreen render is still faster than per-tile rendering because it avoids fillStyle thrashing (batch by tile type)
- For further optimization: use a larger cache (screen + 2 tile borders) and only rebuild exposed strips
- Profile on device to verify the improvement; if camera moves too frequently, switch to strip-based updates

### Fallback Strategy

If the static cache approach doesn't yield sufficient improvement (camera moves too often), an alternative is to batch draw calls by fillStyle within the existing per-frame rendering:
- Collect all tiles by type, then render all WALL tiles (one fillStyle set), then all FLOOR tiles, etc.
- This reduces fillStyle changes from per-tile to per-type

---

## Module 4: ChunkLoadSystem Frame-Split Loading

### Problem

`ChunkLoadSystem.update()` iterates the full `CHUNK_LOAD_RADIUS` grid every frame. For each chunk not yet in the map, it synchronously calls `worldGen.generateChunk()` and creates all associated entities (enemies, traps, mechanisms, chests, bosses). When the player moves to a new area, this can generate 9+ chunks in a single frame, blocking the main thread for tens of milliseconds.

### Solution

Decouple chunk detection from chunk generation. Each frame, detect which chunks are needed and add missing ones to a priority queue. Process at most `MAX_CHUNKS_PER_FRAME` chunks from the queue per frame.

### Changes

**`entry/src/main/ets/game/systems/ChunkLoadSystem.ets`**

New fields:
```
private pendingChunks: Array<{cx: number, cy: number, dist: number}> = []
private readonly MAX_CHUNKS_PER_FRAME: number = 2
```

Modified `update()` method:

Phase 1 — Detection (every frame):
```
1. Compute player chunk position (pcx, pcy)
2. Iterate CHUNK_LOAD_RADIUS grid
3. For each (cx, cy) not in chunks Map AND not in pendingChunks:
   - Add to pendingChunks with distance = max(abs(cx-pcx), abs(cy-pcy))
4. Sort pendingChunks by distance (closest first)
```

Phase 2 — Generation (budgeted):
```
1. Process up to MAX_CHUNKS_PER_FRAME chunks from pendingChunks
2. For each processed chunk:
   - generateChunk(cx, cy)
   - Create all entities (enemies, traps, mechanisms, chests, bosses)
   - Remove from pendingChunks
```

Pending chunk deduplication:
- Before adding to pendingChunks, check both `chunks.has(key)` and whether the key is already in pendingChunks (use a Set<string> for O(1) lookup)

New field for dedup:
```
private pendingKeys: Set<string> = new Set()
```

### Key Design Decisions

- `MAX_CHUNKS_PER_FRAME = 2`: conservative choice. Each chunk generates ~5-15 entities. 2 chunks/frame = 10-30 entities/frame, well within the frame budget. Can be tuned to 3-4 if needed.
- Priority queue sorted by distance: chunks closest to the player are generated first, so the visible area loads fastest.
- Chunks in the pending queue are not yet in the world. `getTile()` calls for those coordinates return WALL (existing behavior for unknown chunks). This is correct — the player can't see chunks that haven't loaded yet (they're beyond the viewport).
- If the player moves very fast and accumulates a large pending queue, the queue naturally drains over subsequent frames. No special handling needed.
- On initial game start, the first frame still loads all chunks within radius synchronously (the queue starts empty and the initial chunks are needed immediately for rendering). This is acceptable because it only happens once.

### Risk

Low. The behavior is identical to the current implementation, just spread across frames. The only visible difference is a brief delay (2-3 frames = ~50ms at 60fps) before distant chunks appear, which is imperceptible.

---

## Implementation Order

The four modules are independent and can be implemented in any order. Recommended sequence by impact:

1. **Module 2 (World.query caching)** — Largest GC pressure reduction, simplest change, immediate effect on all 25 systems
2. **Module 4 (ChunkLoadSystem queue)** — Eliminates the most visible stutter (chunk loading), isolated change
3. **Module 1 (Game loop sync)** — Improves overall smoothness, requires HarmonyOS API verification
4. **Module 3 (TileRenderer cache)** — Largest code change, requires careful testing of cache invalidation

## Files Modified

| File | Module | Change |
|------|--------|--------|
| `Engine/src/main/ets/World.ets` | 2 | Query cache, dirty flag, conditional filter |
| `Engine/src/main/ets/Engine.ets` | 1 | External loop support cleanup |
| `entry/src/main/ets/pages/Index.ets` | 1 | Animator driver |
| `entry/src/main/ets/game/systems/ChunkLoadSystem.ets` | 4 | Pending queue, per-frame budget |
| `entry/src/main/ets/game/renderers/TileRenderer.ets` | 3 | Offscreen static cache |

Note: EvolutionSystem, TransformSystem, HumanFormSystem were audited — they only modify component DATA, not the component set. No `markDirty()` calls needed.

## Testing

- Verify frame time stability with 50+ enemies on screen
- Verify no stutter when walking into ungenerated chunks
- Verify transformation/evolution animations are smooth
- Verify Boss fights with multiple boss entities maintain 60fps
- Verify query cache correctness: entities added/removed mid-frame appear/disappear in next frame's queries
- Verify tile cache visual correctness: no missing tiles, no stale tiles after camera movement
- Fallback paths: test with OffscreenCanvas unavailable, Animator unavailable
