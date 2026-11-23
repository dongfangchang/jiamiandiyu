import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.46 P2 challenge scenes — 1600×900. SCENE_BRIEF_V043 P2. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.46.0", "scenes");
fs.mkdirSync(outputDir, { recursive: true });

function wrap(body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#111612"/>
      <stop offset=".55" stop-color="#28302a"/>
      <stop offset="1" stop-color="#0d110f"/>
    </linearGradient>
    <radialGradient id="paperGlow" cx="50%" cy="42%" r="55%">
      <stop offset="0" stop-color="#EFE1C0" stop-opacity=".16"/>
      <stop offset="1" stop-color="#AF9165" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="fogGlow" cx="50%" cy="45%" r="60%">
      <stop offset="0" stop-color="#c8c2b0" stop-opacity=".22"/>
      <stop offset="1" stop-color="#111612" stop-opacity="0"/>
    </radialGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="#211D18" stroke-width=".7" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="9" height="9" patternUnits="userSpaceOnUse">
      <path d="M0 0L9 9M9 0L0 9" stroke="#E8DFC9" stroke-width=".55" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="3" seed="46" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
      <feComponentTransfer in="mono" result="faint">
        <feFuncA type="table" tableValues="0 .10"/>
      </feComponentTransfer>
      <feBlend in="SourceGraphic" in2="faint" mode="multiply"/>
    </filter>
  </defs>
  <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
  <rect width="1600" height="900" fill="url(#crosshatch)"/>
  <rect width="1600" height="900" fill="url(#paperGlow)"/>
  <rect width="1600" height="900" fill="url(#hatch)" opacity=".2"/>
  <rect x="320" y="120" width="960" height="660" fill="none" stroke="#B99750" stroke-width="1" opacity=".08"/>
  ${body}
</svg>`;
}

const scenes = {
  "battle-megose-descent": `
    <path d="M0 640 H1600 V900 H0Z" fill="#14080c"/>
    <path d="M0 620 L1600 580 V900 H0Z" fill="#2a1018" opacity=".9"/>
    <!-- blackthorn office warped -->
    <path d="M120 80 H700 V620 H120Z" fill="#1a1014" stroke="#7A2828" stroke-width="3" opacity=".55"/>
    <path d="M900 80 H1480 V580 H900Z" fill="#1a1014" stroke="#B99750" stroke-width="3" opacity=".45"/>
    <!-- descending presence -->
    <ellipse cx="800" cy="280" rx="160" ry="90" fill="#7A2828" opacity=".28"/>
    <path d="M800 120 C720 220 720 320 800 420 C880 320 880 220 800 120Z"
      fill="#E8DFC9" opacity=".08" stroke="#7A2828" stroke-width="3"/>
    <circle cx="800" cy="260" r="36" fill="#211D18" stroke="#B99750" stroke-width="2"/>
    <!-- cracks -->
    <path d="M400 200 L520 360 L460 520 M1200 180 L1100 340 L1160 500"
      fill="none" stroke="#7A2828" stroke-width="3" opacity=".45"/>
    <path d="M560 480 H1040" stroke="#B99750" stroke-width="2" opacity=".25"/>
  `,
  "rest-chanis-gate": `
    <path d="M0 600 H1600 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 580 L1600 560 V900 H0Z" fill="#181612" opacity=".88"/>
    <!-- vault corridor -->
    <path d="M280 80 H1320 V580 H280Z" fill="#141210" stroke="#B99750" stroke-width="3" opacity=".5"/>
    <!-- sealed door -->
    <path d="M620 160 H980 V520 H620Z" fill="#211D18" stroke="#B99750" stroke-width="4"/>
    <circle cx="800" cy="340" r="48" fill="none" stroke="#E8D091" stroke-width="3" opacity=".55"/>
    <path d="M800 280 V400 M740 340 H860" stroke="#7A2828" stroke-width="3" opacity=".5"/>
    <!-- seal tags -->
    <g fill="#E8DFC9" stroke="#211D18" stroke-width="2" opacity=".55">
      <rect x="360" y="220" width="70" height="40" rx="3"/>
      <rect x="1170" y="240" width="70" height="40" rx="3"/>
      <rect x="380" y="420" width="60" height="36" rx="3"/>
    </g>
    <path d="M320 160 H560 M1040 160 H1280" stroke="#788079" stroke-width="2" opacity=".25"/>
    <circle cx="800" cy="200" r="20" fill="#B99750" opacity=".2"/>
  `,
  "ritual-above-fog": `
    <rect width="1600" height="900" fill="url(#fogGlow)"/>
    <path d="M0 700 H1600 V900 H0Z" fill="#0a0c0b" opacity=".85"/>
    <!-- grey fog sea -->
    <path d="M0 520 C300 480 500 540 800 500 C1100 460 1300 520 1600 490 V900 H0Z"
      fill="#c8c2b0" opacity=".12"/>
    <path d="M0 580 C280 550 520 600 800 570 C1080 540 1320 590 1600 560"
      fill="none" stroke="#E8DFC9" stroke-width="2" opacity=".25"/>
    <!-- fool's table suggestion -->
    <ellipse cx="800" cy="420" rx="220" ry="70" fill="#211D18" opacity=".45" stroke="#B99750" stroke-width="2"/>
    <circle cx="800" cy="280" r="54" fill="none" stroke="#B99750" stroke-width="3" opacity=".45"/>
    <path d="M800 200 V250" stroke="#E8D091" stroke-width="3" opacity=".4"/>
    <!-- three seats hint -->
    <circle cx="620" cy="460" r="18" fill="#3A3731" stroke="#788079" stroke-width="2" opacity=".6"/>
    <circle cx="800" cy="480" r="18" fill="#3A3731" stroke="#788079" stroke-width="2" opacity=".6"/>
    <circle cx="980" cy="460" r="18" fill="#3A3731" stroke="#788079" stroke-width="2" opacity=".6"/>
  `,
};

const idMap = {
  "battle-megose-descent": "scene.battle.megose_descent",
  "rest-chanis-gate": "scene.rest.chanis_gate",
  "ritual-above-fog": "scene.ritual.above_fog",
};

const manifest = [];
for (const [stem, body] of Object.entries(scenes)) {
  const file = `${stem}.svg`;
  fs.writeFileSync(path.join(outputDir, file), wrap(body));
  manifest.push({
    stable_id: idMap[stem],
    svg: `art/assets/svg/v0.46.0/scenes/${file}`,
    png: `assets/game/v0.46.0/scenes/${stem}.png`,
  });
}
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.46.0", theme: "tingen_p2_scenes", assets: manifest }, null, 2) + "\n",
);
console.log(`Generated ${manifest.length} v0.46 P2 scene SVGs → ${outputDir}`);
