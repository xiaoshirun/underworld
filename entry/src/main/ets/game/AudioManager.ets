import { audio } from '@kit.AudioKit';
import { GameSettings } from './GameConstants';

const SAMPLE_RATE: number = 44100;
const POOL_SIZE: number = 6;
const TWO_PI: number = Math.PI * 2;
const BYTES_PER_SAMPLE: number = 2;

enum SoundId {
  DRILL_HIT = 'drill_hit',
  ENEMY_HIT = 'enemy_hit',
  ENEMY_DEATH = 'enemy_death',
  XP_COLLECT = 'xp_collect',
  DASH = 'dash',
  JUMP = 'jump',
  PLAYER_DAMAGE = 'player_damage',
  ENGULF = 'engulf',
  WALL_BREAK = 'wall_break',
  LEVEL_UP = 'level_up'
}

export class AudioManager {
  private settings: GameSettings = { soundEnabled: true, effectsEnabled: true };
  private renderers: audio.AudioRenderer[] = [];
  private releasedFlags: boolean[] = [];
  private soundBuffers: Map<string, ArrayBuffer> = new Map();
  private currentSounds: (ArrayBuffer | null)[] = [];
  private soundOffsets: number[] = [];
  private initialized: boolean = false;

  async init(): Promise<void> {
    if (this.initialized) return;
    try {
      this.generateAllSounds();
      for (let i = 0; i < POOL_SIZE; i++) {
        const renderer = await audio.createAudioRenderer({
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
        this.setupRenderer(renderer, i);
        this.renderers.push(renderer);
        this.releasedFlags.push(false);
        this.currentSounds.push(null);
        this.soundOffsets.push(0);
      }
      this.initialized = true;
    } catch (e) {
      console.error('[Audio] init failed: ' + JSON.stringify(e));
    }
  }

  setSettings(settings: GameSettings): void {
    this.settings = settings;
  }

  playDrillHit(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.DRILL_HIT);
  }

  playEnemyHit(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.ENEMY_HIT);
  }

