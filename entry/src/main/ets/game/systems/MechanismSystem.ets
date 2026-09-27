import {
  TILE_SIZE, PLAYER_SIZE,
  MECH_INTERACT_RANGE, PUSH_BLOCK_SPEED, TELEPORT_COOLDOWN, PRESSURE_PLATE_RANGE,
  MechanismType, PlayerState, MechanismInstance, TileType,
  COLOR_DRILL_PARTICLE, COLOR_TELEPORT_RUNE,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export interface MechanismBridge {
  checkBreakableWalls(p: PlayerState): void;
}

export class MechanismSystem {
  private g: GameContext;
  private bridge: MechanismBridge;

  constructor(g: GameContext, bridge: MechanismBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  update(dt: number): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    if (this.g.teleportCooldown > 0) this.g.teleportCooldown -= dt;

    for (let i: number = 0; i < this.g.mechanisms.length; i++) {
      const mech: MechanismInstance = this.g.mechanisms[i];
      const dx: number = p.x - mech.x;
      const dy: number = p.y - mech.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE: {
          const wasActive: boolean = mech.active;
          mech.active = dist < PRESSURE_PLATE_RANGE;
          if (mech.active !== wasActive) {
            this.checkLinks(mech);
          }
          break;
        }

        case MechanismType.PUSH_BLOCK:
          if (mech.pushable && dist < PLAYER_SIZE + 12) {
            const pushDirX: number = p.vx;
            const pushDirY: number = p.vy;
            const pushLen: number = Math.sqrt(pushDirX * pushDirX + pushDirY * pushDirY);
            if (pushLen > 0.5) {
              const newX: number = mech.posX + (pushDirX / pushLen) * PUSH_BLOCK_SPEED;
              const newY: number = mech.posY + (pushDirY / pushLen) * PUSH_BLOCK_SPEED;
              const tileAtNew: number = this.g.getTile(newX, newY);
              if (tileAtNew === TileType.FLOOR || tileAtNew === TileType.BROKEN_WALL) {
                mech.posX = newX;
                mech.posY = newY;
                mech.x = newX;
                mech.y = newY;
                if (this.g.settings.effectsEnabled && this.g.frameCount % 3 === 0) {
                  this.g.spawnParticle(mech.x, mech.y + 8, (Math.random() - 0.5) * 0.5, -0.3, 300, COLOR_DRILL_PARTICLE, 2);
                }
              }
            }
          }
          break;

        case MechanismType.TELEPORT_RUNE:
          if (dist < MECH_INTERACT_RANGE && this.g.teleportCooldown <= 0) {
            const pairIndex: number = mech.linkedIndex;
            if (pairIndex >= 0 && pairIndex < this.g.mechanisms.length) {
              const paired: MechanismInstance = this.g.mechanisms[pairIndex];
              if (paired.mechanismType === MechanismType.TELEPORT_RUNE) {
                p.x = paired.x;
                p.y = paired.y;
                this.g.teleportCooldown = TELEPORT_COOLDOWN;
                this.g.audio.playDash();
                if (this.g.settings.effectsEnabled) {
                  for (let k: number = 0; k < 10; k++) {
                    const angle: number = Math.random() * Math.PI * 2;
                    const speed: number = 1.5 + Math.random() * 2;
                    this.g.spawnParticle(paired.x, paired.y,
                      Math.cos(angle) * speed, Math.sin(angle) * speed, 500, COLOR_TELEPORT_RUNE, 3);
                  }
                }
              }
            }
          }
          break;

        case MechanismType.LEVER:
          if (dist < MECH_INTERACT_RANGE && this.g.input.toolPressed) {
            this.g.input.toolPressed = false;
            mech.active = !mech.active;
            mech.rotation = mech.active ? 45 : -45;
            this.g.audio.playDrillHit();
            this.checkLinks(mech);
          }
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          if (dist < MECH_INTERACT_RANGE && this.g.input.toolPressed) {
            this.g.input.toolPressed = false;
            mech.rotation = (mech.rotation + 60) % 360;
            this.g.audio.playDrillHit();
          }
          break;
      }
    }

    this.bridge.checkBreakableWalls(p);
  }

  private checkLinks(mech: MechanismInstance): void {
    for (let i: number = 0; i < this.g.mechanisms.length; i++) {
      const other: MechanismInstance = this.g.mechanisms[i];
      if (other.linkedIndex >= 0 && other !== mech) {
        const linkedMech: MechanismInstance = this.g.mechanisms[other.linkedIndex];
        if (linkedMech === mech) {
          other.active = mech.active;
        }
      }
    }
  }
}
