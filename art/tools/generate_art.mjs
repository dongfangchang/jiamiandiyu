import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, "..");
const svgDir = path.join(artDir, "assets", "svg");
const previewDir = path.join(artDir, "preview");

for (const dir of [
  path.join(svgDir, "templates"),
  path.join(svgDir, "cards"),
  path.join(svgDir, "enemies"),
  path.join(svgDir, "scenes"),
  path.join(svgDir, "icons"),
  previewDir,
]) {
  fs.mkdirSync(dir, { recursive: true });
}

const C = {
  paper: "#D8C29A",
  paperDeep: "#AF9165",
  ink: "#211D18",
  charcoal: "#3A3731",
  gold: "#B99750",
  blood: "#7A2828",
  fog: "#788079",
  bone: "#E8DFC9",
};

const commonDefs = `
  <filter id="paperGrain" x="-10%" y="-10%" width="120%" height="120%">
    <feTurbulence type="fractalNoise" baseFrequency=".72" numOctaves="4" seed="17" result="noise"/>
    <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
    <feComponentTransfer in="mono" result="faint">
      <feFuncA type="table" tableValues="0 .10"/>
    </feComponentTransfer>
    <feBlend in="SourceGraphic" in2="faint" mode="multiply"/>
  </filter>
  <radialGradient id="paperWash" cx="47%" cy="36%" r="72%">
    <stop offset="0" stop-color="#EFE1C0"/>
    <stop offset=".58" stop-color="${C.paper}"/>
    <stop offset="1" stop-color="${C.paperDeep}"/>
  </radialGradient>
  <radialGradient id="vignette" cx="50%" cy="47%" r="68%">
    <stop offset=".55" stop-color="#211D18" stop-opacity="0"/>
    <stop offset="1" stop-color="#211D18" stop-opacity=".48"/>
  </radialGradient>
  <linearGradient id="night" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#171A18"/>
    <stop offset=".55" stop-color="#303530"/>
    <stop offset="1" stop-color="#6E695A"/>
  </linearGradient>
  <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#E0C47A"/>
    <stop offset=".45" stop-color="${C.gold}"/>
    <stop offset="1" stop-color="#69532D"/>
  </linearGradient>
  <pattern id="hatch" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
    <path d="M 0 0 V 7" stroke="${C.ink}" stroke-width=".6" opacity=".13"/>
  </pattern>
  <pattern id="crosshatch" width="8" height="8" patternUnits="userSpaceOnUse">
    <path d="M0 0L8 8M8 0L0 8" stroke="${C.ink}" stroke-width=".45" opacity=".10"/>
  </pattern>
  <filter id="roughInk">
    <feTurbulence type="fractalNoise" baseFrequency=".018" numOctaves="2" seed="7" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="1.8" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
`;

