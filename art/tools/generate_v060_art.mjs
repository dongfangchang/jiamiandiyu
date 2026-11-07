import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, "..");
const version = "v0.6.0";
const svgRoot = path.join(artDir, "assets", "svg", version);
const exportRoot = path.join(artDir, "exports", version);
const previewDir = path.join(artDir, "preview", version);

for (const folder of [
  path.join(svgRoot, "scenes"),
  path.join(svgRoot, "icons"),
  path.join(exportRoot, "scenes"),
  path.join(exportRoot, "icons"),
  previewDir,
]) {
  fs.mkdirSync(folder, { recursive: true });
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
  night: "#10140F",
};

const assets = [];

function svgDoc(width, height, body, extraDefs = "") {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <radialGradient id="paperWash" cx="42%" cy="34%" r="76%">
      <stop offset="0" stop-color="#F1E4C8"/>
      <stop offset=".58" stop-color="${C.paper}"/>
      <stop offset="1" stop-color="${C.paperDeep}"/>
    </radialGradient>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#090D09"/>
      <stop offset=".52" stop-color="#293029"/>
      <stop offset="1" stop-color="#070A07"/>
    </linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E8D091"/>
      <stop offset=".45" stop-color="${C.gold}"/>
      <stop offset="1" stop-color="#5D4726"/>
    </linearGradient>
    <pattern id="hatch" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(28)">
      <path d="M0 0V9" stroke="${C.ink}" stroke-width=".7" opacity=".13"/>
    </pattern>
    <pattern id="crosshatch" width="11" height="11" patternUnits="userSpaceOnUse">
      <path d="M0 0L11 11M11 0L0 11" stroke="${C.bone}" stroke-width=".45" opacity=".055"/>
    </pattern>
    <filter id="grain" x="-8%" y="-8%" width="116%" height="116%">
      <feTurbulence type="fractalNoise" baseFrequency=".58" numOctaves="3" seed="61" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
      <feComponentTransfer in="mono" result="faint">
        <feFuncA type="table" tableValues="0 .09"/>
      </feComponentTransfer>
      <feBlend in="SourceGraphic" in2="faint" mode="multiply"/>
    </filter>
    ${extraDefs}
  </defs>
  ${body}
</svg>
`;
}

function frame(width, height) {
  return `<rect x="30" y="30" width="${width - 60}" height="${height - 60}" fill="none" stroke="${C.gold}" stroke-width="1.6" opacity=".52"/>
    <path d="M30 70H74M30 70V30M${width - 30} 70H${width - 74}M${width - 30} 70V30
      M30 ${height - 70}H74M30 ${height - 70}V${height - 30}
      M${width - 30} ${height - 70}H${width - 74}M${width - 30} ${height - 70}V${height - 30}"
      fill="none" stroke="${C.gold}" stroke-width="3" opacity=".62"/>`;
}

function challengeBackground() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#crosshatch)"/>
    <path d="M0 714 C214 653 359 721 558 672 S909 671 1119 706 S1429 663 1600 687 V900H0Z" fill="#070A07"/>
    <path d="M0 792 C218 744 391 807 610 765 S980 746 1189 783 S1455 744 1600 770 V900H0Z" fill="${C.fog}" opacity=".08"/>
    <g transform="translate(800 316)" opacity=".58">
      <circle r="174" fill="none" stroke="${C.gold}" stroke-width="2"/>
      <circle r="132" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="5 13"/>
      <path d="M0-164V164M-164 0H164M-116-116L116 116M116-116L-116 116"
        stroke="${C.gold}" stroke-width="1" opacity=".34"/>
      <path d="M0-108 C-76-108-102-42-91 26 C-79 97-31 129 0 149 C31 129 79 97 91 26 C102-42 76-108 0-108Z"
        fill="${C.bone}" opacity=".08" stroke="${C.bone}" stroke-width="2"/>
      <path d="M-61-23C-36-43-15-38 0-16C-23 0-45-2-61-23Z" fill="${C.ink}"/>
      <path d="M61-23C36-43 15-38 0-16C23 0 45-2 61-23Z" fill="${C.ink}"/>
      <path d="M0-108C14-54-12-23 9 18C24 49-18 87 0 149" fill="none" stroke="${C.blood}" stroke-width="3"/>
    </g>
    <g stroke="${C.bone}" stroke-width="1.2" opacity=".18" fill="none">
      <path d="M92 142L312 71L444 177L332 336Z"/>
      <path d="M1150 93L1361 71L1470 203L1322 350Z"/>
      <path d="M78 574L232 515L276 688L112 728Z"/>
      <path d="M1328 536L1488 501L1488 686L1348 723Z"/>
    </g>
    <g fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2">
      <rect x="250" y="571" width="300" height="166" rx="7"/>
      <rect x="650" y="571" width="300" height="166" rx="7"/>
      <rect x="1050" y="571" width="300" height="166" rx="7"/>
    </g>
    <g fill="none" stroke="${C.fog}" stroke-width="1.4" opacity=".45">
      <circle cx="400" cy="654" r="42"/>
      <path d="M800 612V696M762 654H838"/>
      <path d="M1162 630L1200 692H1124Z"/>
    </g>
    <path d="M199 789H1401" stroke="${C.gold}" stroke-width="1.3" opacity=".36"/>
    ${frame(1600, 900)}
  `);
}

