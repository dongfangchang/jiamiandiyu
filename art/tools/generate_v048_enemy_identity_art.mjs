import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** v0.48 enemy (900²) + identity (512×640) portraits. ART_BRIEF_V048. No baked text. */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const enemyDir = path.resolve(toolDir, "..", "assets", "svg", "v0.48.0", "enemies");
const identityDir = path.resolve(toolDir, "..", "assets", "svg", "v0.48.0", "identities");
fs.mkdirSync(enemyDir, { recursive: true });
fs.mkdirSync(identityDir, { recursive: true });

function defs(seed) {
  return `<defs>
    <linearGradient id="wash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1a1812"/>
      <stop offset="1" stop-color="#0c0b09"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="42%" r="48%">
      <stop offset="0" stop-color="#EFE1C0" stop-opacity=".14"/>
      <stop offset="1" stop-color="#AF9165" stop-opacity="0"/>
    </radialGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(28)">
      <path d="M0 0V8" stroke="#211D18" stroke-width=".7" opacity=".16"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".6" numOctaves="3" seed="${seed}" result="n"/>
      <feColorMatrix in="n" type="saturate" values="0" result="m"/>
      <feComponentTransfer in="m" result="f"><feFuncA type="table" tableValues="0 .11"/></feComponentTransfer>
      <feBlend in="SourceGraphic" in2="f" mode="multiply"/>
    </filter>
  </defs>`;
}

function enemySvg(body, seed) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="900" height="900" viewBox="0 0 900 900">
  ${defs(seed)}
  <rect width="900" height="900" fill="url(#wash)" filter="url(#grain)"/>
  <rect width="900" height="900" fill="url(#glow)"/>
  <rect width="900" height="900" fill="url(#hatch)" opacity=".25"/>
  <circle cx="450" cy="430" r="310" fill="none" stroke="#B99750" stroke-width="1" opacity=".1"/>
  ${body}
</svg>`;
}

function identitySvg(body, seed) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="640" viewBox="0 0 512 640">
  ${defs(seed)}
  <rect width="512" height="640" fill="url(#wash)" filter="url(#grain)"/>
  <rect width="512" height="640" fill="url(#glow)"/>
  <rect width="512" height="640" fill="url(#hatch)" opacity=".22"/>
  <rect x="36" y="48" width="440" height="544" rx="18" fill="none" stroke="#B99750" stroke-width="3" opacity=".35"/>
  ${body}
</svg>`;
}

