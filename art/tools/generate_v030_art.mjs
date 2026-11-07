import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, "..");
const svgRoot = path.join(artDir, "assets", "svg", "v0.3.0");
const exportRoot = path.join(artDir, "exports", "v0.3.0");
const previewDir = path.join(artDir, "preview", "v0.3.0");

for (const folder of [
  path.join(svgRoot, "enemies"),
  path.join(svgRoot, "scenes"),
  path.join(svgRoot, "cards"),
  path.join(svgRoot, "status"),
  path.join(exportRoot, "enemies"),
  path.join(exportRoot, "scenes"),
  path.join(exportRoot, "cards"),
  path.join(exportRoot, "status"),
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
  night: "#121714",
};

function svgDoc(width, height, body, defs = "") {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <radialGradient id="paperWash" cx="45%" cy="38%" r="72%">
      <stop offset="0" stop-color="#EFE1C0"/>
      <stop offset=".58" stop-color="${C.paper}"/>
      <stop offset="1" stop-color="${C.paperDeep}"/>
    </radialGradient>
    <linearGradient id="nightWash" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#111612"/>
      <stop offset=".55" stop-color="#28302a"/>
      <stop offset="1" stop-color="#0d110f"/>
    </linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E4CA84"/>
      <stop offset=".5" stop-color="${C.gold}"/>
      <stop offset="1" stop-color="#69532D"/>
    </linearGradient>
    <pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(27)">
      <path d="M0 0V8" stroke="${C.ink}" stroke-width=".7" opacity=".15"/>
    </pattern>
    <pattern id="crosshatch" width="9" height="9" patternUnits="userSpaceOnUse">
      <path d="M0 0L9 9M9 0L0 9" stroke="${C.bone}" stroke-width=".55" opacity=".07"/>
    </pattern>
    <filter id="grain" x="-5%" y="-5%" width="110%" height="110%">
      <feTurbulence type="fractalNoise" baseFrequency=".55" numOctaves="3" seed="31" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
      <feComponentTransfer in="mono" result="faint">
        <feFuncA type="table" tableValues="0 .10"/>
      </feComponentTransfer>
      <feBlend in="SourceGraphic" in2="faint" mode="multiply"/>
    </filter>
    <filter id="rough">
      <feTurbulence type="fractalNoise" baseFrequency=".018" numOctaves="2" seed="8" result="n"/>
      <feDisplacementMap in="SourceGraphic" in2="n" scale="1.5" xChannelSelector="R" yChannelSelector="G"/>
    </filter>
    ${defs}
  </defs>
  ${body}
</svg>
`;
}

function paperBackground(width, height) {
  return `
    <rect width="${width}" height="${height}" fill="url(#paperWash)" filter="url(#grain)"/>
    <rect width="${width}" height="${height}" fill="url(#hatch)"/>
    <circle cx="${width * 0.28}" cy="${height * 0.22}" r="${width * 0.18}" fill="${C.bone}" opacity=".11"/>
    <path d="M0 ${height * 0.88} C${width * 0.2} ${height * 0.8}, ${width * 0.38} ${height * 0.93}, ${width * 0.56} ${height * 0.84} S${width * 0.82} ${height * 0.78}, ${width} ${height * 0.86}"
      fill="none" stroke="${C.ink}" stroke-width="1" opacity=".13"/>
  `;
}

function enemyBackground() {
  return `
    <rect width="900" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="900" height="900" fill="url(#crosshatch)"/>
    <circle cx="450" cy="410" r="310" fill="none" stroke="${C.fog}" stroke-width="1.4" opacity=".36"/>
    <circle cx="450" cy="410" r="250" fill="none" stroke="${C.gold}" stroke-width=".9" stroke-dasharray="3 12" opacity=".34"/>
    <path d="M0 744 C148 670 282 718 430 674 S700 680 900 704 V900 H0Z" fill="#080b09" opacity=".78"/>
    <path d="M0 808 C190 756 352 817 545 772 S768 764 900 782 V900 H0Z" fill="${C.fog}" opacity=".08"/>
    <rect x="35" y="35" width="830" height="830" fill="none" stroke="${C.gold}" stroke-width="1.2" opacity=".38"/>
  `;
}

function weepingTenant() {
  return svgDoc(900, 900, `
    ${enemyBackground()}
    <path d="M188 795 V166 H712 V795" fill="none" stroke="${C.gold}" stroke-width="8" opacity=".48"/>
    <path d="M235 795 V225 H665 V795" fill="${C.ink}" opacity=".45"/>
    <path d="M335 270 C355 191 401 153 460 163 C523 176 556 225 559 302 L525 372 H354Z" fill="#080b09"/>
    <path d="M315 373 C343 322 390 303 455 306 C522 307 572 339 603 390 L574 782 H324Z" fill="#080b09"/>
    <path d="M351 294 C372 249 403 237 437 243 C476 249 501 276 510 311 C472 294 434 292 397 304 C379 310 365 305 351 294Z" fill="${C.paperDeep}" opacity=".22"/>
    <path d="M383 345 C410 364 452 367 487 346" fill="none" stroke="${C.fog}" stroke-width="2" opacity=".7"/>
    <g fill="none" stroke="${C.fog}" stroke-width="4" opacity=".58">
      <path d="M392 370 C367 438 401 510 380 574 C365 620 384 673 352 724"/>
      <path d="M414 372 C397 444 427 489 408 551 C392 613 425 669 402 739"/>
      <path d="M443 374 C430 430 457 483 445 536 C430 604 461 682 448 750"/>
      <path d="M475 371 C488 432 458 495 481 548 C501 599 477 664 502 730"/>
      <path d="M506 371 C525 435 497 490 520 552 C539 603 510 658 534 716"/>
    </g>
    <path d="M405 365 C419 383 419 426 401 450 C390 424 390 390 405 365Z" fill="${C.blood}" opacity=".78"/>
    <path d="M484 362 C496 386 493 426 477 448 C468 420 469 388 484 362Z" fill="${C.blood}" opacity=".7"/>
    <path d="M326 468 C278 492 244 548 233 626 M579 463 C634 490 662 541 671 619" fill="none" stroke="#080b09" stroke-width="24" stroke-linecap="round"/>
    <g fill="${C.bone}" opacity=".62">
      <path d="M218 626 C234 612 256 616 264 636 L255 704 L228 703Z"/>
      <path d="M642 617 C660 606 680 613 686 634 L678 701 L650 701Z"/>
    </g>
    <path d="M208 706 L277 706 M620 704 L690 704" stroke="${C.blood}" stroke-width="5" opacity=".65"/>
    <path d="M248 447 C315 422 374 435 430 456 C521 490 615 463 690 427" fill="none" stroke="${C.fog}" stroke-width="15" opacity=".12"/>
  `);
}

function candleMoth() {
  return svgDoc(900, 900, `
    ${enemyBackground()}
    <g transform="translate(450 408)">
      <path d="M-34 -202 C-72 -136 -82 -58 -54 -8 L-6 33 L-43 249 L0 212 L43 249 L6 33 L54 -8 C82 -58 72 -136 34 -202 L0 -156Z" fill="#080b09"/>
      <path d="M-36 -107 C-161 -225 -327 -160 -355 4 C-307 7 -276 54 -259 111 C-201 74 -151 95 -111 139 C-84 112 -61 107 -35 118Z" fill="#0b0e0c" stroke="${C.fog}" stroke-width="3" opacity=".92"/>
      <path d="M36 -107 C161 -225 327 -160 355 4 C307 7 276 54 259 111 C201 74 151 95 111 139 C84 112 61 107 35 118Z" fill="#0b0e0c" stroke="${C.fog}" stroke-width="3" opacity=".92"/>
      <path d="M-37 117 C-141 160 -210 249 -223 375 C-161 335 -111 340 -72 368 C-58 278 -28 213 0 190 C28 213 58 278 72 368 C111 340 161 335 223 375 C210 249 141 160 37 117Z" fill="#080b09" stroke="${C.paperDeep}" stroke-width="2" opacity=".86"/>
      <path d="M-355 4 C-253 17 -207 63 -183 113 M355 4 C253 17 207 63 183 113" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".42"/>
      <g fill="none" stroke="${C.gold}" stroke-width="1" opacity=".34">
        <circle cx="-218" cy="-57" r="76"/><circle cx="218" cy="-57" r="76"/>
        <circle cx="-139" cy="210" r="56"/><circle cx="139" cy="210" r="56"/>
      </g>
      <path d="M0 -126 C-37 -85 -39 -36 -18 -8 C-9 4 9 4 18 -8 C39 -36 37 -85 0 -126Z" fill="${C.bone}" opacity=".92"/>
      <path d="M0 -92 C-17 -64 -17 -31 -6 -12 C0 -3 0 -3 6 -12 C17 -31 17 -64 0 -92Z" fill="${C.blood}"/>
      <circle cx="-14" cy="-28" r="8" fill="${C.blood}"/><circle cx="14" cy="-28" r="8" fill="${C.blood}"/>
      <path d="M-84 -184 L-34 -110 M84 -184 L34 -110" stroke="${C.fog}" stroke-width="3" opacity=".7"/>
      <circle cx="-16" cy="-196" r="5" fill="${C.gold}"/><circle cx="16" cy="-196" r="5" fill="${C.gold}"/>
    </g>
    <path d="M86 755 C252 716 377 762 470 731 S718 725 823 750" fill="none" stroke="${C.fog}" stroke-width="18" opacity=".14"/>
  `);
}

function mirrorHound() {
  return svgDoc(900, 900, `
    ${enemyBackground()}
    <g transform="translate(450 447)">
      <path d="M-332 -198 L-262 -238 L-190 -220 L-104 -179 L-62 -121 L-31 -58 L-68 13 L-19 76 L-66 207 L-184 289 L-305 260 L-360 128Z"
        fill="${C.fog}" opacity=".08" stroke="${C.fog}" stroke-width="2"/>
      <path d="M296 -217 L376 -180 L408 -82 L381 17 L420 98 L378 243 L270 330 L162 287 L95 208 L125 90 L74 9 L107 -111 L194 -214Z"
        fill="${C.fog}" opacity=".07" stroke="${C.fog}" stroke-width="2"/>
      <path d="M-270 140 C-231 44 -162 -26 -71 -66 C38 -113 172 -113 274 -49 C321 -18 337 38 309 82 L243 104 L214 271 L112 271 L93 151 L-89 157 L-114 277 L-214 270 L-192 132Z"
        fill="#070a08" stroke="${C.paperDeep}" stroke-width="2"/>
      <path d="M-49 -58 L23 -136 L64 -96 L17 -36Z" fill="#070a08"/>
      <path d="M169 -79 L231 -148 L277 -100 L226 -36Z" fill="#070a08"/>
      <path d="M-46 -49 L0 -90 L36 -66 L5 -31Z" fill="${C.blood}" opacity=".67"/>
      <path d="M181 -70 L218 -112 L248 -84 L219 -49Z" fill="${C.blood}" opacity=".62"/>
      <path d="M237 94 C295 117 341 99 375 57 L398 77 C354 145 279 161 211 132Z" fill="#070a08"/>
      <path d="M349 79 C381 47 381 16 355 -14" fill="none" stroke="${C.ink}" stroke-width="15" stroke-linecap="round"/>
      <path d="M-47 9 C11 -3 66 5 108 35 M115 -4 C180 5 226 34 252 78" fill="none" stroke="${C.fog}" stroke-width="6" opacity=".63"/>
      <path d="M-20 39 L20 39 L12 68 L-13 68Z" fill="${C.bone}" opacity=".68"/>
      <path d="M188 -4 L221 -19 L231 4 L202 19Z" fill="${C.bone}" opacity=".62"/>
      <g fill="none" stroke="${C.bone}" stroke-width="2" opacity=".45">
        <path d="M-303 249 L-252 175 L-191 232 L-123 161"/>
        <path d="M243 306 L302 237 L352 282 L407 214"/>
        <path d="M-345 -7 L-290 -31 L-257 12 L-214 -17"/>
        <path d="M293 -187 L330 -134 L378 -157 L402 -98"/>
      </g>
      <g fill="${C.blood}" opacity=".62">
        <path d="M-320 89 L-292 72 L-302 109Z"/>
        <path d="M357 -159 L384 -145 L365 -122Z"/>
        <path d="M-162 277 L-134 257 L-127 289Z"/>
      </g>
    </g>
    <path d="M97 748 C266 718 383 755 484 724 S724 726 815 751" fill="none" stroke="${C.fog}" stroke-width="20" opacity=".13"/>
  `);
}

function battleBackground() {
  return svgDoc(1600, 900, `
    <rect width="1600" height="900" fill="url(#nightWash)" filter="url(#grain)"/>
    <rect width="1600" height="900" fill="url(#crosshatch)" opacity=".5"/>
    <path d="M0 570 H1600 V900 H0Z" fill="#0a0c0b"/>
    <path d="M0 570 L1600 520 V900 H0Z" fill="${C.ink}" opacity=".74"/>
    <path d="M0 568 H1600" stroke="${C.gold}" stroke-width="2" opacity=".25"/>
    <path d="M30 570 L223 900 M1570 570 L1378 900 M380 900 L665 570 M1220 900 L934 570 M800 570 V900" stroke="${C.fog}" stroke-width="1" opacity=".09"/>
    <path d="M90 570 V77 H434 V570 M1166 570 V77 H1510 V570" fill="#0a0c0b" stroke="${C.gold}" stroke-width="4" opacity=".75"/>
    <path d="M1166 77 H1510 V570 H1166Z" fill="${C.fog}" opacity=".08"/>
    <path d="M1174 85 H1502 V562 H1174Z M1302 85 V562 M1174 324 H1502" fill="none" stroke="${C.fog}" stroke-width="2" opacity=".32"/>
    <path d="M90 77 H434 V570 H90Z" fill="${C.fog}" opacity=".055"/>
    <path d="M98 85 H426 V562 H98Z M237 85 V562 M98 326 H426" fill="none" stroke="${C.fog}" stroke-width="2" opacity=".25"/>
    <path d="M0 0 H1600 V900 H0Z" fill="url(#hatch)" opacity=".13"/>
    <path d="M434 77 C475 31 548 24 602 72 C650 22 724 31 761 80 L761 570 H434Z" fill="#080a09" opacity=".68"/>
    <path d="M839 80 C879 31 948 31 992 78 C1040 22 1111 29 1158 80 L1158 570 H839Z" fill="#080a09" opacity=".58"/>
    <g fill="none" stroke="${C.gold}" stroke-width="1" opacity=".2">
      <path d="M466 177 C518 146 563 183 604 151 S696 158 735 190"/>
      <path d="M863 177 C915 146 960 183 1001 151 S1093 158 1132 190"/>
      <path d="M0 476 C165 438 300 479 443 447 S736 454 900 481 S1272 431 1600 469"/>
    </g>
    <g opacity=".34">
      <path d="M310 806 C390 752 466 771 532 735 C613 691 702 729 760 701 C834 664 932 684 1002 728 C1080 777 1156 756 1268 804" fill="none" stroke="${C.fog}" stroke-width="34"/>
      <path d="M0 843 C213 791 380 835 562 802 S932 795 1122 830 S1432 793 1600 819 V900 H0Z" fill="${C.fog}" opacity=".12"/>
    </g>
    <g opacity=".58">
      <path d="M804 600 V786" stroke="${C.ink}" stroke-width="13"/>
      <path d="M729 789 H879 L851 842 H757Z" fill="${C.ink}"/>
      <path d="M804 635 C772 613 754 575 762 538 C778 549 794 556 808 562 C821 527 849 505 879 508 C883 547 861 585 823 611 Z" fill="${C.bone}" opacity=".16"/>
      <circle cx="817" cy="577" r="23" fill="${C.gold}" opacity=".5"/>
      <circle cx="817" cy="577" r="7" fill="${C.blood}"/>
    </g>
    <path d="M0 0 H1600 V900 H0Z" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".22"/>
  `);
}

const cardSpecs = [
  {
    file: "card-skill-ink-dart.svg",
    id: "card.skill.ink_dart",
    art: `
      <circle cx="256" cy="196" r="135" fill="none" stroke="${C.fog}" stroke-width="1.2" opacity=".28"/>
      <path d="M91 306 C157 264 208 226 262 190 L426 83" fill="none" stroke="${C.gold}" stroke-width="3" opacity=".34"/>
      <path d="M89 302 C112 260 138 238 174 227 C206 217 229 225 251 244 C236 272 215 287 185 294 C148 302 119 309 89 302Z" fill="${C.ink}"/>
      <path d="M184 239 C240 226 322 199 422 91 C361 163 302 212 221 273" fill="${C.ink}"/>
      <path d="M422 91 L386 109 L400 122 L371 124" fill="none" stroke="${C.blood}" stroke-width="5"/>
      <path d="M145 252 C174 246 197 250 219 266" fill="none" stroke="${C.bone}" stroke-width="2" opacity=".65"/>
      <g fill="${C.blood}">
        <circle cx="380" cy="128" r="5"/><circle cx="346" cy="157" r="4"/><circle cx="311" cy="187" r="3"/>
      </g>
      <path d="M78 335 C150 318 205 331 260 313 S371 294 443 314" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".4"/>
    `,
  },
  {
    file: "card-skill-paper-guard.svg",
    id: "card.skill.paper_guard",
    art: `
      <path d="M256 35 L410 91 V198 C410 292 338 354 256 380 C174 354 102 292 102 198 V91Z" fill="${C.bone}" opacity=".2" stroke="${C.ink}" stroke-width="4"/>
      <g fill="${C.paper}" stroke="${C.ink}" stroke-width="2">
        <path d="M156 73 L283 42 L308 288 L177 323Z"/>
        <path d="M221 40 L353 72 L341 315 L210 291Z"/>
      </g>
      <g fill="none" stroke="${C.ink}" stroke-width="2" opacity=".58">
        <path d="M197 103 L266 87 M202 134 L270 118 M207 165 L275 149"/>
        <path d="M249 86 L314 102 M254 116 L320 132 M259 146 L325 162"/>
      </g>
      <path d="M256 107 L299 146 L286 216 L256 246 L226 216 L213 146Z" fill="none" stroke="${C.gold}" stroke-width="4"/>
      <circle cx="256" cy="174" r="19" fill="none" stroke="${C.blood}" stroke-width="4"/>
      <path d="M118 311 C177 289 227 306 278 288 S368 273 407 300" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".52"/>
    `,
  },
  {
    file: "card-skill-calm-breath.svg",
    id: "card.skill.calm_breath",
    art: `
      <circle cx="256" cy="200" r="145" fill="none" stroke="${C.gold}" stroke-width="1" stroke-dasharray="4 11" opacity=".52"/>
      <path d="M116 245 C171 158 225 120 296 124 C352 128 393 166 404 223 C374 199 342 190 307 197 C260 206 225 243 189 278 C163 265 140 254 116 245Z" fill="${C.ink}"/>
      <path d="M149 216 C180 190 213 178 246 185" fill="none" stroke="${C.bone}" stroke-width="4" opacity=".52"/>
      <path d="M331 146 C378 114 423 132 428 181 C408 166 386 164 361 179" fill="none" stroke="${C.fog}" stroke-width="16" stroke-linecap="round" opacity=".55"/>
      <path d="M94 284 C166 247 228 250 274 277 S367 296 426 255" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".35"/>
      <path d="M200 312 C238 287 281 291 312 320" fill="none" stroke="${C.blood}" stroke-width="3" opacity=".5"/>
      <circle cx="256" cy="200" r="56" fill="none" stroke="${C.bone}" stroke-width="1.5" opacity=".35"/>
    `,
  },
  {
    file: "card-skill-focus.svg",
    id: "card.skill.focus",
    art: `
      <circle cx="256" cy="200" r="150" fill="none" stroke="${C.fog}" stroke-width="1" opacity=".35"/>
      <circle cx="256" cy="200" r="105" fill="none" stroke="${C.gold}" stroke-width="1.2" stroke-dasharray="3 8" opacity=".65"/>
      <circle cx="256" cy="200" r="62" fill="none" stroke="${C.ink}" stroke-width="3"/>
      <path d="M256 52 V346 M108 200 H404" stroke="${C.ink}" stroke-width="1.2" opacity=".34"/>
      <path d="M256 130 C222 160 206 190 210 221 C215 264 239 286 256 297 C273 286 297 264 302 221 C306 190 290 160 256 130Z" fill="${C.bone}" opacity=".2"/>
      <circle cx="256" cy="213" r="27" fill="${C.ink}"/>
      <circle cx="256" cy="213" r="8" fill="${C.bone}"/>
      <path d="M256 73 C273 102 274 132 256 155 C238 132 239 102 256 73Z" fill="${C.blood}" opacity=".76"/>
      <path d="M114 200 L142 186 M398 200 L370 214" stroke="${C.gold}" stroke-width="4"/>
    `,
  },
  {
    file: "card-skill-insight.svg",
    id: "card.skill.insight",
    art: `
      <path d="M72 105 L251 66 L252 324 L80 347Z" fill="${C.bone}" opacity=".18" stroke="${C.ink}" stroke-width="3"/>
      <path d="M435 104 L260 65 L260 323 L428 347Z" fill="${C.bone}" opacity=".18" stroke="${C.ink}" stroke-width="3"/>
      <path d="M84 136 L237 108 M88 176 L231 151 M94 216 L220 195 M430 136 L278 108 M426 176 L283 151 M420 216 L294 195" stroke="${C.ink}" stroke-width="2" opacity=".42"/>
      <path d="M146 207 C188 161 250 156 303 197 C319 210 333 225 342 240 C308 275 270 294 227 288 C183 282 152 248 146 207Z" fill="${C.bone}" opacity=".68" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="244" cy="221" r="34" fill="${C.fog}" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="244" cy="221" r="14" fill="${C.ink}"/>
      <path d="M347 268 L404 315" stroke="${C.ink}" stroke-width="12" stroke-linecap="round"/>
      <path d="M397 309 L420 329" stroke="${C.gold}" stroke-width="6" stroke-linecap="round"/>
      <path d="M403 114 L435 94" stroke="${C.blood}" stroke-width="3" opacity=".6"/>
    `,
  },
  {
    file: "card-skill-omen.svg",
    id: "card.skill.omen",
    art: `
      <circle cx="256" cy="183" r="123" fill="${C.bone}" opacity=".12" stroke="${C.gold}" stroke-width="1.2" stroke-dasharray="3 9"/>
      <path d="M167 194 C177 125 218 87 271 83 C330 78 370 118 380 181 C342 158 310 170 286 203 C258 241 220 252 177 231 C168 219 164 207 167 194Z" fill="${C.ink}"/>
      <path d="M379 144 C421 127 443 86 430 50 C399 61 378 87 369 116Z" fill="${C.ink}"/>
      <path d="M181 219 C219 215 241 226 254 250 C231 266 203 268 177 250Z" fill="${C.ink}"/>
      <circle cx="337" cy="164" r="7" fill="${C.blood}"/>
      <path d="M334 166 L356 178 L343 187Z" fill="${C.blood}"/>
      <g fill="${C.blood}" opacity=".72">
        <path d="M118 303 L144 272 L166 310Z"/>
        <circle cx="396" cy="268" r="8"/>
        <circle cx="349" cy="322" r="5"/>
        <circle cx="89" cy="145" r="4"/>
      </g>
      <path d="M91 320 C150 300 207 312 256 288 S359 279 424 303" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".35"/>
    `,
  },
  {
    file: "card-skill-whisper.svg",
    id: "card.skill.whisper",
    art: `
      <path d="M116 67 C164 34 230 37 266 75 C298 109 302 157 281 196 C260 235 215 263 169 251 C132 241 107 210 100 172 C122 186 144 187 164 177 C132 143 119 104 116 67Z" fill="${C.ink}" opacity=".92"/>
      <path d="M262 198 C299 180 315 211 300 247 C286 279 246 299 205 307" fill="none" stroke="${C.blood}" stroke-width="18" stroke-linecap="round" opacity=".55"/>
      <path d="M287 174 C352 147 408 155 438 192 C401 188 375 200 358 226 C384 230 404 245 413 269 C370 254 335 267 307 294" fill="none" stroke="${C.fog}" stroke-width="3" opacity=".72"/>
      <path d="M330 136 C391 115 443 123 468 156" fill="none" stroke="${C.gold}" stroke-width="2" opacity=".45"/>
      <circle cx="174" cy="120" r="9" fill="${C.blood}"/>
      <path d="M151 187 C174 200 197 198 216 183" fill="none" stroke="${C.blood}" stroke-width="4"/>
      <path d="M381 228 C401 232 416 241 425 255" fill="none" stroke="${C.blood}" stroke-width="5"/>
      <g fill="${C.blood}" opacity=".6">
        <circle cx="430" cy="201" r="4"/><circle cx="450" cy="178" r="3"/><circle cx="404" cy="166" r="3"/>
      </g>
    `,
  },
  {
    file: "card-skill-second-look.svg",
    id: "card.skill.second_look",
    art: `
      <g fill="none" stroke="${C.ink}" stroke-width="5">
        <rect x="71" y="167" width="140" height="59" rx="29" transform="rotate(-8 141 196)"/>
        <rect x="300" y="166" width="140" height="59" rx="29" transform="rotate(8 370 196)"/>
        <path d="M207 192 C222 178 236 178 249 192"/>
      </g>
      <path d="M97 186 C131 137 185 137 217 180 C184 220 134 228 97 186Z" fill="${C.bone}" opacity=".72" stroke="${C.ink}" stroke-width="3"/>
      <path d="M293 181 C330 136 384 140 419 188 C381 225 330 225 293 181Z" fill="${C.bone}" opacity=".72" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="158" cy="183" r="24" fill="${C.fog}" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="353" cy="186" r="24" fill="${C.fog}" stroke="${C.ink}" stroke-width="3"/>
      <circle cx="158" cy="183" r="9" fill="${C.ink}"/>
      <circle cx="353" cy="186" r="9" fill="${C.ink}"/>
      <path d="M256 84 V315" stroke="${C.gold}" stroke-width="1" stroke-dasharray="4 9" opacity=".55"/>
      <path d="M256 112 C278 141 279 172 256 198 C233 172 234 141 256 112Z" fill="${C.blood}" opacity=".65"/>
      <path d="M113 295 C182 273 231 293 284 270 S378 263 428 284" fill="none" stroke="${C.ink}" stroke-width="2" opacity=".38"/>
    `,
  },
];

function writeEnemy(file, body) {
  fs.writeFileSync(path.join(svgRoot, "enemies", file), body, "utf8");
}

function writeCard(spec) {
  const doc = svgDoc(512, 400, `
    ${paperBackground(512, 400)}
    <rect x="8" y="8" width="496" height="384" fill="none" stroke="${C.ink}" stroke-width="1" opacity=".2"/>
    ${spec.art}
  `);
  fs.writeFileSync(path.join(svgRoot, "cards", spec.file), doc, "utf8");
}

const assets = [];
const writeEnemyAsset = (id, filename, body) => {
  writeEnemy(filename, body);
  assets.push({
    id,
    type: "enemy",
    svg: `assets/svg/v0.3.0/enemies/${filename}`,
    png: `exports/v0.3.0/enemies/${filename.replace(/\.svg$/, ".png")}`,
    width: 900,
    height: 900,
  });
};

writeEnemyAsset("enemy.weeping_tenant", "enemy-weeping-tenant.svg", weepingTenant());
writeEnemyAsset("enemy.candle_moth", "enemy-candle-moth.svg", candleMoth());
writeEnemyAsset("enemy.mirror_hound", "enemy-mirror-hound.svg", mirrorHound());

const battleBackgroundSvg = battleBackground();
fs.writeFileSync(path.join(svgRoot, "scenes", "battle-tingen-old-house.svg"), battleBackgroundSvg, "utf8");
assets.push({
  id: "scene.battle.tingen_old_house",
  type: "scene",
  svg: "assets/svg/v0.3.0/scenes/battle-tingen-old-house.svg",
  png: "exports/v0.3.0/scenes/battle-tingen-old-house.png",
  width: 1600,
  height: 900,
});

for (const spec of cardSpecs) {
  writeCard(spec);
  assets.push({
    id: spec.id,
    type: "card",
    svg: `assets/svg/v0.3.0/cards/${spec.file}`,
    png: `exports/v0.3.0/cards/${spec.file.replace(/\.svg$/, ".png")}`,
    width: 512,
    height: 400,
  });
}

const statusSpecs = [
  {
    file: "status-spirit.svg",
    id: "status.spirit",
    color: C.gold,
    art: `<path d="M32 7 C19 19 15 31 22 43 C27 52 36 58 44 47 C52 36 45 20 32 7Z" fill="none" stroke="currentColor" stroke-width="3"/><path d="M32 20 C38 30 39 38 32 45 C25 38 26 30 32 20Z" fill="currentColor" opacity=".45"/>`,
  },
  {
    file: "status-corruption.svg",
    id: "status.corruption",
    color: C.blood,
    art: `<circle cx="32" cy="32" r="20" fill="none" stroke="currentColor" stroke-width="3"/><path d="M32 10 L28 28 L42 25 L34 37 L41 52 L30 45 L18 54 L23 38 L12 32 L26 29Z" fill="currentColor" opacity=".72"/>`,
  },
  {
    file: "status-attention.svg",
    id: "status.attention",
    color: C.bone,
    art: `<path d="M6 32 C16 17 48 17 58 32 C48 47 16 47 6 32Z" fill="none" stroke="currentColor" stroke-width="3"/><circle cx="32" cy="32" r="8" fill="currentColor"/><circle cx="32" cy="32" r="14" fill="none" stroke="currentColor" stroke-width="1.5" opacity=".55"/>`,
  },
  {
    file: "status-health.svg",
    id: "status.health",
    color: C.bone,
    art: `<path d="M7 33 H19 L24 23 L31 45 L39 18 L45 33 H57" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M32 8 C44 8 56 16 56 32 C56 48 44 56 32 56 C20 56 8 48 8 32 C8 16 20 8 32 8Z" fill="none" stroke="currentColor" stroke-width="1.5" opacity=".38"/>`,
  },
  {
    file: "status-block.svg",
    id: "status.block",
    color: C.gold,
    art: `<path d="M32 6 L54 15 V32 C54 45 44 54 32 59 C20 54 10 45 10 32 V15Z" fill="none" stroke="currentColor" stroke-width="3"/><path d="M21 33 H43 M32 22 V44" stroke="currentColor" stroke-width="3"/>`,
  },
  {
    file: "status-attack.svg",
    id: "status.attack",
    color: C.blood,
    art: `<path d="M12 52 L44 20 M39 12 L52 12 L52 25" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M9 47 L17 55 M18 44 L10 56 L21 58Z" fill="currentColor"/>`,
  },
  {
    file: "status-draw.svg",
    id: "status.draw",
    color: C.paper,
    art: `<rect x="19" y="7" width="30" height="42" rx="2" fill="none" stroke="currentColor" stroke-width="3" transform="rotate(8 34 28)"/><rect x="13" y="15" width="30" height="42" rx="2" fill="#111612" stroke="currentColor" stroke-width="3" transform="rotate(-7 28 36)"/><path d="M46 20 L56 31 M56 20 L46 31" stroke="currentColor" stroke-width="2"/>`,
  },
  {
    file: "status-relic.svg",
    id: "status.relic",
    color: C.gold,
    art: `<path d="M32 7 L54 20 V44 L32 57 L10 44 V20Z" fill="none" stroke="currentColor" stroke-width="3"/><circle cx="32" cy="32" r="10" fill="none" stroke="currentColor" stroke-width="3"/><path d="M32 22 V42 M22 32 H42" stroke="currentColor" stroke-width="1.5" opacity=".6"/>`,
  },
  {
    file: "status-persona.svg",
    id: "status.persona",
    color: C.bone,
    art: `<path d="M32 7 C18 7 12 18 14 34 C16 47 24 56 32 60 C40 56 48 47 50 34 C52 18 46 7 32 7Z" fill="none" stroke="currentColor" stroke-width="3"/><path d="M20 27 C25 22 29 23 32 28 M44 27 C39 22 35 23 32 28" fill="none" stroke="currentColor" stroke-width="3"/><path d="M26 45 C30 48 34 48 38 45" fill="none" stroke="currentColor" stroke-width="2"/>`,
  },
  {
    file: "status-rite.svg",
    id: "status.rite",
    color: C.gold,
    art: `<circle cx="32" cy="32" r="24" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="32" cy="32" r="16" fill="none" stroke="currentColor" stroke-width="1" stroke-dasharray="2 4"/><path d="M32 10 L50 43 H14Z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="32" cy="32" r="4" fill="${C.blood}"/>`,
  },
  {
    file: "status-ascension.svg",
    id: "status.ascension",
    color: C.gold,
    art: `<path d="M10 53 H24 V42 H38 V30 H52 V17" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/><path d="M42 17 H52 V27" fill="none" stroke="currentColor" stroke-width="4"/><path d="M10 58 H54" stroke="currentColor" stroke-width="2" opacity=".45"/>`,
  },
  {
    file: "status-madness.svg",
    id: "status.madness",
    color: C.blood,
    art: `<path d="M32 31 C38 24 47 31 43 39 C39 46 27 46 23 37 C18 25 31 13 43 19 C55 25 55 45 42 53 C27 62 8 48 12 30 C15 15 30 7 45 11" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"/><circle cx="32" cy="31" r="3" fill="currentColor"/>`,
  },
];