function challengeResultBackground() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#hatch)" opacity=".12"/>
    <path d="M0 710 C186 646 352 727 536 678 S847 657 1034 710 S1388 664 1600 692 V900H0Z" fill="#080B08"/>
    <g fill="${C.fog}" opacity=".05">
      <path d="M99 117L352 51L472 233L245 351Z"/>
      <path d="M1028 72L1344 104L1398 313L1138 377Z"/>
      <path d="M145 563L357 498L441 657L245 724Z"/>
      <path d="M1184 466L1460 505L1426 701L1206 687Z"/>
    </g>
    <g fill="none" stroke="${C.gold}" opacity=".35">
      <path d="M99 117L352 51L472 233L245 351Z"/>
      <path d="M1028 72L1344 104L1398 313L1138 377Z"/>
      <path d="M145 563L357 498L441 657L245 724Z"/>
      <path d="M1184 466L1460 505L1426 701L1206 687Z"/>
    </g>
    <circle cx="800" cy="448" r="292" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".46"/>
    <circle cx="800" cy="448" r="230" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="4 14" opacity=".58"/>
    <circle cx="800" cy="448" r="144" fill="${C.charcoal}" opacity=".55" stroke="${C.blood}" stroke-width="2"/>
    <g transform="translate(800 448)">
      <path d="M0-110L110 0L0 110L-110 0Z" fill="none" stroke="${C.bone}" stroke-width="2" opacity=".5"/>
      <path d="M-70-26C-39-54-12-48 0-18C-24 3-53-1-70-26Z" fill="${C.bone}" opacity=".28"/>
      <path d="M70-26C39-54 12-48 0-18C24 3 53-1 70-26Z" fill="${C.bone}" opacity=".28"/>
      <path d="M0-110C20-39-16-3 10 45C30 82-19 91 0 110" fill="none" stroke="${C.blood}" stroke-width="3"/>
    </g>
    <path d="M551 760H1049" stroke="${C.gold}" stroke-width="1.3" opacity=".38"/>
    ${frame(1600, 900)}
  `);
}

function modifierIcon(kind) {
  const circle = `<circle cx="64" cy="64" r="50" fill="none" stroke="${C.gold}" stroke-width="2" stroke-dasharray="3 7" opacity=".72"/>`;
  const bodies = {
    pressure: `
      <path d="M45 28H83M45 100H83M50 32C50 51 64 58 64 64C64 70 50 77 50 96M78 32C78 51 64 58 64 64C64 70 78 77 78 96"
        fill="none" stroke="${C.bone}" stroke-width="4"/>
      <path d="M64 91L64 45M54 55L64 45L74 55" fill="none" stroke="${C.blood}" stroke-width="4"/>`,
    echo: `
      <path d="M37 25H91L84 103H44Z" fill="none" stroke="${C.bone}" stroke-width="3"/>
      <path d="M64 28V100M50 33L58 57L43 78M79 33L69 64L86 84" fill="none" stroke="${C.blood}" stroke-width="3"/>
      <ellipse cx="64" cy="59" rx="18" ry="10" fill="none" stroke="${C.gold}" stroke-width="2"/>
      <circle cx="64" cy="59" r="4" fill="${C.gold}"/>`,
    restricted: `
      <rect x="31" y="35" width="66" height="58" rx="4" fill="none" stroke="${C.bone}" stroke-width="3"/>
      <path d="M31 51H97M64 51V93" stroke="${C.gold}" stroke-width="2"/>
      <circle cx="64" cy="68" r="13" fill="none" stroke="${C.blood}" stroke-width="3"/>
      <path d="M51 55L77 81" stroke="${C.blood}" stroke-width="3"/>`,
    compact: `
      <rect x="27" y="49" width="36" height="54" rx="2" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2" transform="rotate(-13 45 76)"/>
      <rect x="47" y="38" width="36" height="54" rx="2" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
      <rect x="67" y="49" width="36" height="54" rx="2" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2" transform="rotate(13 85 76)"/>
      <path d="M55 59H75M55 69H75M55 79H67" stroke="${C.bone}" stroke-width="2" opacity=".8"/>`,
    guard: `
      <path d="M64 23L98 37V67C98 88 84 101 64 109C44 101 30 88 30 67V37Z" fill="none" stroke="${C.bone}" stroke-width="3"/>
      <path d="M64 36L85 44V68C85 81 77 90 64 96C51 90 43 81 43 68V44Z" fill="${C.fog}" opacity=".18" stroke="${C.gold}" stroke-width="2"/>
      <path d="M50 66L61 77L80 52" fill="none" stroke="${C.blood}" stroke-width="4"/>`,
    early: `
      <circle cx="64" cy="66" r="38" fill="none" stroke="${C.bone}" stroke-width="3"/>
      <path d="M64 66V41M64 66L82 78" stroke="${C.blood}" stroke-width="4"/>
      <path d="M42 31L64 18L86 31" fill="none" stroke="${C.gold}" stroke-width="3"/>
      <circle cx="64" cy="18" r="4" fill="${C.gold}"/>
      <path d="M30 92L98 92M39 99L89 99" stroke="${C.gold}" stroke-width="2" opacity=".7"/>`,
  }[kind];
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="16" fill="#151A15" stroke="${C.gold}" stroke-width="2"/>
    ${circle}
    ${bodies}
    <path d="M44 111H84" stroke="${C.blood}" stroke-width="2" opacity=".72"/>
  `);
}

