#!/usr/bin/env python3
"""Deterministic SCREEN 4 art. Pillow is a build-time dependency only."""
from pathlib import Path
import json
import math
import textwrap
from collections import Counter
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'resources/generated'
OUT.mkdir(exist_ok=True)
# V9938 RGB values are multiples of 1/7, not arbitrary 24-bit artwork.
PALETTES=[
[(0,0,0),(0,0,0),(1,3,1),(3,5,2),(1,2,4),(4,6,7),(4,2,1),(6,4,2),(7,1,1),(7,4,4),(7,6,1),(7,7,4),(2,4,1),(5,3,1),(5,5,5),(7,7,6)],
[(0,0,0),(0,0,0),(1,3,1),(3,5,2),(1,2,4),(4,6,7),(5,2,1),(7,4,2),(7,1,1),(7,4,4),(1,3,6),(7,7,4),(2,4,1),(4,1,1),(5,5,5),(7,7,6)],
[(0,0,0),(0,0,0),(3,3,1),(5,5,2),(1,2,4),(4,6,7),(5,3,1),(7,5,2),(7,1,1),(7,4,4),(6,1,1),(7,7,4),(4,4,1),(4,2,1),(5,5,5),(7,7,6)]]
# Reserve 6 as a second black entry: 6 OR 9 gives white (15) in sprite mode 2.
# The scenery keeps its brown tone in slot 13; dark details use black slot 1.
for pal in PALETTES:
    pal[13]=pal[6]
    pal[6]=(0,0,0)