const enemies = {
  "enemy-candle-moth": `
    <!-- 密修会成员：斗篷 + 匕首 -->
    <ellipse cx="450" cy="720" rx="160" ry="28" fill="#3A3731" opacity=".25"/>
    <path d="M260 280 C300 180 380 140 450 140 C520 140 600 180 640 280
      L610 620 H290 Z" fill="#211D18" stroke="#788079" stroke-width="4"/>
    <path d="M330 260 C370 210 430 200 450 200 C470 200 530 210 570 260"
      fill="#15130f" stroke="#B99750" stroke-width="2"/>
    <circle cx="450" cy="250" r="36" fill="#3A3731" stroke="#E8DFC9" stroke-width="3"/>
    <path d="M520 360 L680 300 L670 330 L620 360 Z" fill="#E8DFC9" stroke="#211D18" stroke-width="3"/>
    <path d="M300 420 H420" stroke="#7A2828" stroke-width="4" opacity=".55"/>
  `,
  "enemy-tingen-kidnapper": `
    <!-- 绑匪：粗帽 + 棍棒 -->
    <ellipse cx="450" cy="730" rx="150" ry="26" fill="#3A3731" opacity=".25"/>
    <path d="M320 300 H580 L560 640 H340 Z" fill="#3A3731" stroke="#211D18" stroke-width="4"/>
    <ellipse cx="450" cy="250" rx="70" ry="55" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M360 220 H540 L520 190 H380 Z" fill="#211D18" stroke="#788079" stroke-width="3"/>
    <rect x="620" y="280" width="28" height="280" rx="6" fill="#5D4726" stroke="#211D18" stroke-width="3" transform="rotate(18 634 420)"/>
    <circle cx="430" cy="245" r="6" fill="#211D18"/><circle cx="470" cy="245" r="6" fill="#211D18"/>
    <path d="M300 480 H420" stroke="#B99750" stroke-width="3" opacity=".4"/>
  `,
  "enemy-mirror-hound": `
    <!-- 失控的瑞尔·比伯：扭曲 + 红眼 + 笔记 -->
    <ellipse cx="450" cy="740" rx="170" ry="30" fill="#3A3731" opacity=".28"/>
    <path d="M280 320 C320 200 400 160 450 170 C520 150 600 220 620 340
      C640 460 600 620 520 660 C460 680 380 660 320 600 C260 520 250 400 280 320 Z"
      fill="#2a1818" stroke="#7A2828" stroke-width="4"/>
    <circle cx="400" cy="300" r="22" fill="#7A2828" stroke="#E8D091" stroke-width="2"/>
    <circle cx="500" cy="295" r="26" fill="#7A2828" stroke="#E8D091" stroke-width="2"/>
    <path d="M360 400 C420 440 480 430 540 390" fill="none" stroke="#E8DFC9" stroke-width="3" opacity=".4"/>
    <rect x="620" y="420" width="70" height="90" rx="4" fill="#EFE1C0" stroke="#211D18" stroke-width="3" transform="rotate(12 655 465)"/>
    <path d="M300 500 L260 580 L320 560" fill="#7A2828" opacity=".45"/>
  `,
  "enemy-mirror-hound-echo": `
    <!-- 燕尾服小丑：高礼帽 + 燕尾 -->
    <ellipse cx="450" cy="740" rx="150" ry="26" fill="#3A3731" opacity=".22"/>
    <path d="M340 300 H560 L540 560 H520 L560 700 H480 L450 580 L420 700 H360 L400 560 H360 Z"
      fill="#15130f" stroke="#B99750" stroke-width="3"/>
    <circle cx="450" cy="250" r="48" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <rect x="400" y="120" width="100" height="90" rx="4" fill="#211D18" stroke="#B99750" stroke-width="3"/>
    <ellipse cx="450" cy="210" rx="80" ry="14" fill="#211D18" stroke="#788079" stroke-width="2"/>
    <circle cx="430" cy="245" r="5" fill="#211D18"/><circle cx="470" cy="245" r="5" fill="#211D18"/>
    <path d="M430 270 Q450 285 470 270" fill="none" stroke="#7A2828" stroke-width="3"/>
    <circle cx="600" cy="380" r="28" fill="none" stroke="#E8D091" stroke-width="3" opacity=".5"/>
  `,
  "enemy-weeping-tenant": `
    <!-- 附身恶灵：半透明 + 魔镜 -->
    <ellipse cx="450" cy="720" rx="140" ry="24" fill="#3A3731" opacity=".18"/>
    <path d="M300 260 C340 160 400 140 450 150 C500 140 560 160 600 260
      C620 360 580 560 450 620 C320 560 280 360 300 260 Z"
      fill="#c8c2b0" opacity=".18" stroke="#E8DFC9" stroke-width="3"/>
    <ellipse cx="420" cy="280" rx="18" ry="28" fill="#211D18" opacity=".5"/>
    <ellipse cx="490" cy="280" rx="18" ry="28" fill="#211D18" opacity=".5"/>
    <path d="M400 360 Q450 400 500 360" fill="none" stroke="#788079" stroke-width="3" opacity=".6"/>
    <ellipse cx="450" cy="480" rx="90" ry="50" fill="none" stroke="#B99750" stroke-width="3" opacity=".45"/>
    <path d="M450 430 V530" stroke="#B99750" stroke-width="2" opacity=".35"/>
  `,
  "enemy-tingen-knight-wraith": `
    <!-- 骑士怨魂：黑铠 + 锈剑 -->
    <ellipse cx="450" cy="740" rx="160" ry="28" fill="#3A3731" opacity=".25"/>
    <path d="M340 280 H560 L540 620 H360 Z" fill="#141210" stroke="#788079" stroke-width="4"/>
    <path d="M380 220 H520 L500 300 H400 Z" fill="#211D18" stroke="#B99750" stroke-width="3"/>
    <circle cx="450" cy="250" r="8" fill="#E8D091" opacity=".4"/>
    <rect x="620" y="200" width="22" height="360" rx="3" fill="#5D4726" stroke="#7A2828" stroke-width="3"/>
    <path d="M610 200 H654 L632 160 Z" fill="#788079" stroke="#211D18" stroke-width="2"/>
    <path d="M360 360 H420 M480 360 H540" stroke="#E8DFC9" stroke-width="2" opacity=".25"/>
    <path d="M300 500 C360 460 420 460 450 500" fill="none" stroke="#c8c2b0" stroke-width="2" opacity=".3"/>
  `,
  "enemy-tingen-rampager": `
    <!-- 失控的代罚者：撕裂体态 -->
    <ellipse cx="450" cy="740" rx="170" ry="30" fill="#3A3731" opacity=".28"/>
    <path d="M260 340 C300 220 380 180 450 190 C540 170 640 250 650 380
      C660 520 580 680 470 700 C360 680 250 560 260 340 Z"
      fill="#2a1014" stroke="#7A2828" stroke-width="4"/>
    <path d="M320 400 L280 520 M580 380 L640 500" stroke="#E8DFC9" stroke-width="4" opacity=".35"/>
    <circle cx="410" cy="300" r="18" fill="#7A2828"/><circle cx="500" cy="295" r="20" fill="#7A2828"/>
    <path d="M380 360 L450 400 L520 350" fill="none" stroke="#211D18" stroke-width="4"/>
    <path d="M300 560 H600" stroke="#B99750" stroke-width="2" opacity=".25"/>
  `,
  "enemy-mirror-baron": `
    <!-- 失控的老尼尔：红眼 + 血肉炼成 -->
    <ellipse cx="450" cy="740" rx="180" ry="32" fill="#3A3731" opacity=".3"/>
    <path d="M250 300 C300 180 390 140 450 150 C530 130 640 210 660 350
      C680 500 600 680 450 720 C300 680 220 500 250 300 Z"
      fill="#1a0c10" stroke="#7A2828" stroke-width="5"/>
    <circle cx="390" cy="310" r="34" fill="#7A2828" stroke="#E8D091" stroke-width="3"/>
    <circle cx="520" cy="300" r="40" fill="#7A2828" stroke="#E8D091" stroke-width="3"/>
    <circle cx="390" cy="310" r="10" fill="#211D18"/><circle cx="520" cy="300" r="12" fill="#211D18"/>
    <path d="M340 420 C400 480 500 480 560 410" fill="none" stroke="#E8DFC9" stroke-width="3" opacity=".35"/>
    <path d="M300 520 C360 560 420 580 450 560 C480 580 540 560 600 520"
      fill="#7A2828" opacity=".35" stroke="#B99750" stroke-width="2"/>
    <path d="M200 400 L260 360 L250 420 Z" fill="#7A2828" opacity=".5"/>
  `,
  "enemy-tingen-megose": `
    <!-- 梅高欧丝：异变 + 白骨刀暗示 -->
    <ellipse cx="450" cy="750" rx="190" ry="34" fill="#3A3731" opacity=".3"/>
    <path d="M280 280 C340 160 420 130 450 140 C500 120 600 180 640 300
      C680 440 620 620 500 700 C420 740 340 700 280 560 C240 440 240 340 280 280 Z"
      fill="#241018" stroke="#7A2828" stroke-width="4"/>
    <ellipse cx="450" cy="420" rx="100" ry="120" fill="#7A2828" opacity=".2"/>
    <circle cx="410" cy="280" r="20" fill="#E8DFC9" opacity=".25"/>
    <circle cx="500" cy="270" r="22" fill="#E8DFC9" opacity=".25"/>
    <path d="M600 360 L760 280 L740 320 L680 360 Z" fill="#E8DFC9" stroke="#211D18" stroke-width="3"/>
    <path d="M320 500 C380 560 480 580 560 520" fill="none" stroke="#B99750" stroke-width="3" opacity=".4"/>
    <circle cx="450" cy="500" r="40" fill="none" stroke="#E8D091" stroke-width="2" opacity=".35"/>
  `,
};

