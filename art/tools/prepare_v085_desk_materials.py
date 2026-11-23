"""Normalize user materials without stretching; no image generation/network calls."""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import hashlib, json, math
ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/assets/raster/v0.85.0/materials'
TARGET = ROOT / 'assets/ui/diary'

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def tile_edges(im, band=160):
    # Symmetric edge crossfade: only the outer band is touched. The final edge
    # pairs match exactly; a cosine taper avoids a new hard band at its inside.
    out = im.copy()
    n = im.width
    for i in range(band):
        weight = .25 * (1 + math.cos(math.pi * i / (band - 1)))
        a = im.crop((i, 0, i + 1, n))
        b = im.crop((n - 1 - i, 0, n - i, n))
        out.paste(Image.blend(a, b, weight), (i, 0))
        out.paste(Image.blend(b, a, weight), (n - 1 - i, 0))
    im = out.copy()
    for i in range(band):
        weight = .25 * (1 + math.cos(math.pi * i / (band - 1)))
        a = im.crop((0, i, n, i + 1))
        b = im.crop((0, n - 1 - i, n, n - i))
        out.paste(Image.blend(a, b, weight), (0, i))
        out.paste(Image.blend(b, a, weight), (0, n - 1 - i))
    return out

records = []
for src_name, target_name in [('paper-original.png','parchment_grain.png'),('wood-original.png','desk_wood.png')]:
    src = SOURCE / src_name
    original = Image.open(src).convert('RGB')
    w,h = original.size
    side = min(w,h)
    box = ((w-side)//2,(h-side)//2,(w+side)//2,(h+side)//2)
    im = tile_edges(original.crop(box).resize((2048,2048), Image.Resampling.LANCZOS))
    dest = TARGET / target_name
    im.save(dest)
    edge_x = max(ImageStat.Stat(ImageChops.difference(im.crop((0,0,1,2048)), im.crop((2047,0,2048,2048)))).mean)
    edge_y = max(ImageStat.Stat(ImageChops.difference(im.crop((0,0,2048,1)), im.crop((0,2047,2048,2048)))).mean)
    assert edge_x == edge_y == 0
    tile = im.resize((512,512), Image.Resampling.LANCZOS)
    preview = Image.new('RGB',(1024,1024))
    for x,y in [(0,0),(512,0),(0,512),(512,512)]: preview.paste(tile,(x,y))
    preview.save(ROOT / '.tools/ui-captures' / ('v085_tile_'+target_name))
    records.append({'source':str(src.relative_to(ROOT)), 'source_size':[w,h], 'source_sha256':digest(src), 'crop_box':box, 'target':str(dest.relative_to(ROOT)), 'size':[2048,2048], 'sha256':digest(dest), 'processing':'center square crop, Lanczos resize, cosine crossfade in outer 160px, no global recoloring', 'edge_pair_mean_absolute_difference':[edge_x,edge_y]})
ref=ROOT / 'art/assets/raster/v0.85.0/references/brass-candlestick-original.png'
records.append({'source':str(ref.relative_to(ROOT)), 'source_sha256':digest(ref), 'usage':'modeling reference only; not a transparent sprite'})
(ROOT / 'art/production/v0.85.0/desk_material_sources.json').write_text(json.dumps({'provenance':'User-supplied images, 2026-11-23. No license asserted; use approved for this local game.', 'assets':records},indent=2,ensure_ascii=False)+'\n')
manifest=ROOT / 'art/production/v0.85.0/asset_manifest.json'
data=json.loads(manifest.read_text())
for row in data['assets']:
    for item in records[:2]:
        if row['target']==item['target']:
            row.update(status='integrated_preview', source=item['source'], sha256=item['sha256'], ui_review='pending GPU desk review; exact opposite edge pixels verified')
manifest.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(records,indent=2))
