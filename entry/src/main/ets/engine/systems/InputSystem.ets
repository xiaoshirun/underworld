// entry/src/main/ets/engine/systems/InputSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { PlayerInput } from '../components/PlayerInput';

export class InputSystem extends System {
  readonly name: string = 'input';
  readonly dependencies: string[] = [];
  priority: number = 0;

  private pendingMoveX: number = 0;
  private pendingMoveY: number = 0;
  private pendingAttack: boolean = false;
  private pendingJump: boolean = false;
  private pendingDash: boolean = false;
  private pendingTool: boolean = false;
  private pendingInteract: boolean = false;

  private attackBufferTimer: number = 0;
  private jumpBufferTimer: number = 0;
  private dashBufferTimer: number = 0;
  private readonly BUFFER_WINDOW: number = 150;

  setInput(moveX: number, moveY: number, attack: boolean, jump: boolean, dash: boolean, tool: boolean, interact: boolean): void {
    this.pendingMoveX = moveX;
    this.pendingMoveY = moveY;
    if (attack) this.attackBufferTimer = this.BUFFER_WINDOW;
    if (jump) this.jumpBufferTimer = this.BUFFER_WINDOW;
    if (dash) this.dashBufferTimer = this.BUFFER_WINDOW;
    this.pendingAttack = attack;
    this.pendingJump = jump;
    this.pendingDash = dash;
    this.pendingTool = tool;
    this.pendingInteract = interact;
  }

  update(world: World, dt: number, entities: Entity[]): void {
    if (this.attackBufferTimer > 0) this.attackBufferTimer -= dt;
    if (this.jumpBufferTimer > 0) this.jumpBufferTimer -= dt;
    if (this.dashBufferTimer > 0) this.dashBufferTimer -= dt;

    const inputs: Entity[] = world.query('playerInput');
    for (const e of inputs) {
      const input: PlayerInput | undefined = world.getComponent<PlayerInput>(e, 'playerInput');
      if (!input) continue;

      input.moveX = this.pendingMoveX;
      input.moveY = this.pendingMoveY;
      input.attackPressed = this.attackBufferTimer > 0;
      input.jumpPressed = this.jumpBufferTimer > 0;
      input.dashPressed = this.dashBufferTimer > 0;
      input.toolPressed = this.pendingTool;
      input.interactPressed = this.pendingInteract;
    }
  }
}