function svgDoc(width, height, body, extraDefs = "") {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>${commonDefs}${extraDefs}</defs>
  ${body}
</svg>
`;
}

function paperBase(width, height) {
  return `
    <rect width="${width}" height="${height}" fill="url(#paperWash)" filter="url(#paperGrain)"/>
    <rect width="${width}" height="${height}" fill="url(#hatch)"/>
    <rect width="${width}" height="${height}" fill="url(#vignette)"/>
    <path d="M24 84 C140 70, 197 103, 293 79 S486 62, 579 91" fill="none" stroke="${C.ink}" stroke-width=".6" opacity=".14"/>
    <path d="M39 760 C151 742, 256 772, 366 749 S506 740, 574 756" fill="none" stroke="${C.ink}" stroke-width=".5" opacity=".13"/>
  `;
}

function cardFrame() {
  return `
    <rect x="13" y="13" width="574" height="814" rx="5" fill="none" stroke="${C.ink}" stroke-width="5"/>
    <rect x="23" y="23" width="554" height="794" rx="3" fill="none" stroke="${C.gold}" stroke-width="2"/>
    <rect x="31" y="31" width="538" height="778" fill="none" stroke="${C.ink}" stroke-width=".8" opacity=".65"/>
    <path d="M13 52 L52 13 M548 13 L587 52 M13 788 L52 827 M548 827 L587 788"
      fill="none" stroke="url(#brass)" stroke-width="4"/>
    <path d="M31 53 H78 M31 53 V100 M522 53 H569 M569 53 V100 M31 787 H78 M31 787 V740 M522 787 H569 M569 787 V740"
      fill="none" stroke="${C.ink}" stroke-width="1.5"/>
    <path d="M300 21 L310 31 L300 41 L290 31 Z" fill="url(#brass)" stroke="${C.ink}" stroke-width=".8"/>
    <circle cx="300" cy="819" r="5" fill="${C.blood}" stroke="${C.ink}" stroke-width="1"/>
  `;
}

function reporterArt() {
  return `
    <circle cx="300" cy="348" r="179" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".35"/>
    <circle cx="300" cy="348" r="151" fill="none" stroke="${C.gold}" stroke-width=".8" stroke-dasharray="3 8" opacity=".8"/>
    <path d="M102 495 C149 445, 173 469, 211 428 S265 371, 300 394 S355 466, 412 423 S474 444, 510 489"
      fill="none" stroke="${C.fog}" stroke-width="18" opacity=".34"/>
    <path d="M237 264 C242 228, 270 208, 301 209 C337 210, 359 233, 361 267 L346 287 H257 Z" fill="${C.ink}"/>
    <path d="M220 270 H380 L360 286 H240 Z" fill="${C.ink}"/>
    <ellipse cx="301" cy="315" rx="52" ry="66" fill="${C.charcoal}"/>
    <path d="M258 307 C269 272, 287 257, 303 258 C325 260, 342 279, 346 309 C331 296, 315 290, 297 294 C282 297, 271 306, 258 307 Z" fill="${C.paperDeep}" opacity=".5"/>
    <path d="M190 529 C199 436, 240 386, 300 383 C363 385, 407 441, 417 529 Z" fill="${C.ink}"/>
    <path d="M250 393 C267 422, 333 422, 350 393" fill="none" stroke="${C.gold}" stroke-width="2"/>
    <path d="M275 414 L323 414 L316 507 H282 Z" fill="${C.paper}"/>
    <path d="M276 422 H321 M280 445 H316 M280 468 H311" stroke="${C.ink}" stroke-width="1.4"/>
    <path d="M320 454 L382 507" stroke="${C.ink}" stroke-width="9" stroke-linecap="round"/>
    <path d="M382 507 L394 518" stroke="${C.gold}" stroke-width="4"/>
    <path d="M151 411 C179 386, 203 386, 226 414 C210 443, 179 450, 151 436 Z" fill="${C.bone}" stroke="${C.ink}" stroke-width="1.2"/>
    <ellipse cx="190" cy="415" rx="17" ry="10" fill="${C.fog}" stroke="${C.ink}"/>
    <circle cx="190" cy="415" r="4" fill="${C.ink}"/>
    <path d="M399 247 C426 268, 437 297, 428 331 C423 306, 413 290, 394 278 Z" fill="${C.blood}" opacity=".82"/>
    <path d="M127 535 H473" stroke="${C.ink}" stroke-width="1.2" opacity=".55"/>
  `;
}

function doctorArt() {
  return `
    <circle cx="300" cy="342" r="180" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".3"/>
    <path d="M93 497 C153 446, 195 472, 233 442 S307 369, 364 403 S460 457, 511 478"
      fill="none" stroke="${C.fog}" stroke-width="14" opacity=".26"/>
    <path d="M232 251 C247 217, 275 200, 306 205 C337 211, 355 235, 358 270 L337 278 H249 Z" fill="${C.ink}"/>
    <ellipse cx="301" cy="314" rx="55" ry="67" fill="${C.charcoal}"/>
    <path d="M254 306 C270 269, 291 255, 311 260 C337 268, 348 286, 349 307 C327 295, 309 293, 291 297 C274 301, 263 307, 254 306 Z" fill="${C.paperDeep}" opacity=".45"/>
    <path d="M180 529 C191 431, 240 382, 301 384 C365 386, 408 436, 421 529 Z" fill="${C.ink}"/>
    <path d="M257 388 L251 528 M345 388 L350 528" stroke="${C.gold}" stroke-width="1.5"/>
    <path d="M301 387 V528" stroke="${C.paper}" stroke-width="2" opacity=".7"/>
    <path d="M252 410 L222 459 M349 410 L382 456" stroke="${C.ink}" stroke-width="8" stroke-linecap="round"/>
    <path d="M198 468 C217 452, 238 458, 247 474 L236 493 H207 Z" fill="${C.bone}" stroke="${C.ink}"/>
    <path d="M403 470 L443 476 L441 493 L401 489 Z" fill="${C.bone}" stroke="${C.ink}"/>
    <circle cx="300" cy="347" r="52" fill="none" stroke="${C.gold}" stroke-width="1" opacity=".5"/>
    <path d="M300 295 V399 M248 347 H352" stroke="${C.ink}" stroke-width="1" opacity=".4"/>
    <path d="M119 352 C146 327, 173 331, 190 354 C171 374, 143 378, 119 352 Z" fill="${C.blood}" opacity=".8"/>
    <path d="M143 354 L126 341 L133 366 Z" fill="${C.ink}"/>
    <path d="M130 540 H471" stroke="${C.ink}" stroke-width="1" opacity=".5"/>
  `;
}

function gravediggerArt() {
  return `
    <path d="M300 168 L424 532 H176 Z" fill="${C.charcoal}" opacity=".24"/>
    <circle cx="300" cy="335" r="166" fill="none" stroke="${C.fog}" stroke-width="1.2" opacity=".6"/>
    <path d="M224 270 C233 220, 264 193, 303 197 C345 201, 369 232, 376 278 L348 342 H250 Z" fill="${C.ink}"/>
    <path d="M250 294 C260 258, 280 241, 305 242 C333 244, 349 264, 351 296 C333 282, 311 280, 290 286 C275 290, 263 295, 250 294 Z" fill="${C.paperDeep}" opacity=".34"/>
    <path d="M171 536 C185 444, 229 382, 301 376 C376 382, 416 447, 431 536 Z" fill="${C.ink}"/>
    <path d="M211 448 C252 421, 350 421, 392 450 L371 536 H231 Z" fill="${C.charcoal}"/>
    <path d="M300 450 V535" stroke="${C.paperDeep}" stroke-width="1" opacity=".65"/>
    <path d="M382 237 L421 548" stroke="${C.ink}" stroke-width="10" stroke-linecap="round"/>
    <path d="M360 264 C386 242, 410 248, 421 271 L412 299 C395 310, 374 301, 366 283 Z" fill="${C.paperDeep}" stroke="${C.ink}" stroke-width="2"/>
    <path d="M377 280 L438 524" stroke="${C.gold}" stroke-width="2" opacity=".6"/>
    <path d="M135 504 C149 478, 171 470, 190 485 L183 527 H142 Z" fill="${C.blood}" opacity=".78"/>
    <path d="M146 527 V552 H182 V527" fill="${C.ink}"/>
    <circle cx="163" cy="502" r="25" fill="${C.bone}" opacity=".65"/>
    <path d="M163 477 V527 M138 502 H188" stroke="${C.ink}" stroke-width=".8" opacity=".4"/>
    <path d="M83 548 H219 M388 548 H516" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
    <path d="M99 548 V466 M108 482 H90 M203 548 V478 M212 496 H194" stroke="${C.ink}" stroke-width="2"/>
  `;
}

function eyeArt() {
  return `
    <circle cx="300" cy="336" r="169" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="2 8"/>
    <path d="M300 183 L453 470 H147 Z" fill="none" stroke="${C.ink}" stroke-width="5"/>
    <path d="M300 213 L420 443 H180 Z" fill="none" stroke="${C.gold}" stroke-width="1.5"/>
    <path d="M171 335 C221 264, 379 264, 429 335 C379 406, 221 406, 171 335 Z" fill="${C.bone}" stroke="${C.ink}" stroke-width="3"/>
    <circle cx="300" cy="335" r="67" fill="${C.fog}" stroke="${C.ink}" stroke-width="3"/>
    <circle cx="300" cy="335" r="33" fill="${C.ink}"/>
    <circle cx="300" cy="335" r="10" fill="${C.bone}"/>
    <path d="M300 234 V281 M300 389 V438 M200 335 H247 M353 335 H400" stroke="${C.ink}" stroke-width="2"/>
    <path d="M245 281 C270 293, 330 293, 355 281 M245 389 C270 377, 330 377, 355 389" fill="none" stroke="${C.ink}" stroke-width="1.4"/>
    <path d="M220 439 L380 439 M234 454 L366 454 M251 469 L349 469" stroke="${C.blood}" stroke-width="2" opacity=".72"/>
    <g fill="${C.ink}">
      <circle cx="300" cy="236" r="4"/><circle cx="271" cy="246" r="3"/><circle cx="329" cy="246" r="3"/>
      <circle cx="238" cy="269" r="2.5"/><circle cx="362" cy="269" r="2.5"/><circle cx="218" cy="301" r="2"/>
      <circle cx="382" cy="301" r="2"/><circle cx="207" cy="335" r="2"/><circle cx="393" cy="335" r="2"/>
    </g>
    <path d="M134 490 C212 473, 388 473, 466 490" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".55"/>
  `;
}

function maskArt() {
  return `
    <circle cx="300" cy="338" r="170" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".3"/>
    <path d="M300 177 C238 177, 195 231, 201 314 C207 390, 248 438, 300 471 C352 438, 393 390, 399 314 C405 231, 362 177, 300 177 Z"
      fill="${C.bone}" stroke="${C.ink}" stroke-width="3"/>
    <path d="M230 281 C249 262, 272 265, 289 283 C267 299, 246 300, 230 281 Z" fill="${C.ink}"/>
    <path d="M311 283 C330 265, 352 265, 370 281 C350 300, 329 299, 311 283 Z" fill="${C.ink}"/>
    <path d="M281 352 C291 359, 309 359, 319 352" fill="none" stroke="${C.ink}" stroke-width="2"/>
    <path d="M300 178 C311 220, 288 245, 309 278 C326 309, 285 342, 301 378 C319 411, 289 441, 300 469"
      fill="none" stroke="${C.blood}" stroke-width="2.8"/>
    <path d="M321 222 L343 242 L331 263 L357 278 L336 302 L358 328 L329 340"
      fill="none" stroke="${C.ink}" stroke-width="1.2"/>
    <path d="M223 313 C161 304, 124 341, 113 404 C148 389, 169 407, 174 447"
      fill="none" stroke="${C.charcoal}" stroke-width="10" stroke-linecap="round"/>
    <path d="M377 313 C439 304, 476 341, 487 404 C452 389, 431 407, 426 447"
      fill="none" stroke="${C.charcoal}" stroke-width="10" stroke-linecap="round"/>
    <path d="M255 476 C273 495, 289 505, 300 526 C312 505, 328 495, 345 476"
      fill="none" stroke="${C.charcoal}" stroke-width="5"/>
    <circle cx="181" cy="391" r="16" fill="${C.blood}" opacity=".75"/>
    <circle cx="420" cy="391" r="16" fill="${C.blood}" opacity=".75"/>
    <path d="M122 506 C202 490, 399 490, 478 506" stroke="${C.ink}" stroke-width="1" opacity=".5"/>
  `;
}

const cardSpecs = [
  {
    file: "cards/card-identity-reporter.svg",
    category: "人格牌 · IDENTITY",
    number: "I / 01",
    title: "记者",
    subtitle: "以记录换取真相，以沉默换取明天。",
    art: reporterArt(),
    flavor: "“报纸不会害怕。害怕的是报纸上出现你的名字。”",
    effect: "白昼：降低 1 点注视。夜间首张灵界回响费用 -1。",
    effectLines: ["白昼：降低 1 点注视。", "夜间首张灵界回响费用 -1。"],
    stats: [["调查", "2"], ["灵性", "1"], ["风险", "2"]],
    accent: C.gold,
  },
  {
    file: "cards/card-identity-doctor.svg",
    category: "人格牌 · IDENTITY",
    number: "I / 02",
    title: "医生",
    subtitle: "你治疗伤口，也替伤口保守秘密。",
    art: doctorArt(),
    flavor: "“没有哪种污染真的痊愈，它们只是学会了安静。”",
    effect: "白昼：降低 2 点污染。首次使用封印物不增加注视。",
    effectLines: ["白昼：降低 2 点污染。", "首次使用封印物不增加注视。"],
    stats: [["治疗", "2"], ["灵性", "2"], ["风险", "1"]],
    accent: C.fog,
  },
  {
    file: "cards/card-identity-gravedigger.svg",
    category: "人格牌 · IDENTITY",
    number: "I / 03",
    title: "守墓人",
    subtitle: "你替死者守住名字，也替自己守住秘密。",
    art: gravediggerArt(),
    flavor: "“墓碑从不解答问题，它们只负责让问题安静。”",
    effect: "白昼：获得 2 枚灵性残渣。首名倒下的回响牌返回手牌。",
    effectLines: ["白昼：获得 2 枚灵性残渣。", "首名倒下的回响牌返回手牌。"],
    stats: [["收集", "2"], ["复苏", "1"], ["风险", "2"]],
    accent: C.blood,
  },
  {
    file: "cards/card-artifact-watchers-eye.svg",
    category: "封印物 · SEALED RELIC",
    number: "II / 07",
    title: "窥视者之眼",
    subtitle: "它看见的下一刻，也看见正在看它的人。",
    art: eyeArt(),
    flavor: "“每多用一次，它就离你的眼眶更近一些。”",
    effect: "查看敌人下一步行动。每次使用，注视 +1。",
    effectLines: ["查看敌人下一步行动。", "每次使用，注视 +1。"],
    stats: [["洞察", "3"], ["灵性", "1"], ["注视", "+1"]],
    accent: C.blood,
  },
  {
    file: "cards/card-artifact-faceless-mask.svg",
    category: "封印物 · SEALED RELIC",
    number: "II / 13",
    title: "无面遗嘱",
    subtitle: "戴上它的人，会短暂忘记自己原本是谁。",
    art: maskArt(),
    flavor: "“遗嘱没有继承人。它只是希望有人继续扮演。”",
    effect: "复制上一张人格牌的能力。使用后污染 +2。",
    effectLines: ["复制上一张人格牌的能力。", "使用后污染 +2。"],
    stats: [["复制", "1"], ["代价", "2"], ["污染", "+2"]],
    accent: C.blood,
  },
];

function makeCard(spec) {
  const stats = spec.stats.map(([label, value], index) => {
    const x = 112 + index * 188;
    return `
      <circle cx="${x}" cy="790" r="38" fill="${C.ink}" stroke="${spec.accent}" stroke-width="1.2"/>
      <text x="${x}" y="788" text-anchor="middle" fill="${C.bone}" font-family="'Palatino Linotype','Noto Serif SC',serif" font-size="20">${value}</text>
      <text x="${x}" y="808" text-anchor="middle" fill="${C.bone}" font-family="'Noto Serif SC',serif" font-size="9" letter-spacing="1">${label}</text>
    `;
  }).join("");

  return svgDoc(600, 840, `
    ${paperBase(600, 840)}
    <rect x="44" y="164" width="512" height="390" rx="2" fill="${C.charcoal}" opacity=".08"/>
    <g clip-path="url(#artClip)">${spec.art}</g>
    <rect x="44" y="164" width="512" height="390" rx="2" fill="none" stroke="${C.ink}" stroke-width="2"/>
    <path d="M52 178 H83 M52 178 V209 M548 178 H517 M548 178 V209" fill="none" stroke="${spec.accent}" stroke-width="2"/>
    <line x1="44" y1="569" x2="556" y2="569" stroke="${C.ink}" stroke-width="1"/>
    <text x="50" y="68" fill="${C.ink}" font-family="'Noto Serif SC',serif" font-size="13" letter-spacing="3">${spec.category}</text>
    <text x="550" y="68" text-anchor="end" fill="${C.ink}" font-family="'Palatino Linotype',serif" font-size="13" letter-spacing="2">${spec.number}</text>
    <text x="50" y="119" fill="${C.ink}" font-family="'Noto Serif SC',serif" font-size="38" font-weight="700" letter-spacing="4">${spec.title}</text>
    <text x="51" y="145" fill="${C.charcoal}" font-family="'Noto Serif SC',serif" font-size="12" letter-spacing="1">${spec.subtitle}</text>
    <rect x="44" y="589" width="512" height="116" fill="${C.bone}" opacity=".22" stroke="${C.ink}" stroke-width=".8"/>
    <text x="60" y="615" fill="${C.blood}" font-family="'Noto Serif SC',serif" font-size="12" font-weight="700" letter-spacing="3">效果 / EFFECT</text>
    <text x="60" y="647" fill="${C.ink}" font-family="'Noto Serif SC',serif" font-size="17">
      <tspan x="60" dy="0">${spec.effectLines[0]}</tspan>
      <tspan x="60" dy="27">${spec.effectLines[1]}</tspan>
    </text>
    <text x="60" y="723" fill="${C.charcoal}" font-family="'Noto Serif SC',serif" font-size="12" font-style="italic">${spec.flavor}</text>
    <path d="M44 747 H556" stroke="${C.ink}" stroke-width=".8" opacity=".5"/>
    ${stats}
    ${cardFrame()}
  `, `<clipPath id="artClip"><rect x="44" y="164" width="512" height="390" rx="2"/></clipPath>`);
}

for (const spec of cardSpecs) {
  fs.writeFileSync(path.join(svgDir, spec.file), makeCard(spec), "utf8");
}

fs.writeFileSync(
  path.join(svgDir, "templates", "card-frame.svg"),
  makeCard({
    ...cardSpecs[0],
    title: "身份牌",
    subtitle: "卡牌版式用于检查层级、留白和文字安全区。",
    category: "版式模板 · CARD FRAME",
    number: "00 / 00",
    flavor: "“一张牌首先必须像一页不能被公开的档案。”",
    effect: "标题和安全区保持固定；插画与文字内容独立替换。",
    effectLines: ["标题和安全区保持固定；", "插画与文字内容独立替换。"],
  }),
  "utf8",
);

const enemySvg = svgDoc(900, 900, `
  <rect width="900" height="900" fill="url(#night)" filter="url(#paperGrain)"/>
  <rect width="900" height="900" fill="url(#crosshatch)" opacity=".45"/>
  <circle cx="470" cy="392" r="274" fill="none" stroke="${C.fog}" stroke-width="1.5" opacity=".45"/>
  <path d="M0 690 C130 622, 208 672, 318 624 S548 628, 684 652 S818 622, 900 666 V900 H0 Z" fill="#171A18" opacity=".72"/>
  <path d="M0 740 C153 702, 253 746, 390 707 S650 714, 900 730 V900 H0 Z" fill="${C.fog}" opacity=".12"/>
  <path d="M397 216 C435 190, 499 211, 510 258 L489 327 H416 Z" fill="#090B0A"/>
  <path d="M370 260 H550 L514 287 H405 Z" fill="#090B0A"/>
  <path d="M336 690 C346 511, 403 382, 457 370 C519 385, 580 507, 601 690 Z" fill="#090B0A"/>
  <path d="M395 411 C431 373, 490 379, 525 422 L508 522 H411 Z" fill="#090B0A"/>
  <path d="M392 326 C430 302, 481 306, 509 339 C479 360, 433 368, 392 345 Z" fill="${C.paperDeep}" opacity=".28"/>
  <g fill="${C.bone}" stroke="${C.blood}" stroke-width="2">
    <ellipse cx="429" cy="335" rx="10" ry="6"/><ellipse cx="471" cy="327" rx="8" ry="5"/>
    <ellipse cx="501" cy="343" rx="7" ry="4"/><ellipse cx="447" cy="359" rx="6" ry="3.5"/>
    <ellipse cx="486" cy="365" rx="9" ry="4"/>
  </g>
  <path d="M601 516 C673 478, 717 430, 727 350" fill="none" stroke="${C.ink}" stroke-width="12"/>
  <path d="M727 350 V780" stroke="${C.ink}" stroke-width="10"/>
  <circle cx="727" cy="334" r="47" fill="${C.gold}" opacity=".18"/>
  <circle cx="727" cy="334" r="22" fill="${C.bone}" filter="url(#roughInk)"/>
  <path d="M727 182 V246 M727 422 V486 M575 334 H639 M815 334 H879" stroke="${C.bone}" stroke-width="2" opacity=".3"/>
  <path d="M160 738 C282 703, 355 748, 450 718 S654 724, 789 744" fill="none" stroke="${C.fog}" stroke-width="26" opacity=".16"/>
  <rect x="38" y="36" width="824" height="828" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".65"/>
  <text x="75" y="91" fill="${C.bone}" font-family="'Palatino Linotype',serif" font-size="15" letter-spacing="5">ANOMALY // PURSUER</text>
  <text x="825" y="91" text-anchor="end" fill="${C.blood}" font-family="'Palatino Linotype',serif" font-size="15" letter-spacing="3">GAZE II</text>
  <text x="75" y="797" fill="${C.bone}" font-family="'Noto Serif SC',serif" font-size="46" font-weight="700" letter-spacing="6">提灯追猎者</text>
  <text x="78" y="830" fill="${C.paperDeep}" font-family="'Noto Serif SC',serif" font-size="14" letter-spacing="2">它循着被注视者的脚步出现。</text>
`);
fs.writeFileSync(path.join(svgDir, "enemies", "enemy-lantern-pursuer.svg"), enemySvg, "utf8");

const ritualSvg = svgDoc(1600, 900, `
  <rect width="1600" height="900" fill="url(#night)" filter="url(#paperGrain)"/>
  <rect width="1600" height="900" fill="url(#crosshatch)" opacity=".32"/>
  <path d="M0 730 C220 650, 392 702, 610 634 S1000 663, 1230 620 S1460 654, 1600 610 V900 H0 Z" fill="#111412"/>
  <circle cx="800" cy="472" r="322" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".5"/>
  <circle cx="800" cy="472" r="265" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="4 12" opacity=".65"/>
  <circle cx="800" cy="472" r="154" fill="none" stroke="${C.blood}" stroke-width="1.5" opacity=".55"/>
  <path d="M800 150 V794 M478 472 H1122 M572 244 L1028 700 M1028 244 L572 700"
    stroke="${C.gold}" stroke-width=".9" opacity=".24"/>
  <g transform="translate(800 472)">
    <path d="M-106 -30 C-67 -92, 67 -92, 106 -30 C67 34, -67 34, -106 -30 Z" fill="${C.bone}" opacity=".16" stroke="${C.bone}" stroke-width="2"/>
    <circle r="36" fill="${C.fog}" opacity=".35" stroke="${C.bone}"/>
    <circle r="15" fill="${C.blood}"/>
  </g>
  <g transform="translate(0 0)">
    <g transform="translate(540 490) rotate(-8)">
      <rect x="-66" y="-98" width="132" height="196" fill="${C.paper}" stroke="${C.gold}" stroke-width="2"/>
      <path d="M-44 -60 H44 M-44 -35 H44 M-44 -10 H29 M-44 54 H36" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
      <circle cy="20" r="24" fill="none" stroke="${C.ink}" stroke-width="2"/>
    </g>
    <g transform="translate(800 438) rotate(3)">
      <rect x="-76" y="-112" width="152" height="224" fill="${C.paper}" stroke="${C.gold}" stroke-width="3"/>
      <path d="M-51 -69 H51 M-51 -42 H51" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
      <path d="M0 -16 L16 12 L0 40 L-16 12 Z" fill="${C.blood}" opacity=".75"/>
      <path d="M-51 70 H51" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
    </g>
    <g transform="translate(1080 500) rotate(12)">
      <rect x="-62" y="-94" width="124" height="188" fill="${C.paper}" stroke="${C.gold}" stroke-width="2"/>
      <path d="M-39 -58 H39 M-39 -32 H39 M-39 -6 H25 M-39 56 H31" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
      <path d="M0 15 L29 32 L0 49 L-29 32 Z" fill="none" stroke="${C.ink}" stroke-width="2"/>
    </g>
  </g>
  <g fill="${C.gold}">
    <circle cx="582" cy="283" r="7"/><circle cx="1018" cy="283" r="7"/>
    <circle cx="582" cy="661" r="7"/><circle cx="1018" cy="661" r="7"/>
    <circle cx="800" cy="150" r="7"/><circle cx="800" cy="794" r="7"/>
  </g>
  <text x="92" y="95" fill="${C.bone}" font-family="'Palatino Linotype',serif" font-size="16" letter-spacing="6">PATHWAY ADVANCEMENT // RITE 01</text>
  <text x="92" y="158" fill="${C.bone}" font-family="'Noto Serif SC',serif" font-size="54" font-weight="700" letter-spacing="8">晋升试炼</text>
  <text x="94" y="192" fill="${C.paperDeep}" font-family="'Noto Serif SC',serif" font-size="16" letter-spacing="3">选择正确的人格、顺序与代价。</text>
  <text x="1508" y="848" text-anchor="end" fill="${C.gold}" font-family="'Palatino Linotype',serif" font-size="14" letter-spacing="4">THREE CHOICES. ONE DOOR.</text>
  <rect x="34" y="34" width="1532" height="832" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".55"/>
`);
fs.writeFileSync(path.join(svgDir, "scenes", "ritual-ascension.svg"), ritualSvg, "utf8");

const titleSvg = svgDoc(1600, 900, `
  <rect width="1600" height="900" fill="url(#night)" filter="url(#paperGrain)"/>
  <rect width="1600" height="900" fill="url(#hatch)" opacity=".11"/>
  <path d="M0 660 L0 564 L82 564 L82 522 L130 522 L130 589 L197 589 L197 502 L245 502 L245 569 L320 569 L320 527 L370 527 L370 608 L455 608 L455 551 L519 551 L519 620 L600 620 L600 476 L641 476 L641 594 L706 594 L706 538 L770 538 L770 604 L840 604 L840 492 L885 492 L885 575 L944 575 L944 510 L1004 510 L1004 611 L1074 611 L1074 553 L1130 553 L1130 620 L1213 620 L1213 518 L1268 518 L1268 583 L1322 583 L1322 540 L1380 540 L1380 603 L1471 603 L1471 548 L1520 548 L1520 622 L1600 622 V900 H0 Z" fill="#111412"/>
  <path d="M0 716 C199 642, 333 720, 503 674 S844 644, 1004 692 S1306 652, 1600 697 V900 H0 Z" fill="${C.fog}" opacity=".13"/>
  <path d="M0 776 C187 730, 343 784, 535 747 S892 736, 1110 781 S1408 739, 1600 754 V900 H0 Z" fill="#090B0A" opacity=".76"/>
  <g transform="translate(800 443)">
    <g transform="translate(-176 14) rotate(-16)">
      <rect x="-111" y="-165" width="222" height="330" rx="3" fill="${C.paperDeep}" stroke="${C.gold}" stroke-width="3" opacity=".74"/>
      <circle cy="-37" r="58" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".5"/>
    </g>
    <g transform="translate(176 17) rotate(15)">
      <rect x="-111" y="-165" width="222" height="330" rx="3" fill="${C.paperDeep}" stroke="${C.gold}" stroke-width="3" opacity=".74"/>
      <path d="M-58 8 L0 -56 L58 8 L0 72 Z" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".5"/>
    </g>
    <g>
      <rect x="-124" y="-186" width="248" height="372" rx="4" fill="${C.paper}" stroke="${C.ink}" stroke-width="5"/>
      <rect x="-111" y="-173" width="222" height="346" fill="none" stroke="${C.gold}" stroke-width="2"/>
      <path d="M0 -118 C-78 -118, -105 -35, -91 34 C-76 109, -29 143, 0 158 C29 143, 76 109, 91 34 C105 -35, 78 -118, 0 -118 Z"
        fill="${C.bone}" stroke="${C.ink}" stroke-width="3"/>
      <path d="M-64 -28 C-37 -49, -16 -42, 0 -20 C-24 -3, -49 -5, -64 -28 Z" fill="${C.ink}"/>
      <path d="M64 -28 C37 -49, 16 -42, 0 -20 C24 -3, 49 -5, 64 -28 Z" fill="${C.ink}"/>
      <path d="M0 -117 C18 -56, -12 -27, 10 14 C24 47, -19 87, 0 157" fill="none" stroke="${C.blood}" stroke-width="3"/>
      <path d="M0 52 C14 64, 18 85, 0 98 C-18 85, -14 64, 0 52 Z" fill="${C.blood}" opacity=".75"/>
    </g>
    <g fill="${C.gold}">
      <circle cx="-214" cy="-129" r="5"/><circle cx="214" cy="-129" r="5"/>
      <path d="M-256 166 H-170 M170 166 H256" stroke="${C.gold}" stroke-width="2"/>
    </g>
  </g>
  <text x="800" y="196" text-anchor="middle" fill="${C.bone}" font-family="'Noto Serif SC',serif" font-size="78" font-weight="700" letter-spacing="16">假面低语</text>
  <text x="800" y="242" text-anchor="middle" fill="${C.gold}" font-family="'Palatino Linotype',serif" font-size="17" letter-spacing="8">WHISPERS BENEATH THE MASK</text>
  <path d="M555 273 H689 M911 273 H1045" stroke="${C.gold}" stroke-width="1"/>
  <path d="M800 258 L811 273 L800 288 L789 273 Z" fill="${C.blood}"/>
  <text x="800" y="824" text-anchor="middle" fill="${C.paperDeep}" font-family="'Noto Serif SC',serif" font-size="16" letter-spacing="4">白昼扮演凡人 · 黑夜偿还代价</text>
  <text x="1528" y="852" text-anchor="end" fill="${C.fog}" font-family="'Palatino Linotype',serif" font-size="11" letter-spacing="3">PRIVATE OCCULT PROTOTYPE // 00</text>
  <rect x="34" y="34" width="1532" height="832" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".45"/>
`);
fs.writeFileSync(path.join(svgDir, "scenes", "title-screen.svg"), titleSvg, "utf8");

const iconNames = [
  ["灵性", "spirit"], ["污染", "taint"], ["注视", "gaze"], ["生命", "life"],
  ["护盾", "shield"], ["攻击", "attack"], ["抽牌", "draw"], ["封印物", "relic"],
  ["人格", "persona"], ["仪式", "rite"], ["晋升", "advance"], ["疯狂", "madness"],
];

const iconBodies = [
  `<path d="M60 20 C39 42, 34 61, 43 77 C50 91, 70 100, 84 82 C95 66, 84 43, 60 20 Z" fill="none" stroke="currentColor" stroke-width="4"/>`,
  `<circle cx="60" cy="60" r="27" fill="none" stroke="currentColor" stroke-width="4"/><path d="M42 60 C52 40, 69 38, 80 58 C69 79, 52 82, 42 60Z" fill="currentColor" opacity=".3"/>`,
  `<path d="M60 22 C78 36, 91 52, 88 69 C85 88, 72 100, 60 102 C48 100, 35 88, 32 69 C29 52, 42 36, 60 22Z" fill="none" stroke="currentColor" stroke-width="4"/><circle cx="60" cy="64" r="12" fill="currentColor"/>`,
  `<path d="M60 86 C37 72, 31 53, 39 37 C47 22, 58 28, 60 43 C62 28, 73 22, 81 37 C89 53, 83 72, 60 86Z" fill="none" stroke="currentColor" stroke-width="4"/>`,
  `<path d="M60 20 L91 33 V61 C91 82, 77 94, 60 101 C43 94, 29 82, 29 61 V33Z" fill="none" stroke="currentColor" stroke-width="4"/><path d="M43 60 H77" stroke="currentColor" stroke-width="4"/>`,
  `<path d="M24 94 L87 31 M72 23 L97 48 M50 66 L54 70" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round"/>`,
  `<rect x="31" y="19" width="45" height="74" rx="3" fill="none" stroke="currentColor" stroke-width="4" transform="rotate(9 54 56)"/><path d="M73 34 L101 62" stroke="currentColor" stroke-width="4"/>`,
  `<path d="M60 20 L93 39 L93 75 L60 100 L27 75 L27 39Z" fill="none" stroke="currentColor" stroke-width="4"/><circle cx="60" cy="59" r="14" fill="none" stroke="currentColor" stroke-width="4"/>`,
  `<circle cx="60" cy="50" r="21" fill="none" stroke="currentColor" stroke-width="4"/><path d="M26 100 C29 76, 42 68, 60 68 C78 68, 91 76, 94 100Z" fill="none" stroke="currentColor" stroke-width="4"/>`,
  `<circle cx="60" cy="61" r="37" fill="none" stroke="currentColor" stroke-width="4"/><path d="M60 24 L74 55 L60 98 L46 55Z" fill="none" stroke="currentColor" stroke-width="4"/><circle cx="60" cy="55" r="6" fill="currentColor"/>`,
  `<path d="M27 90 L48 68 L60 77 L90 29" fill="none" stroke="currentColor" stroke-width="5"/><path d="M76 29 H90 V43" fill="none" stroke="currentColor" stroke-width="5"/>`,
  `<path d="M30 79 C17 63, 30 39, 48 50 C45 24, 78 17, 80 45 C103 42, 109 70, 88 81 C96 98, 70 105, 60 90 C45 105, 20 98, 30 79Z" fill="none" stroke="currentColor" stroke-width="4"/>`,
];

