import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, "..");
const svgRoot = path.join(artDir, "assets", "svg", "v0.5.0");
const exportRoot = path.join(artDir, "exports", "v0.5.0");
const previewDir = path.join(artDir, "preview", "v0.5.0");

for (const folder of [
  path.join(svgRoot, "scenes"),
  path.join(svgRoot, "enemies"),
  path.join(svgRoot, "rituals"),
  path.join(svgRoot, "icons"),
  path.join(exportRoot, "scenes"),
  path.join(exportRoot, "enemies"),
  path.join(exportRoot, "rituals"),
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
      <stop offset="0" stop-color="#0E120E"/>
      <stop offset=".52" stop-color="#29302A"/>
      <stop offset="1" stop-color="#090C09"/>
    </linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E8D091"/>
      <stop offset=".45" stop-color="${C.gold}"/>
      <stop offset="1" stop-color="#5D4726"/>
    </linearGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(28)">
      <path d="M0 0V8" stroke="${C.ink}" stroke-width=".65" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="10" height="10" patternUnits="userSpaceOnUse">
      <path d="M0 0L10 10M10 0L0 10" stroke="${C.bone}" stroke-width=".5" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-8%" y="-8%" width="116%" height="116%">
      <feTurbulence type="fractalNoise" baseFrequency=".56" numOctaves="3" seed="53" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
      <feComponentTransfer in="mono" result="faint">
        <feFuncA type="table" tableValues="0 .095"/>
      </feComponentTransfer>
      <feBlend in="SourceGraphic" in2="faint" mode="multiply"/>
    </filter>
    ${extraDefs}
  </defs>
  ${body}
</svg>
`;
}

function paperBackground(width, height) {
  return `
    <rect width="${width}" height="${height}" fill="url(#paperWash)" filter="url(#grain)"/>
    <rect width="${width}" height="${height}" fill="url(#hatch)"/>
    <path d="M0 ${height * 0.82} C${width * 0.23} ${height * 0.73}, ${width * 0.41} ${height * 0.91}, ${width * 0.61} ${height * 0.81} S${width * 0.84} ${height * 0.77}, ${width} ${height * 0.86}"
      fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".12"/>
  `;
}

function routeMap() {
  const nodes = [
    { x: 224, y: 632, kind: "hunt" },
    { x: 505, y: 526, kind: "elite" },
    { x: 758, y: 665, kind: "rest" },
    { x: 1086, y: 424, kind: "boss" },
    { x: 1370, y: 244, kind: "ritual" },
  ];
  const nodeArt = nodes.map((node, index) => {
    const marks = [
      `<circle r="29" fill="none" stroke="${C.ink}" stroke-width="2"/><path d="M-27 0H27M0-27V27" stroke="${C.ink}" stroke-width="1"/>`,
      `<path d="M0-33L30 16L-25 27Z" fill="none" stroke="${C.ink}" stroke-width="2"/><path d="M-18-9L20 19M18-9L-18 19" stroke="${C.blood}" stroke-width="2"/>`,
      `<path d="M-33 20V-14C-18-27 2-27 15-13V22Z" fill="none" stroke="${C.ink}" stroke-width="2"/><path d="M-8 21V-2H10V21" stroke="${C.gold}" stroke-width="2"/>`,
      `<path d="M-28 21L-19-24H19L28 21Z" fill="none" stroke="${C.ink}" stroke-width="2"/><circle cy="-6" r="9" fill="${C.blood}" opacity=".6"/>`,
      `<circle r="27" fill="none" stroke="${C.ink}" stroke-width="2"/><path d="M0-19L18 12L-18 12Z" fill="none" stroke="${C.gold}" stroke-width="2"/><circle r="6" fill="${C.blood}"/>`,
    ];
    return `
      <g transform="translate(${node.x} ${node.y})">
        <circle r="54" fill="${C.bone}" opacity=".16" stroke="${C.gold}" stroke-width="1.5" stroke-dasharray="4 8"/>
        <circle r="39" fill="${C.paper}" stroke="${C.ink}" stroke-width="2"/>
        ${marks[index]}
        <text x="0" y="76" text-anchor="middle" fill="${C.ink}" font-family="'Palatino Linotype',serif" font-size="15" letter-spacing="3">${String(index + 1).padStart(2, "0")}</text>
      </g>
    `;
  }).join("");
  const routePath = nodes.map((node, index) => `${index === 0 ? "M" : "L"}${node.x} ${node.y}`).join(" ");
  return svgDoc(1600, 900, `
    ${paperBackground(1600, 900)}
    <path d="M91 118 C263 74 389 136 531 95 S833 83 1001 118 S1363 77 1509 129 L1481 753 C1302 807 1198 733 1009 786 S671 834 478 766 S166 809 83 748Z"
      fill="${C.bone}" opacity=".22" stroke="${C.ink}" stroke-width="2"/>
    <path d="M113 142 C278 110 387 164 535 126 S832 112 993 145 S1344 111 1473 151"
      fill="none" stroke="${C.gold}" stroke-width="1.2" opacity=".6"/>
    <path d="${routePath}" fill="none" stroke="${C.ink}" stroke-width="7" opacity=".22"/>
    <path d="${routePath}" fill="none" stroke="${C.gold}" stroke-width="2.2" stroke-dasharray="10 12" opacity=".76"/>
    <path d="M195 683 C355 503 587 703 758 665 S987 389 1086 424 S1236 324 1370 244"
      fill="none" stroke="${C.blood}" stroke-width="1" stroke-dasharray="3 15" opacity=".44"/>
    <g opacity=".28" stroke="${C.ink}" fill="none">
      <path d="M180 188 C242 222 290 192 347 249 M1240 685 C1294 631 1356 672 1424 620"/>
      <path d="M216 728 C301 703 351 744 426 711 M914 194 C1000 214 1057 172 1136 210"/>
      <circle cx="118" cy="345" r="48"/><circle cx="1438" cy="434" r="62"/>
    </g>
    ${nodeArt}
    <g transform="translate(800 822)" opacity=".55">
      <path d="M-218 0H218" stroke="${C.gold}" stroke-width="1"/>
      <path d="M0-23L14-8L0 8L-14-8Z" fill="${C.blood}"/>
    </g>
    <rect x="32" y="32" width="1536" height="836" fill="none" stroke="${C.gold}" stroke-width="1.4" opacity=".42"/>
  `);
}

function restScene() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#hatch)" opacity=".11"/>
    <path d="M0 615 L0 178 H1600 V615Z" fill="#1A211B" opacity=".7"/>
    <path d="M90 683V304H1510V683" fill="none" stroke="${C.gold}" stroke-width="3" opacity=".34"/>
    <path d="M108 320H1492V662H108Z" fill="${C.fog}" opacity=".035"/>
    <path d="M0 694 C215 654 351 713 548 673 S902 680 1110 704 S1421 663 1600 687 V900H0Z" fill="#090C09"/>
    <path d="M0 790 C233 744 403 802 624 761 S976 752 1194 782 S1460 742 1600 770 V900H0Z" fill="${C.fog}" opacity=".08"/>
    <g transform="translate(360 505)">
      <rect x="-130" y="-210" width="260" height="365" rx="8" fill="${C.ink}" opacity=".9"/>
      <path d="M-82 72 C-93-28-55-97 0-104 C57-98 94-28 81 72Z" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2"/>
      <path d="M-54 30 C-29-7 30-9 55 29" fill="none" stroke="${C.blood}" stroke-width="3" opacity=".54"/>
      <path d="M-151 102H151V170H-151Z" fill="${C.ink}" stroke="${C.gold}" stroke-width="2"/>
      <path d="M-102 104V-38M102 104V-38" stroke="${C.gold}" stroke-width="2" opacity=".48"/>
    </g>
    <g transform="translate(1168 500)">
      <rect x="-155" y="-180" width="310" height="365" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="2" opacity=".8"/>
      <path d="M-110-115H110V-30H-110Z M-110 40H110V128H-110Z" fill="${C.ink}" opacity=".75"/>
      <path d="M-72-95H72 M-72-60H49 M-72 62H72 M-72 96H42" stroke="${C.paperDeep}" stroke-width="2" opacity=".45"/>
      <path d="M0-13V26" stroke="${C.gold}" stroke-width="2"/>
      <circle cy="34" r="8" fill="${C.blood}"/>
    </g>
    <g transform="translate(791 489)">
      <circle r="111" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".35"/>
      <path d="M0-85 C60-85 84-34 72 22 C60 77 25 103 0 119 C-25 103-60 77-72 22 C-84-34-60-85 0-85Z"
        fill="${C.bone}" opacity=".08" stroke="${C.bone}" stroke-width="1.5"/>
      <path d="M0-80 C12-27-13 0 4 39 C20 76-19 91 0 116" fill="none" stroke="${C.blood}" stroke-width="2.4" opacity=".75"/>
      <path d="M-41-28C-18-44 16-42 41-28C20-12-19-12-41-28Z" fill="${C.ink}" opacity=".72"/>
    </g>
    <path d="M510 681 C694 638 903 638 1081 681" fill="none" stroke="${C.ink}" stroke-width="16" opacity=".72"/>
    <rect x="34" y="34" width="1532" height="832" fill="none" stroke="${C.gold}" stroke-width="1.4" opacity=".28"/>
  `);
}

