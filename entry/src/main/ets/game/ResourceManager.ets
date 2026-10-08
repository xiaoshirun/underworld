/**
 * Centralized ImageBitmap lifecycle manager with memory budget enforcement.
 *
 * Replaces scattered Map<string, ImageBitmap> + manual close() calls with:
 * - Automatic close() on removal/eviction (no leaked bitmaps)
 * - Memory budget tracking with FIFO eviction safety net
 * - Single destroy() for full cleanup
 */
export class ResourceManager {
  private entries: Map<string, ResourceEntry> = new Map();
  private totalBytes: number = 0;
  readonly budget: number;

  constructor(budget: number) {
    this.budget = budget;
  }

  /**
   * Store an ImageBitmap with its memory cost.
   * If adding this would exceed budget, evict oldest entries (FIFO) to make room.
   */
  put(key: string, bmp: ImageBitmap, bytes: number): void {
    // Remove old entry if key already exists
    if (this.entries.has(key)) {
      this.removeInternal(key);
    }
    // Evict oldest entries to make room (keep at least space for the new entry)
    while (this.totalBytes + bytes > this.budget && this.entries.size > 0) {
      const oldestKey: string | undefined = this.entries.keys().next().value;
      if (oldestKey !== undefined) {
        this.removeInternal(oldestKey);
      } else {
        break;
      }
    }
    // Add new entry
    this.entries.set(key, { bmp, bytes });
    this.totalBytes += bytes;
  }

  /** Get a bitmap by key (read-only, does not affect lifecycle) */
  get(key: string): ImageBitmap | undefined {
    const entry: ResourceEntry | undefined = this.entries.get(key);
    return entry?.bmp;
  }

  /** Check if a key exists */
  has(key: string): boolean {
    return this.entries.has(key);
  }

  /** Return all keys as an array */
  keys(): string[] {
    const result: string[] = [];
    this.entries.forEach((_entry: ResourceEntry, key: string) => {
      result.push(key);
    });
    return result;
  }

  /** Remove and close a specific bitmap */
  remove(key: string): void {
    this.removeInternal(key);
  }

  /** Total memory currently used (bytes) */
  get totalUsed(): number {
    return this.totalBytes;
  }

  /** Number of cached entries */
  get size(): number {
    return this.entries.size;
  }

  /** Check if memory usage exceeds budget */
  isOverBudget(): boolean {
    return this.totalBytes > this.budget;
  }

  /** Close all bitmaps and reset */
  destroy(): void {
    this.entries.forEach((entry: ResourceEntry) => {
      try { entry.bmp.close(); } catch (e) { /* ignore */ }
    });
    this.entries.clear();
    this.totalBytes = 0;
  }

  private removeInternal(key: string): void {
    const entry: ResourceEntry | undefined = this.entries.get(key);
    if (entry !== undefined) {
      try { entry.bmp.close(); } catch (e) { /* ignore */ }
      this.totalBytes -= entry.bytes;
      this.entries.delete(key);
    }
  }
}

interface ResourceEntry {
  bmp: ImageBitmap;
  bytes: number;
}
