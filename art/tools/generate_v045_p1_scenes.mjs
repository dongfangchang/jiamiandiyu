import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.45 P1 battle scenes — 1600×900. SCENE_BRIEF_V043 P1. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.45.0", "scenes");
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
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="#211D18" stroke-width=".7" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="9" height="9" patternUnits="userSpaceOnUse">
      <path d="M0 0L9 9M9 0L0 9" stroke="#E8DFC9" stroke-width=".55" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="3" seed="45" result="noise"/>
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
  "battle-moretti-home": `
    <path d="M0 620 H1600 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 600 L1600 580 V900 H0Z" fill="#211D18" opacity=".72"/>
    <!-- apartment walls -->
    <path d="M180 100 H780 V600 H180Z" fill="#161412" stroke="#B99750" stroke-width="3" opacity=".55"/>
    <path d="M820 100 H1420 V580 H820Z" fill="#161412" stroke="#788079" stroke-width="3" opacity=".45"/>
    <!-- broken window -->
    <path d="M920 160 H1320 V360 H920Z" fill="#1a2220" stroke="#B99750" stroke-width="2"/>
    <path d="M920 260 H1320 M1120 160 V360 M1000 180 L1240 340 M1240 180 L1000 340"
      stroke="#E8DFC9" stroke-width="2" opacity=".25"/>
    <!-- candle -->
    <rect x="420" y="420" width="24" height="70" fill="#E8DFC9" stroke="#211D18" stroke-width="2"/>
    <path d="M432 400 C424 380 424 360 432 340 C440 360 440 380 432 400Z" fill="#7A2828" opacity=".7"/>
    <circle cx="432" cy="330" r="18" fill="#E8D091" opacity=".25"/>
    <!-- intruder shadow -->
    <path d="M1180 400 L1240 360 L1300 400 L1280 560 L1200 560 Z"
      fill="#0a0c0b" opacity=".65" stroke="#7A2828" stroke-width="2"/>
    <path d="M200 200 H700 M200 280 H640" stroke="#788079" stroke-width="2" opacity=".22"/>
  `,
  "battle-elliot-ruin": `
    <path d="M0 640 H1600 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 620 C500 580 900 600 1600 590 V900 H0Z" fill="#1a1814" opacity=".88"/>
    <!-- broken beams -->
    <path d="M120 80 L400 620 M280 60 L520 600 M1080 50 L1360 610 M1280 70 L1480 580"
      stroke="#3A3731" stroke-width="14" opacity=".7"/>
    <path d="M200 200 H600 M1000 180 H1400" stroke="#B99750" stroke-width="2" opacity=".25"/>
    <!-- rope -->
    <path d="M720 120 V480" stroke="#7A2828" stroke-width="4" opacity=".55"/>
    <path d="M700 480 Q720 520 740 480" fill="none" stroke="#B99750" stroke-width="3"/>
    <!-- street lamp glow through gap -->
    <circle cx="860" cy="240" r="70" fill="#E8D091" opacity=".14"/>
    <path d="M840 160 V300 M800 220 H900" stroke="#B99750" stroke-width="2" opacity=".35"/>
    <!-- rubble -->
    <g fill="#3A3731" stroke="#211D18" stroke-width="2" opacity=".65">
      <path d="M360 560 L420 500 L500 580 Z"/>
      <path d="M1100 540 L1180 480 L1260 560 Z"/>
      <rect x="700" y="560" width="120" height="50"/>
    </g>
  `,
  "battle-wood-house": `
    <path d="M0 630 H1600 V900 H0Z" fill="#120e12"/>
    <path d="M0 610 L1600 590 V900 H0Z" fill="#1e161c" opacity=".85"/>
    <!-- parlor walls -->
    <path d="M160 90 H1440 V610 H160Z" fill="#18141a" stroke="#B99750" stroke-width="3" opacity=".4"/>
    <!-- large mirror -->
    <path d="M560 140 H1040 V420 H560Z" fill="#E8DFC9" opacity=".12" stroke="#B99750" stroke-width="4"/>
    <path d="M580 160 H1020 V400 H580Z" fill="#211D18" opacity=".35" stroke="#788079" stroke-width="2"/>
    <path d="M800 160 V400" stroke="#7A2828" stroke-width="2" stroke-dasharray="6 10" opacity=".45"/>
    <!-- party table remnants -->
    <ellipse cx="800" cy="560" rx="280" ry="50" fill="#3A3731" stroke="#B99750" stroke-width="2" opacity=".7"/>
    <g fill="#E8DFC9" stroke="#211D18" stroke-width="1.5" opacity=".5">
      <circle cx="700" cy="540" r="12"/><circle cx="800" cy="530" r="10"/><circle cx="900" cy="545" r="11"/>
    </g>
    <!-- uneasy spirit hint -->
    <path d="M640 280 C700 240 760 240 800 280 C840 240 900 240 960 280"
      fill="none" stroke="#788079" stroke-width="3" opacity=".35"/>
    <circle cx="800" cy="300" r="28" fill="#7A2828" opacity=".2"/>
  `,
};

const idMap = {
  "battle-moretti-home": "scene.battle.moretti_home",
  "battle-elliot-ruin": "scene.battle.elliot_ruin",
  "battle-wood-house": "scene.battle.wood_house",
};

const manifest = [];
for (const [stem, body] of Object.entries(scenes)) {
  const file = `${stem}.svg`;
  fs.writeFileSync(path.join(outputDir, file), wrap(body));
  manifest.push({
    stable_id: idMap[stem],
    svg: `art/assets/svg/v0.45.0/scenes/${file}`,
    png: `assets/game/v0.45.0/scenes/${stem}.png`,
  });
}
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.45.0", theme: "tingen_p1_scenes", assets: manifest }, null, 2) + "\n",
);
console.log(`Generated ${manifest.length} v0.45 P1 scene SVGs → ${outputDir}`);