function challengeEmblem() {
  return svgDoc(256, 256, `
    <rect width="256" height="256" rx="34" fill="#111610" stroke="${C.gold}" stroke-width="3"/>
    <circle cx="128" cy="128" r="99" fill="none" stroke="${C.gold}" stroke-width="2" stroke-dasharray="5 10"/>
    <circle cx="128" cy="128" r="76" fill="none" stroke="${C.fog}" stroke-width="1.5" opacity=".56"/>
    <path d="M128 48C82 48 59 82 65 129C71 176 104 201 128 220C152 201 185 176 191 129C197 82 174 48 128 48Z"
      fill="${C.bone}" opacity=".13" stroke="${C.bone}" stroke-width="2"/>
    <path d="M97 111C111 98 124 101 128 115C120 126 105 127 97 111Z" fill="${C.ink}"/>
    <path d="M159 111C145 98 132 101 128 115C136 126 151 127 159 111Z" fill="${C.ink}"/>
    <path d="M128 49C138 88 111 106 130 140C144 166 111 188 128 220"
      fill="none" stroke="${C.blood}" stroke-width="4"/>
    <g fill="${C.gold}">
      <circle cx="128" cy="28" r="6"/><circle cx="128" cy="228" r="6"/>
      <circle cx="28" cy="128" r="6"/><circle cx="228" cy="128" r="6"/>
    </g>
  `);
}

