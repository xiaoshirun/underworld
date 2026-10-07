export class SpriteCache {
  private frames: Map<string, OffscreenCanvas> = new Map<string, OffscreenCanvas>();

  get(key: string): OffscreenCanvas | undefined {
    return this.frames.get(key);
  }

  set(key: string, canvas: OffscreenCanvas): void {
    this.frames.set(key, canvas);
  }

  has(key: string): boolean {
    return this.frames.has(key);
  }

  size(): number {
    return this.frames.size;
  }
}