for (const spec of statusSpecs) {
  const doc = svgDoc(64, 64, `
    <rect width="64" height="64" rx="10" fill="#1b1f1a" stroke="${C.gold}" stroke-width="1" opacity=".98"/>
    <g color="${spec.color}">${spec.art}</g>
  `);
  fs.writeFileSync(path.join(svgRoot, "status", spec.file), doc, "utf8");
  assets.push({
    id: spec.id,
    type: "status",
    svg: `assets/svg/v0.3.0/status/${spec.file}`,
    png: `exports/v0.3.0/status/${spec.file.replace(/\.svg$/, ".png")}`,
    width: 64,
    height: 64,
  });
}

fs.writeFileSync(
  path.join(exportRoot, "render-manifest.json"),
  JSON.stringify({ version: "v0.3.0", assets }, null, 2) + "\n",
  "utf8",
);

const groups = [
  ["P0 战斗场景", assets.filter((asset) => asset.type === "scene")],
  ["P0 敌人", assets.filter((asset) => asset.type === "enemy")],
  ["P1 卡面插画", assets.filter((asset) => asset.type === "card")],
  ["P1 状态图标", assets.filter((asset) => asset.type === "status")],
];

const sections = groups.map(([title, items]) => `
  <section>
    <h2>${title}</h2>
    <div class="grid ${title === "P1 卡面插画" ? "cards" : ""} ${title === "P1 状态图标" ? "statuses" : ""}">
      ${items.map((asset) => `
        <figure>
          <img src="../../${asset.svg}" alt="${asset.id}">
          <figcaption><strong>${asset.id}</strong><span>${asset.width} × ${asset.height}</span></figcaption>
        </figure>
      `).join("")}
    </div>
  </section>
`).join("");

