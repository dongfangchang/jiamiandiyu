import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, "..");
const svgRoot = path.join(artDir, "assets", "svg", "v0.4.0");
const exportRoot = path.join(artDir, "exports", "v0.4.0");
const previewDir = path.join(artDir, "preview", "v0.4.0");

for (const folder of [
  path.join(svgRoot, "identities"),
  path.join(svgRoot, "scenes"),
  path.join(svgRoot, "icons"),
  path.join(svgRoot, "cards"),
  path.join(exportRoot, "identities"),
  path.join(exportRoot, "scenes"),
  path.join(exportRoot, "icons"),
  path.join(exportRoot, "cards"),
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
  night: "#111612",
};

const assets = [];

function svgDoc(width, height, body, extraDefs = "") {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <radialGradient id="paperWash" cx="43%" cy="34%" r="76%">
      <stop offset="0" stop-color="#F0E3C5"/>
      <stop offset=".58" stop-color="${C.paper}"/>
      <stop offset="1" stop-color="${C.paperDeep}"/>
    </radialGradient>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#10140f"/>
      <stop offset=".52" stop-color="#29302a"/>
      <stop offset="1" stop-color="#0a0d0b"/>
    </linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E6CF8F"/>
      <stop offset=".45" stop-color="${C.gold}"/>
      <stop offset="1" stop-color="#5F4927"/>
    </linearGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(28)">
      <path d="M0 0V8" stroke="${C.ink}" stroke-width=".65" opacity=".14"/>
    </pattern>
    <pattern id="crosshatch" width="10" height="10" patternUnits="userSpaceOnUse">
      <path d="M0 0L10 10M10 0L0 10" stroke="${C.bone}" stroke-width=".5" opacity=".06"/>
    </pattern>
    <filter id="grain" x="-8%" y="-8%" width="116%" height="116%">
      <feTurbulence type="fractalNoise" baseFrequency=".58" numOctaves="3" seed="41" result="noise"/>
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
    <circle cx="${width * 0.18}" cy="${height * 0.16}" r="${width * 0.28}" fill="${C.bone}" opacity=".11"/>
    <path d="M0 ${height * 0.84} C${width * 0.23} ${height * 0.76}, ${width * 0.41} ${height * 0.91}, ${width * 0.6} ${height * 0.82} S${width * 0.84} ${height * 0.77}, ${width} ${height * 0.86}"
      fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".12"/>
  `;
}

function portraitFrame() {
  return `
    <rect x="18" y="18" width="476" height="604" rx="4" fill="none" stroke="${C.ink}" stroke-width="5"/>
    <rect x="28" y="28" width="456" height="584" rx="3" fill="none" stroke="${C.gold}" stroke-width="2"/>
    <path d="M18 62 L62 18 M450 18 L494 62 M18 578 L62 622 M450 622 L494 578"
      fill="none" stroke="url(#brass)" stroke-width="5"/>
    <circle cx="256" cy="16" r="6" fill="${C.blood}" stroke="${C.ink}" stroke-width="1"/>
    <path d="M208 584 H304" stroke="${C.blood}" stroke-width="4"/>
  `;
}

function reporterPortrait() {
  return `
    <circle cx="256" cy="276" r="170" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".28"/>
    <circle cx="256" cy="276" r="145" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="3 9" opacity=".62"/>
    <path d="M74 422 C143 360 193 391 246 344 S336 282 438 358" fill="none" stroke="${C.fog}" stroke-width="22" opacity=".19"/>
    <path d="M192 180 C216 146 288 139 322 171 L302 206 H210Z" fill="${C.ink}"/>
    <path d="M171 205 H342 L314 227 H196Z" fill="${C.ink}"/>
    <ellipse cx="256" cy="267" rx="56" ry="69" fill="${C.charcoal}"/>
    <path d="M205 258 C222 220 247 209 270 214 C298 221 314 245 318 267 C293 254 274 253 252 260 C235 265 219 268 205 258Z"
      fill="${C.paperDeep}" opacity=".42"/>
    <path d="M130 493 C144 384 191 322 256 320 C325 322 370 385 385 493Z" fill="${C.ink}"/>
    <path d="M204 329 C223 357 290 357 308 329" fill="none" stroke="${C.gold}" stroke-width="2"/>
    <path d="M233 356 H279 L274 435 H238Z" fill="${C.paper}"/>
    <path d="M239 367 H273 M242 384 H270" stroke="${C.ink}" stroke-width="1.5"/>
    <path d="M303 390 L374 448" stroke="${C.ink}" stroke-width="10" stroke-linecap="round"/>
    <path d="M352 411 L402 461 L382 480 L334 429Z" fill="${C.paperDeep}" stroke="${C.ink}" stroke-width="2"/>
    <path d="M351 427 L369 445 M364 414 L382 432 M339 439 L357 457" stroke="${C.ink}" stroke-width="1"/>
    <path d="M109 340 C137 311 171 317 190 345 C166 368 137 373 109 340Z" fill="${C.bone}" stroke="${C.ink}" stroke-width="1.5" opacity=".78"/>
    <circle cx="151" cy="343" r="9" fill="${C.fog}" stroke="${C.ink}"/>
    <circle cx="151" cy="343" r="3" fill="${C.ink}"/>
    <path d="M348 211 C376 235 388 267 375 305 C365 277 352 257 330 244Z" fill="${C.blood}" opacity=".68"/>
    <path d="M84 515 C183 494 333 495 428 515" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".35"/>
  `;
}

function doctorPortrait() {
  return `
    <circle cx="256" cy="275" r="169" fill="none" stroke="${C.fog}" stroke-width="1.2" opacity=".35"/>
    <path d="M66 450 C143 381 204 420 256 367 S369 339 451 407" fill="none" stroke="${C.fog}" stroke-width="17" opacity=".2"/>
    <path d="M186 173 C211 140 287 139 316 178 L298 210 H204Z" fill="${C.ink}"/>
    <ellipse cx="256" cy="268" rx="57" ry="70" fill="${C.charcoal}"/>
    <path d="M201 258 C219 220 245 208 271 214 C302 221 319 247 322 269 C293 251 274 253 250 262 C229 269 214 268 201 258Z"
      fill="${C.paperDeep}" opacity=".34"/>
    <path d="M124 502 C138 397 188 325 256 322 C327 324 374 398 388 502Z" fill="${C.paper}" stroke="${C.ink}" stroke-width="3"/>
    <path d="M205 327 C224 360 289 360 307 327" fill="none" stroke="${C.ink}" stroke-width="2"/>
    <path d="M256 331 V501" stroke="${C.ink}" stroke-width="1.6" opacity=".58"/>
    <path d="M206 347 L188 502 M306 347 L326 502" stroke="${C.ink}" stroke-width="4"/>
    <path d="M324 388 C373 402 409 430 432 468" fill="none" stroke="${C.gold}" stroke-width="3"/>
    <circle cx="432" cy="468" r="34" fill="none" stroke="${C.gold}" stroke-width="5"/>
    <circle cx="432" cy="468" r="20" fill="${C.ink}" opacity=".7"/>
    <path d="M105 383 C117 355 139 345 161 359 L167 388 C151 410 127 411 108 395Z" fill="${C.fog}" opacity=".45" stroke="${C.ink}" stroke-width="2"/>
    <path d="M121 383 H154 V417 H121Z" fill="${C.paperDeep}" stroke="${C.ink}" stroke-width="2"/>
    <path d="M137 417 V448" stroke="${C.blood}" stroke-width="4"/>
    <circle cx="137" cy="454" r="6" fill="${C.blood}"/>
    <path d="M286 180 C308 151 342 151 361 178" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".6"/>
    <path d="M84 522 C185 491 334 496 430 524" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".35"/>
  `;
}

function gravediggerPortrait() {
  return `
    <path d="M103 239 C137 178 184 141 241 139 C307 139 354 184 386 239" fill="none" stroke="${C.fog}" stroke-width="16" opacity=".15"/>
    <circle cx="256" cy="282" r="168" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".26"/>
    <path d="M56 521 L56 394 C56 327 103 294 151 294 H163 V521Z" fill="${C.charcoal}" opacity=".32" stroke="${C.fog}" stroke-width="2"/>
    <path d="M111 340 C130 323 151 325 166 343 V381 H111Z" fill="${C.fog}" opacity=".22" stroke="${C.ink}" stroke-width="2"/>
    <path d="M176 178 C202 145 285 139 319 176 L300 214 H195Z" fill="${C.ink}"/>
    <path d="M157 206 H347 L315 232 H188Z" fill="${C.ink}"/>
    <ellipse cx="256" cy="272" rx="55" ry="69" fill="${C.charcoal}"/>
    <path d="M203 263 C225 222 249 210 274 216 C301 224 316 247 319 271 C294 253 274 253 251 261 C231 268 215 270 203 263Z"
      fill="${C.paperDeep}" opacity=".28"/>
    <path d="M120 513 C133 397 183 326 256 322 C333 326 379 398 392 513Z" fill="${C.ink}"/>
    <path d="M156 413 C209 389 304 390 358 416 L341 513 H173Z" fill="${C.charcoal}"/>
    <path d="M211 356 L197 513 M301 356 L316 513" stroke="${C.gold}" stroke-width="1.5" opacity=".65"/>
    <path d="M372 189 L419 538" stroke="${C.ink}" stroke-width="13" stroke-linecap="round"/>
    <path d="M351 225 C377 196 409 200 426 225 L418 259 C399 271 373 261 361 241Z" fill="${C.paperDeep}" stroke="${C.ink}" stroke-width="2"/>
    <path d="M377 244 L432 511" stroke="${C.gold}" stroke-width="2" opacity=".6"/>
    <path d="M104 403 C83 433 78 472 92 515" fill="none" stroke="${C.ink}" stroke-width="6"/>
    <path d="M74 413 H130 L122 465 H81Z" fill="${C.paper}" stroke="${C.ink}" stroke-width="2" opacity=".76"/>
    <circle cx="101" cy="440" r="17" fill="${C.gold}" opacity=".55"/>
    <circle cx="101" cy="440" r="6" fill="${C.blood}"/>
    <path d="M76 537 C182 505 333 508 436 538" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".38"/>
  `;
}

function identitySvg(portrait) {
  return svgDoc(512, 640, `
    ${paperBackground(512, 640)}
    <rect x="43" y="102" width="426" height="389" fill="${C.charcoal}" opacity=".075" stroke="${C.ink}" stroke-width="1.5"/>
    <g clip-path="url(#portraitClip)">${portrait}</g>
    ${portraitFrame()}
  `, `<clipPath id="portraitClip"><rect x="43" y="102" width="426" height="389"/></clipPath>`);
}

function altarScene() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#crosshatch)" opacity=".55"/>
    <path d="M0 730 C238 666 388 719 604 674 S982 686 1202 651 S1444 672 1600 633 V900 H0Z" fill="#080b09" opacity=".84"/>
    <path d="M0 798 C219 744 398 805 611 761 S967 757 1177 789 S1455 744 1600 771 V900 H0Z" fill="${C.fog}" opacity=".07"/>
    <path d="M119 720 V167 H424 V720 M1176 720 V167 H1481 V720" fill="#0a0d0b" stroke="${C.gold}" stroke-width="4" opacity=".59"/>
    <path d="M129 177 H414 V710 H129Z M1176 177 H1471 V710 H1176Z" fill="${C.fog}" opacity=".045"/>
    <path d="M375 180 C455 62 570 43 654 135 C742 38 860 60 930 169" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".24"/>
    <path d="M959 643 C1066 510 1189 427 1325 463 C1401 485 1453 544 1472 626" fill="none" stroke="${C.fog}" stroke-width="2" opacity=".2"/>
    <circle cx="800" cy="433" r="285" fill="none" stroke="${C.gold}" stroke-width="2.4" opacity=".45"/>
    <circle cx="800" cy="433" r="224" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="4 13" opacity=".58"/>
    <circle cx="800" cy="433" r="109" fill="none" stroke="${C.blood}" stroke-width="2" opacity=".48"/>
    <path d="M800 118 V748 M515 433 H1085 M591 224 L1009 642 M1009 224 L591 642"
      stroke="${C.gold}" stroke-width="1" opacity=".2"/>
    <g transform="translate(800 433)">
      <path d="M-75 -27 C-41 -82 41 -82 75 -27 C41 28 -41 28 -75 -27Z" fill="${C.bone}" opacity=".12" stroke="${C.bone}" stroke-width="2"/>
      <circle r="34" fill="${C.fog}" opacity=".3" stroke="${C.bone}"/>
      <circle r="13" fill="${C.blood}"/>
      <path d="M0 -112 V-63 M0 63 V112 M-112 0 H-63 M63 0 H112" stroke="${C.gold}" stroke-width="3" opacity=".55"/>
    </g>
    <g transform="translate(530 438) rotate(-10)">
      <rect x="-76" y="-118" width="152" height="236" fill="${C.paper}" opacity=".83" stroke="${C.gold}" stroke-width="2"/>
      <rect x="-61" y="-103" width="122" height="206" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".35"/>
      <circle cy="-12" r="27" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".48"/>
    </g>
    <g transform="translate(800 374) rotate(2)">
      <rect x="-83" y="-128" width="166" height="256" fill="${C.paper}" opacity=".92" stroke="${C.gold}" stroke-width="3"/>
      <rect x="-66" y="-111" width="132" height="222" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".36"/>
      <path d="M0 -49 L20 -14 L0 21 L-20 -14Z" fill="${C.blood}" opacity=".7"/>
    </g>
    <g transform="translate(1070 448) rotate(13)">
      <rect x="-74" y="-115" width="148" height="230" fill="${C.paper}" opacity=".83" stroke="${C.gold}" stroke-width="2"/>
      <rect x="-59" y="-100" width="118" height="200" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".33"/>
      <path d="M-26 13 L27 -18 L34 33 L-20 44Z" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".62"/>
    </g>
    <path d="M610 688 C692 642 905 646 994 689" fill="none" stroke="${C.ink}" stroke-width="15" opacity=".7"/>
    <g fill="${C.blood}" opacity=".72">
      <circle cx="549" cy="285" r="7"/><circle cx="1059" cy="278" r="6"/>
      <circle cx="529" cy="594" r="5"/><circle cx="1075" cy="603" r="5"/>
    </g>
    <rect x="34" y="34" width="1532" height="832" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".35"/>
  `);
}

