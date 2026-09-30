import { System, SystemContext, Entity, PositionComponent, VelocityComponent } from '@qiuyu/engine';
import { MechanismComponent } from '../components/MechanismComponent';
import { MovementComponent } from '../components/MovementComponent';
import { shakeCamera, getTile, setTile } from '../helpers/SystemHelpers';
import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE,
  MECH_INTERACT_RANGE, PUSH_BLOCK_SPEED, TELEPORT_COOLDOWN, PRESSURE_PLATE_RANGE,
  MechanismType, TileType,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class MechanismSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const playerVel: VelocityComponent | null = player.getComponent<VelocityComponent>("Velocity");
    const playerMovement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    if (playerPos === null || playerVel === null || playerMovement === null) return;

    const audio: IAudioService = context.audio as IAudioService;
    const dt: number = context.dt;
    const chunks: Map<string, Object> = context.world.chunks;

    // Global teleport cooldown stored in first teleport rune entity extraData[0]
    let teleportEntity: Entity | null = null;
    let teleportCooldown: number = 0;
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (e.active && e.tag === "mechanism") {
        const m: MechanismComponent | null = e.getComponent<MechanismComponent>("mechanism");
        if (m !== null && m.mechanismType === MechanismType.TELEPORT_RUNE) {
          teleportEntity = e;
          if (m.extraData.length > 0) {
            teleportCooldown = m.extraData[0];
          }
          break;
        }
      }
    }
    if (teleportCooldown > 0) {
      teleportCooldown -= dt;
      if (teleportCooldown < 0) teleportCooldown = 0;
      if (teleportEntity !== null) {
        const m: MechanismComponent = teleportEntity.getComponent<MechanismComponent>("mechanism")!;
        if (m.extraData.length === 0) {
          m.extraData.push(teleportCooldown);
        } else {
          m.extraData[0] = teleportCooldown;
        }
      }
    }

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "mechanism") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const mech: MechanismComponent | null = e.getComponent<MechanismComponent>("mechanism");
      if (pos === null || mech === null) continue;

      const dx: number = playerPos.x - pos.x;
      const dy: number = playerPos.y - pos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE: {
          const wasActive: boolean = mech.active;
          mech.active = dist < PRESSURE_PLATE_RANGE;
          if (mech.active !== wasActive) {
            this.checkLinks(entities, mech);
          }
          break;
        }

        case MechanismType.PUSH_BLOCK: {
          if (mech.pushable && dist < PLAYER_SIZE + 12) {
            const pushDirX: number = playerVel.vx;
            const pushDirY: number = playerVel.vy;
            const pushLen: number = Math.sqrt(pushDirX * pushDirX + pushDirY * pushDirY);
            if (pushLen > 0.5) {
              const newX: number = mech.posX + (pushDirX / pushLen) * PUSH_BLOCK_SPEED;
              const newY: number = mech.posY + (pushDirY / pushLen) * PUSH_BLOCK_SPEED;
              const tileAtNew: number = getTile(chunks, newX, newY);
              if (tileAtNew === TileType.FLOOR || tileAtNew === TileType.BROKEN_WALL) {
                mech.posX = newX;
                mech.posY = newY;
                pos.x = newX;
                pos.y = newY;
              }
            }
          }
          break;
        }

        case MechanismType.TELEPORT_RUNE: {
          if (dist < MECH_INTERACT_RANGE && teleportCooldown <= 0) {
            const pairIndex: number = mech.linkedIndex;
            if (pairIndex >= 0) {
              // Find paired teleport rune by linkedIndex
              let pairCount: number = 0;
              for (let j: number = 0; j < entities.length; j++) {
                const other: Entity = entities[j];
                if (!other.active || other.tag !== "mechanism") continue;
                const otherMech: MechanismComponent | null = other.getComponent<MechanismComponent>("mechanism");
                if (otherMech === null || otherMech.mechanismType !== MechanismType.TELEPORT_RUNE) continue;
                if (pairCount === pairIndex) {
                  const otherPos: PositionComponent | null = other.getComponent<PositionComponent>("Position");
                  if (otherPos !== null) {
                    playerPos.x = otherPos.x;
                    playerPos.y = otherPos.y;
                    audio.playDash();
                    // Set teleport cooldown
                    if (teleportEntity !== null) {
                      const tm: MechanismComponent = teleportEntity.getComponent<MechanismComponent>("mechanism")!;
                      if (tm.extraData.length === 0) {
                        tm.extraData.push(TELEPORT_COOLDOWN);
                      } else {
                        tm.extraData[0] = TELEPORT_COOLDOWN;
                      }
                    }
                  }
                  break;
                }
                pairCount++;
              }
            }
          }
          break;
        }

        case MechanismType.LEVER: {
          if (dist < MECH_INTERACT_RANGE && context.input.toolPressed) {
            context.input.toolPressed = false;
            mech.active = !mech.active;
            mech.rotation = mech.active ? 45 : -45;
            audio.playDrillHit();
            this.checkLinks(entities, mech);
          }
          break;
        }

        case MechanismType.CRYSTAL_REFLECTOR: {
          if (dist < MECH_INTERACT_RANGE && context.input.toolPressed) {
            context.input.toolPressed = false;
            mech.rotation = (mech.rotation + 60) % 360;
            audio.playDrillHit();
          }
          break;
        }

        case MechanismType.BREAKABLE_WALL: {
          // Check if player is drilling this breakable wall
          if (playerMovement.isDrilling) {
            const mechTileX: number = Math.floor(pos.x / TILE_SIZE);
            const mechTileY: number = Math.floor(pos.y / TILE_SIZE);
            const drillTileX: number = playerMovement.drillTargetX;
            const drillTileY: number = playerMovement.drillTargetY;
            const tileDist: number = Math.abs(mechTileX - drillTileX) + Math.abs(mechTileY - drillTileY);
            if (tileDist <= 1) {
              // Break the wall tile
              setTile(chunks, pos.x, pos.y, TileType.BROKEN_WALL);
              audio.playWallBreak();
              shakeCamera(context, 100);
              playerMovement.isDrilling = false;
              playerMovement.drillHitCount = 0;
            }
          }
          break;
        }
      }
    }
  }

  private checkLinks(entities: Entity[], triggeredMech: MechanismComponent): void {
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "mechanism") continue;
      const other: MechanismComponent | null = e.getComponent<MechanismComponent>("mechanism");
      if (other === null || other === triggeredMech) continue;
      if (other.linkedIndex >= 0) {
        // Check if this mechanism is linked to the triggered one
        let mechCount: number = 0;
        for (let j: number = 0; j < entities.length; j++) {
          const ej: Entity = entities[j];
          if (!ej.active || ej.tag !== "mechanism") continue;
          if (mechCount === other.linkedIndex) {
            const linkedMech: MechanismComponent | null = ej.getComponent<MechanismComponent>("mechanism");
            if (linkedMech === triggeredMech) {
              other.active = triggeredMech.active;
            }
            break;
          }
          mechCount++;
        }
      }
    }
  }
}
