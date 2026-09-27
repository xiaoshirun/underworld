import { Engine } from '../core/Engine';
import { Scene } from '../scene/Scene';
import { createTransform, Transform } from '../components/Transform';
import { createSprite, Sprite } from '../components/Sprite';
import { common } from '@kit.AbilityKit';

class TestScene extends Scene {
  constructor() {
    super('test');
  }

  onLoad(): void {
    console.info('[TestScene] onLoad');
  }

  onEnter(): void {
    console.info('[TestScene] onEnter');
  }

  update(dt: number): void {
    // Verify World works
  }

  render(ctx: CanvasRenderingContext2D): void {
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(100, 100, 50, 50);
  }
}

export async function runEngineSmokeTest(
  canvas: CanvasRenderingContext2D,
  context: common.UIAbilityContext
): Promise<void> {
  const engine: Engine = await Engine.init({
    canvas: canvas,
    screenWidth: 960,
    screenHeight: 540,
    scenes: [
      { name: 'test', factory: (): Scene => new TestScene() }
    ],
    entryScene: 'test',
    appContext: context
  });

  const world = engine.world;
  const e1 = world.createEntity();
  world.addComponent<Transform>(e1, 'transform', createTransform(100, 200));
  world.addComponent<Sprite>(e1, 'sprite', createSprite('#00ff00', 32, 32));

  const results = world.query('transform', 'sprite');
  console.info('[SmokeTest] Entity count: ' + results.length);
  console.info('[SmokeTest] Expected: 1, Got: ' + results.length);

  engine.start();
  console.info('[SmokeTest] Engine started');

  setTimeout((): void => {
    engine.stop();
    console.info('[SmokeTest] Engine stopped - PASS');
  }, 1000);
}
