import { TILE_SIZE } from './GameConstants';

export interface Vec2 {
  x: number;
  y: number;
}

export interface AABB {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface PhysicsBody {
  x: number;
  y: number;
  w: number;
  h: number;
  vx: number;
  vy: number;
  onGround: boolean;
  onWall: boolean;
  gravityScale: number;
  friction: number;
  bounciness: number;
  mass: number;
}

export interface CollisionResult {
  hit: boolean;
  overlapX: number;
  overlapY: number;
  normalX: number;
  normalY: number;
}

export interface TileCollisionResult {
  hitLeft: boolean;
  hitRight: boolean;
  hitTop: boolean;
  hitBottom: boolean;
  grounded: boolean;
}

export function vec2(x: number, y: number): Vec2 {
  return { x: x, y: y };
}

export function vec2Add(a: Vec2, b: Vec2): Vec2 {
  return { x: a.x + b.x, y: a.y + b.y };
}

export function vec2Sub(a: Vec2, b: Vec2): Vec2 {
  return { x: a.x - b.x, y: a.y - b.y };
}

export function vec2Scale(v: Vec2, s: number): Vec2 {
  return { x: v.x * s, y: v.y * s };
}

export function vec2Length(v: Vec2): number {
  return Math.sqrt(v.x * v.x + v.y * v.y);
}

export function vec2Normalize(v: Vec2): Vec2 {
  const len: number = vec2Length(v);
  if (len < 0.0001) return { x: 0, y: 0 };
  return { x: v.x / len, y: v.y / len };
}

export function vec2Dot(a: Vec2, b: Vec2): number {
  return a.x * b.x + a.y * b.y;
}

export function vec2Distance(a: Vec2, b: Vec2): number {
  return vec2Length(vec2Sub(a, b));
}

export function vec2Lerp(a: Vec2, b: Vec2, t: number): Vec2 {
  return { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t };
}

export function aabbOverlap(a: AABB, b: AABB): boolean {
  return a.x < b.x + b.w && a.x + a.w > b.x &&
    a.y < b.y + b.h && a.y + a.h > b.y;
}

export function aabbIntersection(a: AABB, b: AABB): AABB {
  const ix: number = Math.max(a.x, b.x);
  const iy: number = Math.max(a.y, b.y);
  const iw: number = Math.min(a.x + a.w, b.x + b.w) - ix;
  const ih: number = Math.min(a.y + a.h, b.y + b.h) - iy;
  if (iw <= 0 || ih <= 0) return { x: 0, y: 0, w: 0, h: 0 };
  return { x: ix, y: iy, w: iw, h: ih };
}

export function aabbContainsPoint(a: AABB, px: number, py: number): boolean {
  return px >= a.x && px <= a.x + a.w && py >= a.y && py <= a.y + a.h;
}

export function aabbCenter(a: AABB): Vec2 {
  return { x: a.x + a.w / 2, y: a.y + a.h / 2 };
}

export function aabbDistance(a: AABB, b: AABB): number {
  return vec2Distance(aabbCenter(a), aabbCenter(b));
}

export function detectCollision(a: AABB, b: AABB): CollisionResult {
  const result: CollisionResult = {
    hit: false, overlapX: 0, overlapY: 0, normalX: 0, normalY: 0
  };

  if (!aabbOverlap(a, b)) return result;

  const overlapLeft: number = (a.x + a.w) - b.x;
  const overlapRight: number = (b.x + b.w) - a.x;
  const overlapTop: number = (a.y + a.h) - b.y;
  const overlapBottom: number = (b.y + b.h) - a.y;

  const minOverlapX: number = overlapLeft < overlapRight ? -overlapLeft : overlapRight;
  const minOverlapY: number = overlapTop < overlapBottom ? -overlapTop : overlapBottom;

  if (Math.abs(minOverlapX) < Math.abs(minOverlapY)) {
    result.overlapX = minOverlapX;
    result.overlapY = 0;
    result.normalX = minOverlapX < 0 ? -1 : 1;
    result.normalY = 0;
  } else {
    result.overlapX = 0;
    result.overlapY = minOverlapY;
    result.normalX = 0;
    result.normalY = minOverlapY < 0 ? -1 : 1;
  }
  result.hit = true;
  return result;
}

export function createBody(x: number, y: number, w: number, h: number): PhysicsBody {
  return {
    x: x, y: y, w: w, h: h,
    vx: 0, vy: 0,
    onGround: false, onWall: false,
    gravityScale: 1.0, friction: 0.85, bounciness: 0.0, mass: 1.0
  };
}

export const GRAVITY: number = 0.5;
export const MAX_FALL_SPEED: number = 12.0;
export const MAX_MOVE_SPEED: number = 20.0;

export class PhysicsEngine {
  private gravity: number = GRAVITY;
  private maxFallSpeed: number = MAX_FALL_SPEED;

