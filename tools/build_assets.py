#!/usr/bin/env python3
"""Deterministic SCREEN 4 art. Pillow is a build-time dependency only."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'resources/generated'
OUT.mkdir(exist_ok=True)
# V9938 RGB values are multiples of 1/7, not arbitrary 24-bit artwork.
PALETTES=[
[(0,0,0),(0,0,0),(1,3,1),(3,5,2),(1,2,4),(4,6,7),(4,2,1),(6,4,2),(6,2,3),(7,4,4),(7,6,1),(7,7,4),(2,4,1),(5,3,1),(5,5,5),(7,7,6)],
[(0,0,0),(0,0,0),(1,3,1),(3,5,2),(7,6,1),(4,6,7),(5,2,1),(7,4,2),(6,2,3),(7,4,4),(1,3,6),(7,7,4),(2,4,1),(4,1,1),(5,5,5),(7,7,6)],
[(0,0,0),(0,0,0),(3,3,1),(5,5,2),(1,2,4),(4,6,7),(5,3,1),(7,5,2),(6,2,3),(7,4,4),(6,1,1),(7,7,4),(4,4,1),(4,2,1),(5,5,5),(7,7,6)]]
def image(w,h,color=0): return Image.new('P',(w,h),color)
patterns=bytearray(2048); colors=bytearray([0xf1]*2048)
font=(ROOT/'resources/font-original.bin').read_bytes()
chars=[32,127,45]+list(range(48,58))+list(range(65,91))
for i,ch in enumerate(chars): patterns[ch*8:ch*8+8]=font[i*8:i*8+8]
# Tile IDs >=128 are reserved for scenery; ASCII remains untouched.
tiles={}
def tile(idx,bg,fg,rows):
    patterns[idx*8:idx*8+8]=bytes(rows)
    colors[idx*8:idx*8+8]=bytes([fg*16+bg]*8)
    tiles[idx]=[bg,fg]
tile(128,3,2,[0,0x20,0,0,2,0,0x40,0]) # pasture
tile(129,3,12,[0,0x18,0x24,0,0,0x42,0x24,0])
tile(130,6,7,[0,0,0x20,0,0,2,0,0]) # packed dirt
tile(131,6,13,[0x18,0x18,0x10,0x18,0x18,8,0x18,0x18]) # tyre track
tile(132,3,6,[3,3,7,7,7,15,7,3]) # shoulder left
tile(133,3,6,[192,192,224,224,224,240,224,192])
tile(134,3,7,[0x18,0x18,0xff,0x18,0x18,0xff,0x18,0x18]) # fence
tile(135,3,2,[0x18,0x3c,0x7e,0xff,0x7e,0x3c,0x18,0x18])
tile(136,3,12,[0x18,0x3c,0x7e,0xff,0x7e,0x3c,0x18,0x18])
tile(137,3,13,[0x18]*8) # tree trunk
tile(138,3,11,[0,0,0x10,0x38,0x10,0,0,0]) # flowers
tile(139,1,1,[0]*8)
(OUT/'patterns.bin').write_bytes(patterns)
(OUT/'colors.bin').write_bytes(colors)
world=[]
for y in range(64):
    row=[]
    for x in range(32):
        t=128 if (x*7+y*3)%5 else 129
        if 8<=x<=23: t=131 if x in (12,19) else 130
        elif x==7: t=132
        elif x==24: t=133
        elif x in (5,26): t=134
        elif x in (2,29) and y%8 in (0,1): t=135 if y%8==0 else 137
        elif x in (1,3,28,30) and y%8==0: t=136
        elif (x+y*5)%37==0: t=138
        row.append(t)
    world.extend(row)
(OUT/'world.bin').write_bytes(bytes(world))
# Art is authored as indexed pixels, then packed into real 16x16 masks.
car=image(16,32); d=ImageDraw.Draw(car)
d.polygon([(6,0),(9,0),(12,2),(13,5),(14,8),(14,25),(13,29),(11,31),(4,31),(2,29),(1,25),(1,8),(2,5),(3,2)],fill=1)
d.rounded_rectangle((3,3,12,28),radius=4,fill=10)
d.rectangle((3,9,12,12),fill=1); d.rectangle((4,9,11,11),fill=5)
d.rectangle((4,23,11,26),fill=1);d.rectangle((5,24,10,25),fill=5)
d.rectangle((5,14,10,21),fill=10)
d.line((3,14,3,23),fill=1);d.line((12,14,12,23),fill=1)
d.rectangle((0,8,1,13),fill=1); d.rectangle((14,8,15,13),fill=1)
d.rectangle((0,23,1,28),fill=1);d.rectangle((14,23,15,28),fill=1)
d.point((4,3),fill=5);d.point((11,3),fill=5)
d.line((5,29,10,29),fill=5)
def cow(pose):
    im=image(32,32);d=ImageDraw.Draw(im)
    d.polygon([(4,11),(14,9),(19,10),(20,5),(22,3),(22,0),(24,0),(25,4),(28,4),(29,1),(31,1),(30,9),(31,12),(31,22),(27,23),(25,26),(25,30),(29,30),(29,31),(22,31),(21,25),(17,25),(16,31),(10,31),(10,26),(7,26),(7,31),(3,31),(3,19),(1,24),(0,24),(0,19),(2,15)],fill=1)
    d.polygon([(5,13),(14,11),(18,13),(18,22),(15,24),(13,28),(12,28),(12,23),(7,23),(5,28),(5,28)],fill=15)
    d.rectangle((21,7,28,13),fill=15);d.rectangle((20,9,29,13),fill=15)
    d.rectangle((23,15,30,20),fill=9)
    # Right-hand colour band has pink only; body remains in left quadrant.
    d.rectangle((16,14,18,20),fill=1)
    d.rectangle((24,10,25,12),fill=1); d.point((25,18),fill=1);d.point((29,18),fill=1)
    d.polygon([(5,13),(9,12),(10,16),(8,19),(5,18)],fill=1)
    d.polygon([(11,19),(14,17),(15,21),(13,23),(10,22)],fill=1)
    if pose:
        d.rectangle((3,28,6,31),fill=0);d.rectangle((5,27,8,30),fill=1)
        d.rectangle((22,28,28,31),fill=0);d.rectangle((20,27,23,31),fill=1)
    return im
sprites=[]; metadata={}
def pack(im,col):
    return bytes(sum((1<<(7-x)) for x in range(8) if im.getpixel((x+dx,y))==col) for dx in (0,8) for y in range(16))
def add_mask(im,mask_colors,line_colors):
    # mask_colors may vary by row, but a mask has only one colour per scanline.
    data=bytes(sum(1<<(7-x) for x in range(8) if im.getpixel((x+dx,y)) in mask_colors[y]) for dx in (0,8) for y in range(16))
    sprites.append((data,bytes(line_colors)))
metadata['car']=len(sprites)
for by in (0,16):
    im=car.crop((0,by,16,by+16))
    for c in (1,10,5): add_mask(im,[{c}]*16,[c]*16)
metadata['cow']=len(sprites)
for direction in (0,1):
    for pose in (0,1):
        im=cow(pose)
        if direction: im=im.transpose(Image.FLIP_LEFT_RIGHT)
        for yy in (0,16):
            for xx in (0,16):
                q=im.crop((xx,yy,xx+16,yy+16))
                add_mask(q,[{1}]*16,[1]*16)
                linecols=[]
                for y in range(16):
                    c=set(q.crop((0,y,16,y+1)).getdata())-{0,1}
                    assert len(c)<=1,(direction,pose,xx,yy,y,c)
                    linecols.append(next(iter(c),15))
                add_mask(q,[{15,9}]*16,linecols)
metadata['dust']=len(sprites)
for frame in range(4):
    im=image(16,16);d=ImageDraw.Draw(im)
    for xx,yy,r in [(5,2,2),(9,6,2),(4,10,3),(11,13,2)]:
        xx=(xx+frame*2)%12+1; yy=(yy+frame*3)%14
        d.ellipse((max(0,xx-r),max(0,yy-r),min(15,xx+r),min(15,yy+r)),fill=7)
    add_mask(im,[{7}]*16,[7]*16)
metadata['bullet']=len(sprites)
im=image(16,16);d=ImageDraw.Draw(im);d.rectangle((7,0,8,4),fill=11)
add_mask(im,[{11}]*16,[11]*16)
assert len(sprites)<=64
(OUT/'sprites.bin').write_bytes(b''.join(s[0] for s in sprites))
(OUT/'sprite_colors.bin').write_bytes(b''.join(s[1] for s in sprites))
for i,pal in enumerate(PALETTES):
    (OUT/f'palette{i}.bin').write_bytes(bytes(v for r,g,b in pal for v in ((r<<4)|b,g)))
metadata.update(sprite_count=len(sprites),palettes=PALETTES,font_chars=chars)
(OUT/'manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
(OUT/'assets.inc').write_text('\n'.join(f'{k.upper()}_PATTERN equ {v*4}' for k,v in metadata.items() if k in ('car','cow','dust','bullet'))+'\nSPRITE_BYTES equ '+str(len(sprites)*32)+'\n')
print(f'Assets: {len(sprites)} sprite patterns, 64x32 world, original 39-glyph font')
