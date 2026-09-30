import { System, SystemContext, Entity, HealthComponent } from '@qiuyu/engine';
import { GameStateComponent } from '../components/GameStateComponent';
import { GameState } from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class DamageSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    const gameStateEntity: Entity | null = context.world.findEntityByTag("gameState");
    if (player === null || gameStateEntity === null) return;

    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const gs: GameStateComponent | null = gameStateEntity.getComponent<GameStateComponent>("gameState");
    if (health === null || gs === null) return;

    const dt: number = context.dt;

    // Decay damage flash timer
    if (gs.damageFlashTimer > 0) {
      gs.damageFlashTimer -= dt;
      if (gs.damageFlashTimer < 0) {
        gs.damageFlashTimer = 0;
      }
    }

    // Check for player death
    if (health.isDead() && gs.state === (GameState.PLAYING as number)) {
      health.current = 0;

      const audio: IAudioService = context.audio as IAudioService;
      audio.playPlayerDamage();

      gs.state = GameState.GAME_OVER as number;
    }
  }
}