  setGravity(g: number): void {
    this.gravity = g;
  }

  setMaxFallSpeed(s: number): void {
    this.maxFallSpeed = s;
  }

  applyGravity(body: PhysicsBody, dt: number): void {
    body.vy += this.gravity * body.gravityScale * (dt / 16);
    if (body.vy > this.maxFallSpeed) {
      body.vy = this.maxFallSpeed;
    }
  }

  applyFriction(body: PhysicsBody): void {
    if (body.onGround) {
      body.vx *= body.friction;
    }
    if (Math.abs(body.vx) < 0.1) body.vx = 0;
    if (Math.abs(body.vx) > MAX_MOVE_SPEED) {
      body.vx = body.vx > 0 ? MAX_MOVE_SPEED : -MAX_MOVE_SPEED;
    }
  }

  applyImpulse(body: PhysicsBody, ix: number, iy: number): void {
    body.vx += ix / body.mass;
    body.vy += iy / body.mass;
  }

  applyKnockback(body: PhysicsBody, fromX: number, fromY: number, force: number): void {
    const cx: number = body.x + body.w / 2;
    const cy: number = body.y + body.h / 2;
    const dx: number = cx - fromX;
    const dy: number = cy - fromY;
    const dist: number = Math.sqrt(dx * dx + dy * dy);
    if (dist < 0.001) {
      body.vx = force * (Math.random() > 0.5 ? 1 : -1);
      body.vy = -force * 0.5;
    } else {
      body.vx = (dx / dist) * force;
      body.vy = (dy / dist) * force;
    }
  }

  moveAndCollide(
    body: PhysicsBody,
    getTile: (wx: number, wy: number) => number,
    isSolid: (tile: number) => boolean,
    dt: number
  ): TileCollisionResult {
    const result: TileCollisionResult = {
      hitLeft: false, hitRight: false,
      hitTop: false, hitBottom: false, grounded: false
    };

    this.applyGravity(body, dt);
    this.applyFriction(body);

    const stepX: number = body.vx * (dt / 16);
    const stepY: number = body.vy * (dt / 16);

    body.x += stepX;
    const xResult = this.resolveTileCollisionX(body, getTile, isSolid);
    result.hitLeft = xResult.hitLeft;
    result.hitRight = xResult.hitRight;
    if (xResult.hitLeft || xResult.hitRight) {
      body.vx = body.bounciness > 0 ? -body.vx * body.bounciness : 0;
      body.onWall = true;
    } else {
      body.onWall = false;
    }

    body.y += stepY;
    const yResult = this.resolveTileCollisionY(body, getTile, isSolid);
    result.hitTop = yResult.hitTop;
    result.hitBottom = yResult.hitBottom;
    result.grounded = yResult.hitBottom;
    body.onGround = yResult.hitBottom;
    if (yResult.hitTop || yResult.hitBottom) {
      body.vy = body.bounciness > 0 ? -body.vy * body.bounciness : 0;
    }

    return result;
  }