const iconCells = iconNames.map(([label], index) => {
  const col = index % 6;
  const row = Math.floor(index / 6);
  const x = 78 + col * 190;
  const y = 180 + row * 300;
  return `
    <g transform="translate(${x} ${y})" color="${C.ink}">
      <circle cx="60" cy="60" r="54" fill="${C.paper}" stroke="${C.gold}" stroke-width="1.5"/>
      ${iconBodies[index]}
      <text x="60" y="153" text-anchor="middle" fill="${C.bone}" font-family="'Noto Serif SC',serif" font-size="18" letter-spacing="3">${label}</text>
    </g>
  `;
}).join("");

const statusSheet = svgDoc(1200, 800, `
  <rect width="1200" height="800" fill="${C.charcoal}" filter="url(#paperGrain)"/>
  <rect width="1200" height="800" fill="url(#crosshatch)" opacity=".22"/>
  <text x="72" y="86" fill="${C.bone}" font-family="'Noto Serif SC',serif" font-size="34" font-weight="700" letter-spacing="4">状态与资源图标</text>
  <text x="74" y="120" fill="${C.gold}" font-family="'Palatino Linotype',serif" font-size="14" letter-spacing="5">STATUS ICON SHEET // VECTOR SOURCE</text>
  ${iconCells}
  <text x="1128" y="748" text-anchor="end" fill="${C.paperDeep}" font-family="'Noto Serif SC',serif" font-size="12">图标为项目内原创几何占位，可在 Godot 中单独着色。</text>
  <rect x="34" y="34" width="1132" height="732" fill="none" stroke="${C.gold}" stroke-width="1" opacity=".5"/>
`);
fs.writeFileSync(path.join(svgDir, "icons", "status-sheet.svg"), statusSheet, "utf8");

