export interface Health {
  current: number;
  max: number;
  invincibleTimer: number;
}

export function createHealth(max: number): Health {
  return { current: max, max: max, invincibleTimer: 0 };
}