function mirrorBaron() {
  return svgDoc(900, 900, `
    <rect width="900" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="900" height="900" fill="url(#crosshatch)" opacity=".55"/>
    <path d="M0 720 C139 647 239 686 365 643 S604 647 737 681 S842 651 900 674 V900H0Z" fill="#080B09"/>
    <g fill="none" stroke="${C.gold}" opacity=".26">
      <path d="M52 116 L238 41 L374 144 L271 320Z"/>
      <path d="M600 75 L756 151 L705 340 L537 286Z"/>
      <path d="M682 481 L861 424 L849 650 L710 706Z"/>
      <path d="M35 407 L185 344 L239 516 L84 578Z"/>
    </g>
    <g fill="${C.fog}" opacity=".06">
      <path d="M52 116L238 41L374 144L271 320Z"/>
      <path d="M600 75L756 151L705 340L537 286Z"/>
      <path d="M682 481L861 424L849 650L710 706Z"/>
      <path d="M35 407L185 344L239 516L84 578Z"/>
    </g>
    <circle cx="461" cy="421" r="274" fill="none" stroke="${C.fog}" stroke-width="1.4" opacity=".27"/>
    <path d="M337 257 C363 191 430 164 493 181 C552 196 585 245 576 306 L544 331 H370Z" fill="#080A08"/>
    <path d="M281 289 H637 L578 341 H340Z" fill="${C.ink}"/>
    <path d="M352 691 C363 516 393 365 460 340 C532 364 565 518 575 691Z" fill="#090B09"/>
    <path d="M389 380 H531 L557 681 H360Z" fill="${C.charcoal}"/>
    <path d="M425 344 L460 420 L495 344" fill="${C.paper}" opacity=".74"/>
    <path d="M430 389 L460 441 L491 389" fill="${C.blood}" opacity=".68"/>
    <path d="M352 430 C293 459 259 515 252 590 L309 610 C321 532 347 494 390 474Z" fill="${C.ink}"/>
    <path d="M568 430 C627 459 661 515 668 590 L611 610 C599 532 573 494 530 474Z" fill="${C.ink}"/>
    <path d="M621 458 L721 756" stroke="${C.ink}" stroke-width="13" stroke-linecap="round"/>
    <path d="M708 739 L756 751" stroke="${C.gold}" stroke-width="8" stroke-linecap="round"/>
    <g fill="none" stroke="${C.bone}" stroke-width="2" opacity=".7">
      <path d="M408 278L438 255L462 285L436 312Z"/>
      <path d="M462 285L493 264L515 294L492 324Z"/>
      <path d="M438 255L451 219L482 229L493 264"/>
    </g>
    <g fill="${C.blood}">
      <circle cx="439" cy="286" r="5"/><circle cx="491" cy="293" r="4"/>
      <circle cx="462" cy="440" r="5"/><circle cx="327" cy="490" r="3"/>
    </g>
    <path d="M219 714 C339 673 577 671 691 716" fill="none" stroke="${C.fog}" stroke-width="24" opacity=".1"/>
    <rect x="38" y="36" width="824" height="828" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity="${"0.5"}"/>
  `);
}