const contactHtml = `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>假面低语 v0.3.0 · 美术返工审稿</title>
  <style>
    :root { color-scheme: dark; --ink:#111410; --paper:#d8c29a; --gold:#b99750; --blood:#7a2828; }
    * { box-sizing: border-box; }
    body { margin:0; background:var(--ink); color:#e8dfc9; font-family:"Noto Serif SC","Songti SC",Georgia,serif; }
    header { padding:54px 6vw 28px; border-bottom:1px solid #5e4d32; }
    h1 { margin:0; font-size:clamp(34px,5vw,74px); letter-spacing:.12em; }
    header p { color:var(--gold); letter-spacing:.16em; }
    section { padding:28px 5vw 40px; }
    h2 { color:var(--gold); font-size:20px; letter-spacing:.18em; border-bottom:1px solid #4b412d; padding-bottom:12px; }
    .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(250px,1fr)); gap:18px; }
    .grid.cards { grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); }
    .grid.statuses { grid-template-columns:repeat(auto-fit,minmax(112px,1fr)); }
    figure { margin:0; background:#1d211c; border:1px solid #4b432f; }
    img { display:block; width:100%; height:auto; }
    figcaption { display:flex; justified-content:space-between; gap:12px; padding:12px 14px; font-size:12px; color:#a99c7e; }
    figcaption strong { color:#e8dfc9; font-weight:500; overflow-wrap:anywhere; }
  </style>
</head>
<body>
  <header>
    <h1>假面低语 · 美术返工</h1>
    <p>V0.3.0 / P0-P1 VISUAL PRODUCTION / UI REVIEW REQUIRED</p>
  </header>
  ${sections}
</body>
</html>
`;

fs.writeFileSync(path.join(previewDir, "index.html"), contactHtml, "utf8");
console.log(`Generated ${assets.length} SVG assets under ${svgRoot}`);
console.log(`Preview: ${path.join(previewDir, "index.html")}`);
