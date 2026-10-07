export interface Component {
  getType(): string;
}

export class PositionComponent implements Component {
  x: number = 0;
  y: number = 0;

  constructor(x: number = 0, y: number = 0) {
    this.x = x;
    this.y = y;
  }

  getType(): string {
    return 'Position';
  }
}

export class VelocityComponent implements Component {
  vx: number = 0;
  vy: number = 0;

  constructor(vx: number = 0, vy: number = 0) {
    this.vx = vx;
    this.vy = vy;
  }

  getType(): string {
    return 'Velocity';
  }
}

export class HealthComponent implements Component {
  current: number = 100;
  max: number = 100;

  constructor(current: number = 100, max: number = 100) {
    this.current = current;
    this.max = max;
  }

  getType(): string {
    return 'Health';
  }

  isDead(): boolean {
    return this.current <= 0;
  }

  damage(amount: number): void {
    this.current = Math.max(0, this.current - amount);
  }

  heal(amount: number): void {
    this.current = Math.min(this.max, this.current + amount);
  }
}

export class SpriteComponent implements Component {
  color: string = '#ffffff';
  width: number = 16;
  height: number = 16;
  visible: boolean = true;

  getType(): string {
    return 'Sprite';
  }
}

export class ColliderComponent implements Component {
  width: number = 16;
  height: number = 16;
  offsetX: number = 0;
  offsetY: number = 0;
  isSolid: boolean = true;

  constructor(width: number = 16, height: number = 16, offsetX: number = 0,
              offsetY: number = 0, isSolid: boolean = true) {
    this.width = width;
    this.height = height;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.isSolid = isSolid;
  }

  getType(): string {
    return 'Collider';
  }
}

export interface Serializable {
  serialize(): Record<string, Object>;
  deserialize(data: Record<string, Object>): void;
}
