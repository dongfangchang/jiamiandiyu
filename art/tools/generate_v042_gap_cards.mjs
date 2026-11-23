import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.42 — 12 missing skill card faces (ART_BRIEF_V042). No baked text. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.42.0", "cards");
fs.mkdirSync(outputDir, { recursive: true });

const motifs = {
  ink_scarlet: `
    <ellipse cx="256" cy="210" rx="88" ry="70" fill="#7A2828" opacity=".35" stroke="#211D18" stroke-width="4"/>
    <path d="M190 160 C220 120 250 120 256 150 C262 120 292 120 322 160
      C340 190 330 240 300 270 C280 290 232 290 212 270 C182 240 172 190 190 160 Z"
      fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M230 200 C246 170 266 170 282 200" fill="none" stroke="#7A2828" stroke-width="5"/>
    <path d="M256 210 V290" stroke="#B99750" stroke-width="4"/>
    <circle cx="256" cy="300" r="12" fill="#7A2828" stroke="#211D18" stroke-width="2"/>
  `,
  echo_reading: `
    <rect x="168" y="110" width="176" height="120" rx="8" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M188 140 H324 M188 164 H300 M188 188 H312" stroke="#211D18" stroke-width="3" opacity=".55"/>
    <circle cx="256" cy="280" r="36" fill="none" stroke="#B99750" stroke-width="3"/>
    <path d="M232 280 L248 296 L288 256" fill="none" stroke="#7A2828" stroke-width="5" stroke-linecap="round"/>
    <path d="M140 250 C180 220 220 220 256 245 C292 220 332 220 372 250"
      fill="none" stroke="#211D18" stroke-width="2" stroke-dasharray="4 8" opacity=".5"/>
  `,
  midnight_ledger: `
    <rect x="176" y="100" width="160" height="200" rx="6" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M196 140 H316 M196 168 H300 M196 196 H308 M196 224 H280" stroke="#211D18" stroke-width="2.5" opacity=".5"/>
    <path d="M360 120 C340 160 340 220 360 280" fill="none" stroke="#B99750" stroke-width="6" stroke-linecap="round"/>
    <circle cx="360" cy="108" r="14" fill="#7A2828" stroke="#211D18" stroke-width="2"/>
    <path d="M152 300 H360" stroke="#211D18" stroke-width="3" opacity=".4"/>
  `,
  borrowed_breath: `
    <path d="M160 280 C200 200 230 160 256 150 C282 160 312 200 352 280"
      fill="none" stroke="#211D18" stroke-width="4"/>
    <path d="M190 270 C220 210 240 180 256 172 C272 180 292 210 322 270"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <g fill="#E8DFC9" stroke="#211D18" stroke-width="2">
      <circle cx="210" cy="220" r="10"/><circle cx="256" cy="200" r="12"/>
      <circle cx="300" cy="222" r="9"/><circle cx="236" cy="250" r="8"/>
      <circle cx="278" cy="248" r="8"/>
    </g>
    <rect x="200" y="290" width="112" height="28" rx="4" fill="none" stroke="#7A2828" stroke-width="3"/>
  `,
  glass_thesis: `
    <ellipse cx="256" cy="210" rx="120" ry="70" fill="#E8DFC9" opacity=".45" stroke="#211D18" stroke-width="3"/>
    <rect x="196" y="150" width="48" height="72" rx="4" fill="#E8DFC9" stroke="#211D18" stroke-width="3" transform="rotate(-12 220 186)"/>
    <rect x="236" y="140" width="48" height="72" rx="4" fill="#E8DFC9" stroke="#B99750" stroke-width="3"/>
    <rect x="276" y="154" width="48" height="72" rx="4" fill="#E8DFC9" stroke="#211D18" stroke-width="3" transform="rotate(14 300 190)"/>
    <circle cx="256" cy="280" r="28" fill="none" stroke="#7A2828" stroke-width="4"/>
    <path d="M140 120 C180 90 220 90 256 110 C292 90 332 90 372 120"
      fill="none" stroke="#B99750" stroke-width="2" stroke-dasharray="5 8" opacity=".7"/>
  `,
  hungry_symbol: `
    <path d="M210 120 H302 L320 280 H192 Z" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <ellipse cx="256" cy="200" rx="34" ry="48" fill="#211D18"/>
    <ellipse cx="256" cy="200" rx="18" ry="28" fill="#7A2828"/>
    <circle cx="256" cy="200" r="8" fill="#E8DFC9"/>
    <path d="M220 300 C240 320 272 320 292 300" fill="none" stroke="#B99750" stroke-width="4"/>
    <path d="M168 160 C188 140 200 140 210 160 M344 160 C324 140 312 140 302 160"
      fill="none" stroke="#211D18" stroke-width="3" opacity=".55"/>
  `,
  candle_archive: `
    <rect x="236" y="170" width="40" height="120" rx="4" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M256 170 C248 140 248 120 256 100 C264 120 264 140 256 170 Z"
      fill="#7A2828" stroke="#211D18" stroke-width="2"/>
    <path d="M256 100 C250 88 250 78 256 70 C262 78 262 88 256 100"
      fill="#B99750" stroke="#5D4726" stroke-width="1.5"/>
    <ellipse cx="256" cy="300" rx="70" ry="16" fill="#3A3731" opacity=".2"/>
    <path d="M180 220 C210 200 230 200 256 220 C282 200 302 200 332 220"
      fill="none" stroke="#B99750" stroke-width="2" stroke-dasharray="4 7" opacity=".65"/>
  `,
  omen_chorus: `
    <ellipse cx="256" cy="210" rx="110" ry="90" fill="#10140F" opacity=".35" stroke="#211D18" stroke-width="3"/>
    <path d="M170 210 C200 150 230 140 256 160 C282 140 312 150 342 210
      C312 260 282 280 256 270 C230 280 200 260 170 210 Z"
      fill="#E8DFC9" opacity=".4" stroke="#B99750" stroke-width="3"/>
    <circle cx="230" cy="200" r="10" fill="#211D18"/>
    <circle cx="282" cy="200" r="10" fill="#211D18"/>
    <path d="M220 236 C240 252 272 252 292 236" fill="none" stroke="#7A2828" stroke-width="4"/>
    <path d="M256 100 V140" stroke="#B99750" stroke-width="5" stroke-linecap="round"/>
  `,
  closed_eye: `
    <path d="M140 210 C190 150 222 150 256 210 C290 150 322 150 372 210
      C322 270 290 270 256 210 C222 270 190 270 140 210 Z"
      fill="none" stroke="#211D18" stroke-width="5"/>
    <path d="M168 210 C210 170 236 170 256 210 C276 170 302 170 344 210"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <path d="M200 210 H312" stroke="#7A2828" stroke-width="6" stroke-linecap="round"/>
    <circle cx="256" cy="280" r="18" fill="none" stroke="#211D18" stroke-width="3" stroke-dasharray="3 6"/>
  `,
  black_thread: `
    <path d="M140 140 C200 120 240 180 256 210 C272 180 312 120 372 140
      C320 200 300 260 256 300 C212 260 192 200 140 140 Z"
      fill="none" stroke="#211D18" stroke-width="5"/>
    <path d="M180 160 C220 150 240 190 256 220 C272 190 292 150 332 160"
      fill="none" stroke="#7A2828" stroke-width="3"/>
    <rect x="220" y="250" width="72" height="40" rx="8" fill="#E8DFC9" stroke="#B99750" stroke-width="3"/>
    <path d="M232 270 H280" stroke="#211D18" stroke-width="3"/>
  `,
  eclipse: `
    <circle cx="256" cy="200" r="90" fill="#B99750" stroke="#211D18" stroke-width="4"/>
    <circle cx="256" cy="200" r="70" fill="#E8D091" stroke="#5D4726" stroke-width="2"/>
    <path d="M256 120 V160 M256 240 V280 M176 200 H216 M296 200 H336
      M200 144 L228 172 M284 228 L312 256 M312 144 L284 172 M228 228 L200 256"
      stroke="#7A2828" stroke-width="4" stroke-linecap="round"/>
    <rect x="230" y="300" width="52" height="28" rx="3" fill="#E8DFC9" stroke="#211D18" stroke-width="3"/>
  `,
  red_corridor: `
    <circle cx="256" cy="190" r="88" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <circle cx="256" cy="190" r="58" fill="none" stroke="#B99750" stroke-width="5"/>
    <path d="M256 132 V248 M198 190 H314 M214 148 L298 232 M298 148 L214 232"
      stroke="#7A2828" stroke-width="4"/>
    <path d="M160 300 C200 270 230 270 256 290 C282 270 312 270 352 300"
      fill="none" stroke="#211D18" stroke-width="3" opacity=".55"/>
    <circle cx="256" cy="190" r="110" fill="none" stroke="#B99750" stroke-width="1" stroke-dasharray="3 9" opacity=".65"/>
  `,
};

