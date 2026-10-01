import { image } from '@kit.ImageKit';

export interface RawFileDescriptor {
  fd: number;
  length: number;
}

export interface RawFileProvider {
  getRawFileContent(path: string): Promise<ArrayBuffer>;
  getRawFileDescriptor(path: string): Promise<RawFileDescriptor>;
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
      const descriptor: RawFileDescriptor = await this.fileProvider.getRawFileDescriptor(filePath);
      const imageSource: image.ImageSource = image.createImageSource(descriptor.fd);
      const imageInfo: image.ImageInfo = await imageSource.getImageInfo();
      const cols: number = Math.floor(imageInfo.size.width / frameWidth);
      const rows: number = Math.floor(imageInfo.size.height / frameHeight);
      const sheet: SpriteSheet = new SpriteSheet();
      sheet.frameWidth = frameWidth;
      sheet.frameHeight = frameHeight;
      for (let row: number = 0; row < rows; row++) {
        for (let col: number = 0; col < cols; col++) {
          const frameSize: image.Size = { width: frameWidth, height: frameHeight } as image.Size;
          const frameRegion: image.Region = {
            x: col * frameWidth,
            y: row * frameHeight,
            size: frameSize
          } as image.Region;
          const opts: image.DecodingOptions = { desiredRegion: frameRegion };
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
    const descriptor: RawFileDescriptor = await this.fileProvider.getRawFileDescriptor(filePath);
    const imageSource: image.ImageSource = image.createImageSource(descriptor.fd);
    const pixelMap: image.PixelMap = await imageSource.createPixelMap();
    imageSource.release();
    return pixelMap;
  }
}
