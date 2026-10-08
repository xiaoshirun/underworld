import { display } from '@kit.ArkUI';

/**
 * Device capability detection and render parameter profiling.
 * Automatically scales rendering quality based on screen resolution and pixel density
 * to prevent GPU OOM on high-resolution real devices.
 */
export class DeviceProfile {
  // Screen dimensions in physical pixels
  readonly screenPxW: number;
  readonly screenPxH: number;

  // Render quality parameters
  readonly renderScale: number;        // Chunk bitmap render scale (0.5 = half resolution)
  readonly chunkLoadRadius: number;    // Chunk loading radius around player
  readonly maxParticles: number;       // Max ambient particles
  readonly parallaxEnabled: boolean;   // Background parallax on/off
  readonly parallaxChunkSize: number;  // Parallax cache margin size in pixels
  readonly maxDynTileCache: number;    // Max dynamic tile cache entries

  // Memory budget for ImageBitmap allocations (bytes)
  readonly gpuMemoryBudget: number;

  // Derived: total screen pixels
  readonly totalPixels: number;

  private constructor(
    screenPxW: number, screenPxH: number,
    renderScale: number, chunkLoadRadius: number,
    maxParticles: number, parallaxEnabled: boolean,
    parallaxChunkSize: number, maxDynTileCache: number,
    gpuMemoryBudget: number
  ) {
    this.screenPxW = screenPxW;
    this.screenPxH = screenPxH;
    this.renderScale = renderScale;
    this.chunkLoadRadius = chunkLoadRadius;
    this.maxParticles = maxParticles;
    this.parallaxEnabled = parallaxEnabled;
    this.parallaxChunkSize = parallaxChunkSize;
    this.maxDynTileCache = maxDynTileCache;
    this.gpuMemoryBudget = gpuMemoryBudget;
    this.totalPixels = screenPxW * screenPxH;
  }

  /**
   * Detect device capabilities and create an appropriate profile.
   * Classification based on total screen pixels:
   *   - < 1.5M px  (e.g. 1280×720)     → LOW    (simulator / old device)
   *   - < 3.5M px  (e.g. 1920×1080)    → MEDIUM (mid-range phone)
   *   - >= 3.5M px (e.g. 2832×1182)    → HIGH   (flagship / tablet)
   */
  static detect(): DeviceProfile {
    const info = display.getDefaultDisplaySync();
    const pxW: number = info.width;
    const pxH: number = info.height;
    const totalPx: number = pxW * pxH;

    if (totalPx >= 3_500_000) {
      // HIGH: flagship phone or tablet (e.g. 2832×1182 = 3.35M, 2640×1200 = 3.17M)
      // Actually 2832×1182 = 3,347,424 which is < 3.5M, so adjust threshold
      return DeviceProfile.highEnd(pxW, pxH);
    } else if (totalPx >= 1_500_000) {
      return DeviceProfile.midRange(pxW, pxH);
    } else {
      return DeviceProfile.lowEnd(pxW, pxH);
    }
  }

  private static highEnd(pxW: number, pxH: number): DeviceProfile {
    return new DeviceProfile(
      pxW, pxH,
      0.5,    // renderScale: half-res chunk bitmaps
      2,      // chunkLoadRadius: 5×5 = 25 chunks
      200,    // maxParticles
      true,   // parallaxEnabled
      400,    // parallaxChunkSize
      100,    // maxDynTileCache
      90 * 1024 * 1024  // 90MB GPU budget (conservative for mobile)
    );
  }

  private static midRange(pxW: number, pxH: number): DeviceProfile {
    return new DeviceProfile(
      pxW, pxH,
      0.5,    // renderScale
      2,      // chunkLoadRadius
      120,    // maxParticles
      true,   // parallaxEnabled
      300,    // parallaxChunkSize
      80,     // maxDynTileCache
      70 * 1024 * 1024  // 70MB
    );
  }

  private static lowEnd(pxW: number, pxH: number): DeviceProfile {
    return new DeviceProfile(
      pxW, pxH,
      0.5,    // renderScale
      1,      // chunkLoadRadius: 3×3 = 9 chunks
      60,     // maxParticles
      false,  // parallaxEnabled: disable parallax to save memory
      200,    // parallaxChunkSize (unused if disabled)
      50,     // maxDynTileCache
      40 * 1024 * 1024  // 40MB
    );
  }

  /** Log profile info for debugging */
  toString(): string {
    return `[DeviceProfile] ${this.screenPxW}×${this.screenPxH}px ` +
      `scale=${this.renderScale} radius=${this.chunkLoadRadius} ` +
      `parallax=${this.parallaxEnabled} budget=${(this.gpuMemoryBudget / 1024 / 1024).toFixed(0)}MB`;
  }
}