function wrap(motif) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="400" viewBox="0 0 512 400">
  <defs>
    <radialGradient id="paper" cx="48%" cy="38%" r="78%">
      <stop offset="0" stop-color="#F1E4C8"/>
      <stop offset=".6" stop-color="#D8C29A"/>
      <stop offset="1" stop-color="#AF9165"/>
    </radialGradient>
    <pattern id="hatch" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(24)">
      <path d="M0 0V9" stroke="#211D18" stroke-width=".7" opacity=".11"/>
    </pattern>
    <filter id="grain">
      <feTurbulence type="fractalNoise" baseFrequency=".68" numOctaves="3" seed="142" result="n"/>
      <feColorMatrix in="n" type="saturate" values="0" result="m"/>
      <feComponentTransfer in="m" result="f"><feFuncA type="table" tableValues="0 .07"/></feComponentTransfer>
      <feBlend in="SourceGraphic" in2="f" mode="multiply"/>
    </filter>
  </defs>
  <rect width="512" height="400" fill="url(#paper)" filter="url(#grain)"/>
  <rect width="512" height="400" fill="url(#hatch)"/>
  <rect x="18" y="18" width="476" height="364" fill="none" stroke="#211D18" stroke-width="2" opacity=".66"/>
  <path d="M18 44H70M442 18H494M18 356H70M442 382H494"
    stroke="#B99750" stroke-width="2" opacity=".78"/>
  <circle cx="256" cy="200" r="146" fill="none" stroke="#211D18" stroke-width=".8" stroke-dasharray="2 9" opacity=".24"/>
  ${motif}
</svg>`;
}

const manifest = [];
for (const [name, motif] of Object.entries(motifs)) {
  const file = `card_skill_${name}.svg`;
  fs.writeFileSync(path.join(outputDir, file), wrap(motif));
  manifest.push({
    stable_id: `card.skill.${name}`,
    svg: `art/assets/svg/v0.42.0/cards/${file}`,
    png: `assets/game/v0.42.0/cards/card_skill_${name}.png`,
  });
}
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.42.0", theme: "gap_skill_cards", assets: manifest }, null, 2) + "\n",
);
console.log(`Generated ${manifest.length} v0.42 gap card SVGs → ${outputDir}`);