const identities = {
  "card-identity-reporter": `
    <!-- 占卜俱乐部会员：灵摆 -->
    <ellipse cx="256" cy="520" rx="120" ry="24" fill="#3A3731" opacity=".2"/>
    <ellipse cx="256" cy="360" rx="140" ry="50" fill="#211D18" stroke="#B99750" stroke-width="3" opacity=".7"/>
    <circle cx="256" cy="220" r="54" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M256 120 V180" stroke="#B99750" stroke-width="4"/>
    <path d="M220 250 Q256 280 292 250" fill="none" stroke="#7A2828" stroke-width="3"/>
    <path d="M256 274 V340" stroke="#E8D091" stroke-width="3"/>
    <path d="M256 340 L230 400 L282 400 Z" fill="#B99750" stroke="#211D18" stroke-width="2"/>
    <g fill="#EFE1C0" stroke="#211D18" stroke-width="2" opacity=".55">
      <rect x="120" y="400" width="60" height="80" rx="4"/>
      <rect x="332" y="400" width="60" height="80" rx="4"/>
    </g>
  `,
  "card-identity-doctor": `
    <!-- 值夜者文职：徽章 + 手套 -->
    <ellipse cx="256" cy="520" rx="120" ry="24" fill="#3A3731" opacity=".2"/>
    <path d="M170 300 H342 L320 500 H192 Z" fill="#211D18" stroke="#788079" stroke-width="3"/>
    <circle cx="256" cy="220" r="50" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <circle cx="256" cy="360" r="48" fill="#7A2828" stroke="#E8D091" stroke-width="3"/>
    <path d="M256 330 V390 M230 360 H282" stroke="#E8D091" stroke-width="3"/>
    <path d="M140 420 C180 400 200 400 230 430" fill="none" stroke="#B99750" stroke-width="6" stroke-linecap="round"/>
    <path d="M372 420 C332 400 312 400 282 430" fill="none" stroke="#B99750" stroke-width="6" stroke-linecap="round"/>
  `,
  "card-identity-gravedigger": `
    <!-- 霍伊大学历史系：典籍 + 残页 -->
    <ellipse cx="256" cy="530" rx="120" ry="22" fill="#3A3731" opacity=".2"/>
    <rect x="150" y="220" width="140" height="200" rx="6" fill="#EFE1C0" stroke="#211D18" stroke-width="4"/>
    <rect x="220" y="200" width="140" height="200" rx="6" fill="#E8DFC9" stroke="#B99750" stroke-width="4"/>
    <path d="M240 240 H340 M240 270 H320 M240 300 H330 M240 330 H300" stroke="#211D18" stroke-width="2.5" opacity=".45"/>
    <path d="M340 360 L400 320 L420 400 L360 420 Z" fill="#EFE1C0" stroke="#7A2828" stroke-width="2" opacity=".75"/>
    <circle cx="256" cy="160" r="28" fill="none" stroke="#B99750" stroke-width="3" opacity=".5"/>
    <path d="M256 140 V180 M236 160 H276" stroke="#B99750" stroke-width="2" opacity=".5"/>
  `,
};

