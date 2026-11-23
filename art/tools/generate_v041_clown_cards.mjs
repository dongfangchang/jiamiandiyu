import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/**
 * v0.41.0 — 序列 8「小丑」八张卡面 SVG（与 ART_BRIEF_V041 / 既有纸张铜版语言一致）。
 * 无烘焙中文、费用或规则文本。稳定 ID 与文件名后缀一一对应。
 */

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(toolDir, "..", "assets", "svg", "v0.41.0", "cards");
fs.mkdirSync(outputDir, { recursive: true });

const motifs = {
  // 身体控制与平衡 — 几乎不跌倒的轻盈步态
  veil_step: `
    <ellipse cx="256" cy="318" rx="78" ry="14" fill="#3A3731" opacity=".18"/>
    <path d="M188 292 C210 250 232 214 256 168 C280 214 302 250 324 292"
      fill="none" stroke="#211D18" stroke-width="5" stroke-linecap="round"/>
    <path d="M210 270 C232 236 248 210 256 188 C264 210 280 236 302 270"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <circle cx="256" cy="152" r="28" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M236 148 H276 M256 128 V172" stroke="#7A2828" stroke-width="3"/>
    <path d="M168 220 C196 198 224 198 256 220 C288 198 316 198 344 220"
      fill="none" stroke="#211D18" stroke-width="2" stroke-dasharray="4 8" opacity=".55"/>
    <circle cx="256" cy="200" r="118" fill="none" stroke="#B99750" stroke-width="1" stroke-dasharray="3 9" opacity=".7"/>
  `,
  // 预判下一步 — 看穿意图的预感
  severed_fate: `
    <path d="M132 250 C176 170 220 140 256 140 C292 140 336 170 380 250"
      fill="none" stroke="#211D18" stroke-width="5"/>
    <path d="M156 250 C192 190 228 168 256 168 C284 168 320 190 356 250"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <ellipse cx="256" cy="210" rx="42" ry="26" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <circle cx="256" cy="210" r="10" fill="#7A2828"/>
    <path d="M256 96 L274 148 L256 138 L238 148 Z" fill="#B99750" stroke="#211D18" stroke-width="2"/>
    <path d="M200 286 H312 M220 304 H292" stroke="#211D18" stroke-width="3" opacity=".55"/>
    <circle cx="256" cy="210" r="96" fill="none" stroke="#211D18" stroke-width=".8" stroke-dasharray="2 10" opacity=".35"/>
  `,
  // 纸牌连掷 — 多枚锋利纸牌
  paper_swarm: `
    <g stroke="#211D18" stroke-width="3" fill="#E8DFC9">
      <rect x="148" y="120" width="54" height="78" rx="4" transform="rotate(-28 175 159)"/>
      <rect x="214" y="108" width="54" height="78" rx="4" transform="rotate(-8 241 147)"/>
      <rect x="268" y="112" width="54" height="78" rx="4" transform="rotate(12 295 151)"/>
      <rect x="318" y="132" width="54" height="78" rx="4" transform="rotate(32 345 171)"/>
    </g>
    <g fill="none" stroke="#B99750" stroke-width="2">
      <path d="M160 150 L190 190"/>
      <path d="M230 130 L255 175"/>
      <path d="M285 140 L305 185"/>
      <path d="M335 160 L355 200"/>
    </g>
    <path d="M120 280 C180 240 230 240 256 260 C282 240 332 240 392 280"
      fill="none" stroke="#7A2828" stroke-width="4" stroke-linecap="round"/>
    <circle cx="256" cy="210" r="124" fill="none" stroke="#211D18" stroke-width=".8" stroke-dasharray="2 9" opacity=".28"/>
  `,
  // 闪身反击 — 闪避后反击
  mirror_shard: `
    <path d="M168 120 L256 88 L344 120 L312 250 C300 300 270 322 256 330 C242 322 212 300 200 250 Z"
      fill="#E8DFC9" opacity=".5" stroke="#211D18" stroke-width="4"/>
    <path d="M196 140 L256 116 L316 140 L292 240 C284 278 266 296 256 302 C246 296 228 278 220 240 Z"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <path d="M210 210 L256 176 L302 210" fill="none" stroke="#7A2828" stroke-width="5" stroke-linecap="round"/>
    <path d="M256 176 V268" stroke="#211D18" stroke-width="4"/>
    <circle cx="180" cy="286" r="16" fill="none" stroke="#B99750" stroke-width="2" stroke-dasharray="3 5"/>
    <circle cx="332" cy="286" r="16" fill="none" stroke="#B99750" stroke-width="2" stroke-dasharray="3 5"/>
  `,
  // 小丑的微笑 — 小丑妆微笑（联动件 A）
  last_witness: `
    <circle cx="256" cy="188" r="92" fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <circle cx="220" cy="176" r="10" fill="#211D18"/>
    <circle cx="292" cy="176" r="10" fill="#211D18"/>
    <path d="M214 222 C236 248 276 248 298 222" fill="none" stroke="#7A2828" stroke-width="6" stroke-linecap="round"/>
    <path d="M188 148 C206 128 230 124 256 136 C282 124 306 128 324 148"
      fill="none" stroke="#B99750" stroke-width="4"/>
    <ellipse cx="210" cy="204" rx="14" ry="10" fill="#7A2828" opacity=".55"/>
    <ellipse cx="302" cy="204" rx="14" ry="10" fill="#7A2828" opacity=".55"/>
    <path d="M160 300 H352 M180 318 H332" stroke="#211D18" stroke-width="3" opacity=".45"/>
    <circle cx="256" cy="188" r="118" fill="none" stroke="#B99750" stroke-width="1" stroke-dasharray="3 8" opacity=".75"/>
  `,
  // 小丑的危险预感 — 强化预感（联动件 B）
  false_death: `
    <path d="M256 86 C210 140 190 190 210 236 C224 268 288 268 302 236 C322 190 302 140 256 86 Z"
      fill="#E8DFC9" stroke="#211D18" stroke-width="4"/>
    <path d="M256 120 C232 168 228 198 246 228" fill="none" stroke="#7A2828" stroke-width="5" stroke-linecap="round"/>
    <circle cx="256" cy="246" r="18" fill="#211D18"/>
    <circle cx="256" cy="246" r="8" fill="#B99750"/>
    <path d="M146 250 C186 210 226 210 256 236 C286 210 326 210 366 250"
      fill="none" stroke="#B99750" stroke-width="3"/>
    <path d="M176 300 H336" stroke="#211D18" stroke-width="3" opacity=".5"/>
    <circle cx="256" cy="200" r="126" fill="none" stroke="#211D18" stroke-width=".8" stroke-dasharray="2 10" opacity=".3"/>
  `,
  // 阿兹克铜哨 — 器物 + 亡灵代价感
  sealed_answer: `
    <ellipse cx="256" cy="210" rx="78" ry="54" fill="#B99750" stroke="#211D18" stroke-width="4"/>
    <ellipse cx="256" cy="210" rx="52" ry="34" fill="#E8D091" stroke="#5D4726" stroke-width="2"/>
    <circle cx="256" cy="210" r="14" fill="#211D18"/>
    <path d="M256 156 V120 M240 132 H272" stroke="#211D18" stroke-width="5" stroke-linecap="round"/>
    <path d="M178 280 C210 250 240 250 256 266 C272 250 302 250 334 280"
      fill="none" stroke="#7A2828" stroke-width="4" opacity=".85"/>
    <path d="M150 160 C170 120 200 108 230 118 M362 160 C342 120 312 108 282 118"
      fill="none" stroke="#211D18" stroke-width="3" stroke-dasharray="4 7" opacity=".55"/>
    <circle cx="256" cy="210" r="120" fill="none" stroke="#B99750" stroke-width="1" stroke-dasharray="3 9" opacity=".65"/>
  `,
  // 飞牌 — 单张飞牌如刀
  hollow_bell: `
    <g transform="translate(256 200) rotate(-18)">
      <rect x="-36" y="-78" width="72" height="110" rx="5" fill="#E8DFC9" stroke="#211D18" stroke-width="5"/>
      <rect x="-24" y="-64" width="48" height="82" rx="3" fill="none" stroke="#B99750" stroke-width="2"/>
      <path d="M-10 -20 L10 10 M10 -20 L-10 10" stroke="#7A2828" stroke-width="4" stroke-linecap="round"/>
    </g>
    <path d="M120 268 C170 230 220 220 256 236 C292 220 342 230 392 268"
      fill="none" stroke="#211D18" stroke-width="3" stroke-dasharray="5 8" opacity=".5"/>
    <path d="M186 120 L210 96 M326 120 L302 96" stroke="#B99750" stroke-width="4" stroke-linecap="round"/>
    <circle cx="256" cy="200" r="130" fill="none" stroke="#211D18" stroke-width=".8" stroke-dasharray="2 9" opacity=".28"/>
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
      <feTurbulence type="fractalNoise" baseFrequency=".68" numOctaves="3" seed="141" result="n"/>
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
    svg: `art/assets/svg/v0.41.0/cards/${file}`,
    png: `assets/game/v0.41.0/cards/card_skill_${name}.png`,
  });
}

fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ version: "v0.41.0", theme: "clown_sequence_8", assets: manifest }, null, 2) + "\n",
);

console.log(`Generated ${manifest.length} v0.41 clown card SVGs → ${outputDir}`);
