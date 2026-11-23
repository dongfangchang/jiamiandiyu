import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.69 formal diary parchment — 1024×1536. ART_BRIEF_V069. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.69.0", "diary");
fs.mkdirSync(outputDir, { recursive: true });

const fibers = [];
for (let y = 48; y < 1500; y += 36) {
  const wobble = ((y * 17) % 40) - 20;
  fibers.push(
    `<path d="M40 ${y} C220 ${y + wobble} 420 ${y - wobble} 620 ${y + wobble * 0.5} C820 ${y - wobble} 980 ${y + wobble * 0.3} 990 ${y}" />`
  );
}

const stains = [
  [140, 220, 90],
  [820, 480, 120],
  [300, 980, 70],
  [700, 1200, 110],
  [180, 1350, 55],
  [880, 200, 65],
  [520, 640, 80],
  [420, 400, 45],
];

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1536" viewBox="0 0 1024 1536">
  <defs>
    <linearGradient id="wash" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#f6ebd0"/>
      <stop offset="22%" stop-color="#e8d0a0"/>
      <stop offset="55%" stop-color="#c9a66c"/>
      <stop offset="82%" stop-color="#a67b45"/>
      <stop offset="100%" stop-color="#8a6236"/>
    </linearGradient>
    <radialGradient id="candleWarm" cx="18%" cy="12%" r="55%">
      <stop offset="0%" stop-color="#ffe0a8" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#c9a66c" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="edgeBurn" cx="50%" cy="50%" r="74%">
      <stop offset="40%" stop-color="#000000" stop-opacity="0"/>
      <stop offset="100%" stop-color="#2a1608" stop-opacity="0.55"/>
    </radialGradient>
    <filter id="pulp" x="-4%" y="-4%" width="108%" height="108%">
      <feTurbulence type="fractalNoise" baseFrequency="0.78" numOctaves="5" seed="69" stitchTiles="stitch"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.42  0 0 0 0 0.28  0 0 0 0 0.14  0 0 0 0.34 0"/>
    </filter>
    <filter id="micro" x="-4%" y="-4%" width="108%" height="108%">
      <feTurbulence type="fractalNoise" baseFrequency="1.55" numOctaves="3" seed="11" stitchTiles="stitch"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.55  0 0 0 0 0.40  0 0 0 0 0.22  0 0 0 0.16 0"/>
    </filter>
    <filter id="softBlur">
      <feGaussianBlur stdDeviation="1.2"/>
    </filter>
  </defs>
  <rect width="1024" height="1536" fill="url(#wash)"/>
  <rect width="1024" height="1536" fill="url(#candleWarm)"/>
  <rect width="1024" height="1536" filter="url(#pulp)" opacity="0.92"/>
  <rect width="1024" height="1536" filter="url(#micro)" opacity="0.6"/>
  <g fill="#5a3a1c" fill-opacity="0.28" filter="url(#softBlur)">
    ${stains.map(([cx, cy, r]) => `<circle cx="${cx}" cy="${cy}" r="${r}"/>`).join("\n    ")}
  </g>
  <g fill="#3a2010" fill-opacity="0.2">
    <ellipse cx="260" cy="1280" rx="140" ry="60"/>
    <ellipse cx="780" cy="180" rx="110" ry="48"/>
    <ellipse cx="510" cy="760" rx="95" ry="40"/>
    <ellipse cx="160" cy="520" rx="70" ry="30"/>
  </g>
  <g stroke="#7a5530" stroke-opacity="0.55" stroke-width="1.8" fill="none">
    ${fibers.join("\n    ")}
  </g>
  <g stroke="#5a3a20" stroke-opacity="0.22" stroke-width="3" fill="none">
    <path d="M512 60 C500 400 524 900 508 1480"/>
    <path d="M70 760 C300 740 700 780 960 750"/>
  </g>
  <g stroke="#4a2e14" stroke-opacity="0.35" stroke-width="1.1" fill="none">
    <path d="M90 160 C170 210 140 280 220 320"/>
    <path d="M760 900 C840 960 810 1040 900 1090"/>
    <path d="M180 1100 C250 1140 230 1220 300 1260"/>
  </g>
  <rect width="1024" height="1536" fill="url(#edgeBurn)"/>
</svg>
`;

const outPath = path.join(outputDir, "parchment_grain.svg");
fs.writeFileSync(outPath, svg);
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify(
    {
      version: "v0.69.0",
      brief: "ART_BRIEF_V069",
      assets: ["parchment_grain.svg"],
      size: [1024, 1536],
    },
    null,
    2
  )
);
console.log("V069_PARCHMENT_SVG_OK", outPath);
