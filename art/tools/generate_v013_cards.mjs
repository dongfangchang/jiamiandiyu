import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(
  toolDir,
  "..",
  "assets",
  "svg",
  "v0.13.0",
  "cards",
);
fs.mkdirSync(outputDir, { recursive: true });

const motifs = {
  dream_question: `
    <circle cx="256" cy="202" r="112" fill="none" stroke="#211D18" stroke-width="2" stroke-dasharray="3 10"/>
    <path d="M150 202 C192 154 224 154 256 202 C288 250 320 250 362 202"
      fill="none" stroke="#211D18" stroke-width="5"/>
    <ellipse cx="256" cy="202" rx="38" ry="23" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <circle cx="256" cy="202" r="9" fill="#7A2828"/>
    <path d="M234 116 C248 93 279 92 292 113 C304 132 293 149 276 158 C263 165 260 177 260 187"
      fill="none" stroke="#B99750" stroke-width="6" stroke-linecap="round"/>
    <circle cx="260" cy="213" r="5" fill="#B99750"/>
  `,
  mirror_ward: `
    <path d="M256 70 L366 116 L340 254 C330 302 292 330 256 344 C220 330 182 302 172 254 L146 116 Z"
      fill="#E8DFC9" opacity=".55" stroke="#211D18" stroke-width="4"/>
    <path d="M256 92 L336 126 L316 242 C308 281 282 305 256 316 C230 305 204 281 196 242 L176 126 Z"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <path d="M256 94 V316" stroke="#7A2828" stroke-width="3" stroke-dasharray="5 9"/>
    <path d="M182 206 H330" stroke="#211D18" stroke-width="2" opacity=".55"/>
    <circle cx="222" cy="202" r="22" fill="#3A3731"/>
    <circle cx="290" cy="202" r="22" fill="#3A3731"/>
  `,
  severed_string: `
    <path d="M92 135 C164 100 212 180 252 198 C292 216 340 286 420 250"
      fill="none" stroke="#211D18" stroke-width="5"/>
    <path d="M92 264 C160 300 212 226 246 210 M266 190 C300 174 352 100 420 136"
      fill="none" stroke="#7A2828" stroke-width="4"/>
    <path d="M236 184 L276 216 M276 184 L236 216" stroke="#B99750" stroke-width="8" stroke-linecap="round"/>
    <circle cx="256" cy="200" r="88" fill="none" stroke="#211D18" stroke-width="1" stroke-dasharray="2 9" opacity=".4"/>
    <path d="M112 200 H150 M362 200 H400" stroke="#B99750" stroke-width="2"/>
  `,
  last_rites: `
    <path d="M256 72 C228 114 214 150 224 184 C232 212 280 212 288 184 C298 150 284 114 256 72 Z"
      fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M256 112 C244 138 240 158 246 174" fill="none" stroke="#7A2828" stroke-width="5" stroke-linecap="round"/>
    <rect x="218" y="205" width="76" height="108" rx="6" fill="#D8C29A" stroke="#211D18" stroke-width="4"/>
    <path d="M204 312 H308 M188 330 H324" stroke="#B99750" stroke-width="4"/>
    <path d="M150 244 C178 220 204 220 218 242 M362 244 C334 220 308 220 294 242"
      fill="none" stroke="#211D18" stroke-width="4" stroke-linecap="round"/>
    <circle cx="256" cy="164" r="70" fill="none" stroke="#B99750" stroke-width="1" stroke-dasharray="3 8"/>
  `,
};

for (const [name, motif] of Object.entries(motifs)) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="400" viewBox="0 0 512 400">
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
      <feTurbulence type="fractalNoise" baseFrequency=".68" numOctaves="3" seed="103" result="n"/>
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
  fs.writeFileSync(path.join(outputDir, `card_skill_${name}.svg`), svg);
}

console.log(`Generated ${Object.keys(motifs).length} v0.13 card SVGs.`);