function deckRestrictionIcon() {
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="18" fill="#161A15" stroke="${C.gold}" stroke-width="2"/>
    <g transform="translate(64 64)">
      <rect x="-41" y="-48" width="45" height="76" rx="3" fill="${C.charcoal}" stroke="${C.fog}" stroke-width="2" transform="rotate(-12)"/>
      <rect x="-13" y="-54" width="45" height="76" rx="3" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
      <rect x="19" y="-44" width="40" height="70" rx="3" fill="${C.charcoal}" stroke="${C.fog}" stroke-width="2" transform="rotate(13)"/>
      <path d="M-34-10H22M-34 3H22M-34 16H7" stroke="${C.bone}" stroke-width="2" opacity=".6"/>
      <circle r="22" fill="${C.night}" stroke="${C.blood}" stroke-width="3"/>
      <path d="M-14-14L14 14" stroke="${C.blood}" stroke-width="4"/>
    </g>
  `);
}

function resultSeal(success) {
  const color = success ? C.gold : C.blood;
  const mark = success
    ? `<path d="M43 65L58 80L86 46" fill="none" stroke="${C.bone}" stroke-width="7" stroke-linecap="round"/>`
    : `<path d="M46 46L82 82M82 46L46 82" stroke="${C.bone}" stroke-width="7" stroke-linecap="round"/>`;
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="18" fill="#151914" stroke="${color}" stroke-width="3"/>
    <circle cx="64" cy="64" r="49" fill="none" stroke="${color}" stroke-width="2" stroke-dasharray="${success ? "4 8" : "2 6"}"/>
    <circle cx="64" cy="64" r="37" fill="${color}" opacity="${success ? ".32" : ".22"}"/>
    ${mark}
    <path d="M64 8V20M64 108V120M8 64H20M108 64H120" stroke="${color}" stroke-width="3"/>
  `);
}

function writeAsset(id, type, relativeSvg, width, height, content) {
  const svgPath = path.join(svgRoot, relativeSvg);
  fs.mkdirSync(path.dirname(svgPath), { recursive: true });
  fs.writeFileSync(svgPath, content, "utf8");
  const relativePng = relativeSvg.replace(/\.svg$/, ".png");
  assets.push({
    id,
    type,
    svg: `assets/svg/v0.6.0/${relativeSvg.split(path.sep).join("/")}`,
    png: `exports/v0.6.0/${relativePng.split(path.sep).join("/")}`,
    width,
    height,
  });
}

writeAsset(
  "scene.challenge.selection",
  "scene",
  "scenes/challenge-selection.svg",
  1600,
  900,
  challengeBackground(),
);
writeAsset(
  "scene.challenge.result",
  "scene",
  "scenes/challenge-result.svg",
  1600,
  900,
  challengeResultBackground(),
);
writeAsset(
  "challenge.modifier.pressure_advance",
  "icon",
  "icons/modifier-pressure-advance.svg",
  128,
  128,
  modifierIcon("pressure"),
);
writeAsset(
  "challenge.modifier.mirror_echo",
  "icon",
  "icons/modifier-mirror-echo.svg",
  128,
  128,
  modifierIcon("echo"),
);
writeAsset(
  "challenge.modifier.restricted_reward",
  "icon",
  "icons/modifier-restricted-reward.svg",
  128,
  128,
  modifierIcon("restricted"),
);
writeAsset(
  "challenge.modifier.compact_deck",
  "icon",
  "icons/modifier-compact-deck.svg",
  128,
  128,
  modifierIcon("compact"),
);
writeAsset(
  "challenge.modifier.reinforced_guard",
  "icon",
  "icons/modifier-reinforced-guard.svg",
  128,
  128,
  modifierIcon("guard"),
);
writeAsset(
  "challenge.modifier.early_phase",
  "icon",
  "icons/modifier-early-phase.svg",
  128,
  128,
  modifierIcon("early"),
);
writeAsset(
  "status.challenge.success",
  "icon",
  "icons/challenge-success.svg",
  128,
  128,
  resultSeal(true),
);
writeAsset(
  "status.challenge.failure",
  "icon",
  "icons/challenge-failure.svg",
  128,
  128,
  resultSeal(false),
);
writeAsset(
  "challenge.mode.emblem",
  "emblem",
  "icons/challenge-emblem.svg",
  256,
  256,
  challengeEmblem(),
);
writeAsset(
  "challenge.deck.restricted",
  "icon",
  "icons/deck-restricted.svg",
  128,
  128,
  deckRestrictionIcon(),
);

fs.writeFileSync(
  path.join(exportRoot, "render-manifest.json"),
  JSON.stringify({ version, assets }, null, 2) + "\n",
  "utf8",
);

