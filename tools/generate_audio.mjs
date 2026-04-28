import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = dirname(__dirname);
const outDir = join(projectRoot, "assets", "audio");
const sampleRate = 44100;

mkdirSync(outDir, { recursive: true });

let seed = 0x51c0ab;

function randomSigned() {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return (seed / 0xffffffff) * 2 - 1;
}

function clamp(value) {
  return Math.max(-1, Math.min(1, value));
}

function writeWav(filename, durationSeconds, sampleFn) {
  const sampleCount = Math.floor(durationSeconds * sampleRate);
  const dataSize = sampleCount * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write("RIFF", 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write("WAVE", 8);
  buffer.write("fmt ", 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write("data", 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < sampleCount; i += 1) {
    const t = i / sampleRate;
    const sample = clamp(sampleFn(t, i, sampleCount));
    buffer.writeInt16LE(Math.round(sample * 32767), 44 + i * 2);
  }

  writeFileSync(join(outDir, filename), buffer);
}

writeWav("qoob_hum.wav", 6.0, (t) => {
  const phase = Math.sin(2 * Math.PI * 0.5 * t) * 0.18;
  const low = Math.sin(2 * Math.PI * 55 * t + phase);
  const detuned = Math.sin(2 * Math.PI * 58 * t - phase * 0.7);
  const sub = Math.sin(2 * Math.PI * 27.5 * t);
  const texture = Math.sin(2 * Math.PI * (91 + Math.sin(t * 1.3) * 4) * t) * 0.12;
  const envelope = 0.82 + Math.sin(2 * Math.PI * 0.333333 * t) * 0.08;
  return (low * 0.34 + detuned * 0.24 + sub * 0.26 + texture) * envelope * 0.54;
});

writeWav("wrong_screech.wav", 0.82, (t) => {
  const n = t / 0.82;
  const freq = 420 + 1280 * n + Math.sin(t * 46) * 120;
  const carrier = Math.sin(2 * Math.PI * freq * t + Math.sin(t * 120) * 2.1);
  const scrape = randomSigned() * (0.22 + n * 0.24);
  const envelope = Math.sin(Math.PI * Math.min(1, n)) * Math.pow(1 - n, 0.45);
  return (carrier * 0.72 + scrape) * envelope * 0.72;
});

writeWav("lightning_storm.wav", 2.25, (t) => {
  const n = t / 2.25;
  const rumble = Math.sin(2 * Math.PI * 34 * t) * 0.35 + Math.sin(2 * Math.PI * 47 * t) * 0.22;
  const strike1 = Math.exp(-Math.pow((t - 0.18) * 8.0, 2));
  const strike2 = Math.exp(-Math.pow((t - 0.88) * 6.5, 2));
  const strike3 = Math.exp(-Math.pow((t - 1.55) * 7.5, 2));
  const strikeEnvelope = Math.min(1, strike1 + strike2 + strike3);
  const crack = randomSigned() * strikeEnvelope * 0.95;
  const tail = randomSigned() * Math.pow(1 - n, 0.65) * 0.18;
  return (rumble * Math.pow(1 - n, 0.35) + crack + tail) * 0.8;
});

writeWav("success_chime.wav", 1.15, (t) => {
  const env = Math.exp(-t * 2.8);
  const attack = Math.min(1, t * 18);
  const chord =
    Math.sin(2 * Math.PI * 523.25 * t) * 0.42 +
    Math.sin(2 * Math.PI * 659.25 * t) * 0.34 +
    Math.sin(2 * Math.PI * 783.99 * t) * 0.28 +
    Math.sin(2 * Math.PI * 1046.5 * t) * 0.16;
  const shimmer = Math.sin(2 * Math.PI * (1320 + Math.sin(t * 8) * 24) * t) * 0.08;
  return (chord + shimmer) * env * attack * 0.58;
});

console.log("Generated original procedural Qoob audio assets.");

