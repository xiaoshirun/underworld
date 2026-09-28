import { audio } from '@kit.AudioKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

export interface ScreenSize {
  width: number;
  height: number;
}

export interface AudioRendererAdapter {
  write(pcmData: ArrayBuffer): void;
  start(): void;
  stop(): void;
  release(): void;
}

class AudioRendererImpl implements AudioRendererAdapter {
  private renderer: audio.AudioRenderer;

  constructor(renderer: audio.AudioRenderer) {
    this.renderer = renderer;
  }

  write(pcmData: ArrayBuffer): void {
    // AudioRenderer uses callback model; write is handled via on('writeData')
  }

  start(): void {
    this.renderer.start().catch((): void => {});
  }

  stop(): void {
    this.renderer.stop().catch((): void => {});
  }

  release(): void {
    this.renderer.release().catch((): void => {});
  }
}

export class HarmonyOSPlatform {
  private static appContext: common.UIAbilityContext | null = null;

  static setContext(context: common.UIAbilityContext): void {
    HarmonyOSPlatform.appContext = context;
  }

  static getContext(): common.UIAbilityContext | null {
    return HarmonyOSPlatform.appContext;
  }

  static now(): number {
    return Date.now();
  }

  static getScreenSize(): ScreenSize {
    return { width: 960, height: 540 } as ScreenSize;
  }

  static async saveData(key: string, value: string): Promise<void> {
    if (!HarmonyOSPlatform.appContext) return;
    try {
      const pref = await preferences.getPreferences(HarmonyOSPlatform.appContext, 'engine_prefs');
      await pref.put(key, value);
      await pref.flush();
    } catch (e) {
      console.error('[Platform] saveData failed: ' + JSON.stringify(e));
    }
  }

  static async loadData(key: string): Promise<string | null> {
    if (!HarmonyOSPlatform.appContext) return null;
    try {
      const pref = await preferences.getPreferences(HarmonyOSPlatform.appContext, 'engine_prefs');
      const value: string = await pref.get(key, '') as string;
      return value.length > 0 ? value : null;
    } catch (e) {
      return null;
    }
  }

  static async loadRawFile(path: string): Promise<ArrayBuffer> {
    if (!HarmonyOSPlatform.appContext) return new ArrayBuffer(0);
    try {
      const mgr = HarmonyOSPlatform.appContext.resourceManager;
      const buffer: ArrayBuffer = await mgr.getRawFileContent(path);
      return buffer;
    } catch (e) {
      console.error('[Platform] loadRawFile failed: ' + path);
      return new ArrayBuffer(0);
    }
  }

  static async createAudioRenderer(sampleRate: number): Promise<AudioRendererAdapter | null> {
    try {
      let samplingRate: audio.AudioSamplingRate = audio.AudioSamplingRate.SAMPLE_RATE_44100;
      if (sampleRate === 8000) {
        samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_8000;
      } else if (sampleRate === 16000) {
        samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_16000;
      } else if (sampleRate === 22050) {
        samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_22050;
      } else if (sampleRate === 48000) {
        samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_48000;
      } else if (sampleRate === 64000) {
        samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_64000;
      } else if (sampleRate === 96000) {
        samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_96000;
      }
      const renderer: audio.AudioRenderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: samplingRate,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_GAME,
          rendererFlags: 0
        }
      });
      return new AudioRendererImpl(renderer);
    } catch (e) {
      console.error('[Platform] createAudioRenderer failed');
      return null;
    }
  }
}
