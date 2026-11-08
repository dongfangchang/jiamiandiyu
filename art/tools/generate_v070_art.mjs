import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, "..");
const version = "v0.7.0";
const svgRoot = path.join(artDir, "assets", "svg", version);
const exportRoot = path.join(artDir, "exports", version);
const previewDir = path.join(artDir, "preview", version);

for (const folder of [
  path.join(svgRoot, "cards"),
  path.join(svgRoot, "scenes"),
  path.join(svgRoot, "icons"),
  path.join(exportRoot, "cards"),
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
    <radialGradient id="paperWash" cx="46%" cy="40%" r="78%">
      <stop offset="0" stop-color="#F1E4C8"/>
      <stop offset=".6" stop-color="${C.paper}"/>
      <stop offset="1" stop-color="${C.paperDeep}"/>
    </radialGradient>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#090D09"/>
      <stop offset=".55" stop-color="#2A3029"/>
      <stop offset="1" stop-color="#070A07"/>
    </linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E8D091"/>
      <stop offset=".45" stop-color="${C.gold}"/>
      <stop offset="1" stop-color="#5D4726"/>
    </linearGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="${C.ink}" stroke-width=".7" opacity=".12"/>
    </pattern>
    <pattern id="crosshatch" width="11" height="11" patternUnits="userSpaceOnUse">
      <path d="M0 0L11 11M11 0L0 11" stroke="${C.bone}" stroke-width=".45" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-8%" y="-8%" width="116%" height="116%">
      <feTurbulence type="fractalNoise" baseFrequency=".61" numOctaves="3" seed="71" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
      <feComponentTransfer in="mono" result="faint">
        <feFuncA type="table" tableValues="0 .08"/>
      </feComponentTransfer>
      <feBlend in="SourceGraphic" in2="faint" mode="multiply"/>
    </filter>
    <filter id="rough">
      <feTurbulence type="fractalNoise" baseFrequency=".015" numOctaves="2" seed="19" result="n"/>
      <feDisplacementMap in="SourceGraphic" in2="n" scale="2"/>
    </filter>
    ${extraDefs}
  </defs>
  ${body}
</svg>
`;
}

function paperCardBase() {
  return `
    <rect width="512" height="400" fill="url(#paperWash)" filter="url(#grain)"/>
    <rect width="512" height="400" fill="url(#hatch)"/>
    <rect x="18" y="18" width="476" height="364" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".66"/>
    <path d="M18 42H64M448 18H494M18 358H64M448 382H494"
      stroke="${C.gold}" stroke-width="2" opacity=".75"/>
    <circle cx="256" cy="200" r="146" fill="none" stroke="${C.ink}" stroke-width=".8" stroke-dasharray="2 9" opacity=".28"/>
  `;
}

function frame(width, height) {
  return `<rect x="28" y="28" width="${width - 56}" height="${height - 56}" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".55"/>
    <path d="M28 64H68M28 64V28M${width - 28} 64H${width - 68}M${width - 28} 64V28
      M28 ${height - 64}H68M28 ${height - 64}V${height - 28}
      M${width - 28} ${height - 64}H${width - 68}M${width - 28} ${height - 64}V${height - 28}"
      fill="none" stroke="${C.gold}" stroke-width="2" opacity=".7"/>`;
}

function cardArt(kind) {
  const common = `
    <circle cx="256" cy="200" r="126" fill="${C.charcoal}" opacity=".08"/>
    <circle cx="256" cy="200" r="112" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="3 8" opacity=".78"/>
  `;
  const art = {
    ward_fold: `
      <path d="M256 66L362 124V262L256 338L150 262V124Z" fill="${C.bone}" opacity=".38" stroke="${C.ink}" stroke-width="4"/>
      <path d="M256 91L334 134V251L256 309L178 251V134Z" fill="none" stroke="${C.gold}" stroke-width="2"/>
      <path d="M256 121C214 147 194 177 200 218C206 260 231 279 256 296C281 279 306 260 312 218C318 177 298 147 256 121Z"
        fill="${C.charcoal}" opacity=".48" stroke="${C.ink}" stroke-width="2"/>
      <path d="M215 202C229 186 242 188 256 201C270 188 283 186 297 202C284 219 267 226 256 230C245 226 228 219 215 202Z"
        fill="${C.ink}"/>
      <circle cx="256" cy="207" r="8" fill="${C.blood}"/>`,
    seal_boundary: `
      <circle cx="256" cy="198" r="105" fill="none" stroke="${C.ink}" stroke-width="4"/>
      <circle cx="256" cy="198" r="86" fill="none" stroke="${C.gold}" stroke-width="1.5" stroke-dasharray="4 7"/>
      <g fill="${C.blood}" stroke="${C.ink}" stroke-width="1.5">
        <circle cx="256" cy="76" r="20"/><circle cx="354" cy="152" r="18"/>
        <circle cx="330" cy="288" r="19"/><circle cx="182" cy="288" r="18"/>
        <circle cx="158" cy="152" r="19"/>
      </g>
      <path d="M256 96V162M256 234V284M174 163L229 191M283 209L334 263M338 163L284 191M229 209L178 263"
        stroke="${C.ink}" stroke-width="4"/>
      <path d="M256 149L288 198L256 247L224 198Z" fill="${C.bone}" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="256" cy="198" r="12" fill="${C.blood}"/>`,
    echo_wall: `
      <path d="M133 92H379V309H133Z" fill="${C.charcoal}" opacity=".7" stroke="${C.ink}" stroke-width="3"/>
      <path d="M133 142H379M133 192H379M133 242H379M180 92V142M282 92V142M234 142V192M333 142V192M180 192V242M282 192V242M234 242V309M333 242V309"
        stroke="${C.bone}" stroke-width="2" opacity=".16"/>
      <path d="M204 197C232 167 280 167 308 197C280 228 232 228 204 197Z" fill="${C.bone}" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="256" cy="197" r="19" fill="${C.fog}" stroke="${C.ink}" stroke-width="2"/>
      <circle cx="256" cy="197" r="7" fill="${C.blood}"/>
      <path d="M371 184C395 201 395 220 371 237M386 166C421 193 421 229 386 256"
        fill="none" stroke="${C.blood}" stroke-width="3"/>`,
    pendulum: `
      <path d="M256 62V182" stroke="${C.ink}" stroke-width="4"/>
      <circle cx="256" cy="58" r="11" fill="${C.gold}" stroke="${C.ink}" stroke-width="2"/>
      <path d="M256 182L194 283" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="188" cy="299" r="27" fill="${C.blood}" stroke="${C.ink}" stroke-width="3"/>
      <path d="M179 292L197 307M198 291L178 306" stroke="${C.bone}" stroke-width="2"/>
      <g transform="translate(332 252) rotate(12)">
        <rect x="-34" y="-54" width="68" height="108" fill="${C.bone}" stroke="${C.gold}" stroke-width="2"/>
        <path d="M-18-28H18M-18-10H18M-18 8H9" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
      </g>
      <g transform="translate(174 262) rotate(-11)">
        <rect x="-34" y="-54" width="68" height="108" fill="${C.bone}" stroke="${C.gold}" stroke-width="2"/>
        <path d="M-18-28H18M-18-10H18M-18 8H9" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
      </g>`,
    ink_return: `
      <path d="M105 294C153 242 183 276 219 234S284 169 328 202S365 273 408 229"
        fill="none" stroke="${C.ink}" stroke-width="16" opacity=".72"/>
      <path d="M111 292C159 241 187 273 223 232S288 173 328 205S365 271 403 231"
        fill="none" stroke="${C.gold}" stroke-width="2" stroke-dasharray="5 8"/>
      <path d="M349 75L432 158L281 309L205 318L217 240Z" fill="${C.bone}" stroke="${C.ink}" stroke-width="3"/>
      <path d="M302 144L374 216M260 186L351 277" stroke="${C.blood}" stroke-width="4"/>
      <path d="M227 296L251 228L285 262Z" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
      <circle cx="127" cy="281" r="11" fill="${C.blood}"/>
      <circle cx="214" cy="247" r="8" fill="${C.blood}"/>
      <circle cx="305" cy="200" r="6" fill="${C.blood}"/>`,
    crossroads: `
      <path d="M256 333V204L167 113M256 204L345 113M256 204L256 84"
        fill="none" stroke="${C.ink}" stroke-width="12" stroke-linecap="round"/>
      <path d="M256 333V204L167 113M256 204L345 113M256 204L256 84"
        fill="none" stroke="${C.gold}" stroke-width="2" stroke-dasharray="4 7"/>
      <g transform="translate(153 99)">
        <circle r="35" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
        <path d="M-12 18V-18M-12-18L0-30L12-18M-12-18L-26-7M-12-18L1-6" fill="none" stroke="${C.bone}" stroke-width="4"/>
      </g>
      <g transform="translate(359 99)">
        <circle r="35" fill="${C.blood}" opacity=".72" stroke="${C.gold}" stroke-width="2"/>
        <circle r="11" fill="${C.bone}"/>
      </g>
      <g transform="translate(256 61)">
        <circle r="31" fill="${C.bone}" stroke="${C.ink}" stroke-width="2"/>
        <path d="M0-17V17M-14-7L0-20L14-7" fill="none" stroke="${C.ink}" stroke-width="3"/>
      </g>`,
    lantern_step: `
      <g transform="translate(162 192)">
        <path d="M-44-78H44L34 58H-34Z" fill="${C.charcoal}" opacity=".76" stroke="${C.ink}" stroke-width="3"/>
        <path d="M-32-57H32L24 40H-24Z" fill="${C.bone}" opacity=".28" stroke="${C.gold}" stroke-width="2"/>
        <path d="M0-78V-104M-19-91H19" fill="none" stroke="${C.ink}" stroke-width="4"/>
        <path d="M0-39C22-22 24 7 0 25C-24 7-22-22 0-39Z" fill="${C.blood}" opacity=".76"/>
        <path d="M-27-57L-74-24L-104 47M27-57L80-18L111 52" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".38"/>
      </g>
      <path d="M221 283C247 262 277 268 294 289C272 302 245 300 221 283Z"
        fill="${C.ink}" opacity=".78"/>
      <path d="M282 326C307 307 335 312 351 332C330 344 305 343 282 326Z"
        fill="${C.ink}" opacity=".58"/>
      <path d="M196 301L225 273M260 343L292 316" stroke="${C.blood}" stroke-width="3"/>`,
    coffin_nail: `
      <path d="M139 111H373V325H139Z" fill="${C.charcoal}" opacity=".72" stroke="${C.ink}" stroke-width="4"/>
      <path d="M139 111L373 325M373 111L139 325" stroke="${C.ink}" stroke-width="3" opacity=".44"/>
      <g transform="rotate(-28 256 197)">
        <path d="M256 49L285 86L270 285L242 285L227 86Z" fill="${C.bone}" opacity=".5" stroke="${C.ink}" stroke-width="3"/>
        <path d="M210 61H302L286 91H226Z" fill="${C.blood}" stroke="${C.ink}" stroke-width="3"/>
        <path d="M256 94V276" stroke="${C.ink}" stroke-width="2" opacity=".45"/>
      </g>
      <path d="M165 291C194 271 214 289 237 276S282 272 307 287S337 290 355 279"
        fill="none" stroke="${C.blood}" stroke-width="3" opacity=".7"/>
      <circle cx="188" cy="147" r="10" fill="${C.blood}"/>
      <circle cx="340" cy="247" r="7" fill="${C.blood}"/>`,
    twin_mark: `
      <g transform="translate(178 196)">
        <path d="M0-76L78 0L0 76L-78 0Z" fill="${C.bone}" opacity=".35" stroke="${C.ink}" stroke-width="3"/>
        <path d="M-51-42L51 42M51-42L-51 42" stroke="${C.blood}" stroke-width="4"/>
        <circle r="38" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
        <ellipse rx="25" ry="14" fill="${C.bone}" stroke="${C.ink}" stroke-width="2"/>
        <circle r="7" fill="${C.blood}"/>
      </g>
      <g transform="translate(334 196)">
        <path d="M0-76L78 0L0 76L-78 0Z" fill="${C.bone}" opacity=".24" stroke="${C.ink}" stroke-width="3"/>
        <path d="M-51-42L51 42M51-42L-51 42" stroke="${C.blood}" stroke-width="4"/>
        <circle r="38" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
        <ellipse rx="25" ry="14" fill="${C.bone}" stroke="${C.ink}" stroke-width="2"/>
        <circle r="7" fill="${C.blood}"/>
      </g>
      <path d="M256 101V292" stroke="${C.ink}" stroke-width="2" stroke-dasharray="3 7" opacity=".45"/>`,
    mirror_burst: `
      <circle cx="256" cy="200" r="128" fill="${C.charcoal}" opacity=".72" stroke="${C.gold}" stroke-width="2"/>
      <circle cx="256" cy="200" r="97" fill="${C.bone}" opacity=".2" stroke="${C.ink}" stroke-width="2"/>
      <path d="M256 72L242 168L181 112L223 188L145 200L223 212L181 288L242 232L256 328L270 232L331 288L289 212L367 200L289 188L331 112L270 168Z"
        fill="${C.bone}" opacity=".54" stroke="${C.ink}" stroke-width="2"/>
      <path d="M256 73V327M146 200H366M181 112L331 288M331 112L181 288"
        stroke="${C.blood}" stroke-width="2" opacity=".72"/>
      <path d="M195 166C225 137 287 137 317 166C287 196 225 196 195 166Z" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
      <circle cx="256" cy="166" r="12" fill="${C.blood}"/>
      <circle cx="256" cy="200" r="6" fill="${C.bone}"/>`,
  }[kind];
  return `${paperCardBase()}${common}${art}`;
}

function deckArchiveBackground() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#crosshatch)"/>
    <path d="M0 742C188 679 330 727 510 683S853 672 1047 715S1374 674 1600 701V900H0Z" fill="#080B08"/>
    <g opacity=".42" fill="none" stroke="${C.gold}">
      <path d="M70 154H1015L1046 185V688H70Z"/>
      <path d="M1092 154H1530L1530 688H1092Z"/>
      <path d="M70 154H1015" stroke-width="2"/>
      <path d="M1092 154H1530" stroke-width="2"/>
      <path d="M1092 612H1530M1092 690H1530"/>
    </g>
    <g fill="#111510" stroke="${C.gold}" stroke-width="1.3" opacity=".72">
      ${Array.from({ length: 10 }, (_, index) => {
        const col = index % 5;
        const row = Math.floor(index / 5);
        const x = 100 + col * 180;
        const y = 216 + row * 172;
        return `<rect x="${x}" y="${y}" width="138" height="134" rx="5"/>`;
      }).join("")}
    </g>
    <g stroke="${C.gold}" fill="none" opacity=".52">
      ${Array.from({ length: 8 }, (_, index) => {
        const y = 222 + index * 48;
        return `<rect x="1114" y="${y}" width="394" height="38" rx="4"/>`;
      }).join("")}
    </g>
    <g fill="${C.gold}" opacity=".55">
      <circle cx="1124" cy="120" r="5"/><circle cx="1478" cy="120" r="5"/>
      <circle cx="1124" cy="707" r="5"/><circle cx="1478" cy="707" r="5"/>
    </g>
    <path d="M1058 136V704" stroke="${C.blood}" stroke-width="1.3" opacity=".55"/>
    ${frame(1600, 900)}
  `);
}

