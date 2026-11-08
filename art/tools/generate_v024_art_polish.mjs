import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const artDir = path.resolve(toolDir, '..');
const sourceRoot = path.join(artDir, 'assets', 'svg');
const outputRoot = path.join(artDir, 'assets', 'svg', 'v0.24.0');
const previewRoot = path.join(artDir, 'preview', 'v0.24.0');
const files = [];

function collect(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === 'v0.24.0' || entry.name.endsWith('.import')) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) collect(full);
    else if (entry.isFile() && entry.name.endsWith('.svg')) files.push(full);
  }
}
collect(sourceRoot);

function relativeSource(file) {
  return path.relative(sourceRoot, file).split(path.sep).join('/');
}

function dimensions(svg) {
  const match = svg.match(/<svg[^>]*width="([0-9.]+)"[^>]*height="([0-9.]+)"[^>]*viewBox="([^"]+)"/);
  if (!match) throw new Error(`Missing SVG dimensions: ${svg.slice(0, 100)}`);
  const view = match[3].trim().split(/\s+/).map(Number);
  return { width: Number(match[1]), height: Number(match[2]), viewWidth: view[2], viewHeight: view[3] };
}

function polish(svg, relative) {
  const { viewWidth: w, viewHeight: h } = dimensions(svg);
  const isScene = w >= 1000 || h >= 800;
  const isCard = w >= 400 && w <= 700 && h >= 350;
  const isIcon = !isScene && !isCard;
  const defs = `
  <defs>
    <radialGradient id="v024Vignette_${hash(relative)}" cx="50%" cy="45%" r="72%">
      <stop offset="0" stop-color="#000000" stop-opacity="0"/>
      <stop offset="0.72" stop-color="#000000" stop-opacity="0.02"/>
      <stop offset="1" stop-color="#211D18" stop-opacity="0.32"/>
    </radialGradient>
    <pattern id="v024Hatch_${hash(relative)}" width="13" height="13" patternUnits="userSpaceOnUse" patternTransform="rotate(24)">
      <path d="M0 0V13" stroke="#211D18" stroke-width="0.7" opacity="0.12"/>
      <path d="M6.5 0V13" stroke="#E8DFC9" stroke-width="0.35" opacity="0.08"/>
    </pattern>
    <filter id="v024Grain_${hash(relative)}" x="-8%" y="-8%" width="116%" height="116%">
      <feTurbulence type="fractalNoise" baseFrequency="0.72" numOctaves="2" seed="${hash(relative) % 97}" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0" result="mono"/>
      <feComponentTransfer in="mono"><feFuncA type="table" tableValues="0 0.06"/></feComponentTransfer>
      <feBlend in="SourceGraphic" in2="mono" mode="multiply"/>
    </filter>
  </defs>`;
  let overlay = '';
  let sceneAccent = '';
  if (isScene) {
    overlay = `
  <g pointer-events="none" opacity="0.8">
    <rect width="${w}" height="${h}" fill="url(#v024Vignette_${hash(relative)})"/>
    <rect x="${Math.max(18, w * 0.018)}" y="${Math.max(18, h * 0.03)}" width="${w - Math.max(36, w * 0.036)}" height="${h - Math.max(36, h * 0.06)}" fill="none" stroke="#B99750" stroke-width="1.2" opacity="0.42"/>
    <path d="M${w * 0.018} ${h * 0.09}h${w * 0.035}M${w * 0.018} ${h * 0.09}V${h * 0.03}M${w * 0.982} ${h * 0.09}h-${w * 0.035}M${w * 0.982} ${h * 0.09}V${h * 0.03}M${w * 0.018} ${h * 0.91}h${w * 0.035}M${w * 0.018} ${h * 0.91}V${h * 0.97}M${w * 0.982} ${h * 0.91}h-${w * 0.035}M${w * 0.982} ${h * 0.91}V${h * 0.97}" fill="none" stroke="#D8C29A" stroke-width="2" opacity="0.55"/>
  </g>`;
    sceneAccent = sceneDetails(relative, w, h);
  } else if (isCard) {
    overlay = `
  <g pointer-events="none" opacity="0.78">
    <rect width="${w}" height="${h}" fill="url(#v024Hatch_${hash(relative)})"/>
    <rect x="${w * 0.026}" y="${h * 0.045}" width="${w * 0.948}" height="${h * 0.91}" fill="none" stroke="#B99750" stroke-width="1.4" opacity="0.48"/>
    <path d="M${w * 0.026} ${h * 0.12}h${w * 0.09}M${w * 0.974} ${h * 0.12}h-${w * 0.09}M${w * 0.026} ${h * 0.88}h${w * 0.09}M${w * 0.974} ${h * 0.88}h-${w * 0.09}" stroke="#7A2828" stroke-width="1.2" opacity="0.48"/>
  </g>`;
  } else if (isIcon) {
    overlay = `
  <g pointer-events="none" opacity="0.62">
    <circle cx="${w / 2}" cy="${h / 2}" r="${Math.min(w, h) * 0.39}" fill="none" stroke="#B99750" stroke-width="0.9" stroke-dasharray="2 7" opacity="0.55"/>
    <path d="M${w / 2} ${h * 0.08}v${h * 0.08}M${w / 2} ${h * 0.84}v${h * 0.08}M${w * 0.08} ${h / 2}h${w * 0.08}M${w * 0.84} ${h / 2}h${w * 0.08}" stroke="#E8DFC9" stroke-width="1" opacity="0.4"/>
  </g>`;
  }
  return svg.replace(/<\/svg>\s*$/, `${defs}${overlay}${sceneAccent}</svg>`);
}