const groups = [
  ["挑战背景", assets.filter((asset) => asset.type === "scene")],
  ["挑战徽记与修饰", assets.filter((asset) => asset.type === "icon" || asset.type === "emblem")],
];

const sections = groups.map(([title, items]) => `
  <section>
    <h2>${title}</h2>
    <div class="grid ${items[0]?.type === "scene" ? "scenes" : "icons"}">
      ${items.map((asset) => `
        <figure>
          <img src="../../${asset.svg}" alt="${asset.id}">
          <figcaption><strong>${asset.id}</strong><span>${asset.width} × ${asset.height}</span></figcaption>
        </figure>
      `).join("")}
    </div>
  </section>
`).join("");

const previewHtml = `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>假面低语 v0.6.0 · 挑战美术候选</title>
  <style>
    :root { color-scheme:dark; --ink:#10130f; --gold:#b99750; --bone:#e8dfc9; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--ink); color:var(--bone); font-family:"Noto Serif SC","Songti SC",Georgia,serif; }
    header { padding:36px 5vw 20px; border-bottom:1px solid #5a4a31; }
    h1 { margin:0; font-size:44px; letter-spacing:.12em; }
    header p { color:var(--gold); letter-spacing:.14em; }
    section { padding:22px 4vw 28px; }
    h2 { color:var(--gold); font-size:18px; letter-spacing:.16em; border-bottom:1px solid #453b29; padding-bottom:7px; }
    .grid { display:grid; gap:14px; align-items:start; }
    .scenes { grid-template-columns:1fr; }
    .icons { grid-template-columns:repeat(5,1fr); }
    figure { margin:0; background:#1a1e19; border:1px solid #473e2c; }
    img { display:block; width:100%; height:230px; object-fit:contain; background:#141813; }
    .scenes img { height:auto; max-height:620px; }
    figcaption { display:flex; justify-content:space-between; gap:8px; padding:8px 10px; font-size:11px; color:#a99b7f; }
    figcaption strong { color:var(--bone); font-weight:500; overflow-wrap:anywhere; }
  </style>
</head>
<body>
  <header>
    <h1>假面低语 · v0.6 挑战候选</h1>
    <p>CHALLENGE / MODIFIERS / RESULT / UI REVIEW REQUIRED</p>
  </header>
  ${sections}
</body>
</html>
`;
fs.writeFileSync(path.join(previewDir, "index.html"), previewHtml, "utf8");

const edgeCandidates = [
  process.env.EDGE_PATH,
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
].filter(Boolean);
const edge = edgeCandidates.find((candidate) => fs.existsSync(candidate));

if (!edge) {
  console.log("SVG and preview generated. Microsoft Edge was not found; PNG rendering skipped.");
  process.exit(0);
}

for (const asset of assets) {
  const source = path.join(artDir, asset.svg);
  const destination = path.join(artDir, asset.png);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  const result = spawnSync(edge, [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    `--window-size=${asset.width},${asset.height}`,
    `--screenshot=${destination}`,
    pathToFileURL(source).href,
  ], { encoding: "utf8", timeout: 30000 });
  if (result.status !== 0 || !fs.existsSync(destination)) {
    throw new Error(`Failed to render ${asset.id}: ${result.stderr || result.stdout || "unknown error"}`);
  }
}

const contactOutput = path.join(exportRoot, "contact-sheet.png");
const contactResult = spawnSync(edge, [
  "--headless=new",
  "--disable-gpu",
  "--hide-scrollbars",
  "--window-size=1600,2300",
  `--screenshot=${contactOutput}`,
  pathToFileURL(path.join(previewDir, "index.html")).href,
], { encoding: "utf8", timeout: 30000 });
if (contactResult.status !== 0 || !fs.existsSync(contactOutput)) {
  throw new Error(`Failed to render contact sheet: ${contactResult.stderr || contactResult.stdout || "unknown error"}`);
}

console.log(`Generated ${assets.length} SVG and PNG assets under ${svgRoot} / ${exportRoot}`);
console.log(`Preview: ${path.join(previewDir, "index.html")}`);
console.log(`Contact sheet: ${contactOutput}`);
