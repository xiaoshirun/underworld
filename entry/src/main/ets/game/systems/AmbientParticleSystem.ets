import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { AmbientParticle, BiomeType } from '../GameConstants';
import { WorldGenerator } from '../WorldGenerator';

export class AmbientParticleSystem extends System {
  private particles: AmbientParticle[] = [];
  private maxParticles: number = 30;
  private initialized: boolean = false;

  update(entities: Entity[], context: SystemContext): void {
    if (!this.initialized) {
      this.initParticles(context);
      this.initialized = true;
    }

    const dt: number = context.dt;
    let playerBiome: BiomeType = BiomeType.NORMAL;
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player !== null && player.hasComponent("Position")) {
      const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
      const wg: WorldGenerator | null = context.world.worldGen as WorldGenerator | null;
      if (wg !== null) {
        playerBiome = wg.getBiome(pos.x, pos.y);
      }
    }

    for (let i: number = 0; i < this.particles.length; i++) {
      const ap: AmbientParticle = this.particles[i];
      ap.x += ap.vx;
      ap.y += ap.vy;
      ap.life -= dt;
      if (ap.life <= 0 || ap.y < -10 || ap.x < -10 || ap.x > context.screenW + 10) {
        ap.x = Math.random() * context.screenW;
        ap.y = context.screenH + 5;
        ap.life = ap.maxLife;
        ap.alpha = 0.1 + Math.random() * 0.25;
        switch (playerBiome) {
          case BiomeType.CRYSTAL:
            ap.color = Math.random() < 0.5 ? '#00ced150' : '#e0ffff40';
            ap.vx = (Math.random() - 0.5) * 0.5;
            ap.vy = -0.15 - Math.random() * 0.35;
            ap.size = 1 + Math.random() * 2;
            break;
          case BiomeType.MUSHROOM:
            ap.color = Math.random() < 0.5 ? '#ff69b435' : '#da70d640';
            ap.vx = (Math.random() - 0.5) * 0.2;
            ap.vy = -0.05 - Math.random() * 0.15;
            ap.size = 1.5 + Math.random() * 3;
            break;
          case BiomeType.WATER:
            ap.color = Math.random() < 0.5 ? '#1e90ff35' : '#00bfff40';
            ap.vx = (Math.random() - 0.5) * 0.15;
            ap.vy = -0.2 - Math.random() * 0.3;
            ap.size = 1 + Math.random() * 2.5;
            break;
          case BiomeType.LAVA:
            ap.color = Math.random() < 0.5 ? '#ff450045' : '#ff634840';
            ap.vx = (Math.random() - 0.5) * 0.4;
            ap.vy = -0.3 - Math.random() * 0.5;
            ap.size = 1 + Math.random() * 2;
            break;
          case BiomeType.SHADOW:
            ap.color = Math.random() < 0.6 ? '#7c3aed40' : '#4c1d9540';
            ap.vx = (Math.random() - 0.5) * 0.3;
            ap.vy = -0.2 - Math.random() * 0.4;
            ap.size = 1 + Math.random() * 2.5;
            break;
          default:
            const colors: string[] = ['#ffd70033', '#00ced133', '#ff69b433', '#4ade8033', '#60a5fa33'];
            ap.color = colors[Math.floor(Math.random() * colors.length)];
            ap.vx = (Math.random() - 0.5) * 0.3;
            ap.vy = -0.1 - Math.random() * 0.3;
            ap.size = 1 + Math.random() * 2.5;
            break;
        }
      }
    }
  }

  private initParticles(context: SystemContext): void {
    const colors: string[] = ['#ffd70033', '#00ced133', '#ff69b433', '#4ade8033', '#60a5fa33'];
    for (let i: number = 0; i < this.maxParticles; i++) {
      this.particles.push({
        x: Math.random() * context.screenW,
        y: Math.random() * context.screenH,
        vx: (Math.random() - 0.5) * 0.3,
        vy: -0.1 - Math.random() * 0.3,
        size: 1 + Math.random() * 2.5,
        alpha: 0.1 + Math.random() * 0.25,
        color: colors[Math.floor(Math.random() * colors.length)],
        life: Math.random() * 4000,
        maxLife: 3000 + Math.random() * 3000
      });
    }
  }
}
