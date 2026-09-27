export type Entity = number;

const INDEX_MASK: number = 0xFFFF;
const GENERATION_SHIFT: number = 16;

export function makeEntity(index: number, generation: number): Entity {
  return (generation << GENERATION_SHIFT) | index;
}

export function getIndex(entity: Entity): number {
  return entity & INDEX_MASK;
}

export function getGeneration(entity: Entity): number {
  return entity >> GENERATION_SHIFT;
}

export class EntityPool {
  private generations: number[] = [];
  private available: number[] = [];
  private alive: boolean[] = [];
  private nextIndex: number = 0;

  acquire(): Entity {
    if (this.available.length > 0) {
      const index: number = this.available.pop()!;
      this.alive[index] = true;
      return makeEntity(index, this.generations[index]);
    }
    const index: number = this.nextIndex;
    this.nextIndex++;
    this.generations[index] = 0;
    this.alive[index] = true;
    return makeEntity(index, 0);
  }

  release(entity: Entity): void {
    const index: number = getIndex(entity);
    if (!this.alive[index]) return;
    this.alive[index] = false;
    this.generations[index]++;
    this.available.push(index);
  }

  isValid(entity: Entity): boolean {
    const index: number = getIndex(entity);
    const generation: number = getGeneration(entity);
    return index < this.nextIndex &&
      this.alive[index] === true &&
      this.generations[index] === generation;
  }

  isAlive(index: number): boolean {
    return index < this.nextIndex && this.alive[index] === true;
  }
}