function rewardScene() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#hatch)" opacity=".12"/>
    <path d="M0 610 C237 557 403 616 615 577 S974 570 1190 607 S1462 564 1600 589 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 724 C259 674 440 725 661 685 S1012 681 1240 715 S1480 686 1600 699 V900 H0Z" fill="${C.charcoal}" opacity=".35"/>
    <path d="M0 624 H1600" stroke="${C.gold}" stroke-width="3" opacity=".23"/>
    <path d="M90 129 V561 H422 V129 M1178 129 V561 H1510 V129" fill="#0c100d" stroke="${C.gold}" stroke-width="3" opacity=".48"/>
    <path d="M116 156 H397 V535 H116Z M1203 156 H1484 V535 H1203Z" fill="${C.fog}" opacity=".04"/>
    <path d="M235 602 H1365 L1270 866 H330Z" fill="${C.ink}" opacity=".84"/>
    <path d="M276 632 H1324 L1250 836 H350Z" fill="${C.charcoal}" stroke="${C.gold}" stroke-width="1.5" opacity=".6"/>
    <g transform="translate(421 505) rotate(-8)">
      <rect x="-159" y="-200" width="318" height="450" fill="${C.paper}" opacity=".88" stroke="${C.gold}" stroke-width="3"/>
      <rect x="-135" y="-176" width="270" height="402" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".32"/>
      <path d="M-82 -95 H82 M-82 -58 H82 M-82 -21 H58 M-82 135 H61" stroke="${C.ink}" stroke-width="2" opacity=".25"/>
      <circle cx="0" cy="53" r="43" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".42"/>
      <circle cx="0" cy="53" r="17" fill="${C.blood}" opacity=".55"/>
    </g>
    <g transform="translate(800 475) rotate(1)">
      <rect x="-180" y="-225" width="360" height="510" fill="${C.paper}" opacity=".96" stroke="${C.gold}" stroke-width="4"/>
      <rect x="-152" y="-197" width="304" height="454" fill="none" stroke="${C.ink}" stroke-width="1.2" opacity=".38"/>
      <path d="M-95 -120 H95 M-95 -80 H95 M-95 -40 H77" stroke="${C.ink}" stroke-width="2.2" opacity=".22"/>
      <path d="M0 0 L58 69 L0 138 L-58 69Z" fill="${C.blood}" opacity=".63"/>
      <path d="M0 35 V103 M-34 69 H34" stroke="${C.bone}" stroke-width="3" opacity=".55"/>
      <path d="M-95 166 H95" stroke="${C.ink}" stroke-width="2" opacity=".2"/>
    </g>
    <g transform="translate(1181 510) rotate(9)">
      <rect x="-158" y="-200" width="316" height="450" fill="${C.paper}" opacity=".86" stroke="${C.gold}" stroke-width="3"/>
      <rect x="-134" y="-176" width="268" height="402" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".3"/>
      <path d="M-80 -95 H80 M-80 -58 H80 M-80 -21 H58" stroke="${C.ink}" stroke-width="2" opacity=".22"/>
      <path d="M-45 89 L44 15 L60 88 L-26 142Z" fill="none" stroke="${C.fog}" stroke-width="3" opacity=".5"/>
    </g>
    <path d="M612 604 C765 577 901 578 1057 603" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".27"/>
    <rect x="34" y="34" width="1532" height="832" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".34"/>
  `);
}

function iconSvg(art) {
  return svgDoc(128, 128, `
    <rect width="128" height="128" rx="16" fill="#181c17" stroke="${C.gold}" stroke-width="2"/>
    <rect x="8" y="8" width="112" height="112" rx="10" fill="none" stroke="${C.paperDeep}" stroke-width="1" opacity=".4"/>
    ${art}
  `);
}

function upgradeIcon(rank) {
  const rings = Array.from({ length: rank }, (_, index) => {
    const radius = 21 + index * 10;
    return `<circle cx="64" cy="63" r="${radius}" fill="none" stroke="${C.gold}" stroke-width="${index === rank - 1 ? 3 : 1.4}" opacity="${index === rank - 1 ? .9 : .48}"/>`;
  }).join("");
  return iconSvg(`
    ${rings}
    <path d="M64 29 L78 42 L94 43 L88 58 L97 72 L81 78 L72 94 L58 85 L42 94 L35 78 L19 71 L29 57 L22 42 L39 41Z"
      fill="${rank >= 2 ? C.blood : C.ink}" stroke="${C.gold}" stroke-width="2" opacity=".9"/>
    <path d="M64 43 L73 55 L67 71 L55 71 L49 55Z" fill="${C.bone}" opacity="${rank === 3 ? .9 : .62}"/>
    <path d="M64 94 V111" stroke="${C.gold}" stroke-width="3" opacity=".6"/>
  `);
}

function shardIcon() {
  return iconSvg(`
    <path d="M35 24 L77 16 L63 55 L101 72 L70 80 L56 109 L43 73 L18 60 L52 51Z"
      fill="${C.paper}" stroke="${C.ink}" stroke-width="2.5" opacity=".9"/>
    <path d="M35 24 L52 51 L77 16 M52 51 L63 55 L43 73 M63 55 L70 80" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".8"/>
    <path d="M56 63 L69 68 L62 83 L49 78Z" fill="${C.blood}" opacity=".72"/>
  `);
}

function ticketIcon() {
  return iconSvg(`
    <g transform="rotate(-9 64 64)">
      <rect x="22" y="28" width="84" height="72" rx="5" fill="${C.paper}" stroke="${C.ink}" stroke-width="3"/>
      <rect x="29" y="35" width="70" height="58" fill="none" stroke="${C.gold}" stroke-width="1.5"/>
      <circle cx="64" cy="64" r="21" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".55"/>
      <path d="M64 45 L72 60 L65 81 L56 61Z" fill="${C.blood}" opacity=".68"/>
      <path d="M34 42 H45 M83 42 H94 M34 87 H45 M83 87 H94" stroke="${C.ink}" stroke-width="2" opacity=".38"/>
    </g>
  `);
}

function cardBack() {
  return svgDoc(512, 720, `
    <rect width="512" height="720" fill="#121612"/>
    <rect width="512" height="720" fill="url(#crosshatch)" opacity=".7"/>
    <rect x="18" y="18" width="476" height="684" rx="5" fill="none" stroke="${C.ink}" stroke-width="6"/>
    <rect x="28" y="28" width="456" height="664" rx="3" fill="${C.paperDeep}" opacity=".14" stroke="${C.gold}" stroke-width="2"/>
    <path d="M256 71 L422 360 L256 649 L90 360Z" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".32"/>
    <circle cx="256" cy="360" r="165" fill="none" stroke="${C.gold}" stroke-width="1.5" opacity=".48"/>
    <circle cx="256" cy="360" r="132" fill="none" stroke="${C.blood}" stroke-width="1.5" stroke-dasharray="3 11" opacity=".55"/>
    <circle cx="256" cy="360" r="94" fill="#080b09" stroke="${C.gold}" stroke-width="2"/>
    <path d="M256 230 C207 230 179 269 183 325 C187 380 217 414 256 441 C295 414 325 380 329 325 C333 269 305 230 256 230Z"
      fill="${C.bone}" opacity=".12" stroke="${C.bone}" stroke-width="2"/>
    <path d="M212 321 C229 305 244 307 256 323 C268 307 283 305 300 321 C282 337 266 338 256 326 C246 338 230 337 212 321Z" fill="${C.paper}" opacity=".7"/>
    <path d="M256 234 C271 280 242 304 259 339 C274 371 240 403 256 438" fill="none" stroke="${C.blood}" stroke-width="3"/>
    <path d="M256 74 V114 M256 606 V646 M91 360 H131 M381 360 H421" stroke="${C.gold}" stroke-width="3" opacity=".54"/>
    <path d="M98 89 L126 61 M414 89 L386 61 M98 631 L126 659 M414 631 L386 659" stroke="${C.ink}" stroke-width="4" opacity=".7"/>
    <circle cx="256" cy="57" r="7" fill="${C.blood}" stroke="${C.gold}" stroke-width="1.5"/>
    <circle cx="256" cy="663" r="7" fill="${C.blood}" stroke="${C.gold}" stroke-width="1.5"/>
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
    svg: `assets/svg/v0.4.0/${relativeSvg.split(path.sep).join("/")}`,
    png: `exports/v0.4.0/${relativePng.split(path.sep).join("/")}`,
    width,
    height,
  });
}

