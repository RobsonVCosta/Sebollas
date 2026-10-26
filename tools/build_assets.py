#!/usr/bin/env python3
"""Deterministic SCREEN 4 art. Pillow is a build-time dependency only."""
from pathlib import Path
import json
import math
import textwrap
import re
import random
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
    pal[10]=(7,6,1) # the cheese keeps the same yellow in every stage
def image(w,h,color=0): return Image.new('P',(w,h),color)
patterns=bytearray(2048); colors=bytearray([0xf1]*2048)
font=(ROOT/'resources/font-original.bin').read_bytes()
question=re.search(r'QuestionMarkGlyph:\s*db\s+([^;\n]+)',(ROOT/'string.asm').read_text(),re.I)
question_rows=bytes(int(value.strip().replace('$','0x'),0) for value in question.group(1).split(','))
assert len(question_rows)==8
patterns[63*8:64*8]=question_rows
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
extras={33:[0x18,0x18,0x18,0x18,0x18,0,0x18,0],47:[0x03,0x06,0x0c,0x18,0x30,0x60,0xc0,0],40:[0x0e,0x18,0x30,0x30,0x30,0x18,0x0e,0],
41:[0x70,0x18,0x0c,0x0c,0x0c,0x18,0x70,0],
44:[0,0,0,0,0,0x18,0x18,0x30],46:[0,0,0,0,0,0x18,0x18,0],
240:[0,0x3e,0x63,0x60,0x63,0x3e,0x0c,0x18],
241:[0x0c,0x18,0x3e,0x63,0x7f,0x60,0x3e,0],
242:[0x0c,0x18,0x3e,0x63,0x63,0x63,0x3e,0],
243:[0x18,0x24,0x3e,0x63,0x7f,0x60,0x3e,0],
244:[0x3e,0x63,0x60,0x60,0x63,0x3e,0x0c,0x18],
245:[0x0c,0x18,0,0x38,0x18,0x18,0x3c,0]}
for ch,rows in extras.items(): patterns[ch*8:ch*8+8]=bytes(rows)
CREDIT_PARAGRAPHS=[
'Essa foi a aventura de Argon, Gordinho (Leto) e Robson em sua jornada de Nova Iguaçu até Sebollas.',
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
(OUT/'credits_text.json').write_text(json.dumps({'paragraphs':CREDIT_PARAGRAPHS,'rows':credit_rows,'pixel_rows':[(y*8+3*i,x,line) for i,(y,x,line) in enumerate(credit_rows,1)]},ensure_ascii=False,indent=2)+'\n')
PROLOGUE_PARAGRAPHS=[
'Em 1991, três amigos resolveram visitar Sebollas. Este jogo conta a história da saga de Argon, Robson e Wellington durante essa aventura.',
'Foi mais ou menos assim...']
prologue_rows=[]; row=5
for paragraph in PROLOGUE_PARAGRAPHS:
    for line in textwrap.wrap(paragraph,28):
        prologue_rows.append((row,(32-len(line))//2,line)); row+=1
    row+=2
records=[]
for y,x,line in prologue_rows:
    records.extend([y,x]+[{'ê':243,**encoding}.get(ch,ord(ch)) for ch in line]+[0])
records.append(255)
(OUT/'prologue.inc').write_text(''.join('    db '+','.join(map(str,records[i:i+64]))+'\n' for i in range(0,len(records),64)))
(OUT/'prologue_text.json').write_text(json.dumps({'paragraphs':PROLOGUE_PARAGRAPHS,'rows':prologue_rows,'pixel_rows':[(y*8+3*i,x,line) for i,(y,x,line) in enumerate(prologue_rows)]},ensure_ascii=False,indent=2)+'\n')
# Scenery uses free tile IDs; the cane arena swaps 186..201 temporarily.
tiles={}
def tile(idx,bg,fg,rows):
    bg={6:13,13:1}.get(bg,bg)
    fg={6:13,13:1}.get(fg,fg)
    patterns[idx*8:idx*8+8]=bytes(rows)
    colors[idx*8:idx*8+8]=bytes([fg*16+bg]*8)
    tiles[idx]=[bg,fg]
tile(128,3,2,[0,0x10,0x28,0x10,0,2,5,2]) # tufts of pasture grass
tile(129,3,12,[0,0x48,0x54,0x10,0,0x02,0x15,0x08])
tile(130,6,7,[0,0,0x20,0,0,2,0,0]) # packed dirt
# Approved option 2: four native sizes, with angular edges and contact shadows.
ROAD_STONES=json.loads((ROOT/'resources/road-stones.json').read_text())
ROAD_STONE_TILES=tuple(ROAD_STONES['tiles'])
DRIVABLE_TILES=(130,146,157,159)+ROAD_STONE_TILES
for idx,variant in zip(ROAD_STONE_TILES,ROAD_STONES['variants']):
    tile(idx,13,14,variant['rows'])
    colors[idx*8:idx*8+8]=bytes(fg*16+13 for fg in variant['fg'])
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
tile(159,7,1,[0xff,0,0,0,0xff,0,0,0]) # wooden fishing deck
tile(160,3,2,[0,0x07,0x1f,0x3f,0x7d,0x3f,0x1a,0]) # shrub, left/right
tile(161,3,12,[0,0xe0,0xf8,0xfc,0xbe,0xfc,0x58,0])
tile(162,3,15,[0,0x10,0x38,0x10,0x10,0x28,0x10,0]) # wildflowers
for row,fg in ((3,10),(4,2),(5,2),(6,2)): colors[162*8+row]=fg*16+3
tile(163,4,3,[0x22,0x36,0x22,0x22,0x6a,0x26,0x22,0]) # reeds on the water
tile(164,3,14,[0,0,0x0c,0x1e,0x0c,0,0x60,0xf0]) # field stones
tile(165,3,12,[0,0x44,0xaa,0x44,0,0x11,0x2a,0x11]) # planted green patches

# Broad 24x24 trees: native two-color tile rows, shaded foliage and a trunk.
TREE_TILES=(186,187,188,189,190,191,192,194,195) # leave the VAVÁ glyph intact
tree=image(24,24,3);td=ImageDraw.Draw(tree)
td.rectangle((9,12,13,23),fill=13)
td.line((11,16,11,22),fill=7)
td.polygon([(8,0),(15,0),(15,2),(19,2),(19,5),(22,5),(22,13),
            (19,13),(19,17),(14,17),(14,19),(7,19),(7,17),(2,17),
            (2,14),(0,14),(0,7),(3,7),(3,3),(8,3)],fill=2)
td.polygon([(8,2),(14,2),(14,4),(18,4),(18,7),(20,7),(20,12),
            (16,12),(16,15),(11,15),(11,17),(6,16),(6,13),(3,13),
            (3,8),(6,8),(6,5),(8,5)],fill=12)
for x,y in ((9,3),(6,6),(14,5),(16,9),(7,11),(11,13),(4,9)):
    td.line((x,y,x+1,y),fill=3)
for q,idx in enumerate(TREE_TILES):
    xx,yy=q%3*8,q//3*8
    for y in range(8):
        values=[tree.getpixel((xx+x,yy+y)) for x in range(8)]
        common=[v for v,n in Counter(values).most_common(2)]
        if len(common)==1: common.append(common[0])
        bg,fg=common
        chosen=[min(common,key=lambda c:sum((u-v)**2 for u,v in zip(PALETTES[0][color],PALETTES[0][c]))) for color in values]
        patterns[idx*8+y]=sum(128>>x for x,color in enumerate(chosen) if color==fg)
        colors[idx*8+y]=fg*16+bg
    tiles[idx]=[3,2]
# Closed track with a sliding needle, without E/F lettering.
tile(166,1,14,[0,0x3f,0x20,0x20,0x20,0x20,0x3f,0])
tile(167,1,14,[0,0xfc,0x04,0x04,0x04,0x04,0xfc,0])
tile(168,1,14,[0,0xff,0,0,0,0,0xff,0])
for x in range(8):
    mask=128>>x
    tile(169+x,1,15,[mask,0xff,mask,mask,mask,mask,0xff,mask])
    tile(177+x,1,8,[mask,0xff,mask,mask,mask,mask,0xff,mask])
tile(184,6,11,[0x18,0x18,0x18,0x18,0x18,0,0x18,0x18])
tile(185,6,11,[0x18,0x18,0x18,0,0x18,0x18,0x18,0x18])
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
# Remove quiet stretches while keeping both bridges, decks, home and meeting.
FISHING_ROWS=[y for y in range(WORLD_ROWS) if not (14<=y<=25 or 62<=y<=73 or 122<=y<=127)]
def fishing_row(source_row): return FISHING_ROWS.index(source_row)
FISHING_START_ROW=fishing_row(138)
FISHING_STATIONS=[fishing_row(y) for y in (54,110)]
def make_route(stage):
    suffix='' if stage==2 else str(stage)
    world=[]
    centers=[]
    for y in range(WORLD_ROWS):
        shift=round((3 if stage<2 else 4)*math.sin(y*math.pi/40))
        left,right=10+shift,21+shift
        for lo,hi in (() if stage!=2 else ((28,47),(78,97))):
            if lo<=y<=hi:
                inset=min(5,y-lo+1,hi-y+1)
                left,right=8+shift+inset,23+shift-inset
        if stage==2 and 123<=y<=132: left,right=11+shift,20+shift
        if stage==3: left,right=12+shift,19+shift
        if stage==1: left,right=11+shift,20+shift
        if stage==0: left,right=9+shift,22+shift
        if stage==2 and y<30:
            # A centered approach ends at the bar, with no side passage.
            half=min(4,max(0,(y-12)//4))
            left,right=15-half,16+half
        centers.append(((left+right)//2)*8)
        river=33<=y<=40 or 83<=y<=90
        row=[]
        for x in range(32):
            t=129 if (x//3*3+y//5+stage)%4==0 else 128
            if (x*13+y*7)%41==0: t=162
            elif (x+2*y)%43==0: t=164
            elif (x//4+y//7+stage)%9==0: t=165
            if river:
                t=146 if left<=x<=right else 147 if x in (left-1,right+1) else 145
                if t==145 and y in (33,40,83,90) and x%4==2: t=163
            elif left<=x<=right:
                t=131 if ((x+1)*(y+13)*19+y*y*7+stage*31)%37<5 else 130
            elif x==left-1: t=132
            elif x==right+1: t=133
            elif x in (left-3,right+3): t=134
            elif (x+y*5)%37==0: t=138
            row.append(t)
        world.append(row)
    plain=(128,129,138,160,161,162,164,165)
    for side,offset in ((0,5+stage),(29,11+stage)):
        for top in range(offset,157,12):
            if all(world[top+dy][side+dx] in plain for dy in range(3) for dx in range(3)):
                for dy in range(3): world[top+dy][side:side+3]=TREE_TILES[dy*3:dy*3+3]
    for y in range(4,158,7):
        for x in (3,26):
            if all(world[y][x+dx] in plain for dx in range(2)):
                world[y][x:x+2]=[160,161]
    def label(y,x,text): world[y][x:x+len(text)]=map(ord,text)
    def house(y,x,name):
        if name: label(y-1,x,name)
        world[y][x:x+6]=[148,149,149,149,149,150]
        world[y+1][x:x+6]=[149]*6
        world[y+2][x:x+6]=[151,152,151,151,152,151]
        world[y+3][x:x+6]=[151,151,153,153,151,151]
        world[y+4][x:x+6]=[151,151,153,153,151,151]
    # Vava's home is beside the initial car; the destination faces its driveway.
    for y in range(150,157): world[y][3:16]=[157]*13
    house(148,1,'VAVÁ' if stage>=2 else '')
    if stage==2:
        for y in range(7,19): world[y][13:19]=[157]*6
        house(2,13,'BAR')
    # The route now ends in an enemy encounter, without a destination house.
    for y in (54,110):
        if stage<2:
            for yy in range(y-2,y+8):
                world[yy][24:32]=[145]*8
                left=min(centers[yy]//8+3,20)
                world[yy][left:25]=[159]*(25-left)
            label(y-3,24,'PESCA')
        else:
            for yy in range(y-2,y+8): world[yy][min(centers[yy]//8+4,21):28]=[157]*(28-min(centers[yy]//8+4,21))
            label(y-3,24,'POSTO')
            world[y][25:27]=[154,156]
            world[y+1][25:27]=[155,156]
            world[y+2][25:27]=[158,128]
    if stage==0:
        # Keep the 160-row RAM bundle; its unused tail pads the shorter route.
        world=[world[y] for y in FISHING_ROWS]
        centers=[centers[y] for y in FISHING_ROWS]
        world.extend([world[-1].copy() for _ in range(WORLD_ROWS-len(world))])
        centers.extend([centers[-1]]*(WORLD_ROWS-len(centers)))
    for y,row in enumerate(world):
        for x,t in enumerate(row):
            if t==131:
                choice=random.Random(y*32+x+1991).choice(ROAD_STONES['weights'])
                row[x]=ROAD_STONE_TILES[choice]
    (OUT/f'road_centers{suffix}.bin').write_bytes(bytes(centers))
    # Drivable limits for the complete 16px-wide car; include station forecourts.
    road_bounds=[]
    for y,row in enumerate(world):
        columns=[x for x,t in enumerate(row) if t in DRIVABLE_TILES]
        if stage==2 and y<7:
            road_bounds.extend((120,120))
            continue
        middle=min(columns,key=lambda x:abs(x-centers[y]//8))
        left=right=middle
        while left>0 and row[left-1] in DRIVABLE_TILES: left-=1
        while right<31 and row[right+1] in DRIVABLE_TILES: right+=1
        road_bounds.extend((left*8,right*8-8))
    (OUT/f'road_bounds{suffix}.bin').write_bytes(bytes(road_bounds))
    (OUT/f'world{suffix}.bin').write_bytes(bytes(t for row in world for t in row))
    (OUT/f'route{stage}.bin').write_bytes(bytes(t for row in world for t in row)+bytes(centers)+bytes(road_bounds))
    return world,centers
world,centers=make_route(2)
make_route(0)
make_route(1)
make_route(3)
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
sprites.extend([(bytes(32),bytes(16))]*2) # slots 6/7 complete the walking trio
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
    # A rounded wheel with a pale upper rim, depth and rotating clear holes.
    # One hardware sprite per frame preserves the scanline budget.
    im=image(16,16);d=ImageDraw.Draw(im)
    d.ellipse((1,3,14,14),fill=10)
    d.ellipse((1,1,14,11),fill=10)
    for x,y in ((5,4),(10,6),(6,9)):
        if frame: x,y=14-y,x
        d.rectangle((x,y,x+1,y+1),fill=0)
    d.point((1,10),fill=0);d.point((14,10),fill=0)
    line_colors=[11 if 1<=y<=9 else 10 for y in range(16)]
    add_mask(im,[{10}]*16,line_colors)
    levels=(0,43,81,118,153,187,221,255)
    preview=Image.new('RGBA',(16,16))
    for y in range(16):
        color=tuple(levels[c] for c in PALETTES[0][line_colors[y]])+(255,)
        for x in range(16):
            if im.getpixel((x,y)): preview.putpixel((x,y),color)
    preview.save(ROOT/f'previews/round-cheese-{frame}.png')
    preview.resize((256,256),Image.NEAREST).save(ROOT/f'previews/round-cheese-{frame}-16x.png')
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
def add_reference_person(filename,size,palette_index,preview,canvas=(32,32),palette_override=None,fixed_pair=None,source_image=None):
    # Preserve the reference's proportions inside a 32x32 hardware sprite group.
    reference=(source_image.copy() if source_image is not None else Image.open(ROOT/'resources'/filename)).convert('RGBA')
    reference=reference.resize(size,Image.NEAREST)
    boss_source=Image.new('RGBA',canvas);boss_source.paste(reference,((canvas[0]-size[0])//2,0))
    levels=(0,43,81,118,153,187,221,255)
    boss_rgb=[tuple(levels[v] for v in rgb) for rgb in (palette_override or PALETTES[palette_index])]
    boss=image(*canvas)
    # Two masks per quadrant, with CC overlap: up to three colors on each row.
    # Select the hardware color pair that best matches each half-row of the art.
    for yy in range(0,canvas[1],16):
        for xx in range(0,canvas[0],16):
            first=[];second=[];first_colors=[];second_colors=[]
            for y in range(16):
                source=[boss_source.getpixel((xx+x,yy+y)) for x in range(16)]
                opaque=[rgb[:3] for rgb in source if rgb[3]>=128]
                def error(rgb,index): return sum((a-b)**2 for a,b in zip(rgb,boss_rgb[index]))
                allowed={1,4,5,6,7,8,9,10,11,13,15} # keep skin/hair/cloth hues; never green
                if palette_override: allowed.add(14)
                pairs=((a,b) for a in sorted(allowed) for b in sorted(allowed) if a<=b and (a|b) in allowed)
                if fixed_pair: pairs=[fixed_pair]
                c1,c2=min(pairs,key=lambda pair:sum((2 if min(rgb)>220 else 1)*min(error(rgb,c) for c in {pair[0],pair[1],pair[0]|pair[1]}) for rgb in opaque))
                combined=c1|c2
                for x,rgba in enumerate(source):
                    if rgba[3]>=128:
                        color=min({c1,c2,combined},key=lambda c:error(rgba[:3],c))
                        boss.putpixel((xx+x,yy+y),color)
                first.append({c1,combined});second.append({c2,combined})
                first_colors.append(c1);second_colors.append(0x40|c2)
            part=boss.crop((xx,yy,xx+16,yy+16))
            add_mask(part,first,first_colors)
            add_mask(part,second,second_colors)
    boss_preview=Image.new('RGBA',canvas)
    boss_preview.putdata([(*boss_rgb[color],255) if color else (0,0,0,0) for color in boss.getdata()])
    boss_preview.save(ROOT/f'previews/{preview}.png')
    boss_preview.resize((canvas[0]*8,canvas[1]*8),Image.NEAREST).save(ROOT/f'previews/{preview}-8x.png')
metadata['boss']=len(sprites)
add_reference_person('garapa-reference.png',(20,32),2,'garapa-sprite')
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
# The supplied side-view strip replaces the old generic front-facing runners.
runner_strip=Image.open(ROOT/'resources/runners-reference.png').convert('RGBA')
assert runner_strip.size==(48,32)
# Remove only the connected white backdrop; preserve whites inside the figures.
stack=[(x,y) for x in range(48) for y in (0,31)]+[(x,y) for x in (0,47) for y in range(32)]
seen=set()
while stack:
    x,y=stack.pop()
    if not(0<=x<48 and 0<=y<32) or (x,y) in seen: continue
    seen.add((x,y));r,g,b,alpha=runner_strip.getpixel((x,y))
    if min(r,g,b)<245: continue
    runner_strip.putpixel((x,y),(r,g,b,0))
    stack.extend(((x-1,y),(x+1,y),(x,y-1),(x,y+1)))
# Trim neutral antialiasing outside each figure, so the white matte does not
# turn into a bright outline against the road. Interior shirt/shoe whites stay.
for cell in range(3):
    for y in range(32):
        strong=[]
        for x in range(16):
            r,g,b,alpha=runner_strip.getpixel((cell*16+x,y))
            if alpha and (min(r,g,b)<120 or max(r,g,b)-min(r,g,b)>45): strong.append(x)
        left,right=(min(strong),max(strong)) if strong else (16,-1)
        for x in range(16):
            r,g,b,alpha=runner_strip.getpixel((cell*16+x,y))
            if (x<left or x>right) and min(r,g,b)>120 and max(r,g,b)-min(r,g,b)<30:
                runner_strip.putpixel((cell*16+x,y),(r,g,b,0))
for index,name in enumerate(('runner_small','runner_tall','runner_fat')):
    metadata[name]=len(sprites)
    source=runner_strip.crop((index*16,0,index*16+16,32))
    for frame in range(2):
        pose=source.copy()
        if frame:
            for y in range(27,32):
                for x in range(16): pose.putpixel((x,y),(0,0,0,0))
            for y in range(27,32):
                for x in range(16):
                    pixel=source.getpixel((x,y));dx=-1 if x<8 else 1
                    if pixel[3] and 0<=x+dx<16: pose.putpixel((x+dx,y),pixel)
        add_reference_person('runners-reference.png',(16,32),2,f'{name}-{frame}',canvas=(16,32),source_image=pose)
assert len(sprites)<=64
(OUT/'sprites.bin').write_bytes(b''.join(s[0] for s in sprites))
(OUT/'sprite_colors.bin').write_bytes(b''.join(s[1] for s in sprites))
for i,pal in enumerate(PALETTES):
    (OUT/f'palette{i}.bin').write_bytes(bytes(v for r,g,b in pal for v in ((r<<4)|b,g)))
metadata.update(road_stone_tiles=ROAD_STONE_TILES, fishing_start_row=FISHING_START_ROW, fishing_stations=FISHING_STATIONS, fishing_rivers=[[fishing_row(a),fishing_row(b)] for a,b in ((33,40),(83,90))],world_rows=WORLD_ROWS, start_row=138, stations=[54,110], rivers=[[33,40],[83,90]], road_centers=centers, sprite_count=len(sprites),palettes=PALETTES,font_chars=chars,extra_font_chars=[63,193]+list(range(97,123))+list(extras),scenery_tiles=sorted(tiles))
(OUT/'manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
(OUT/'assets.inc').write_text('\n'.join(f'{k.upper()}_PATTERN equ {v*4}' for k,v in metadata.items() if k in ('car','cow','dust','cheese','boss','cane','runner_small','runner_tall','runner_fat'))+'\nSPRITE_BYTES equ '+str(len(sprites)*32)+'\n'+f'FISHING_START_ROW equ {FISHING_START_ROW}\nFISHING_FIRST_DECK equ {FISHING_STATIONS[0]}\nFISHING_SECOND_DECK equ {FISHING_STATIONS[1]}\n')
print(f'Assets: {len(sprites)} sprite patterns, 160x32 route, original 39-glyph font')

# Alternate boss graphics share the garapa VRAM slots during the second fight.
base=len(sprites)
cheese_fight_palette=list(PALETTES[1])
cheese_fight_palette[9]=(7,4,2)
cheese_fight_palette[14]=(7,4,2)
(OUT/'cheese_fight_palette.bin').write_bytes(bytes(v for r,g,b in cheese_fight_palette for v in ((r<<4)|b,g)))
add_reference_person('cheese-man-reference.png',(32,32),1,'cheese-man-sprite',palette_override=cheese_fight_palette)
(OUT/'cheese_boss_patterns.bin').write_bytes(b''.join(p for p,c in sprites[base:]))
(OUT/'cheese_boss_colors.bin').write_bytes(b''.join(c for p,c in sprites[base:]))
del sprites[base:]
add_reference_person('enemy-cheese-reference.png',(16,16),1,'enemy-cheese-sprite',canvas=(16,16),palette_override=cheese_fight_palette,fixed_pair=(10,13))
(OUT/'enemy_cheese_patterns.bin').write_bytes(b''.join(p for p,c in sprites[base:]))
(OUT/'enemy_cheese_colors.bin').write_bytes(b''.join(c for p,c in sprites[base:]))
del sprites[base:]

base=len(sprites)
add_reference_person('trio-reference.png',(32,32),0,'trio-sprite')
(OUT/'trio_patterns.bin').write_bytes(b''.join(p for p,c in sprites[base:]))
(OUT/'trio_colors.bin').write_bytes(b''.join(c for p,c in sprites[base:]))
del sprites[base:]

# The full-size donkey replaces the walking stages' dogs, in both directions.
source=Image.open(ROOT/'resources/donkey-reference.png').convert('RGBA')
source=source.crop(source.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox())
source=source.resize((32,32),Image.NEAREST)
base=len(sprites)
for direction in (0,1):
    pose=source if direction==0 else source.transpose(Image.FLIP_LEFT_RIGHT)
    add_reference_person('',(32,32),0,f'donkey-{direction}',source_image=pose,palette_override=PALETTES[0],fixed_pair=(1,14))
(OUT/'donkey_patterns.bin').write_bytes(b''.join(p for p,c in sprites[base:]))
(OUT/'donkey_colors.bin').write_bytes(b''.join(c for p,c in sprites[base:]))
del sprites[base:]

# Garapa is a tile actor in the collection arena, leaving all 32 sprite slots
# for the trio and three full-size, multicolor donkeys.
garapa=Image.open(ROOT/'resources/garapa-reference.png').convert('RGBA').resize((20,32),Image.NEAREST)
canvas=Image.new('RGBA',(32,32));canvas.paste(garapa,(6,0))
levels=(0,43,81,118,153,187,221,255)
pal=[tuple(levels[c] for c in color) for color in PALETTES[0]]
bg_patterns=bytearray();bg_colors=bytearray()
for yy in range(0,32,8):
    for xx in range(0,32,8):
        for y in range(8):
            pixels=[canvas.getpixel((xx+x,yy+y)) for x in range(8)]
            colors_for_row=[min(range(1,16),key=lambda c:sum((u-v)**2 for u,v in zip(pixel[:3],pal[c]))) if pixel[3]>=128 else 13 for pixel in pixels]
            common=[c for c,n in Counter(colors_for_row).most_common(2)]
            if len(common)==1: common.append(common[0])
            bg,fg=common
            chosen=[min(common,key=lambda c:sum((u-v)**2 for u,v in zip(pal[color],pal[c]))) for color in colors_for_row]
            bg_patterns.append(sum(128>>x for x,color in enumerate(chosen) if color==fg))
            bg_colors.append(fg*16+bg)
(OUT/'garapa_tile_patterns.bin').write_bytes(bg_patterns)
(OUT/'garapa_tile_colors.bin').write_bytes(bg_colors)
