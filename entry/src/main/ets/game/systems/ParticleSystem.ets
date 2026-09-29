import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { ParticleComponent } from '../components/ParticleComponent';

export class ParticleSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const dt: number = context.dt;
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || !e.hasComponent("particle")) continue;

      const p: ParticleComponent = e.getComponent<ParticleComponent>("particle")!;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;

      p.life -= dt;
      if (p.life <= 0) {
        e.active = false;
        continue;
      }

      pos.x += p.vx * dt / 16;
      pos.y += p.vy * dt / 16;
      p.vy += p.gravity * dt / 16;
    }
  }
}
