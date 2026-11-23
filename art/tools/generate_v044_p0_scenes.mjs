import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.44 P0 scenes — 1600×900, no baked text. SCENE_BRIEF_V043. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.44.0", "scenes");
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
      <stop offset="0" stop-color="#EFE1C0" stop-opacity=".18"/>
      <stop offset="1" stop-color="#AF9165" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E4CA84"/>
      <stop offset=".5" stop-color="#B99750"/>
      <stop offset="1" stop-color="#69532D"/>
    </linearGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="#211D18" stroke-width=".7" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="9" height="9" patternUnits="userSpaceOnUse">
      <path d="M0 0L9 9M9 0L0 9" stroke="#E8DFC9" stroke-width=".55" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="3" seed="44" result="noise"/>
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
  <!-- safe-zone guide (invisible structure only via low opacity frame) -->
  <rect x="320" y="120" width="960" height="660" fill="none" stroke="#B99750" stroke-width="1" opacity=".08"/>
  ${body}
</svg>`;
}

const scenes = {
  "battle-tyrell-warehouse": `
    <path d="M0 620 H1600 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 600 L1600 560 V900 H0Z" fill="#211D18" opacity=".7"/>
    <path d="M0 598 H1600" stroke="#B99750" stroke-width="2" opacity=".22"/>
    <!-- crates -->
    <g fill="#3A3731" stroke="#B99750" stroke-width="2" opacity=".75">
      <rect x="120" y="520" width="160" height="110"/><rect x="150" y="480" width="120" height="50"/>
      <rect x="1320" y="510" width="170" height="120"/><rect x="1350" y="470" width="130" height="50"/>
      <rect x="680" y="540" width="140" height="90"/>
    </g>
    <!-- puppet / string motif -->
    <path d="M800 80 V420" stroke="#7A2828" stroke-width="3" opacity=".55"/>
    <path d="M720 160 Q800 200 880 160" fill="none" stroke="#B99750" stroke-width="2" opacity=".5"/>
    <circle cx="800" cy="450" r="54" fill="#E8DFC9" opacity=".12" stroke="#211D18" stroke-width="3"/>
    <path d="M760 430 L800 470 L840 430" fill="none" stroke="#7A2828" stroke-width="3"/>
    <!-- beams -->
    <path d="M80 120 H1520 M80 120 V600 M1520 120 V560" fill="none" stroke="#788079" stroke-width="4" opacity=".35"/>
    <path d="M200 120 L200 600 M400 120 L400 580 M1200 120 L1200 560 M1400 120 L1400 540"
      stroke="#788079" stroke-width="2" opacity=".2"/>
  `,
  "battle-blackthorn-neil": `
    <path d="M0 640 H1600 V900 H0Z" fill="#12080a"/>
    <path d="M0 620 L1600 580 V900 H0Z" fill="#2a1216" opacity=".85"/>
    <!-- office walls -->
    <path d="M100 80 H700 V620 H100Z" fill="#1a1414" stroke="#B99750" stroke-width="3" opacity=".55"/>
    <path d="M900 80 H1500 V580 H900Z" fill="#1a1414" stroke="#7A2828" stroke-width="3" opacity=".55"/>
    <!-- desk -->
    <rect x="520" y="500" width="560" height="90" fill="#3A3731" stroke="#B99750" stroke-width="2"/>
    <!-- flesh / alchemy stain -->
    <path d="M640 420 C700 360 780 380 820 440 C860 500 780 560 700 540 C640 520 600 470 640 420Z"
      fill="#7A2828" opacity=".45" stroke="#211D18" stroke-width="2"/>
    <circle cx="760" cy="300" r="70" fill="none" stroke="#7A2828" stroke-width="4" opacity=".4" stroke-dasharray="6 10"/>
    <path d="M200 200 H600 M200 280 H520 M1100 200 H1400 M1100 280 H1360"
      stroke="#788079" stroke-width="2" opacity=".25"/>
  `,
  "battle-lamud-chapel": `
    <path d="M0 660 H1600 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 640 C400 600 800 620 1600 600 V900 H0Z" fill="#161a16" opacity=".9"/>
    <!-- chapel silhouette -->
    <path d="M520 620 L800 140 L1080 620 Z" fill="#121612" stroke="#B99750" stroke-width="3" opacity=".7"/>
    <rect x="740" y="380" width="120" height="240" fill="#0d110f" stroke="#B99750" stroke-width="2"/>
    <!-- armor silhouette -->
    <path d="M1180 300 L1240 260 L1300 300 L1280 520 L1200 520 Z"
      fill="#211D18" stroke="#788079" stroke-width="3" opacity=".8"/>
    <circle cx="1240" cy="230" r="28" fill="#3A3731" stroke="#B99750" stroke-width="2"/>
    <!-- sun emblem glow -->
    <circle cx="800" cy="280" r="40" fill="#B99750" opacity=".25"/>
    <path d="M800 220 V340 M740 280 H860 M760 240 L840 320 M840 240 L760 320"
      stroke="#E8D091" stroke-width="3" opacity=".45"/>
    <!-- graves -->
    <g fill="#3A3731" stroke="#211D18" stroke-width="2" opacity=".6">
      <rect x="180" y="560" width="40" height="70"/><rect x="260" y="540" width="36" height="90"/>
      <rect x="1400" y="550" width="40" height="80"/>
    </g>
  `,
  "rest-divination-club": `
    <path d="M0 580 H1600 V900 H0Z" fill="#1a1610"/>
    <path d="M0 560 L1600 540 V900 H0Z" fill="#2a2418" opacity=".85"/>
    <!-- warm club table -->
    <ellipse cx="800" cy="620" rx="420" ry="90" fill="#3A3731" stroke="#B99750" stroke-width="3"/>
    <ellipse cx="800" cy="600" rx="360" ry="60" fill="#4a3b1d" opacity=".5"/>
    <!-- tarot / pendulum -->
    <g fill="#E8DFC9" stroke="#211D18" stroke-width="2">
      <rect x="680" y="520" width="48" height="70" rx="3" transform="rotate(-12 704 555)"/>
      <rect x="760" y="500" width="48" height="70" rx="3"/>
      <rect x="840" y="515" width="48" height="70" rx="3" transform="rotate(10 864 550)"/>
    </g>
    <path d="M980 420 V560" stroke="#B99750" stroke-width="3"/>
    <circle cx="980" cy="575" r="14" fill="#7A2828" stroke="#211D18" stroke-width="2"/>
    <!-- lamps -->
    <circle cx="420" cy="220" r="50" fill="#E8D091" opacity=".2"/>
    <circle cx="1180" cy="200" r="45" fill="#E8D091" opacity=".18"/>
    <path d="M200 80 H1400 V500 H200Z" fill="none" stroke="#B99750" stroke-width="2" opacity=".2"/>
    <path d="M280 160 H600 M1000 160 H1320" stroke="#788079" stroke-width="2" opacity=".25"/>
  `,
  "ritual-clown-ascension": `
    <path d="M0 650 H1600 V900 H0Z" fill="#0a0c0b"/>
    <ellipse cx="800" cy="480" rx="280" ry="120" fill="#1a1610" stroke="#B99750" stroke-width="3" opacity=".7"/>
    <!-- goddess hint: moon disk -->
    <circle cx="800" cy="220" r="70" fill="none" stroke="#B99750" stroke-width="4" opacity=".55"/>
    <circle cx="800" cy="220" r="40" fill="#E8DFC9" opacity=".12"/>
    <!-- potion cup -->
    <path d="M760 420 L780 520 H820 L840 420 Z" fill="#E8DFC9" stroke="#211D18" stroke-width="3" opacity=".7"/>
    <ellipse cx="800" cy="420" rx="40" ry="12" fill="#7A2828" opacity=".5" stroke="#B99750" stroke-width="2"/>
    <!-- restrained clown makeup hint: smile arc -->
    <path d="M720 340 C760 380 840 380 880 340" fill="none" stroke="#7A2828" stroke-width="4" opacity=".35"/>
    <path d="M400 160 H1200 M400 160 V560 M1200 160 V560" fill="none" stroke="#788079" stroke-width="2" opacity=".25"/>
    <path d="M560 280 H1040 M560 360 H1040" stroke="#B99750" stroke-width="1" opacity=".2"/>
  `,
};

const manifest = [];
for (const [fileStem, body] of Object.entries(scenes)) {
  const file = `${fileStem}.svg`;
  fs.writeFileSync(path.join(outputDir, file), wrap(body));
  const sceneId = {
    "battle-tyrell-warehouse": "scene.battle.tyrell_warehouse",
    "battle-blackthorn-neil": "scene.battle.blackthorn_neil",
    "battle-lamud-chapel": "scene.battle.lamud_chapel",
    "rest-divination-club": "scene.rest.divination_club",
    "ritual-clown-ascension": "scene.ritual.clown_ascension",
  }[fileStem];
  manifest.push({
    stable_id: sceneId,
    svg: `art/assets/svg/v0.44.0/scenes/${file}`,
    png: `assets/game/v0.44.0/scenes/${fileStem}.png`,
  });
}
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.44.0", theme: "tingen_p0_scenes", assets: manifest }, null, 2) + "\n",
);
console.log(`Generated ${manifest.length} v0.44 P0 scene SVGs → ${outputDir}`);