const showcase = [
  ["title-screen.svg", "标题画面", "16:9 · 1600 x 900"],
  ["cards/card-identity-reporter.svg", "人格牌：记者", "2:3 · 600 x 840"],
  ["cards/card-identity-doctor.svg", "人格牌：医生", "2:3 · 600 x 840"],
  ["cards/card-identity-gravedigger.svg", "人格牌：守墓人", "2:3 · 600 x 840"],
  ["cards/card-artifact-watchers-eye.svg", "封印物：窥视者之眼", "2:3 · 600 x 840"],
  ["cards/card-artifact-faceless-mask.svg", "封印物：无面遗嘱", "2:3 · 600 x 840"],
  ["enemies/enemy-lantern-pursuer.svg", "敌人：提灯追猎者", "1:1 · 900 x 900"],
  ["scenes/ritual-ascension.svg", "晋升试炼", "16:9 · 1600 x 900"],
  ["icons/status-sheet.svg", "状态图标", "3:2 · 1200 x 800"],
];

const cardsHtml = showcase.map(([file, title, spec], index) => `
  <figure class="${index === 0 || file.includes('scenes/ritual') || file.includes('icons/') ? 'wide' : ''}">
    <img src="../assets/svg/${file}" alt="${title}">
    <figcaption><strong>${title}</strong><span>${spec}</span></figcaption>
  </figure>
`).join("");

