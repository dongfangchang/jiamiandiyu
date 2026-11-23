import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.47 P3 system shells — 1600×900. SCENE_BRIEF_V043 P3. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.47.0", "scenes");
fs.mkdirSync(outputDir, { recursive: true });

function wrap(body, washStops = ["#15130f", "#2a261f", "#0e0c0a"]) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${washStops[0]}"/>
      <stop offset=".55" stop-color="${washStops[1]}"/>
      <stop offset="1" stop-color="${washStops[2]}"/>
    </linearGradient>
    <radialGradient id="paperGlow" cx="50%" cy="40%" r="58%">
      <stop offset="0" stop-color="#EFE1C0" stop-opacity=".18"/>
      <stop offset="1" stop-color="#AF9165" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="candleGlow" cx="62%" cy="48%" r="28%">
      <stop offset="0" stop-color="#E8D091" stop-opacity=".35"/>
      <stop offset="1" stop-color="#211D18" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="fogGlow" cx="50%" cy="42%" r="55%">
      <stop offset="0" stop-color="#c8c2b0" stop-opacity=".2"/>
      <stop offset="1" stop-color="#111612" stop-opacity="0"/>
    </radialGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="#211D18" stroke-width=".7" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="9" height="9" patternUnits="userSpaceOnUse">
      <path d="M0 0L9 9M9 0L0 9" stroke="#E8DFC9" stroke-width=".55" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="3" seed="47" result="noise"/>
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
  "title-mask-desk": {
    wash: ["#14110e", "#2c2418", "#0c0a08"],
    body: `
    <rect width="1600" height="900" fill="url(#candleGlow)"/>
    <path d="M0 620 H1600 V900 H0Z" fill="#0a0907"/>
    <path d="M80 640 H1520 V780 H80Z" fill="#211D18" stroke="#B99750" stroke-width="3" opacity=".85"/>
    <!-- desk grain -->
    <path d="M120 680 H1480 M160 720 H1440" stroke="#788079" stroke-width="1.5" opacity=".2"/>
    <!-- mask -->
    <ellipse cx="720" cy="470" rx="150" ry="95" fill="#3A3731" stroke="#E8DFC9" stroke-width="3"/>
    <ellipse cx="670" cy="455" rx="28" ry="34" fill="#15130f"/>
    <ellipse cx="770" cy="455" rx="28" ry="34" fill="#15130f"/>
    <path d="M720 490 Q740 520 760 505" fill="none" stroke="#B99750" stroke-width="3"/>
    <!-- wax seal -->
    <circle cx="980" cy="560" r="42" fill="#7A2828" stroke="#E8D091" stroke-width="3"/>
    <path d="M980 540 V580 M960 560 H1000" stroke="#E8D091" stroke-width="2" opacity=".7"/>
    <!-- candle -->
    <rect x="1088" y="420" width="28" height="110" rx="4" fill="#E8DFC9" stroke="#B99750" stroke-width="2"/>
    <ellipse cx="1102" cy="410" rx="14" ry="22" fill="#E8D091" opacity=".85"/>
    <path d="M1102 392 Q1110 380 1102 368" fill="none" stroke="#7A2828" stroke-width="2" opacity=".5"/>
    <!-- papers -->
    <g fill="#EFE1C0" stroke="#211D18" stroke-width="2" opacity=".55">
      <rect x="420" y="560" width="140" height="90" transform="rotate(-8 490 605)"/>
      <rect x="1180" y="540" width="120" height="80" transform="rotate(6 1240 580)"/>
    </g>
  `,
  },
  "hub-route-map": {
    wash: ["#1a1812", "#2f2a20", "#100e0b"],
    body: `
    <path d="M180 100 H1420 V780 H180Z" fill="#EFE1C0" opacity=".08" stroke="#B99750" stroke-width="3"/>
    <path d="M220 140 H1380 V740 H220Z" fill="#211D18" opacity=".35" stroke="#788079" stroke-width="2"/>
    <!-- street grid suggestion -->
    <g fill="none" stroke="#E8DFC9" stroke-width="2" opacity=".28">
      <path d="M280 280 H1320"/>
      <path d="M280 420 H1320"/>
      <path d="M280 560 H1320"/>
      <path d="M420 180 V700"/>
      <path d="M700 180 V700"/>
      <path d="M980 180 V700"/>
      <path d="M1180 180 V700"/>
    </g>
    <!-- river / fog band -->
    <path d="M260 500 C500 460 700 540 900 500 C1100 460 1280 520 1340 490"
      fill="none" stroke="#788079" stroke-width="8" opacity=".35"/>
    <!-- markers -->
    <g fill="#7A2828" stroke="#E8D091" stroke-width="2">
      <circle cx="520" cy="320" r="14"/>
      <circle cx="820" cy="360" r="14"/>
      <circle cx="1080" cy="300" r="14"/>
      <circle cx="640" cy="600" r="14"/>
    </g>
    <path d="M520 320 L820 360 L1080 300 L640 600" fill="none" stroke="#B99750" stroke-width="2" opacity=".45" stroke-dasharray="8 6"/>
    <!-- compass rose -->
    <circle cx="1280" cy="200" r="36" fill="none" stroke="#B99750" stroke-width="2" opacity=".55"/>
    <path d="M1280 170 V230 M1250 200 H1310" stroke="#E8D091" stroke-width="2" opacity=".55"/>
  `,
  },
  "hub-deck-archive": {
    wash: ["#121410", "#252820", "#0b0d0b"],
    body: `
    <path d="M0 700 H1600 V900 H0Z" fill="#0a0c0b"/>
    <!-- cabinet -->
    <path d="M360 120 H1240 V700 H360Z" fill="#1a1814" stroke="#B99750" stroke-width="4" opacity=".75"/>
    <path d="M400 160 H1200 V280 H400Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <path d="M400 300 H1200 V420 H400Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <path d="M400 440 H1200 V560 H400Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <path d="M400 580 H1200 V660 H400Z" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <!-- drawer pulls + seals -->
    <g>
      <circle cx="800" cy="220" r="16" fill="#7A2828" stroke="#E8D091" stroke-width="2"/>
      <circle cx="800" cy="360" r="16" fill="#7A2828" stroke="#E8D091" stroke-width="2"/>
      <circle cx="800" cy="500" r="16" fill="#7A2828" stroke="#E8D091" stroke-width="2"/>
      <circle cx="800" cy="620" r="16" fill="#3A3731" stroke="#B99750" stroke-width="2"/>
    </g>
    <!-- card stacks hint -->
    <g fill="#EFE1C0" stroke="#211D18" stroke-width="2" opacity=".45">
      <rect x="460" y="190" width="70" height="55" rx="3"/>
      <rect x="1070" y="330" width="70" height="55" rx="3"/>
      <rect x="470" y="470" width="70" height="55" rx="3"/>
    </g>
    <path d="M300 160 V640 M1300 160 V640" stroke="#B99750" stroke-width="2" opacity=".2"/>
  `,
  },
  "hub-gacha-altar": {
    wash: ["#101214", "#1e2428", "#090b0c"],
    body: `
    <rect width="1600" height="900" fill="url(#fogGlow)"/>
    <path d="M0 640 H1600 V900 H0Z" fill="#0a0c0b" opacity=".9"/>
    <path d="M0 560 C300 520 500 600 800 550 C1100 500 1300 580 1600 540 V900 H0Z"
      fill="#c8c2b0" opacity=".1"/>
    <!-- altar stone -->
    <path d="M520 480 H1080 L1020 620 H580Z" fill="#211D18" stroke="#B99750" stroke-width="3"/>
    <ellipse cx="800" cy="470" rx="180" ry="50" fill="#3A3731" stroke="#788079" stroke-width="2" opacity=".7"/>
    <!-- offering glow -->
    <circle cx="800" cy="400" r="70" fill="#E8D091" opacity=".12"/>
    <circle cx="800" cy="400" r="36" fill="none" stroke="#B99750" stroke-width="3" opacity=".55"/>
    <path d="M800 330 V370" stroke="#E8D091" stroke-width="3" opacity=".45"/>
    <!-- three wish slots -->
    <g fill="#15130f" stroke="#E8DFC9" stroke-width="2" opacity=".5">
      <rect x="560" y="500" width="90" height="70" rx="4"/>
      <rect x="755" y="510" width="90" height="70" rx="4"/>
      <rect x="950" y="500" width="90" height="70" rx="4"/>
    </g>
    <!-- vertical fog shafts -->
    <path d="M400 120 V480 M1200 140 V500" stroke="#E8DFC9" stroke-width="2" opacity=".12"/>
  `,
  },
};

const idMap = {
  "title-mask-desk": "scene.title.mask_desk",
  "hub-route-map": "scene.hub.route_map",
  "hub-deck-archive": "scene.hub.deck_archive",
  "hub-gacha-altar": "scene.hub.gacha_altar",
};

const manifest = [];
for (const [stem, scene] of Object.entries(scenes)) {
  const file = `${stem}.svg`;
  fs.writeFileSync(path.join(outputDir, file), wrap(scene.body, scene.wash));
  manifest.push({
    stable_id: idMap[stem],
    svg: `art/assets/svg/v0.47.0/scenes/${file}`,
    png: `assets/game/v0.47.0/scenes/${stem}.png`,
  });
}
fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.47.0", theme: "tingen_p3_system_shells", assets: manifest }, null, 2) + "\n",
);
console.log(`Generated ${manifest.length} v0.47 P3 scene SVGs → ${outputDir}`);