writeAsset("identity.reporter", "identity", "identities/card-identity-reporter.svg", 512, 640, identitySvg(reporterPortrait()));
writeAsset("identity.doctor", "identity", "identities/card-identity-doctor.svg", 512, 640, identitySvg(doctorPortrait()));
writeAsset("identity.gravedigger", "identity", "identities/card-identity-gravedigger.svg", 512, 640, identitySvg(gravediggerPortrait()));
writeAsset("scene.gacha.altar", "scene", "scenes/gacha-altar.svg", 1600, 900, altarScene());
writeAsset("scene.reward.archive", "scene", "scenes/reward-archive.svg", 1600, 900, rewardScene());
writeAsset("status.upgrade_1", "icon", "icons/upgrade-1.svg", 128, 128, upgradeIcon(1));
writeAsset("status.upgrade_2", "icon", "icons/upgrade-2.svg", 128, 128, upgradeIcon(2));
writeAsset("status.upgrade_3", "icon", "icons/upgrade-3.svg", 128, 128, upgradeIcon(3));
writeAsset("resource.card_shard", "icon", "icons/card-shard.svg", 128, 128, shardIcon());
writeAsset("resource.divination_ticket", "icon", "icons/divination-ticket.svg", 128, 128, ticketIcon());
writeAsset("card.back.sealed_omen", "card-back", "cards/card-back-sealed-omen.svg", 512, 720, cardBack());

