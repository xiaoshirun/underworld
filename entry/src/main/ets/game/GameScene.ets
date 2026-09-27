import { Scene } from '../engine/scene/Scene';
import { World } from '../engine/core/World';
import { RenderSystem } from '../engine/systems/RenderSystem';
import { PhysicsSystem } from '../engine/systems/PhysicsSystem';
import { CameraSystem } from '../engine/systems/CameraSystem';
import { InputSystem } from '../engine/systems/InputSystem';
import { ParticleSimSystem } from '../engine/systems/ParticleSimSystem';
import { AudioSystem } from '../engine/systems/AudioSystem';

export class GameScene extends Scene {
  private world: World;

  constructor(world: World) {
    super('game');
    this.world = world;
  }

  onLoad(): void {
    this.world.addSystem(new InputSystem());
    this.world.addSystem(new PhysicsSystem());
    this.world.addSystem(new CameraSystem());
    this.world.addSystem(new ParticleSimSystem());
    this.world.addSystem(new AudioSystem());
    this.world.addSystem(new RenderSystem());
  }

  onEnter(): void {
  }

  update(dt: number): void {
    this.world.update(dt);
  }

  render(ctx: CanvasRenderingContext2D): void {
    this.world.render(ctx);
  }
}