const contactHtml = `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>假面低语 · 美术样张</title>
  <style>
    :root { color-scheme: dark; --ink:#171613; --paper:#d8c29a; --gold:#b99750; --blood:#7a2828; }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--ink); color: #e8dfc9; font-family: "Noto Serif SC", "Songti SC", Georgia, serif; }
    header { padding: 64px 7vw 34px; border-bottom: 1px solid #6b5934; }
    h1 { margin: 0; font-size: clamp(36px, 6vw, 82px); letter-spacing: .18em; font-weight: 700; }
    header p { margin: 18px 0 0; color: var(--gold); letter-spacing: .2em; }
    main { columns: 3 280px; column-gap: 22px; padding: 32px 4vw 80px; }
    figure { margin: 0 0 24px; break-inside: avoid; border: 1px solid #4d432f; background: #211f1b; }
    figure.wide { column-span: all; }
    img { display: block; width: 100%; height: auto; }
    figcaption { display: flex; justify-content: space-between; gap: 16px; padding: 13px 15px; color: #bfb393; font-size: 13px; }
    figcaption strong { color: #e8dfc9; font-weight: 600; }
    footer { padding: 0 7vw 50px; color: #746b59; font-size: 12px; }
  </style>
</head>
<body>
  <header>
    <h1>假面低语</h1>
    <p>PRIVATE OCCULT CARD PROTOTYPE / ART DIRECTION 01</p>
  </header>
  <main>${cardsHtml}</main>
  <footer>程序化 SVG 原型资产。正式插画可沿用同一卡框和文字安全区替换。</footer>
</body>
</html>`;

fs.writeFileSync(path.join(previewDir, "contact-sheet.html"), contactHtml, "utf8");

console.log(`Generated ${cardSpecs.length + 5} SVG assets under ${svgDir}`);
console.log(`Preview: ${path.join(previewDir, "contact-sheet.html")}`);

