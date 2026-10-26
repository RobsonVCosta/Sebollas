#!/usr/bin/env python3
"""Two review-only stone designs, rendered with native SCREEN 4 tile limits."""
from pathlib import Path
import importlib.util
import json
import random
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'previews/pedras'
OUT.mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location('native_preview', ROOT/'tools/render_previews.py')
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)

# Each 8-pixel scanline has one stone color and the road background (13).
# Four sizes, with restrained highlights and short contact shadows.
OPTIONS = [
    dict(name='Pedras arredondadas', detail='Seixos cinzentos, contornos suaves e tamanhos variados.',
         variants=[
             dict(rows=[0,0,0,0x18,0x10,0,0,0], fg=[14,14,14,14,1,14,14,14]),
             dict(rows=[0,0,0x18,0x3c,0x18,0,0,0], fg=[14,14,15,14,1,14,14,14]),
             dict(rows=[0,0x18,0x3c,0x7e,0x3c,0x18,0,0], fg=[14,15,14,14,14,1,14,14]),
             dict(rows=[0,0x18,0x3e,0x7f,0x7f,0x3e,0x1c,0], fg=[14,15,14,14,14,14,1,14]),
         ], weights=[0,0,1,1,1,1,2,2,2,3]),
    dict(name='Pedras irregulares', detail='Lascas angulosas, detalhes de desgaste e pedras maiores.',
         variants=[
             dict(rows=[0,0,0x0c,0x08,0,0,0,0], fg=[14,14,14,1,14,14,14,14]),
             dict(rows=[0,0,0x38,0x78,0x30,0,0,0], fg=[14,14,15,14,1,14,14,14]),
             dict(rows=[0,0x1c,0x3e,0x7c,0x3e,0x0c,0,0], fg=[14,15,14,14,14,1,14,14]),
             dict(rows=[0,0x3c,0x7e,0xfc,0x7f,0x3e,0x18,0], fg=[14,15,14,14,14,14,1,14]),
         ], weights=[0,0,1,1,1,2,2,2,3,3]),
]
STYLE = 1  # The actual car-to-bar road and its stage palette.
MAP_ROW = 96
levels = (0,43,81,118,153,187,221,255)
palette = [tuple(levels[v] for v in c) for c in native.META['palettes'][STYLE]]
world = (native.DATA/'world.bin').read_bytes()
base = native.render(STYLE, MAP_ROW, with_sprites=False)
with_sprites = native.render(STYLE, MAP_ROW, with_sprites=True)
# Hardware sprite masks preserve every opaque pixel over the redesigned road.
sprite_mask = Image.new('1', (256,192))
for x,y,n in native.scene_sprites(MAP_ROW, STYLE):
    if 8 <= n < 24 or n >= 28:
        continue  # Keep the car visible; leave the road clear for art review.
    for sy in range(16):
        if not (native.SCOL[n*16+sy] & 15):
            continue
        for sx in range(16):
            bits = native.SPR[n*32+(16 if sx>=8 else 0)+sy]
            if bits & (128>>(sx%8)) and 0<=x+sx<256 and 0<=y+sy<192:
                sprite_mask.putpixel((x+sx,y+sy),1)

def tile(variant):
    result = Image.new('RGB',(8,8),palette[13])
    for y,(bits,fg) in enumerate(zip(variant['rows'],variant['fg'])):
        for x in range(8):
            if bits & (128>>x): result.putpixel((x,y),palette[fg])
    # A real SCREEN 4 tile may use at most two colors per scanline.
    assert all(len({result.getpixel((x,y)) for x in range(8)})<=2 for y in range(8))
    return result

font_path='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
font=ImageFont.truetype(font_path,24)
small=ImageFont.truetype(font_path,18)
for number, option in enumerate(OPTIONS,1):
    stones = [tile(v) for v in option['variants']]
    scene = base.copy()
    counts = [0]*len(stones)
    for sy in range(22):
        wy=MAP_ROW+sy
        for tx in range(32):
            if world[wy*32+tx] not in native.META.get('road_stone_tiles',[131]): continue
            variation=random.Random(wy*32+tx+1991).choice(option['weights'])
            counts[variation]+=1
            scene.paste(stones[variation],(tx*8,(sy+2)*8))
    assert all(counts), counts
    scene.paste(with_sprites,(0,0),sprite_mask)
    scene.save(OUT/f'opcao-{number}-gameplay.png')
    canvas=Image.new('RGB',(1088,1016),'#101820')
    d=ImageDraw.Draw(canvas)
    d.text((32,18),f'OPÇÃO {number} — {option["name"]}',font=font,fill='#f5f1df')
    d.text((32,52),option['detail'],font=small,fill='#bac4ca')
    canvas.paste(scene.resize((1024,768),Image.NEAREST),(32,92))
    d.text((32,882),'Detalhe dos quatro tamanhos • pixels e cores compatíveis com o MSX2',font=small,fill='#bac4ca')
    for i,stone in enumerate(stones):
        canvas.paste(stone.resize((80,80),Image.NEAREST),(32+i*112,920))
    canvas.save(OUT/f'opcao-{number}.png')
(OUT/'opcoes.json').write_text(json.dumps(OPTIONS,ensure_ascii=False,indent=2)+'\n')
print('Prévias criadas em previews/pedras/opcao-1.png e opcao-2.png. ROM preservada.')
