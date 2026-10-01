export class SpriteCache {
  private frames: Map<string, ImageBitmap> = new Map<string, ImageBitmap>();

  get(key: string): ImageBitmap | undefined {
    return this.frames.get(key);
  }

  set(key: string, bitmap: ImageBitmap): void {
    this.frames.set(key, bitmap);
  }

  has(key: string): boolean {
    return this.frames.has(key);
  }

  size(): number {
    return this.frames.size;
  }
}
