export enum ResourceType {
  TEXTURE = 'texture',
  AUDIO = 'audio',
  DATA = 'data',
  FONT = 'font'
}

interface ResourceEntry {
  key: string;
  type: ResourceType;
  data: Object | null;
  state: 'loading' | 'loaded' | 'error';
  refCount: number;
}

export class ResourceManager {
  private resources: Map<string, ResourceEntry> = new Map();
  private totalLoadCount: number = 0;
  private completedLoadCount: number = 0;

  async load(key: string, type: ResourceType, loader: () => Promise<Object>): Promise<Object | null> {
    const existing: ResourceEntry | undefined = this.resources.get(key);
    if (existing) {
      if (existing.state === 'loaded') return existing.data;
      if (existing.state === 'loading') return null;
    }

    const entry: ResourceEntry = {
      key: key,
      type: type,
      data: null,
      state: 'loading',
      refCount: 1
    };
    this.resources.set(key, entry);
    this.totalLoadCount++;

    try {
      const data: Object = await loader();
      entry.data = data;
      entry.state = 'loaded';
      this.completedLoadCount++;
      return data;
    } catch (e) {
      entry.state = 'error';
      this.completedLoadCount++;
      console.error('[ResourceManager] Failed to load: ' + key);
      return null;
    }
  }

  async loadAll(entries: { key: string; type: ResourceType; loader: () => Promise<Object> }[]): Promise<void> {
    const promises: Promise<Object | null>[] = [];
    for (const entry of entries) {
      promises.push(this.load(entry.key, entry.type, entry.loader));
    }
    await Promise.all(promises);
  }

  get<T>(key: string): T | null {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    if (!entry || entry.state !== 'loaded' || !entry.data) return null;
    return entry.data as T;
  }

  acquire(key: string): void {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    if (entry) {
      entry.refCount++;
    }
  }

  release(key: string): void {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    if (entry) {
      entry.refCount--;
      if (entry.refCount <= 0) {
        this.unload(key);
      }
    }
  }

  unload(key: string): void {
    this.resources.delete(key);
  }

  unloadUnused(): void {
    const toRemove: string[] = [];
    this.resources.forEach((entry: ResourceEntry, key: string) => {
      if (entry.refCount <= 0 && entry.state !== 'loading') {
        toRemove.push(key);
      }
    });
    for (const key of toRemove) {
      this.resources.delete(key);
    }
  }

  isLoaded(key: string): boolean {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    return entry !== undefined && entry.state === 'loaded';
  }

  getLoadProgress(): number {
    if (this.totalLoadCount === 0) return 1.0;
    return this.completedLoadCount / this.totalLoadCount;
  }

  resetProgress(): void {
    this.totalLoadCount = 0;
    this.completedLoadCount = 0;
  }
}
