import { PLAYER_MAX_HP, PlayerState, GameState } from '../GameConstants';
import { GameContext } from '../GameContext';

export interface DamageBridge {
  autoSave(): void;
  setState(state: GameState): void;
}

export class DamageSystem {
  private g: GameContext;
  private bridge: DamageBridge;

  constructor(g: GameContext, bridge: DamageBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  update(dt: number): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    if (this.g.damageFlashTimer > 0) {
      this.g.damageFlashTimer -= dt;
      if (this.g.damageFlashTimer < 0) this.g.damageFlashTimer = 0;
    }

    if (p.hp <= 0 && this.g.state === GameState.PLAYING) {
      this.handlePlayerDeath(p);
    }
  }

  private handlePlayerDeath(p: PlayerState): void {
    p.hp = 0;

    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.explosion(p.x, p.y, '#ef4444', 20);
      this.g.particleMgr.sparks(p.x, p.y, '#fbbf24', 12);
    }
    this.g.shakeTimer = 500;
    this.g.audio.playPlayerDamage();

    this.bridge.autoSave();
    this.bridge.setState(GameState.GAME_OVER);
  }
}
