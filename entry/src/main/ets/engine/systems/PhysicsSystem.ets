// entry/src/main/ets/engine/systems/PhysicsSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { Transform } from '../components/Transform';
import { RigidBody } from '../components/RigidBody';
import { Collider } from '../components/Collider';
import { TilemapCollider } from '../components/TilemapCollider';

const DEFAULT_GRAVITY: number = 0.5;
const MAX_FALL_SPEED: number = 12.0;
const MAX_MOVE_SPEED: number = 20.0;

export class PhysicsSystem extends System {
  readonly name: string = 'physics';
  readonly dependencies: string[] = [];
  priority: number = 10;

  private gravity: number = DEFAULT_GRAVITY;
  private maxFallSpeed: number = MAX_FALL_SPEED;

  setGravity(g: number): void { this.gravity = g; }
  setMaxFallSpeed(s: number): void { this.maxFallSpeed = s; }

  update(world: World, dt: number, entities: Entity[]): void {
    const bodies: Entity[] = world.query('rigidBody', 'transform');
    const tilemapEntities: Entity[] = world.query('tilemapCollider');
    let tilemap: TilemapCollider | undefined = undefined;
    if (tilemapEntities.length > 0) {
      tilemap = world.getComponent<TilemapCollider>(tilemapEntities[0], 'tilemapCollider');
    }

    for (const e of bodies) {
      const body: RigidBody | undefined = world.getComponent<RigidBody>(e, 'rigidBody');
      const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
      const collider: Collider | undefined = world.getComponent<Collider>(e, 'collider');
      if (!body || !transform) continue;
      if (body.isKinematic) continue;

      body.vy += this.gravity * body.gravityScale * (dt / 16);
      if (body.vy > this.maxFallSpeed) body.vy = this.maxFallSpeed;

      if (body.onGround) {
        body.vx *= body.friction;
      }
      if (Math.abs(body.vx) < 0.1) body.vx = 0;
      if (body.vx > MAX_MOVE_SPEED) body.vx = MAX_MOVE_SPEED;
      if (body.vx < -MAX_MOVE_SPEED) body.vx = -MAX_MOVE_SPEED;

      const stepX: number = body.vx * (dt / 16);
      const stepY: number = body.vy * (dt / 16);

      const w: number = collider ? collider.width : 16;
      const h: number = collider ? collider.height : 16;

      transform.x += stepX;
      if (tilemap) {
        this.resolveTileCollisionX(world, transform, body, w, h, tilemap);
      }

      transform.y += stepY;
      if (tilemap) {
        this.resolveTileCollisionY(world, transform, body, w, h, tilemap);
      }

      if (collider) {
        collider.onCollisionEnter = false;
      }
    }
  }

  private resolveTileCollisionX(
    world: World, transform: Transform, body: RigidBody,
    w: number, h: number, tilemap: TilemapCollider
  ): void {
    const tileSize: number = tilemap.tileSize;
    const top: number = Math.floor(transform.y / tileSize);
    const bottom: number = Math.floor((transform.y + h - 1) / tileSize);
    const margin: number = 1;

    if (body.vx < 0) {
      const tileX: number = Math.floor(transform.x / tileSize);
      for (let ty: number = top; ty <= bottom; ty++) {
        if (tileX >= 0 && ty >= 0 && ty < tilemap.tileMap.length &&
          tileX < tilemap.tileMap[ty].length) {
          const tile: number = tilemap.tileMap[ty][tileX];
          if (tilemap.isSolid(tile)) {
            transform.x = (tileX + 1) * tileSize + margin;
            body.vx = body.bounciness > 0 ? -body.vx * body.bounciness : 0;
            body.onWall = true;
            return;
          }
        }
      }
    } else if (body.vx > 0) {
      const tileX: number = Math.floor((transform.x + w) / tileSize);
      for (let ty: number = top; ty <= bottom; ty++) {
        if (tileX >= 0 && ty >= 0 && ty < tilemap.tileMap.length &&
          tileX < tilemap.tileMap[ty].length) {
          const tile: number = tilemap.tileMap[ty][tileX];
          if (tilemap.isSolid(tile)) {
            transform.x = tileX * tileSize - w - margin;
            body.vx = body.bounciness > 0 ? -body.vx * body.bounciness : 0;
            body.onWall = true;
            return;
          }
        }
      }
    }
    body.onWall = false;
  }

  private resolveTileCollisionY(
    world: World, transform: Transform, body: RigidBody,
    w: number, h: number, tilemap: TilemapCollider
  ): void {
    const tileSize: number = tilemap.tileSize;
    const left: number = Math.floor(transform.x / tileSize);
    const right: number = Math.floor((transform.x + w - 1) / tileSize);

    if (body.vy < 0) {
      const tileY: number = Math.floor(transform.y / tileSize);
      for (let tx: number = left; tx <= right; tx++) {
        if (tileY >= 0 && tileY < tilemap.tileMap.length &&
          tx >= 0 && tx < tilemap.tileMap[tileY].length) {
          const tile: number = tilemap.tileMap[tileY][tx];
          if (tilemap.isSolid(tile)) {
            transform.y = (tileY + 1) * tileSize + 1;
            body.vy = body.bounciness > 0 ? -body.vy * body.bounciness : 0;
            body.onGround = false;
            return;
          }
        }
      }
    } else if (body.vy > 0) {
      const tileY: number = Math.floor((transform.y + h) / tileSize);
      for (let tx: number = left; tx <= right; tx++) {
        if (tileY >= 0 && tileY < tilemap.tileMap.length &&
          tx >= 0 && tx < tilemap.tileMap[tileY].length) {
          const tile: number = tilemap.tileMap[tileY][tx];
          if (tilemap.isSolid(tile)) {
            transform.y = tileY * tileSize - h - 1;
            body.vy = 0;
            body.onGround = true;
            return;
          }
        }
      }
      body.onGround = false;
    }
  }

  checkEntityCollision(
    ax: number, ay: number, aw: number, ah: number,
    bx: number, by: number, bw: number, bh: number
  ): boolean {
    return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
  }
}
