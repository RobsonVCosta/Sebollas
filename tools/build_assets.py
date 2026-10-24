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
[(0,0,0),(0,0,0),(1,3,1),(3,5,2),(1,2,4),(4,6,7),(4,2,1),(6,4,2),(7,1,1),(7,4,4),(7,6,1),(7,7,4),(2,4,1),(5,3,1),(5,5,5),(7,7,6)],
[(0,0,0),(0,0,0),(1,3,1),(3,5,2),(1,2,4),(4,6,7),(5,2,1),(7,4,2),(7,1,1),(7,4,4),(1,3,6),(7,7,4),(2,4,1),(4,1,1),(5,5,5),(7,7,6)],
[(0,0,0),(0,0,0),(3,3,1),(5,5,2),(1,2,4),(4,6,7),(5,3,1),(7,5,2),(7,1,1),(7,4,4),(6,1,1),(7,7,4),(4,4,1),(4,2,1),(5,5,5),(7,7,6)]]
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
tile(140,1,8,[0,0x66,0xff,0xff,0x7e,0x3c,0x18,0]) # red heart
tile(141,1,14,[0,0x66,0x99,0x81,0x42,0x24,0x18,0]) # empty heart
tile(142,1,3,[0x7e]*8) # fuel remaining
tile(143,1,14,[0x7e,0x42,0x42,0x42,0x42,0x42,0x42,0x7e])
tile(144,1,8,[0x7e]*8) # low fuel
tile(145,4,5,[0,0x38,0x44,0,0,0x83,0x44,0]) # river waves
tile(146,7,6,[0xff,0,0,0,0xff,0,0,0]) # bridge deck
tile(147,4,15,[0x18,0x18,0xff,0x18,0x18,0xff,0x18,0x18])
tile(148,3,8,[0x01,0x03,0x07,0x0f,0x1f,0x3f,0x7f,0xff])
tile(149,8,13,[0xff,0,0,0,0xff,0,0,0]) # roof
tile(150,3,8,[0x80,0xc0,0xe0,0xf0,0xf8,0xfc,0xfe,0xff])
tile(151,15,7,[0,0,0,0,0,0,0,0xff]) # house wall
tile(152,15,4,[0,0x7e,0x5a,0x5a,0x7e,0x5a,0x5a,0])
tile(153,15,6,[0x7e,0x7e,0x7e,0x7e,0x76,0x7e,0x7e,0x7e])
tile(154,3,8,[0x3e,0x41,0x41,0x7d,0x7d,0x7d,0x7f,0x7f])
tile(155,3,8,[0x7f,0x7d,0x7d,0x7c,0x7c,0x7c,0x7c,0xff])
tile(156,3,15,[0x80,0xc0,0x60,0x30,0x10,0x10,0x70,0x60])
tile(157,14,15,[0,0,0,0,0,0,0,0xff]) # forecourt / driveway
tile(158,3,15,[0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18])
(OUT/'patterns.bin').write_bytes(patterns)
(OUT/'colors.bin').write_bytes(colors)
# Finite northbound route. The viewport starts at row 138 and ends at row 0.
WORLD_ROWS=160
world=[]
for y in range(WORLD_ROWS):
    left,right=8,23
    for lo,hi in ((28,47),(78,97)):
        if lo<=y<=hi:
            inset=min(5,y-lo+1,hi-y+1)
            left,right=8+inset,23-inset
    if 123<=y<=132: left,right=11,20
    river=33<=y<=40 or 83<=y<=90
    row=[]
    for x in range(32):
        t=128 if (x*7+y*3)%5 else 129
        if river:
            t=146 if left<=x<=right else 147 if x in (left-1,right+1) else 145
        elif left<=x<=right: t=131 if x in (left+3,right-3) else 130
        elif x==left-1: t=132
        elif x==right+1: t=133
        elif x in (left-3,right+3): t=134
        elif x in (2,29) and y%8 in (0,1): t=135 if y%8==0 else 137
        elif x in (1,3,28,30) and y%8==0: t=136
        elif (x+y*5)%37==0: t=138
        row.append(t)
    world.append(row)
def label(y,x,text): world[y][x:x+len(text)]=map(ord,text)
def house(y,x,name):
    label(y-1,x,name)
    world[y][x:x+6]=[148,149,149,149,149,150]
    world[y+1][x:x+6]=[149]*6
    world[y+2][x:x+6]=[151,152,151,151,152,151]
    world[y+3][x:x+6]=[151,151,153,153,151,151]
    world[y+4][x:x+6]=[151,151,153,153,151,151]
