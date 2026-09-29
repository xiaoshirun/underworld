import { image } from '@kit.ArkUI';

export interface RawFileProvider {
  getRawFileContent(path: string): Promise<ArrayBuffer>;
}

export class SpriteSheet {
  frames: image.PixelMap[] = [];
  frameWidth: number = 0;
  frameHeight: number = 0;

  getFrame(index: number): image.PixelMap | undefined {
    if (index >= 0 && index < this.frames.length) {
      return this.frames[index];
    }
    return undefined;
  }

  getFrameCount(): number {
    return this.frames.length;
  }
}

export class ResourceManager {
  private images: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private spriteSheets: Map<string, SpriteSheet> = new Map<string, SpriteSheet>();
  private fileProvider: RawFileProvider | null = null;
  loadingCount: number = 0;

  setFileProvider(provider: RawFileProvider): void {
    this.fileProvider = provider;
  }

  async loadImage(key: string, filePath: string): Promise<image.PixelMap> {
    const cached: image.PixelMap | undefined = this.images.get(key);
    if (cached !== undefined) {
      return cached;
    }
    this.loadingCount++;
    try {
      const pixelMap: image.PixelMap = await this.loadPixelMap(filePath);
      this.images.set(key, pixelMap);
      return pixelMap;
    } finally {
      this.loadingCount--;
    }
  }

  async loadSpriteSheet(key: string, filePath: string,
    frameWidth: number, frameHeight: number): Promise<SpriteSheet> {
    const cacheKey: string = `${filePath}_${frameWidth}_${frameHeight}`;
    const cached: SpriteSheet | undefined = this.spriteSheets.get(cacheKey);
    if (cached !== undefined) {
      this.spriteSheets.set(key, cached);
      return cached;
    }
    this.loadingCount++;
    try {
      if (this.fileProvider === null) {
        throw new Error('RawFileProvider not set. Call setFileProvider() first.');
      }
      const buffer: ArrayBuffer = await this.fileProvider.getRawFileContent(filePath);
      const imageSource: image.ImageSource = image.createImageSource(buffer);
      const imageInfo: image.ImageInfo = await imageSource.getImageInfo();
      const cols: number = Math.floor(imageInfo.size.width / frameWidth);
      const rows: number = Math.floor(imageInfo.size.height / frameHeight);
      const sheet: SpriteSheet = new SpriteSheet();
      sheet.frameWidth = frameWidth;
      sheet.frameHeight = frameHeight;
      for (let row: number = 0; row < rows; row++) {
        for (let col: number = 0; col < cols; col++) {
          const opts: image.DecodingOptions = {
            srcRegion: {
              x: col * frameWidth,
              y: row * frameHeight,
              size: { width: frameWidth, height: frameHeight }
            }
          };
          const frame: image.PixelMap = await imageSource.createPixelMap(opts);
          sheet.frames.push(frame);
        }
      }
      imageSource.release();
      this.spriteSheets.set(cacheKey, sheet);
      this.spriteSheets.set(key, sheet);
      return sheet;
    } finally {
      this.loadingCount--;
    }
  }

  getImage(key: string): image.PixelMap | undefined {
    return this.images.get(key);
  }

  getSpriteSheet(key: string): SpriteSheet | undefined {
    return this.spriteSheets.get(key);
  }

  getLoadedCount(): number {
    return this.images.size;
  }

  private async loadPixelMap(filePath: string): Promise<image.PixelMap> {
    if (this.fileProvider === null) {
      throw new Error('RawFileProvider not set. Call setFileProvider() first.');
    }
    const buffer: ArrayBuffer = await this.fileProvider.getRawFileContent(filePath);
    const imageSource: image.ImageSource = image.createImageSource(buffer);
    const pixelMap: image.PixelMap = await imageSource.createPixelMap();
    imageSource.release();
    return pixelMap;
  }
}