function modifierIcon(kind) {
  const body = {
    ritual_interference: `
      <circle cx="64" cy="64" r="38" fill="none" stroke="${C.gold}" stroke-width="2"/>
      <circle cx="64" cy="64" r="25" fill="none" stroke="${C.fog}" stroke-width="1.5" stroke-dasharray="3 6"/>
      <path d="M64 19L73 47L102 55L74 65L64 108L54 65L26 55L55 47Z" fill="${C.bone}" opacity=".26" stroke="${C.bone}" stroke-width="2"/>
      <path d="M47 42L82 81M80 43L48 82" stroke="${C.blood}" stroke-width="4"/>
      <circle cx="64" cy="64" r="8" fill="${C.blood}"/>`,
    twin_pursuit: `
      <path d="M27 78C34 57 48 47 66 52C78 55 87 65 91 78L105 85L89 90C85 103 75 111 63 111C48 111 38 101 36 88L27 78Z"
        fill="${C.charcoal}" stroke="${C.bone}" stroke-width="2"/>
      <path d="M38 61L29 41L48 51M82 61L91 41L72 51" fill="${C.charcoal}" stroke="${C.bone}" stroke-width="2"/>
      <path d="M49 96C48 115 54 120 61 120M75 96C76 115 70 120 63 120" fill="none" stroke="${C.gold}" stroke-width="3"/>
      <path d="M42 27L56 43M86 27L72 43" stroke="${C.blood}" stroke-width="3"/>`,
    vigil: `
      <path d="M48 104H80L75 116H53Z" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
      <path d="M55 103V67C55 52 73 52 73 67V103Z" fill="${C.bone}" opacity=".24" stroke="${C.bone}" stroke-width="2"/>
      <path d="M64 45C74 56 75 68 64 80C53 68 54 56 64 45Z" fill="${C.blood}" stroke="${C.ink}" stroke-width="1.5"/>
      <circle cx="64" cy="66" r="31" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="3 6" opacity=".7"/>
      <path d="M31 68H43M85 68H97M38 42L47 51M90 42L81 51" stroke="${C.fog}" stroke-width="2"/>`,
  }[kind];
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="16" fill="#151A15" stroke="${C.gold}" stroke-width="2"/>
    <circle cx="64" cy="64" r="51" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="3 7" opacity=".6"/>
    ${body}
    <path d="M42 113H86" stroke="${C.blood}" stroke-width="2" opacity=".72"/>
  `);
}

function brokenProcessionEmblem() {
  return svgDoc(256, 256, `
    <rect width="256" height="256" rx="34" fill="#10140F" stroke="${C.gold}" stroke-width="3"/>
    <circle cx="128" cy="128" r="101" fill="none" stroke="${C.gold}" stroke-width="2" stroke-dasharray="5 11"/>
    <circle cx="128" cy="128" r="78" fill="none" stroke="${C.fog}" stroke-width="1.5" opacity=".5"/>
    <g fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2">
      <path d="M41 142L67 100L91 146L67 166Z"/>
      <path d="M95 132L122 86L147 139L122 158Z"/>
      <path d="M151 140L177 97L202 144L177 168Z"/>
    </g>
    <path d="M50 174C78 159 100 183 126 164S177 159 205 174" fill="none" stroke="${C.bone}" stroke-width="3" opacity=".5"/>
    <path d="M128 39L118 101L68 60L104 116L46 128L104 140L68 196L118 155L128 217L138 155L188 196L152 140L210 128L152 116L188 60L138 101Z"
      fill="none" stroke="${C.blood}" stroke-width="3"/>
    <circle cx="128" cy="128" r="12" fill="${C.gold}"/>
  `);
}

function routeOverrideIcon() {
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="16" fill="#151A15" stroke="${C.gold}" stroke-width="2"/>
    <path d="M25 96L45 76L62 87L101 32" fill="none" stroke="${C.bone}" stroke-width="4"/>
    <path d="M87 32H103V50" fill="none" stroke="${C.gold}" stroke-width="4"/>
    <circle cx="32" cy="96" r="8" fill="${C.blood}"/>
    <circle cx="62" cy="87" r="7" fill="${C.gold}"/>
    <path d="M31 101L45 112M63 92L74 110" stroke="${C.fog}" stroke-width="2" opacity=".65"/>
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
    svg: `assets/svg/v0.7.0/${relativeSvg.split(path.sep).join("/")}`,
    png: `exports/v0.7.0/${relativePng.split(path.sep).join("/")}`,
    width,
    height,
  });
}

const cardCandidates = [
  ["card.skill.warding_circle", "seal_boundary", "守夜圆环 · 防御"],
  ["card.skill.lantern_step", "lantern_step", "提灯步 · 防御/抽牌"],
  ["card.skill.whispered_hunch", "pendulum", "灵性预感 · 抽牌"],
  ["card.skill.mirrored_memory", "ink_return", "镜中记忆 · 灵性/抽牌"],
  ["card.skill.fated_echo", "twin_mark", "命运回声 · 标记"],
  ["card.skill.piercing_omen", "mirror_burst", "穿刺凶兆 · 标记爆发"],
  ["card.skill.coffin_nail", "coffin_nail", "棺钉 · 高风险爆发"],
  ["card.skill.second_sight", "crossroads", "第二视觉 · 灵性/揭示"],
];

for (const [id, kind, role] of cardCandidates) {
  const fileName = id.replaceAll(".", "_");
  writeAsset(id, "card", `cards/${fileName}.svg`, 512, 400, svgDoc(512, 400, cardArt(kind)));
  const asset = assets[assets.length - 1];
  asset.role = role;
}

writeAsset(
  "scene.deck.archive",
  "scene",
  "scenes/deck_archive.svg",
  1600,
  900,
  deckArchiveBackground(),
);
writeAsset(
  "challenge.mode.broken_procession",
  "emblem",
  "icons/challenge_broken_procession.svg",
  256,
  256,
  brokenProcessionEmblem(),
);
writeAsset(
  "challenge.modifier.obituary_echo",
  "icon",
  "icons/modifier_obituary_echo.svg",
  128,
  128,
  modifierIcon("ritual_interference"),
);
writeAsset(
  "challenge.modifier.twin_shadow",
  "icon",
  "icons/modifier_twin_shadow.svg",
  128,
  128,
  modifierIcon("twin_pursuit"),
);
writeAsset(
  "challenge.modifier.ritual_vigil",
  "icon",
  "icons/modifier_ritual_vigil.svg",
  128,
  128,
  modifierIcon("vigil"),
);
writeAsset(
  "route.variant.overridden_node",
  "icon",
  "icons/route_overridden_node.svg",
  128,
  128,
  routeOverrideIcon(),
);

fs.writeFileSync(
  path.join(exportRoot, "render-manifest.json"),
  JSON.stringify({ version, assets }, null, 2) + "\n",
  "utf8",
);

const cardsHtml = assets
  .filter((asset) => asset.type === "card")
  .map((asset) => `
    <figure>
      <img src="../../${asset.svg}" alt="${asset.id}">
      <figcaption><strong>${asset.id}</strong><span>${asset.role}</span></figcaption>
    </figure>
  `)
  .join("");

const supportHtml = assets
  .filter((asset) => asset.type !== "card")
  .map((asset) => `
    <figure class="${asset.type === "scene" ? "wide" : ""}">
      <img src="../../${asset.svg}" alt="${asset.id}">
      <figcaption><strong>${asset.id}</strong><span>${asset.width} × ${asset.height}</span></figcaption>
    </figure>
  `)
  .join("");

const previewHtml = `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>假面低语 v0.7.0 · 构筑与第二挑战候选</title>
  <style>
    :root { color-scheme:dark; --ink:#10130f; --gold:#b99750; --bone:#e8dfc9; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--ink); color:var(--bone); font-family:"Noto Serif SC","Songti SC",Georgia,serif; }
    header { padding:36px 5vw 20px; border-bottom:1px solid #5a4a31; }
    h1 { margin:0; font-size:40px; letter-spacing:.12em; }
    header p { color:var(--gold); letter-spacing:.14em; }
    section { padding:22px 4vw 28px; }
    h2 { color:var(--gold); font-size:18px; letter-spacing:.16em; border-bottom:1px solid #453b29; padding-bottom:7px; }
    .grid { display:grid; gap:14px; align-items:start; }
    .cards { grid-template-columns:repeat(4,1fr); }
    .support { grid-template-columns:repeat(5,1fr); }
    figure { margin:0; background:#1a1e19; border:1px solid #473e2c; }
    figure.wide { grid-column:1/-1; max-width:1100px; }
    img { display:block; width:100%; height:auto; background:#141813; }
    figcaption { display:flex; flex-direction:column; gap:4px; padding:9px 10px; font-size:11px; color:#a99b7f; }
    figcaption strong { color:var(--bone); font-weight:500; overflow-wrap:anywhere; }
  </style>
</head>
<body>
  <header>
    <h1>假面低语 · v0.7 构筑与第二挑战</h1>
    <p>DECK ARCHIVE / EIGHT CARD CANDIDATES / BROKEN PROCESSION / UI REVIEW REQUIRED</p>
  </header>
  <section><h2>新增卡面候选</h2><div class="grid cards">${cardsHtml}</div></section>
  <section><h2>卡组、第二挑战与修饰</h2><div class="grid support">${supportHtml}</div></section>
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