const enemyIdMap = {
  "enemy-candle-moth": "enemy.candle_moth",
  "enemy-tingen-kidnapper": "enemy.tingen.kidnapper",
  "enemy-mirror-hound": "enemy.mirror_hound",
  "enemy-mirror-hound-echo": "enemy.mirror_hound_echo",
  "enemy-weeping-tenant": "enemy.weeping_tenant",
  "enemy-tingen-knight-wraith": "enemy.tingen.knight_wraith",
  "enemy-tingen-rampager": "enemy.tingen.rampager",
  "enemy-mirror-baron": "enemy.mirror_baron",
  "enemy-tingen-megose": "enemy.tingen.megose",
};

const identityIdMap = {
  "card-identity-reporter": "identity.reporter",
  "card-identity-doctor": "identity.doctor",
  "card-identity-gravedigger": "identity.gravedigger",
};

const manifest = { version: "v0.48.0", theme: "tingen_enemy_identity", enemies: [], identities: [] };
let seed = 480;
for (const [stem, body] of Object.entries(enemies)) {
  fs.writeFileSync(path.join(enemyDir, `${stem}.svg`), enemySvg(body, seed++));
  manifest.enemies.push({
    stable_id: enemyIdMap[stem],
    svg: `art/assets/svg/v0.48.0/enemies/${stem}.svg`,
    png: `assets/game/v0.48.0/enemies/${stem}.png`,
  });
}
for (const [stem, body] of Object.entries(identities)) {
  fs.writeFileSync(path.join(identityDir, `${stem}.svg`), identitySvg(body, seed++));
  manifest.identities.push({
    stable_id: identityIdMap[stem],
    svg: `art/assets/svg/v0.48.0/identities/${stem}.svg`,
    png: `assets/game/v0.48.0/identities/${stem}.png`,
  });
}
fs.writeFileSync(
  path.resolve(toolDir, "..", "assets", "svg", "v0.48.0", "manifest.json"),
  JSON.stringify(manifest, null, 2) + "\n",
);
console.log(
  `Generated ${manifest.enemies.length} enemies + ${manifest.identities.length} identities → v0.48.0`,
);