function ritualScene() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#hatch)" opacity=".12"/>
    <path d="M0 746 C222 652 424 730 636 664 S1011 671 1224 645 S1464 666 1600 626 V900H0Z" fill="#070A07"/>
    <path d="M0 803 C213 755 407 812 622 777 S970 758 1179 792 S1445 747 1600 773 V900H0Z" fill="${C.fog}" opacity=".07"/>
    <circle cx="800" cy="445" r="332" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".38"/>
    <circle cx="800" cy="445" r="276" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="4 14" opacity=".5"/>
    <circle cx="800" cy="445" r="145" fill="none" stroke="${C.blood}" stroke-width="1.6" opacity=".48"/>
    <path d="M800 113V777 M468 445H1132 M565 210L1035 680 M1035 210L565 680"
      stroke="${C.gold}" stroke-width=".9" opacity=".2"/>
    <g transform="translate(800 445)">
      <circle r="53" fill="${C.fog}" opacity=".16" stroke="${C.bone}" stroke-width="2"/>
      <circle r="22" fill="none" stroke="${C.blood}" stroke-width="3"/>
      <path d="M0-39V39M-39 0H39" stroke="${C.gold}" stroke-width="2" opacity=".58"/>
    </g>
    <g transform="translate(380 489) rotate(-10)">
      <rect x="-134" y="-189" width="268" height="378" fill="${C.paper}" opacity=".82" stroke="${C.gold}" stroke-width="3"/>
      <rect x="-113" y="-168" width="226" height="336" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".35"/>
      <path d="M-72-94H72 M-72-58H72 M-72-22H52 M-72 78H64" stroke="${C.ink}" stroke-width="2" opacity=".24"/>
      <circle cy="20" r="31" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".4"/>
    </g>
    <g transform="translate(800 460) rotate(2)">
      <rect x="-142" y="-200" width="284" height="400" fill="${C.paper}" opacity=".92" stroke="${C.gold}" stroke-width="4"/>
      <rect x="-119" y="-177" width="238" height="354" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".38"/>
      <path d="M-72-110H72 M-72-73H72 M-72-36H49" stroke="${C.ink}" stroke-width="2" opacity=".24"/>
      <path d="M0-5L45 48L0 101L-45 48Z" fill="${C.blood}" opacity=".58"/>
    </g>
    <g transform="translate(1220 500) rotate(12)">
      <rect x="-134" y="-189" width="268" height="378" fill="${C.paper}" opacity=".82" stroke="${C.gold}" stroke-width="3"/>
      <rect x="-113" y="-168" width="226" height="336" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".35"/>
      <circle cy="20" r="51" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".42"/>
      <path d="M0-31L13-10L0 11L-13-10Z" fill="${C.blood}" opacity=".68"/>
    </g>
    <path d="M630 692 C708 651 892 651 970 692" fill="none" stroke="${C.ink}" stroke-width="15" opacity=".72"/>
    <path d="M602 736H998" stroke="${C.gold}" stroke-width="2" opacity=".28"/>
    <rect x="34" y="34" width="1532" height="832" fill="none" stroke="${C.gold}" stroke-width="1.4" opacity=".34"/>
  `);
}

function ritualCard(kind) {
  const content = {
    names: `
      <path d="M53 132H367 M53 174H307 M53 216H367 M53 258H301 M53 300H367 M53 342H323"
        stroke="${C.ink}" stroke-width="4" opacity=".32"/>
      <path d="M68 394H352V489H68Z" fill="${C.bone}" opacity=".18" stroke="${C.ink}" stroke-width="1"/>
      <path d="M93 440H156 M244 440H307" stroke="${C.blood}" stroke-width="5"/>
      <circle cx="326" cy="119" r="19" fill="none" stroke="${C.gold}" stroke-width="2"/>
      <path d="M318 119L325 126L337 110" fill="none" stroke="${C.gold}" stroke-width="3"/>
    `,
    order: `
      <g transform="translate(210 176)">
        <circle r="48" fill="none" stroke="${C.ink}" stroke-width="3"/>
        <path d="M-19 4C-5-20 8-23 21-8C35 8 18 25 5 17C-5 11-5-2 4-5" fill="none" stroke="${C.ink}" stroke-width="4"/>
        <path d="M-48 0H48M0-48V48" stroke="${C.gold}" stroke-width="1.5" opacity=".5"/>
      </g>
      <g transform="translate(210 316)">
        <path d="M0-45L39 39H-39Z" fill="none" stroke="${C.ink}" stroke-width="3"/>
        <path d="M0-20V20M-17 6H17" stroke="${C.blood}" stroke-width="4"/>
      </g>
      <g transform="translate(210 456)">
        <path d="M-53 8V-18C-20-44 22-44 53-18V8Z" fill="none" stroke="${C.ink}" stroke-width="4"/>
        <path d="M-35 8V45H35V8" fill="none" stroke="${C.gold}" stroke-width="2"/>
      </g>
    `,
    seal: `
      <circle cx="210" cy="255" r="123" fill="none" stroke="${C.gold}" stroke-width="2" stroke-dasharray="4 11"/>
      <circle cx="210" cy="255" r="82" fill="${C.fog}" opacity=".12" stroke="${C.ink}" stroke-width="3"/>
      <path d="M210 135L309 236L266 371H154L111 236Z" fill="none" stroke="${C.ink}" stroke-width="4"/>
      <path d="M155 236C181 195 239 195 265 236C239 277 181 277 155 236Z" fill="${C.bone}" opacity=".85" stroke="${C.ink}" stroke-width="2"/>
      <circle cx="210" cy="236" r="18" fill="${C.fog}" stroke="${C.ink}" stroke-width="2"/>
      <circle cx="210" cy="236" r="6" fill="${C.ink}"/>
      <path d="M210 135V88M309 236H356M210 371V421M111 236H64" stroke="${C.blood}" stroke-width="3" opacity=".72"/>
    `,
  }[kind];
  return svgDoc(420, 600, `
    ${paperBackground(420, 600)}
    <rect x="20" y="20" width="380" height="560" rx="4" fill="none" stroke="${C.ink}" stroke-width="5"/>
    <rect x="30" y="30" width="360" height="540" fill="none" stroke="${C.gold}" stroke-width="2"/>
    <path d="M20 58L58 20M362 20L400 58M20 542L58 580M362 580L400 542"
      fill="none" stroke="url(#brass)" stroke-width="4"/>
    <path d="M45 92H375 M45 520H375" stroke="${C.ink}" stroke-width="1" opacity=".35"/>
    ${content}
    <path d="M210 551L219 560L210 569L201 560Z" fill="${C.blood}"/>
  `);
}

function routeStateIcon(state) {
  const body = {
    pending: `<circle cx="48" cy="48" r="31" fill="none" stroke="${C.fog}" stroke-width="3" stroke-dasharray="5 8"/>`,
    current: `<circle cx="48" cy="48" r="34" fill="none" stroke="${C.gold}" stroke-width="3"/><circle cx="48" cy="48" r="17" fill="${C.blood}" opacity=".72"/><path d="M48 8V22M48 74V88M8 48H22M74 48H88" stroke="${C.gold}" stroke-width="3"/>`,
    completed: `<circle cx="48" cy="48" r="34" fill="none" stroke="${C.gold}" stroke-width="3"/><path d="M28 49L42 62L69 32" fill="none" stroke="${C.bone}" stroke-width="5" stroke-linecap="round"/>`,
  }[state];
  return svgDoc(96, 96, `
    <rect width="96" height="96" rx="18" fill="#171B16" stroke="${C.gold}" stroke-width="2"/>
    ${body}
  `);
}

function ritualResultIcon(success) {
  const color = success ? C.gold : C.blood;
  const mark = success
    ? `<path d="M36 66L55 84L92 39" fill="none" stroke="${C.bone}" stroke-width="7" stroke-linecap="round"/>`
    : `<path d="M39 39L89 89M89 39L39 89" stroke="${C.bone}" stroke-width="7" stroke-linecap="round"/>`;
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="18" fill="#151914" stroke="${color}" stroke-width="3"/>
    <circle cx="64" cy="64" r="49" fill="none" stroke="${color}" stroke-width="2" stroke-dasharray="${success ? "4 8" : "2 6"}"/>
    <circle cx="64" cy="64" r="36" fill="${color}" opacity="${success ? ".32" : ".22"}"/>
    ${mark}
    <circle cx="64" cy="12" r="5" fill="${color}"/>
    <circle cx="64" cy="116" r="5" fill="${color}"/>
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
    svg: `assets/svg/v0.5.0/${relativeSvg.split(path.sep).join("/")}`,
    png: `exports/v0.5.0/${relativePng.split(path.sep).join("/")}`,
    width,
    height,
  });
}

writeAsset("scene.route.v050.short_road", "route-map", "scenes/route-map.svg", 1600, 900, routeMap());
writeAsset("scene.rest.old_house", "scene", "scenes/rest-old-house.svg", 1600, 900, restScene());
writeAsset("enemy.mirror_baron", "enemy", "enemies/enemy-mirror-baron.svg", 900, 900, mirrorBaron());
writeAsset("scene.ritual.tampered_obituary", "scene", "scenes/ritual-tampered-obituary.svg", 1600, 900, ritualScene());
writeAsset("ritual.card.name_record", "ritual-card", "rituals/ritual-card-name-record.svg", 420, 600, ritualCard("names"));
writeAsset("ritual.card.chronology", "ritual-card", "rituals/ritual-card-chronology.svg", 420, 600, ritualCard("order"));
writeAsset("ritual.card.seal", "ritual-card", "rituals/ritual-card-seal.svg", 420, 600, ritualCard("seal"));
writeAsset("status.route.pending", "icon", "icons/route-pending.svg", 96, 96, routeStateIcon("pending"));
writeAsset("status.route.current", "icon", "icons/route-current.svg", 96, 96, routeStateIcon("current"));
writeAsset("status.route.completed", "icon", "icons/route-completed.svg", 96, 96, routeStateIcon("completed"));
writeAsset("status.ritual.success", "icon", "icons/ritual-success.svg", 128, 128, ritualResultIcon(true));
writeAsset("status.ritual.failure", "icon", "icons/ritual-failure.svg", 128, 128, ritualResultIcon(false));

fs.writeFileSync(
  path.join(exportRoot, "render-manifest.json"),
  JSON.stringify({ version: "v0.5.0", assets }, null, 2) + "\n",
  "utf8",
);

const groups = [
  ["路线与场景", assets.filter((asset) => asset.type === "route-map" || asset.type === "scene")],
  ["首领", assets.filter((asset) => asset.type === "enemy")],
  ["晋升仪式", assets.filter((asset) => asset.type === "ritual-card")],
  ["状态图标", assets.filter((asset) => asset.type === "icon")],
];

const sections = groups.map(([title, items]) => `
  <section>
    <h2>${title}</h2>
    <div class="grid ${items[0]?.type === "icon" ? "icons" : ""} ${items[0]?.type === "ritual-card" ? "cards" : ""}">
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
  <title>假面低语 v0.5.0 · 美术候选</title>
  <style>
    :root { color-scheme:dark; --ink:#10130f; --gold:#b99750; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--ink); color:#e8dfc9; font-family:"Noto Serif SC","Songti SC",Georgia,serif; }
    header { padding:36px 5vw 20px; border-bottom:1px solid #5a4a31; }
    h1 { margin:0; font-size:44px; letter-spacing:.12em; }
    header p { color:var(--gold); letter-spacing:.14em; }
    section { padding:18px 4vw 22px; }
    h2 { color:var(--gold); font-size:18px; letter-spacing:.16em; border-bottom:1px solid #453b29; padding-bottom:7px; }
    .grid { display:grid; grid-template-columns:repeat(2,1fr); gap:14px; }
    .grid.icons { grid-template-columns:repeat(5,1fr); }
    .grid.cards { grid-template-columns:repeat(3,1fr); }
    figure { margin:0; background:#1a1e19; border:1px solid #473e2c; }
    img { display:block; width:100%; height:280px; object-fit:contain; background:#141813; }
    .icons img { height:130px; }
    .cards img { height:420px; }
    figcaption { display:flex; justify-content:space-between; gap:8px; padding:8px 10px; font-size:11px; color:#a99b7f; }
    figcaption strong { color:#e8dfc9; font-weight:500; overflow-wrap:anywhere; }
  </style>
</head>
<body>
  <header>
    <h1>假面低语 · v0.5 美术候选</h1>
    <p>ROUTE / REST / BOSS / TAMPERED OBITUARY / UI REVIEW REQUIRED</p>
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
  "--window-size=1600,2400",
  `--screenshot=${contactOutput}`,
  pathToFileURL(path.join(previewDir, "index.html")).href,
], { encoding: "utf8", timeout: 30000 });
if (contactResult.status !== 0 || !fs.existsSync(contactOutput)) {
  throw new Error(`Failed to render contact sheet: ${contactResult.stderr || contactResult.stdout || "unknown error"}`);
}

console.log(`Generated ${assets.length} SVG and PNG assets under ${svgRoot} / ${exportRoot}`);
console.log(`Preview: ${path.join(previewDir, "index.html")}`);
console.log(`Contact sheet: ${contactOutput}`);