function sceneDetails(relative, w, h) {
  const center = `<g pointer-events="none" opacity="0.7" fill="none" stroke="#B99750">`;
  if (relative.includes('battle-tingen-old-house')) {
    return `${center}
      <path d="M${w * 0.08} ${h * 0.18}H${w * 0.29}V${h * 0.55}H${w * 0.08}M${w * 0.71} ${h * 0.18}H${w * 0.92}V${h * 0.55}H${w * 0.71}" stroke-width="2" opacity="0.42"/>
      <path d="M${w * 0.08} ${h * 0.18}L${w * 0.16} ${h * 0.1}H${w * 0.26}L${w * 0.29} ${h * 0.18}M${w * 0.71} ${h * 0.18}L${w * 0.74} ${h * 0.1}H${w * 0.84}L${w * 0.92} ${h * 0.18}" stroke-width="1.4" opacity="0.55"/>
      <path d="M${w * 0.36} ${h * 0.77}Q${w * 0.5} ${h * 0.67} ${w * 0.64} ${h * 0.77}" stroke="#788079" stroke-width="3" opacity="0.4"/>
      <path d="M${w * 0.44} ${h * 0.77}V${h * 0.66}H${w * 0.56}V${h * 0.77}" stroke="#7A2828" stroke-width="1.6" opacity="0.42"/>
    </g>`;
  }
  if (relative.includes('route-map')) {
    return `${center}
      <path d="M${w * 0.08} ${h * 0.73}Q${w * 0.25} ${h * 0.58} ${w * 0.42} ${h * 0.7}T${w * 0.78} ${h * 0.62}T${w * 0.94} ${h * 0.72}" stroke="#7A2828" stroke-width="2" opacity="0.45"/>
      <path d="M${w * 0.1} ${h * 0.76}H${w * 0.9}" stroke="#211D18" stroke-width="1" stroke-dasharray="3 10" opacity="0.42"/>
    </g>`;
  }
  if (relative.includes('rest-old-house')) {
    return `${center}
      <path d="M${w * 0.39} ${h * 0.64}V${h * 0.32}H${w * 0.61}V${h * 0.64}M${w * 0.35} ${h * 0.64}H${w * 0.65}" stroke-width="2" opacity="0.52"/>
      <path d="M${w * 0.47} ${h * 0.52}Q${w * 0.5} ${h * 0.44} ${w * 0.53} ${h * 0.52}V${h * 0.6}H${w * 0.47}Z" fill="#B99750" stroke="none" opacity="0.28"/>
    </g>`;
  }
  if (relative.includes('deck_archive')) {
    return `${center}
      <path d="M${w * 0.12} ${h * 0.18}H${w * 0.42}M${w * 0.12} ${h * 0.22}H${w * 0.42}M${w * 0.58} ${h * 0.18}H${w * 0.88}M${w * 0.58} ${h * 0.22}H${w * 0.88}" stroke-width="1" opacity="0.38"/>
      <path d="M${w * 0.5} ${h * 0.28}V${h * 0.66}M${w * 0.46} ${h * 0.6}L${w * 0.5} ${h * 0.66}L${w * 0.54} ${h * 0.6}" stroke="#7A2828" stroke-width="1.5" opacity="0.38"/>
    </g>`;
  }
  if (relative.includes('gacha-altar')) {
    return `${center}
      <circle cx="${w * 0.5}" cy="${h * 0.48}" r="${Math.min(w, h) * 0.22}" stroke-width="1.6" stroke-dasharray="3 12" opacity="0.55"/>
      <path d="M${w * 0.42} ${h * 0.7}H${w * 0.58}M${w * 0.45} ${h * 0.66}H${w * 0.55}" stroke="#7A2828" stroke-width="2" opacity="0.5"/>
    </g>`;
  }
  if (relative.includes('reward-archive')) {
    return `${center}
      <path d="M${w * 0.18} ${h * 0.66}H${w * 0.82}M${w * 0.22} ${h * 0.7}H${w * 0.78}" stroke-width="1.5" opacity="0.45"/>
      <path d="M${w * 0.28} ${h * 0.3}V${h * 0.55}M${w * 0.5} ${h * 0.26}V${h * 0.55}M${w * 0.72} ${h * 0.3}V${h * 0.55}" stroke="#788079" stroke-width="2" opacity="0.32"/>
    </g>`;
  }
  if (relative.includes('challenge-selection') || relative.includes('challenge-result')) {
    return `${center}
      <circle cx="${w * 0.5}" cy="${h * 0.48}" r="${Math.min(w, h) * 0.23}" stroke="#7A2828" stroke-width="1.4" stroke-dasharray="5 13" opacity="0.5"/>
      <path d="M${w * 0.43} ${h * 0.48}H${w * 0.57}M${w * 0.5} ${h * 0.41}V${h * 0.55}" stroke="#B99750" stroke-width="1.4" opacity="0.5"/>
    </g>`;
  }
  if (relative.includes('ritual-tampered-obituary') || relative.includes('ritual-ascension')) {
    return `${center}
      <circle cx="${w * 0.5}" cy="${h * 0.52}" r="${Math.min(w, h) * 0.27}" stroke="#7A2828" stroke-width="1.4" stroke-dasharray="4 16" opacity="0.5"/>
      <path d="M${w * 0.5} ${h * 0.18}V${h * 0.32}M${w * 0.5} ${h * 0.72}V${h * 0.86}M${w * 0.28} ${h * 0.52}H${w * 0.38}M${w * 0.62} ${h * 0.52}H${w * 0.72}" stroke-width="2" opacity="0.45"/>
    </g>`;
  }
  return '';
}

