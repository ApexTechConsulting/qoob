import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { deflateSync } from "node:zlib";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = dirname(__dirname);
const outPath = join(projectRoot, "assets", "art", "Qoob_icon_1024.png");
const size = 1024;
const pixels = Buffer.alloc(size * size * 4);

mkdirSync(dirname(outPath), { recursive: true });

function rgba(hex, alpha = 255) {
  const value = hex.replace("#", "");
  return [
    Number.parseInt(value.slice(0, 2), 16),
    Number.parseInt(value.slice(2, 4), 16),
    Number.parseInt(value.slice(4, 6), 16),
    alpha,
  ];
}

function blendPixel(x, y, color) {
  if (x < 0 || y < 0 || x >= size || y >= size) return;
  const index = (Math.floor(y) * size + Math.floor(x)) * 4;
  const a = color[3] / 255;
  pixels[index] = Math.round(color[0] * a + pixels[index] * (1 - a));
  pixels[index + 1] = Math.round(color[1] * a + pixels[index + 1] * (1 - a));
  pixels[index + 2] = Math.round(color[2] * a + pixels[index + 2] * (1 - a));
  pixels[index + 3] = 255;
}

function fill(color) {
  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) {
      blendPixel(x, y, color);
    }
  }
}

function pointInPoly(x, y, points) {
  let inside = false;
  for (let i = 0, j = points.length - 1; i < points.length; j = i, i += 1) {
    const xi = points[i][0], yi = points[i][1];
    const xj = points[j][0], yj = points[j][1];
    const intersect = ((yi > y) !== (yj > y)) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

function fillPoly(points, color) {
  const minX = Math.max(0, Math.floor(Math.min(...points.map((p) => p[0]))));
  const maxX = Math.min(size - 1, Math.ceil(Math.max(...points.map((p) => p[0]))));
  const minY = Math.max(0, Math.floor(Math.min(...points.map((p) => p[1]))));
  const maxY = Math.min(size - 1, Math.ceil(Math.max(...points.map((p) => p[1]))));
  for (let y = minY; y <= maxY; y += 1) {
    for (let x = minX; x <= maxX; x += 1) {
      if (pointInPoly(x + 0.5, y + 0.5, points)) {
        blendPixel(x, y, color);
      }
    }
  }
}

function drawCircle(cx, cy, radius, color) {
  const r2 = radius * radius;
  for (let y = Math.floor(cy - radius); y <= Math.ceil(cy + radius); y += 1) {
    for (let x = Math.floor(cx - radius); x <= Math.ceil(cx + radius); x += 1) {
      const dx = x - cx;
      const dy = y - cy;
      if (dx * dx + dy * dy <= r2) {
        blendPixel(x, y, color);
      }
    }
  }
}

function drawLine(x0, y0, x1, y1, width, color) {
  const steps = Math.ceil(Math.hypot(x1 - x0, y1 - y0));
  for (let i = 0; i <= steps; i += 1) {
    const t = i / steps;
    drawCircle(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, width / 2, color);
  }
}

function drawArc(cx, cy, rx, ry, start, end, width, color) {
  const segments = 130;
  let prev = null;
  for (let i = 0; i <= segments; i += 1) {
    const t = start + ((end - start) * i) / segments;
    const point = [cx + Math.cos(t) * rx, cy + Math.sin(t) * ry];
    if (prev) drawLine(prev[0], prev[1], point[0], point[1], width, color);
    prev = point;
  }
}

function crc32(buffer) {
  let c = ~0;
  for (const byte of buffer) {
    c ^= byte;
    for (let k = 0; k < 8; k += 1) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const typeBuffer = Buffer.from(type);
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  typeBuffer.copy(out, 4);
  data.copy(out, 8);
  out.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 8 + data.length);
  return out;
}

fill(rgba("#120a1d"));
fillPoly([[512, 104], [858, 300], [512, 496], [166, 300]], rgba("#594f88"));
fillPoly([[512, 496], [858, 300], [858, 692], [512, 888]], rgba("#1d6d78"));
fillPoly([[512, 496], [166, 300], [166, 692], [512, 888]], rgba("#40215a"));
fillPoly([[512, 104], [858, 300], [858, 692], [512, 888], [166, 692], [166, 300]], rgba("#221434", 90));

drawArc(512, 320, 300, 118, Math.PI * 1.08, Math.PI * 1.92, 32, rgba("#7ff8ff", 150));
drawArc(512, 708, 292, 104, Math.PI * 0.08, Math.PI * 0.92, 24, rgba("#ffce68", 132));
drawLine(512, 106, 512, 886, 10, rgba("#9efbff", 76));
drawCircle(410, 456, 36, rgba("#8fffff"));
drawCircle(614, 456, 36, rgba("#8fffff"));

const scanlines = Buffer.alloc((size * 4 + 1) * size);
for (let y = 0; y < size; y += 1) {
  scanlines[y * (size * 4 + 1)] = 0;
  pixels.copy(scanlines, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(size, 0);
ihdr.writeUInt32BE(size, 4);
ihdr[8] = 8;
ihdr[9] = 6;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;

const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr),
  chunk("IDAT", deflateSync(scanlines, { level: 9 })),
  chunk("IEND", Buffer.alloc(0)),
]);

writeFileSync(outPath, png);
console.log(`Generated ${outPath}`);

