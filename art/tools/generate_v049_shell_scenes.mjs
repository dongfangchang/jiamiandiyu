import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.49 remaining system shells — 1600×900. SCENE_BRIEF §2 leftover. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.49.0", "scenes");
fs.mkdirSync(outputDir, { recursive: true });

function wrap(body, wash = ["#15130f", "#2a261f", "#0e0c0a"]) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${wash[0]}"/>
      <stop offset=".55" stop-color="${wash[1]}"/>
      <stop offset="1" stop-color="${wash[2]}"/>
    </linearGradient>
    <radialGradient id="paperGlow" cx="50%" cy="40%" r="58%">
      <stop offset="0" stop-color="#EFE1C0" stop-opacity=".16"/>
      <stop offset="1" stop-color="#AF9165" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="sealGlow" cx="50%" cy="45%" r="40%">
      <stop offset="0" stop-color="#7A2828" stop-opacity=".18"/>
      <stop offset="1" stop-color="#211D18" stop-opacity="0"/>
    </radialGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="#211D18" stroke-width=".7" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="9" height="9" patternUnits="userSpaceOnUse">
      <path d="M0 0L9 9M9 0L0 9" stroke="#E8DFC9" stroke-width=".55" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="3" seed="49" result="noise"/>
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
  "hub-reward-archive": {
    wash: ["#16140f", "#2c261c", "#0d0b08"],
    body: `
    <path d="M0 680 H1600 V900 H0Z" fill="#0a0907"/>
    <!-- reward chest -->
    <path d="M520 360 H1080 L1040 620 H560 Z" fill="#211D18" stroke="#B99750" stroke-width="4"/>
    <path d="M540 300 H1060 L1080 360 H520 Z" fill="#3A3731" stroke="#E8D091" stroke-width="3"/>
    <circle cx="800" cy="420" r="36" fill="#7A2828" stroke="#E8D091" stroke-width="3"/>
    <path d="M800 400 V440 M780 420 H820" stroke="#E8D091" stroke-width="2"/>
    <!-- three choice slots -->
    <g fill="#15130f" stroke="#E8DFC9" stroke-width="2" opacity=".55">
      <rect x="420" y="200" width="140" height="120" rx="8"/>
      <rect x="730" y="180" width="140" height="120" rx="8"/>
      <rect x="1040" y="200" width="140" height="120" rx="8"/>
    </g>
    <path d="M360 640 H1240" stroke="#788079" stroke-width="2" opacity=".25"/>
  `,
  },
  "hub-challenge-board": {
    wash: ["#121410", "#242820", "#0a0c0a"],
    body: `
    <!-- dossier board -->
    <path d="M280 100 H1320 V780 H280Z" fill="#1a1814" stroke="#B99750" stroke-width="4" opacity=".8"/>
    <path d="M320 140 H1280 V720 H320Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <!-- three modifier cards -->
    <g fill="#EFE1C0" stroke="#211D18" stroke-width="3" opacity=".5">
      <rect x="400" y="260" width="180" height="260" rx="8"/>
      <rect x="710" y="240" width="180" height="280" rx="8"/>
      <rect x="1020" y="260" width="180" height="260" rx="8"/>
    </g>
    <g fill="#7A2828" stroke="#E8D091" stroke-width="2">
      <circle cx="490" cy="300" r="22"/>
      <circle cx="800" cy="290" r="22"/>
      <circle cx="1110" cy="300" r="22"/>
    </g>
    <path d="M360 180 H1240" stroke="#B99750" stroke-width="2" opacity=".3"/>
    <path d="M360 640 H1240" stroke="#B99750" stroke-width="2" opacity=".25"/>
  `,
  },
  "hub-challenge-result": {
    wash: ["#16120f", "#2a221c", "#0c0a08"],
    body: `
    <rect width="1600" height="900" fill="url(#sealGlow)"/>
    <path d="M360 160 H1240 V720 H360Z" fill="#1a1814" stroke="#B99750" stroke-width="4" opacity=".75"/>
    <!-- case stamp -->
    <circle cx="800" cy="400" r="120" fill="none" stroke="#7A2828" stroke-width="8" opacity=".55"/>
    <circle cx="800" cy="400" r="90" fill="none" stroke="#E8D091" stroke-width="3" opacity=".45"/>
    <path d="M740 400 L780 440 L880 340" fill="none" stroke="#E8D091" stroke-width="8" stroke-linecap="round"/>
    <!-- dossier corners -->
    <path d="M400 200 H520 M400 200 V300" stroke="#788079" stroke-width="3" opacity=".4"/>
    <path d="M1200 200 H1080 M1200 200 V300" stroke="#788079" stroke-width="3" opacity=".4"/>
    <path d="M400 680 H520 M400 680 V580" stroke="#788079" stroke-width="3" opacity=".4"/>
    <path d="M1200 680 H1080 M1200 680 V580" stroke="#788079" stroke-width="3" opacity=".4"/>
  `,
  },
  "hub-rest-blackthorn": {
    wash: ["#141210", "#282420", "#0c0a09"],
    body: `
    <path d="M0 640 H1600 V900 H0Z" fill="#0a0908"/>
    <!-- blackthorn lounge -->
    <path d="M200 120 H1400 V620 H200Z" fill="#1a1614" stroke="#B99750" stroke-width="3" opacity=".55"/>
    <path d="M280 200 H700 V520 H280Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <path d="M900 200 H1320 V520 H900Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <!-- sofa suggestion -->
    <path d="M400 480 H1200 L1160 580 H440 Z" fill="#3A3731" stroke="#B99750" stroke-width="3" opacity=".7"/>
    <!-- window moonlight -->
    <rect x="1000" y="240" width="240" height="160" fill="#E8DFC9" opacity=".06" stroke="#788079" stroke-width="2"/>
    <circle cx="520" cy="300" r="28" fill="#E8D091" opacity=".15"/>
    <path d="M480 360 V440" stroke="#B99750" stroke-width="3" opacity=".3"/>
  `,
  },
  "ritual-obituary": {
    wash: ["#12100e", "#262018", "#0b0a08"],
    body: `
    <path d="M0 700 H1600 V900 H0Z" fill="#0a0907"/>
    <!-- ritual table -->
    <ellipse cx="800" cy="520" rx="420" ry="90" fill="#211D18" stroke="#B99750" stroke-width="3"/>
    <path d="M480 400 H1120 L1080 520 H520 Z" fill="#3A3731" stroke="#788079" stroke-width="2" opacity=".7"/>
    <!-- four corners food / candles -->
    <g>
      <circle cx="560" cy="460" r="22" fill="#E8DFC9" stroke="#211D18" stroke-width="2" opacity=".55"/>
      <circle cx="1040" cy="460" r="22" fill="#E8DFC9" stroke="#211D18" stroke-width="2" opacity=".55"/>
      <circle cx="600" cy="560" r="22" fill="#E8DFC9" stroke="#211D18" stroke-width="2" opacity=".55"/>
      <circle cx="1000" cy="560" r="22" fill="#E8DFC9" stroke="#211D18" stroke-width="2" opacity=".55"/>
    </g>
    <!-- obituary sheet -->
    <rect x="700" y="280" width="200" height="160" rx="4" fill="#EFE1C0" stroke="#211D18" stroke-width="3" opacity=".55"/>
    <path d="M730 320 H870 M730 350 H850 M730 380 H860" stroke="#211D18" stroke-width="2" opacity=".4"/>
    <path d="M520 420 L1080 420 L1040 480 L560 480 Z" fill="none" stroke="#7A2828" stroke-width="2" opacity=".35"/>
  `,
  },
  "ritual-ascension": {
    wash: ["#101214", "#1e2420", "#090b0a"],
    body: `
    <!-- goddess / oath hall -->
    <path d="M200 80 H1400 V700 H200Z" fill="#141814" stroke="#B99750" stroke-width="3" opacity=".5"/>
    <path d="M400 120 H1200 L1100 280 H500 Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <!-- potion cup -->
    <path d="M740 400 H860 L840 520 H760 Z" fill="#E8DFC9" stroke="#B99750" stroke-width="3" opacity=".55"/>
    <ellipse cx="800" cy="400" rx="70" ry="20" fill="#3A3731" stroke="#E8D091" stroke-width="2"/>
    <path d="M800 360 V390" stroke="#E8D091" stroke-width="3" opacity=".5"/>
    <!-- oath circle -->
    <circle cx="800" cy="560" r="100" fill="none" stroke="#B99750" stroke-width="3" opacity=".45"/>
    <circle cx="800" cy="560" r="60" fill="none" stroke="#7A2828" stroke-width="2" opacity=".4"/>
    <!-- clown makeup hint (restrained) -->
    <circle cx="800" cy="240" r="36" fill="#E8DFC9" opacity=".12" stroke="#B99750" stroke-width="2"/>
    <path d="M780 250 Q800 265 820 250" fill="none" stroke="#7A2828" stroke-width="2" opacity=".45"/>
    <path d="M320 640 H1280" stroke="#788079" stroke-width="2" opacity=".25"/>
  `,
  },
};

const idMap = {
  "hub-reward-archive": "scene.hub.reward_archive",
  "hub-challenge-board": "scene.hub.challenge_board",
  "hub-challenge-result": "scene.hub.challenge_result",
  "hub-rest-blackthorn": "scene.hub.rest_blackthorn",
  "ritual-obituary": "scene.ritual.obituary",
  "ritual-ascension": "scene.ritual.ascension",
};

const manifest = [];
for (const [stem, scene] of Object.entries(scenes)) {
  const file = `${stem}.svg`;
  fs.writeFileSync(path.join(outputDir, file), wrap(scene.body, scene.wash));
  manifest.push({
    stable_id: idMap[stem],
    svg: `art/assets/svg/v0.49.0/scenes/${file}`,
    png: `assets/game/v0.49.0/scenes/${stem}.png`,
  });
}
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.49.0", theme: "tingen_p4_system_shells", assets: manifest }, null, 2) + "\n",
);
console.log(`Generated ${manifest.length} v0.49 shell SVGs → ${outputDir}`);
