// entry/src/main/ets/engine/platform/AudioSynth.ets

const SAMPLE_RATE: number = 44100;
const TWO_PI: number = Math.PI * 2;
const BYTES_PER_SAMPLE: number = 2;

export class AudioSynth {
  static genToneSweep(durationSec: number, startFreq: number, endFreq: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    let phase: number = 0;
    for (let i: number = 0; i < numSamples; i++) {
      const progress: number = i / numSamples;
      const freq: number = startFreq + (endFreq - startFreq) * progress;
      phase += TWO_PI * freq / SAMPLE_RATE;
      const envelope: number = Math.min(1.0, (numSamples - i) / (SAMPLE_RATE * 0.02));
      const sample: number = Math.sin(phase) * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genDualTone(durationSec: number, freq1: number, freq2: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    let phase1: number = 0;
    let phase2: number = 0;
    for (let i: number = 0; i < numSamples; i++) {
      phase1 += TWO_PI * freq1 / SAMPLE_RATE;
      phase2 += TWO_PI * freq2 / SAMPLE_RATE;
      const envelope: number = Math.min(1.0, (numSamples - i) / (SAMPLE_RATE * 0.015));
      const sample: number = (Math.sin(phase1) + Math.sin(phase2)) * 0.5 * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genArpeggio(durationSec: number, freqs: number[], vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    const noteSamples: number = Math.floor(numSamples / freqs.length);
    for (let i: number = 0; i < numSamples; i++) {
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

  static genNoiseBurst(durationSec: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    for (let i: number = 0; i < numSamples; i++) {
      const decay: number = 1.0 - (i / numSamples);
      const noise: number = Math.random() * 2 - 1;
      const sample: number = noise * vol * decay * decay;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genFilteredNoise(durationSec: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    const coeff: number = 0.3;
    let prev: number = 0;
    for (let i: number = 0; i < numSamples; i++) {
      const decay: number = 1.0 - (i / numSamples);
      const noise: number = Math.random() * 2 - 1;
      prev = prev * (1.0 - coeff) + noise * coeff;
      const sample: number = prev * vol * decay;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }
}
