export interface RigidBody {
  vx: number;
  vy: number;
  mass: number;
  gravityScale: number;
  friction: number;
  bounciness: number;
  isKinematic: boolean;
  onGround: boolean;
  onWall: boolean;
}

export function createRigidBody(): RigidBody {
  return { vx: 0, vy: 0, mass: 1.0, gravityScale: 1.0, friction: 0.85, bounciness: 0.0, isKinematic: false, onGround: false, onWall: false };
}
