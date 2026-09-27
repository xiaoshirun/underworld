import { audio } from '@kit.AudioKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

export interface AudioRendererAdapter {
  write(pcmData: ArrayBuffer): void;
  start(): void;
  stop(): void;
  release(): void;
}

export class HarmonyOSPlatform {
  private static appContext: common.UIAbilityContext | null = null;

  static setContext(context: common.UIAbilityContext): void {
    this.appContext = context;
  }

  static getContext(): common.UIAbilityContext | null {
    return this.appContext;
  }

  static now(): number {
    return Date.now();
  }

  static getScreenSize(): { width: number; height: number } {
    return { width: 960, height: 540 };
  }

  static async saveData(key: string, value: string): Promise<void> {
    if (!this.appContext) return;
    try {
      const pref = await preferences.getPreferences(this.appContext, 'engine_prefs');
      await pref.put(key, value);
      await pref.flush();
    } catch (e) {
      console.error('[Platform] saveData failed: ' + JSON.stringify(e));
    }
  }

  static async loadData(key: string): Promise<string | null> {
    if (!this.appContext) return null;
    try {
      const pref = await preferences.getPreferences(this.appContext, 'engine_prefs');
      const value: string = await pref.get(key, '') as string;
      return value.length > 0 ? value : null;
    } catch (e) {
      return null;
    }
  }

  static async loadRawFile(path: string): Promise<ArrayBuffer> {
    if (!this.appContext) return new ArrayBuffer(0);
    try {
      const mgr: resourceManager.ResourceManager = this.appContext.resourceManager;
      const buffer: ArrayBuffer = await mgr.getRawFileContent(path);
      return buffer;
    } catch (e) {
      console.error('[Platform] loadRawFile failed: ' + path);
      return new ArrayBuffer(0);
    }
  }

  static async createAudioRenderer(sampleRate: number): Promise<AudioRendererAdapter | null> {
    try {
      const renderer: audio.AudioRenderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_GAME,
          rendererFlags: 0
        }
      });
      return {
        write(pcmData: ArrayBuffer): void {
          // AudioRenderer uses callback model; write is handled via on('writeData')
        },
        start(): void {
          renderer.start().catch((): void => {});
        },
        stop(): void {
          renderer.stop().catch((): void => {});
        },
        release(): void {
          renderer.release().catch((): void => {});
        }
      };
    } catch (e) {
      console.error('[Platform] createAudioRenderer failed');
      return null;
    }
  }
}