fs.writeFileSync(
  path.join(exportRoot, "render-manifest.json"),
  JSON.stringify({ version: "v0.4.0", assets }, null, 2) + "\n",
  "utf8",
);

const groups = [
  ["身份肖像", assets.filter((asset) => asset.type === "identity")],
  ["场景", assets.filter((asset) => asset.type === "scene")],
  ["升级、碎片与祈愿图标", assets.filter((asset) => asset.type === "icon")],
  ["卡背", assets.filter((asset) => asset.type === "card-back")],
];

const sections = groups.map(([title, items]) => `
  <section>
    <h2>${title}</h2>
    <div class="grid ${title === "场景" ? "scenes" : ""} ${title === "升级、碎片与祈愿图标" ? "icons" : ""}">
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
  <title>假面低语 v0.4.0 · 美术候选</title>
  <style>
    :root { color-scheme:dark; --ink:#10130f; --paper:#d8c29a; --gold:#b99750; --blood:#7a2828; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--ink); color:#e8dfc9; font-family:"Noto Serif SC","Songti SC",Georgia,serif; }
    header { padding:40px 5vw 24px; border-bottom:1px solid #5a4a31; }
    h1 { margin:0; font-size:48px; letter-spacing:.12em; }
    header p { color:var(--gold); letter-spacing:.14em; }
    section { padding:20px 4vw 24px; }
    h2 { color:var(--gold); font-size:19px; letter-spacing:.16em; border-bottom:1px solid #453b29; padding-bottom:8px; }
    .grid { display:grid; grid-template-columns:repeat(3,1fr); gap:14px; }
    .grid.scenes { grid-template-columns:repeat(2,1fr); }
    .grid.icons { grid-template-columns:repeat(5,1fr); }
    figure { margin:0; background:#1a1e19; border:1px solid #473e2c; }
    img { display:block; width:100%; height:200px; object-fit:contain; background:#141813; }
    .scenes img { height:230px; }
    figcaption { display:flex; justify-content:space-between; gap:8px; padding:8px 10px; font-size:11px; color:#a99b7f; }
    figcaption strong { color:#e8dfc9; font-weight:500; overflow-wrap:anywhere; }
  </style>
</head>
<body>
  <header>
    <h1>假面低语 · v0.4 美术候选</h1>
    <p>IDENTITY / REWARD / DIVINATION / UPGRADE / UI REVIEW REQUIRED</p>
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
  "--window-size=1600,1600",
  `--screenshot=${contactOutput}`,
  pathToFileURL(path.join(previewDir, "index.html")).href,
], { encoding: "utf8", timeout: 30000 });
if (contactResult.status !== 0 || !fs.existsSync(contactOutput)) {
  throw new Error(`Failed to render contact sheet: ${contactResult.stderr || contactResult.stdout || "unknown error"}`);
}

console.log(`Generated ${assets.length} SVG and PNG assets under ${svgRoot} / ${exportRoot}`);
console.log(`Preview: ${path.join(previewDir, "index.html")}`);
console.log(`Contact sheet: ${contactOutput}`);
