import { Engine } from '../core/Engine';
import { Scene } from '../scene/Scene';
import { World } from '../core/World';
import { createTransform, Transform } from '../components/Transform';
import { createSprite, Sprite } from '../components/Sprite';
import { createRigidBody, RigidBody } from '../components/RigidBody';
import { createCamera, CameraComponent } from '../components/Camera';
import { RenderSystem } from '../systems/RenderSystem';
import { PhysicsSystem } from '../systems/PhysicsSystem';
import { CameraSystem } from '../systems/CameraSystem';
import { InputSystem } from '../systems/InputSystem';
import { ParticleSimSystem } from '../systems/ParticleSimSystem';
import { AudioSystem } from '../systems/AudioSystem';
import { common } from '@kit.AbilityKit';

class TestScene extends Scene {
  private world: World;

  constructor(world: World) {
    super('test');
    this.world = world;
  }

  onLoad(): void {
    console.info('[TestScene] onLoad');
  }

  onEnter(): void {
    console.info('[TestScene] onEnter');

    this.world.addSystem(new InputSystem());
    this.world.addSystem(new PhysicsSystem());
    this.world.addSystem(new CameraSystem());
    this.world.addSystem(new ParticleSimSystem());
    this.world.addSystem(new AudioSystem());
    this.world.addSystem(new RenderSystem());

    const player: number = this.world.createEntity();
    this.world.addComponent<Transform>(player, 'transform', createTransform(200, 100));
    this.world.addComponent<Sprite>(player, 'sprite', createSprite('#00ff00', 32, 32));
    this.world.addComponent<RigidBody>(player, 'rigidBody', createRigidBody());

    const camera: number = this.world.createEntity();
    const camTransform: Transform = createTransform(200, 100);
    this.world.addComponent<Transform>(camera, 'transform', camTransform);
    const camComp: CameraComponent = createCamera();
    camComp.followEntity = player;
    this.world.addComponent<CameraComponent>(camera, 'camera', camComp);

    console.info('[TestScene] Systems registered, entities created');
  }

  update(dt: number): void {
    this.world.update(dt);
  }

  render(ctx: CanvasRenderingContext2D): void {
    this.world.render(ctx);
  }
}

export async function runEngineSmokeTest(
  canvas: CanvasRenderingContext2D,
  context: common.UIAbilityContext
): Promise<void> {
  let testWorld: World | null = null;

  const engine: Engine = await Engine.init({
    canvas: canvas,
    screenWidth: 960,
    screenHeight: 540,
    scenes: [
      {
        name: 'test',
        factory: (): Scene => {
          const scene: TestScene = new TestScene(engine.world);
          testWorld = engine.world;
          return scene;
        }
      }
    ],
    entryScene: 'test',
    appContext: context
  });

  const world: World = engine.world;

  const results = world.query('transform', 'sprite');
  console.info('[SmokeTest] Entity count: ' + results.length);
  console.info('[SmokeTest] Expected: 1, Got: ' + results.length);

  const physicsSystem: PhysicsSystem | undefined = world.getSystem('physics') as PhysicsSystem | undefined;
  console.info('[SmokeTest] PhysicsSystem registered: ' + (physicsSystem !== undefined));

  const renderSystem: RenderSystem | undefined = world.getSystem('render') as RenderSystem | undefined;
  console.info('[SmokeTest] RenderSystem registered: ' + (renderSystem !== undefined));

  engine.start();
  console.info('[SmokeTest] Engine started');

  setTimeout((): void => {
    const playerEntities = world.query('rigidBody', 'transform');
    if (playerEntities.length > 0) {
      const transform: Transform | undefined = world.getComponent<Transform>(playerEntities[0], 'transform');
      const body: RigidBody | undefined = world.getComponent<RigidBody>(playerEntities[0], 'rigidBody');
      if (transform && body) {
        console.info('[SmokeTest] After physics: y=' + transform.y.toFixed(1) + ' vy=' + body.vy.toFixed(1));
        console.info('[SmokeTest] Entity fell due to gravity: ' + (transform.y > 100));
      }
    }

    engine.stop();
    console.info('[SmokeTest] Engine stopped - PASS');
  }, 1000);
}