# Vava's home is beside the initial car; the destination faces its driveway.
for y in range(150,157): world[y][3:16]=[157]*13
house(148,1,'VAVA')
for y in range(7,19): world[y][13:19]=[157]*6
house(2,13,'DESTINO')
for y in (54,110):
    for yy in range(y-2,y+8): world[yy][21:28]=[157]*7
    label(y-3,24,'POSTO')
    world[y][25:27]=[154,156]
    world[y+1][25:27]=[155,156]
    world[y+2][25:27]=[158,128]
(OUT/'world.bin').write_bytes(bytes(t for row in world for t in row))
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
def cow():
    # Static 32x32 silhouette: broad flank, upright horns and oversized muzzle.
    # Each 16px quadrant uses black plus one foreground color per scanline.
    im=image(32,32);d=ImageDraw.Draw(im)
    d.polygon([(2,14),(4,10),(6,8),(15,8),(16,6),(19,6),
               (20,3),(20,0),(22,0),(22,2),(23,2),(23,3),
               (27,3),(27,2),(28,2),(28,0),(30,0),(30,6),
               (31,6),(31,9),(30,10),(30,14),(31,15),(31,21),
               (28,22),(25,22),(25,27),(27,28),(27,30),
               (23,30),(22,28),(20,28),(20,30),(16,30),
               (15,26),(13,26),(13,30),(9,30),(8,28),
               (7,28),(7,30),(3,30),(3,18),(2,22),(0,24),
               (0,21),(1,20),(1,16)],fill=1)
    d.polygon([(5,12),(6,10),(7,10),(7,13),(10,15),(12,15),
               (12,11),(14,9),(15,9),(15,11),(17,12),(17,18),
               (19,20),(21,22),(23,22),(23,24),(21,25),
               (19,24),(18,27),(17,27),(17,24),(14,23),
               (9,23),(7,22),(6,24),(5,27),(4,27),(4,18),
               (6,17),(6,15),(4,14)],fill=15)
    d.polygon([(11,17),(13,15),(15,16),(15,20),(12,20),(10,19)],fill=1)
    d.polygon([(21,6),(27,6),(28,8),(29,9),(29,12),(28,13),
               (28,14),(23,14),(22,16),(22,19),(20,18),
               (19,16),(19,10),(20,9)],fill=15)
    d.rectangle((22,9,23,11),fill=1)
    d.rectangle((28,11,29,12),fill=1)
    d.polygon([(25,14),(29,14),(29,15),(30,15),(30,19),
               (29,20),(23,20),(23,16),(24,16),(24,15),(25,15)],fill=9)
    d.rectangle((25,18,25,19),fill=1);d.rectangle((28,18,28,19),fill=1)
    # Pink udder below the flank; legs in this quadrant are black on these rows.
    d.rectangle((8,24,12,25),fill=9);d.point((10,26),fill=9)
    for y in (24,25,26):
        for x in range(16):
            if im.getpixel((x,y))==15: im.putpixel((x,y),1)
    for y in range(14,21):
        for x in range(16,32):
            if im.getpixel((x,y))==15: im.putpixel((x,y),1)
    d.rectangle((23,25,24,27),fill=15)
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
    im=cow()
    if direction: im=im.transpose(Image.FLIP_LEFT_RIGHT)
    for yy in (0,16):
        for xx in (0,16):
            q=im.crop((xx,yy,xx+16,yy+16))
            add_mask(q,[{1}]*16,[1]*16)
            linecols=[]
            for y in range(16):
                c=set(q.crop((0,y,16,y+1)).getdata())-{0,1}
                assert len(c)<=1,(direction,xx,yy,y,c)
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
metadata.update(world_rows=WORLD_ROWS, start_row=138, stations=[54,110], rivers=[[33,40],[83,90]], sprite_count=len(sprites),palettes=PALETTES,font_chars=chars)
(OUT/'manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
(OUT/'assets.inc').write_text('\n'.join(f'{k.upper()}_PATTERN equ {v*4}' for k,v in metadata.items() if k in ('car','cow','dust','bullet'))+'\nSPRITE_BYTES equ '+str(len(sprites)*32)+'\n')
print(f'Assets: {len(sprites)} sprite patterns, 160x32 route, original 39-glyph font')
