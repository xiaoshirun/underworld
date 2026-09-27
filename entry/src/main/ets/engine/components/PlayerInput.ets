export interface PlayerInput {
  moveX: number;
  moveY: number;
  attackPressed: boolean;
  jumpPressed: boolean;
  dashPressed: boolean;
  toolPressed: boolean;
  interactPressed: boolean;
}

export function createPlayerInput(): PlayerInput {
  return { moveX: 0, moveY: 0, attackPressed: false, jumpPressed: false, dashPressed: false, toolPressed: false, interactPressed: false };
}