  private resolveTileCollisionX(
    body: PhysicsBody,
    getTile: (wx: number, wy: number) => number,
    isSolid: (tile: number) => boolean
  ): { hitLeft: boolean; hitRight: boolean } {
    let hitLeft: boolean = false;
    let hitRight: boolean = false;

    const top: number = Math.floor(body.y / TILE_SIZE);
    const bottom: number = Math.floor((body.y + body.h - 1) / TILE_SIZE);
    const margin: number = 1;

    if (body.vx < 0) {
      const tileX: number = Math.floor(body.x / TILE_SIZE);
      for (let ty: number = top; ty <= bottom; ty++) {
        const tile: number = getTile(tileX, ty);
        if (isSolid(tile)) {
          body.x = (tileX + 1) * TILE_SIZE + margin;
          hitLeft = true;
          break;
        }
      }
    } else if (body.vx > 0) {
      const tileX: number = Math.floor((body.x + body.w) / TILE_SIZE);
      for (let ty: number = top; ty <= bottom; ty++) {
        const tile: number = getTile(tileX, ty);
        if (isSolid(tile)) {
          body.x = tileX * TILE_SIZE - body.w - margin;
          hitRight = true;
          break;
        }
      }
    }

    return { hitLeft: hitLeft, hitRight: hitRight };
  }

  private resolveTileCollisionY(
    body: PhysicsBody,
    getTile: (wx: number, wy: number) => number,
    isSolid: (tile: number) => boolean
  ): { hitTop: boolean; hitBottom: boolean } {
    let hitTop: boolean = false;
    let hitBottom: boolean = false;

    const left: number = Math.floor(body.x / TILE_SIZE);
    const right: number = Math.floor((body.x + body.w - 1) / TILE_SIZE);
    const margin: number = 1;

    if (body.vy < 0) {
      const tileY: number = Math.floor(body.y / TILE_SIZE);
      for (let tx: number = left; tx <= right; tx++) {
        const tile: number = getTile(tx, tileY);
        if (isSolid(tile)) {
          body.y = (tileY + 1) * TILE_SIZE + margin;
          hitTop = true;
          break;
        }
      }
    } else if (body.vy > 0) {
      const tileY: number = Math.floor((body.y + body.h) / TILE_SIZE);
      for (let tx: number = left; tx <= right; tx++) {
        const tile: number = getTile(tx, tileY);
        if (isSolid(tile)) {
          body.y = tileY * TILE_SIZE - body.h - margin;
          hitBottom = true;
          break;
        }
      }
    }

    return { hitTop: hitTop, hitBottom: hitBottom };
  }

  checkEntityCollision(a: PhysicsBody, b: PhysicsBody): CollisionResult {
    const aabbA: AABB = { x: a.x, y: a.y, w: a.w, h: a.h };
    const aabbB: AABB = { x: b.x, y: b.y, w: b.w, h: b.h };
    return detectCollision(aabbA, aabbB);
  }

  isPointInBody(body: PhysicsBody, px: number, py: number): boolean {
    return px >= body.x && px <= body.x + body.w &&
      py >= body.y && py <= body.y + body.h;
  }

  isGrounded(
    body: PhysicsBody,
    getTile: (wx: number, wy: number) => number,
    isSolid: (tile: number) => boolean
  ): boolean {
    const footY: number = body.y + body.h + 2;
    const left: number = Math.floor(body.x / TILE_SIZE);
    const right: number = Math.floor((body.x + body.w - 1) / TILE_SIZE);
    const tileY: number = Math.floor(footY / TILE_SIZE);
    for (let tx: number = left; tx <= right; tx++) {
      if (isSolid(getTile(tx, tileY))) return true;
    }
    return false;
  }

  raycast(
    startX: number, startY: number,
    dirX: number, dirY: number,
    maxDist: number,
    getTile: (wx: number, wy: number) => number,
    isSolid: (tile: number) => boolean
  ): Vec2 | null {
    const len: number = Math.sqrt(dirX * dirX + dirY * dirY);
    if (len < 0.001) return null;
    const ndx: number = dirX / len;
    const ndy: number = dirY / len;

    const step: number = 4;
    let dist: number = 0;
    while (dist < maxDist) {
      const cx: number = startX + ndx * dist;
      const cy: number = startY + ndy * dist;
      const tx: number = Math.floor(cx / TILE_SIZE);
      const ty: number = Math.floor(cy / TILE_SIZE);
      if (isSolid(getTile(tx, ty))) {
        return { x: cx, y: cy };
      }
      dist += step;
    }
    return null;
  }
}