def image(w,h,color=0): return Image.new('P',(w,h),color)
patterns=bytearray(2048); colors=bytearray([0xf1]*2048)
font=(ROOT/'resources/font-original.bin').read_bytes()
chars=[32,127,45]+list(range(48,58))+list(range(65,91))
for i,ch in enumerate(chars): patterns[ch*8:ch*8+8]=font[i*8:i*8+8]
# Extended Latin-1 glyph for the name VAVÁ; original ASCII remains untouched.
patterns[193*8:193*8+8]=bytes([0x0c,0x18,0x1c,0x36,0x63,0x7f,0x63,0x63])
# Bold 8x8 lowercase companions to the original Konami-style MSX capitals.
lower={
'a':[0,0,0x3e,3,0x3f,0x63,0x3f,0],
'b':[0x60,0x60,0x7c,0x66,0x63,0x63,0x7e,0],
'c':[0,0,0x3e,0x63,0x60,0x63,0x3e,0],
'd':[3,3,0x1f,0x33,0x63,0x63,0x3f,0],
'e':[0,0,0x3e,0x63,0x7f,0x60,0x3e,0],
'f':[0x0e,0x1b,0x18,0x7e,0x18,0x18,0x18,0],
'g':[0,0,0x3f,0x63,0x63,0x3f,3,0x3e],
'h':[0x60,0x60,0x7c,0x66,0x63,0x63,0x63,0],
'i':[0x18,0,0x38,0x18,0x18,0x18,0x3c,0],
'j':[6,0,0x0e,6,6,0x66,0x66,0x3c],
'k':[0x60,0x60,0x66,0x6c,0x78,0x6c,0x66,0],
'l':[0x38,0x18,0x18,0x18,0x18,0x18,0x3c,0],
'm':[0,0,0x76,0x7f,0x6b,0x6b,0x63,0],
'n':[0,0,0x7c,0x66,0x63,0x63,0x63,0],
'o':[0,0,0x3e,0x63,0x63,0x63,0x3e,0],
'p':[0,0,0x7e,0x63,0x63,0x7e,0x60,0x60],
'q':[0,0,0x3f,0x63,0x63,0x3f,3,3],
'r':[0,0,0x6e,0x73,0x60,0x60,0x60,0],
's':[0,0,0x3f,0x60,0x3e,3,0x7e,0],
 't':[0x18,0x18,0x7e,0x18,0x18,0x1b,0x0e,0],
'u':[0,0,0x63,0x63,0x63,0x67,0x3b,0],
'v':[0,0,0x63,0x63,0x36,0x1c,8,0],
'w':[0,0,0x63,0x6b,0x6b,0x7f,0x36,0],
'x':[0,0,0x63,0x36,0x1c,0x36,0x63,0],
'y':[0,0,0x63,0x63,0x3f,3,0x63,0x3e],
'z':[0,0,0x7f,6,0x1c,0x30,0x7f,0]}
for ch,rows in lower.items(): patterns[ord(ch)*8:ord(ch)*8+8]=bytes(rows)
extras={40:[0x0e,0x18,0x30,0x30,0x30,0x18,0x0e,0],
41:[0x70,0x18,0x0c,0x0c,0x0c,0x18,0x70,0],
44:[0,0,0,0,0,0x18,0x18,0x30],46:[0,0,0,0,0,0x18,0x18,0],
240:[0,0x3e,0x63,0x60,0x63,0x3e,0x0c,0x18],
241:[0x0c,0x18,0x3e,0x63,0x7f,0x60,0x3e,0],
242:[0x0c,0x18,0x3e,0x63,0x63,0x63,0x3e,0],
244:[0x3e,0x63,0x60,0x60,0x63,0x3e,0x0c,0x18]}
for ch,rows in extras.items(): patterns[ch*8:ch*8+8]=bytes(rows)
CREDIT_PARAGRAPHS=[
'Essa foi a aventura de Argon, Gordinho (Leto) e Robson em sua jornada de Nova Iguaçu até o Sebollas.',
'Obrigado amigos, pelas boas memórias.',
'By Robson Velloso']
credit_rows=[]; row=4
for paragraph in CREDIT_PARAGRAPHS:
    for line in textwrap.wrap(paragraph,28):
        credit_rows.append((row,(32-len(line))//2,line));row+=1
    row+=2
encoding={'ç':240,'é':241,'ó':242,'Ç':244}
records=[]
for y,x,line in credit_rows:
    records.extend([y,x]+[encoding.get(ch,ord(ch)) for ch in line]+[0])
records.append(255)
(OUT/'credits.inc').write_text('CreditLines:\n'+''.join('    db '+','.join(map(str,records[i:i+64]))+'\n' for i in range(0,len(records),64)))
(OUT/'credits_text.json').write_text(json.dumps({'paragraphs':CREDIT_PARAGRAPHS,'rows':credit_rows},ensure_ascii=False,indent=2)+'\n')
# Scenery and HUD tile IDs occupy 128..184.
tiles={}
def tile(idx,bg,fg,rows):
    bg={6:13,13:1}.get(bg,bg)
    fg={6:13,13:1}.get(fg,fg)
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
# River Raid style gauge: an outlined track with a sliding needle, E to F.
tile(168,1,14,[0,0xff,0,0,0,0,0xff,0])
for x in range(8):
    mask=128>>x
    tile(169+x,1,15,[mask,0xff,mask,mask,mask,mask,0xff,mask])
    tile(177+x,1,8,[mask,0xff,mask,mask,mask,mask,0xff,mask])
# Side-view bus for the final chase, 8x4 background tiles.
bus=image(64,32,14);d=ImageDraw.Draw(bus)
d.rounded_rectangle((0,0,63,27),radius=3,fill=1)
d.rectangle((2,8,61,24),fill=15)
d.rectangle((2,20,61,26),fill=4)
for x in range(4,57,10): d.rectangle((x,9,x+7,17),fill=5)
d.rectangle((52,9,59,24),fill=1);d.line((55,10,55,24),fill=15)
for x in (10,48):
    d.ellipse((x,24,x+9,31),fill=1);d.rectangle((x+3,27,x+6,29),fill=14)
for q in range(32):
    xx,yy=(q%8)*8,(q//8)*8
    for y in range(8):
        values=[bus.getpixel((xx+x,yy+y)) for x in range(8)]
        common=[v for v,_ in Counter(values).most_common(2)]
        if len(common)==1: common.append(common[0])
        bg,fg=common
        def choose(v):
            return min(common,key=lambda color:sum((a-b)**2 for a,b in zip(PALETTES[0][color],PALETTES[0][v])))
        patterns[(200+q)*8+y]=sum(128>>x for x,v in enumerate(values) if choose(v)==fg)
        colors[(200+q)*8+y]=fg*16+bg
(OUT/'patterns.bin').write_bytes(patterns)
(OUT/'colors.bin').write_bytes(colors)
# Finite northbound route. The viewport starts at row 138 and ends at row 0.
WORLD_ROWS=160
world=[]
centers=[]
for y in range(WORLD_ROWS):
    shift=round(4*math.sin(y*math.pi/40))
    left,right=10+shift,21+shift
    for lo,hi in ((28,47),(78,97)):
        if lo<=y<=hi:
            inset=min(5,y-lo+1,hi-y+1)
            left,right=8+shift+inset,23+shift-inset
    if 123<=y<=132: left,right=11+shift,20+shift
    centers.append(((left+right)//2)*8)
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
house(148,1,'VAVÁ')
for y in range(7,19): world[y][13:19]=[157]*6
house(2,13,'DESTINO')
for y in (54,110):
    for yy in range(y-2,y+8): world[yy][min(centers[yy]//8+4,21):28]=[157]*(28-min(centers[yy]//8+4,21))
    label(y-3,24,'POSTO')
    world[y][25:27]=[154,156]
    world[y+1][25:27]=[155,156]
    world[y+2][25:27]=[158,128]
(OUT/'road_centers.bin').write_bytes(bytes(centers))
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
    # The user's reference is kept locally and reduced to the native sprite grid.
    src=Image.open(ROOT/'resources/cow-reference.png').convert('RGBA')
    src=src.crop(src.getbbox()).resize((32,24),Image.NEAREST)
    im=image(32,32)
    for y in range(24):
        for x in range(32):
            r,g,b,alpha=src.getpixel((x,y))
            if alpha: im.putpixel((x,y+4),9 if r>200 and g<200 else 15 if r>200 else 1)
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
            # Yamaha CC bit combines the two masks: black 6, pink 9, white 15.
            add_mask(q,[{1,15}]*16,[6]*16)
            add_mask(q,[{9,15}]*16,[0x40|9]*16)
metadata['dust']=len(sprites)
for frame in range(4):
    im=image(16,16);d=ImageDraw.Draw(im)
    for xx,yy,r in [(5,2,2),(9,6,2),(4,10,3),(11,13,2)]:
        xx=(xx+frame*2)%12+1; yy=(yy+frame*3)%14
        d.ellipse((max(0,xx-r),max(0,yy-r),min(15,xx+r),min(15,yy+r)),fill=7)
    add_mask(im,[{7}]*16,[7]*16)
metadata['cheese']=len(sprites)
for frame in range(2):
    # Unset mask bits are transparent, including the contour and cheese holes.
    im=image(16,16);d=ImageDraw.Draw(im)
    d.ellipse((1,1,14,14),fill=10)
    for x,y in ((5,4),(10,7),(6,11)):
        if frame: x,y=15-y,x
        d.rectangle((x,y,x+1,y+1),fill=0)
    add_mask(im,[{10}]*16,[10]*16)
def add_person(im):
    for yy in (0,16):
        part=im.crop((0,yy,16,yy+16))
        add_mask(part,[{1}]*16,[1]*16)
        linecols=[]
        for y in range(16):
            cols=set(part.crop((0,y,16,y+1)).getdata())-{0,1}
            assert len(cols)<=1,cols
            linecols.append(next(iter(cols),15))
        add_mask(part,[{c} for c in linecols],linecols)
metadata['boss']=len(sprites)
im=image(16,32);d=ImageDraw.Draw(im)
d.rectangle((4,0,12,2),fill=1);d.rectangle((5,0,11,1),fill=3)
d.rectangle((4,3,12,11),fill=1);d.rectangle((5,3,11,10),fill=9)
d.point((7,6),fill=1);d.point((10,6),fill=1)
d.rectangle((3,12,13,23),fill=1);d.rectangle((4,12,12,22),fill=8)
d.rectangle((1,14,3,20),fill=1);d.rectangle((13,13,15,19),fill=1)
d.rectangle((4,24,12,29),fill=1);d.rectangle((5,24,7,29),fill=5);d.rectangle((10,24,11,29),fill=5)
d.rectangle((3,30,7,31),fill=1);d.rectangle((10,30,14,31),fill=1)
add_person(im)
metadata['cane']=len(sprites)
for frame in range(2):
    im=image(16,16);d=ImageDraw.Draw(im)
    if frame:
        d.rectangle((6,1,8,14),fill=11)
        d.line((6,5,8,5),fill=0);d.line((6,10,8,10),fill=0)
    else:
        d.line((3,1,12,14),fill=11,width=3)
        d.line((4,5,7,5),fill=0);d.line((8,10,11,10),fill=0)
    add_mask(im,[{11}]*16,[11]*16)
for name,top,width,shirt in [('runner_small',18,7,3),('runner_tall',8,7,10),('runner_fat',14,13,4)]:
    metadata[name]=len(sprites)
    for frame in range(2):
        im=image(16,32);d=ImageDraw.Draw(im)
        d.rectangle((5,top,10,top+4),fill=1);d.rectangle((6,top+1,9,top+4),fill=9)
        d.point((9,top+2),fill=1)
        left=(16-width)//2;right=left+width-1
        d.rectangle((left,top+5,right,27),fill=1)
        d.rectangle((left+1,top+5,right-1,26),fill=shirt)
        if frame:
            d.line((5,28,3,31),fill=1,width=2);d.line((10,28,13,30),fill=1,width=2)
        else:
            d.line((5,28,7,31),fill=1,width=2);d.line((10,28,9,31),fill=1,width=2)
        add_person(im)
assert len(sprites)<=64
(OUT/'sprites.bin').write_bytes(b''.join(s[0] for s in sprites))
(OUT/'sprite_colors.bin').write_bytes(b''.join(s[1] for s in sprites))
for i,pal in enumerate(PALETTES):
    (OUT/f'palette{i}.bin').write_bytes(bytes(v for r,g,b in pal for v in ((r<<4)|b,g)))
metadata.update(world_rows=WORLD_ROWS, start_row=138, stations=[54,110], rivers=[[33,40],[83,90]], road_centers=centers, sprite_count=len(sprites),palettes=PALETTES,font_chars=chars,extra_font_chars=[193]+list(range(97,123))+list(extras))
(OUT/'manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
(OUT/'assets.inc').write_text('\n'.join(f'{k.upper()}_PATTERN equ {v*4}' for k,v in metadata.items() if k in ('car','cow','dust','cheese','boss','cane','runner_small','runner_tall','runner_fat'))+'\nSPRITE_BYTES equ '+str(len(sprites)*32)+'\n')
print(f'Assets: {len(sprites)} sprite patterns, 160x32 route, original 39-glyph font')