  playEnemyDeath(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.ENEMY_DEATH);
  }

  playXpCollect(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.XP_COLLECT);
  }

  playDash(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.DASH);
  }

  playJump(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.JUMP);
  }

  playPlayerDamage(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.PLAYER_DAMAGE);
  }

  playEngulf(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.ENGULF);
  }

  playWallBreak(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.WALL_BREAK);
  }

  playLevelUp(): void {
    if (!this.settings.soundEnabled) return;
    this.playSound(SoundId.LEVEL_UP);
  }

  destroy(): void {
    for (let i = 0; i < this.renderers.length; i++) {
      this.releasedFlags[i] = true;
      this.currentSounds[i] = null;
      try {
        this.renderers[i].stop();
        this.renderers[i].release();
      } catch (e) {
        // ignore cleanup errors
      }
    }
    this.renderers = [];
    this.releasedFlags = [];
    this.currentSounds = [];
    this.soundOffsets = [];
    this.initialized = false;
  }

  private setupRenderer(renderer: audio.AudioRenderer, idx: number): void {
    renderer.on('writeData', (buffer: ArrayBuffer): audio.AudioDataCallbackResult => {
      if (this.releasedFlags[idx]) {
        this.fillSilence(buffer);
        return audio.AudioDataCallbackResult.VALID;
      }
      const soundData = this.currentSounds[idx];
      if (soundData === null) {
        this.fillSilence(buffer);
        return audio.AudioDataCallbackResult.VALID;
      }
      const soundView = new Int16Array(soundData);
      const outView = new Int16Array(buffer);
      const outLen = outView.length;
      let offset = this.soundOffsets[idx];
      for (let i = 0; i < outLen; i++) {
        if (offset < soundView.length) {
          outView[i] = soundView[offset];
          offset++;
        } else {
          outView[i] = 0;
        }
      }
      this.soundOffsets[idx] = offset;
      if (offset >= soundView.length) {
        this.currentSounds[idx] = null;
        this.soundOffsets[idx] = 0;
        this.finishRenderer(idx);
      }
      return audio.AudioDataCallbackResult.VALID;
    });

    renderer.on('stateChange', (state: audio.AudioState): void => {
      if (this.releasedFlags[idx]) return;
      if (state === audio.AudioState.STATE_STOPPED) {
        this.finishRenderer(idx);
      }
    });
  }

  private playSound(soundId: string): void {
    if (!this.initialized) return;
    const buffer = this.soundBuffers.get(soundId);
    if (!buffer) return;

    let idx: number = -1;
    for (let i = 0; i < this.renderers.length; i++) {
      if (!this.releasedFlags[i]) {
        idx = i;
        break;
      }
    }
    if (idx < 0) return;

    this.currentSounds[idx] = buffer;
    this.soundOffsets[idx] = 0;

    const renderer = this.renderers[idx];
    if (renderer.state === audio.AudioState.STATE_PREPARED ||
      renderer.state === audio.AudioState.STATE_STOPPED) {
      renderer.start().catch(() => {
        // start failed
      });
    }
  }

  private finishRenderer(idx: number): void {
    if (this.releasedFlags[idx]) return;
    this.releasedFlags[idx] = true;
    this.currentSounds[idx] = null;
    this.soundOffsets[idx] = 0;

    const oldRenderer = this.renderers[idx];
    try {
      oldRenderer.off('writeData');
      oldRenderer.off('stateChange');
      oldRenderer.stop();
      oldRenderer.release();
    } catch (e) {
      // ignore
    }

    audio.createAudioRenderer({
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
    }).then((newRenderer: audio.AudioRenderer): void => {
      this.setupRenderer(newRenderer, idx);
      this.renderers[idx] = newRenderer;
      this.releasedFlags[idx] = false;
    }).catch(() => {
      // recreate failed, slot stays released
    });
  }

  private fillSilence(buffer: ArrayBuffer): void {
    const view = new Int16Array(buffer);
    for (let i = 0; i < view.length; i++) {
      view[i] = 0;
    }
  }

  private generateAllSounds(): void {
    this.soundBuffers.set(SoundId.DRILL_HIT, this.genNoiseBurst(0.05, 0.3));
    this.soundBuffers.set(SoundId.ENEMY_HIT, this.genToneSweep(0.08, 330, 220, 0.4));
    this.soundBuffers.set(SoundId.ENEMY_DEATH, this.genToneSweep(0.15, 440, 110, 0.5));
    this.soundBuffers.set(SoundId.XP_COLLECT, this.genDualTone(0.06, 660, 880, 0.25));
    this.soundBuffers.set(SoundId.DASH, this.genFilteredNoise(0.1, 0.3));
    this.soundBuffers.set(SoundId.JUMP, this.genToneSweep(0.07, 300, 600, 0.2));
    this.soundBuffers.set(SoundId.PLAYER_DAMAGE, this.genToneSweep(0.15, 180, 80, 0.5));
    this.soundBuffers.set(SoundId.ENGULF, this.genToneSweep(0.2, 120, 60, 0.6));
    this.soundBuffers.set(SoundId.WALL_BREAK, this.genNoiseBurst(0.1, 0.4));
    this.soundBuffers.set(SoundId.LEVEL_UP, this.genArpeggio(0.2, [523, 659, 784, 1047], 0.5));
  }

  private genToneSweep(durationSec: number, startFreq: number, endFreq: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    let phase: number = 0;
    for (let i = 0; i < numSamples; i++) {
      const progress: number = i / numSamples;
      const freq: number = startFreq + (endFreq - startFreq) * progress;
      phase += TWO_PI * freq / SAMPLE_RATE;
      const envelope: number = Math.min(1.0, (numSamples - i) / (SAMPLE_RATE * 0.02));
      const sample: number = Math.sin(phase) * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  private genDualTone(durationSec: number, freq1: number, freq2: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    let phase1: number = 0;
    let phase2: number = 0;
    for (let i = 0; i < numSamples; i++) {
      phase1 += TWO_PI * freq1 / SAMPLE_RATE;
      phase2 += TWO_PI * freq2 / SAMPLE_RATE;
      const envelope: number = Math.min(1.0, (numSamples - i) / (SAMPLE_RATE * 0.015));
      const sample: number = (Math.sin(phase1) + Math.sin(phase2)) * 0.5 * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  private genArpeggio(durationSec: number, freqs: number[], vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    const noteSamples: number = Math.floor(numSamples / freqs.length);
    for (let i = 0; i < numSamples; i++) {
      const noteIdx: number = Math.min(Math.floor(i / noteSamples), freqs.length - 1);
      const freq: number = freqs[noteIdx];
      const t: number = (i % noteSamples) / SAMPLE_RATE;
      const noteProgress: number = (i % noteSamples) / noteSamples;
      const envelope: number = Math.max(0, 1.0 - noteProgress * 0.6);
      const sample: number = Math.sin(TWO_PI * freq * t) * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  private genNoiseBurst(durationSec: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    for (let i = 0; i < numSamples; i++) {
      const decay: number = 1.0 - (i / numSamples);
      const noise: number = Math.random() * 2 - 1;
      const sample: number = noise * vol * decay * decay;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  private genFilteredNoise(durationSec: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    const coeff: number = 0.3;
    let prev: number = 0;
    for (let i = 0; i < numSamples; i++) {
      const decay: number = 1.0 - (i / numSamples);
      const noise: number = Math.random() * 2 - 1;
      prev = prev * (1.0 - coeff) + noise * coeff;
      const sample: number = prev * vol * decay;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }
}