function hash(value) {
  let result = 7;
  for (const char of value) result = (result * 31 + char.charCodeAt(0)) >>> 0;
  return result;
}

for (const file of files) {
  const relative = relativeSource(file);
  const destination = path.join(outputRoot, relative);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, polish(fs.readFileSync(file, 'utf8'), relative), 'utf8');
}

fs.mkdirSync(previewRoot, { recursive: true });
const groups = files.map(file => {
  const relative = relativeSource(file);
  return `<figure><img src="../../assets/svg/v0.24.0/${relative}" alt="${relative}"><figcaption>${relative}</figcaption></figure>`;
}).join('\n');
fs.writeFileSync(path.join(previewRoot, 'index.html'), `<!doctype html><meta charset="utf-8"><title>假面低语 v0.24 美术抛光</title><style>body{margin:0;background:#10140f;color:#e8dfc9;font-family:Georgia,"Songti SC",serif}header{padding:32px 5vw;border-bottom:1px solid #5a4a31}h1{margin:0;color:#e8dfc9}p{color:#b99750}.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;padding:24px 4vw}figure{margin:0;background:#1a1e19;border:1px solid #473e2c}img{display:block;width:100%;height:auto}figcaption{padding:8px;font-size:11px;overflow-wrap:anywhere;color:#a99b7f}</style><header><h1>假面低语 · v0.24 美术抛光包</h1><p>统一纸张纹理、铜版线、暗角与套印边缘语言；保留原构图与稳定 ID。</p></header><main class="grid">${groups}</main>`, 'utf8');
console.log(`V024_ART_SVG_OK assets=${files.length} output=${outputRoot}`);
