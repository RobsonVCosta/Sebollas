#!/usr/bin/env python3
"""Render native SCREEN 4 pixels from ROM assets, not AI concept pixels."""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'resources/generated'
OUT=ROOT/'previews'
OUT.mkdir(exist_ok=True)
META=json.loads((DATA/'manifest.json').read_text())
PAT=(DATA/'patterns.bin').read_bytes()
COL=(DATA/'colors.bin').read_bytes()
WORLD=(DATA/'world.bin').read_bytes()
SPR=(DATA/'sprites.bin').read_bytes()
SCOL=(DATA/'sprite_colors.bin').read_bytes()
def scene_sprites(map_row=76):
    s=[]
    for half in range(2):
        for layer in range(3): s.append((136,128+half*16,META['car']+half*3+layer))
    s.append((136,160,META['dust']+2))
    for y,direction in [(24,0),(152,1)]:
        x=META["road_centers"][map_row+y//8]-8
        start=META['cow']+direction*8
        for q in range(4):
            for layer in range(2): s.append((x+(q%2)*16,y+(q//2)*16,start+q*2+layer))
    s.append((144,96,META['cheese']))
    return s

def render(style=0, map_row=76, with_sprites=True):
    pixels=[0]*(256*192)
    tilemap=[32]*64
    for row in range(22):
        start=(map_row+row)*32
        tilemap.extend(WORLD[start:start+32])
    def text(row,col,s):
        for i,c in enumerate(s): tilemap[row*32+col+i]=ord(c)
    text(0,1,'SCORE 00001200');text(0,25,chr(140)+' '+chr(140)+' '+chr(140))
    text(0,17,'FASE 1')
    text(1,1,'GAS E'+chr(168)*6+chr(173)+chr(168)*3+'F')
    text(1,18,'QUEIJOS 03')
    for ty in range(24):
        for tx in range(32):
            ch=tilemap[ty*32+tx]
            for y in range(8):
                bits=PAT[ch*8+y]; color=COL[ch*8+y]
                for x in range(8): pixels[(ty*8+y)*256+tx*8+x]=(color>>4) if bits&(128>>x) else color&15
    sprites=scene_sprites(map_row) if with_sprites else []
    counts=[0]*192
    for x,y,n in sprites:
        for sy in range(max(0,y),min(192,y+16)): counts[sy]+=1
    assert max(counts)<=8,max(counts)
    # Consecutive CC layers combine with their preceding normal layer.
    groups=[]
    for sprite in sprites:
        if SCOL[sprite[2]*16]&0x40:
            groups[-1].append(sprite)
        else:
            groups.append([sprite])
    for group in reversed(groups):
        x,y,n=group[0]
        for sy in range(16):
            for sx in range(16):
                color=0
                for _,_,pattern in group:
                    bits=SPR[pattern*32+(16 if sx>=8 else 0)+sy]
                    if bits&(128>>(sx%8)): color|=SCOL[pattern*16+sy]&15
                if color and 0<=x+sx<256 and 0<=y+sy<192:
                    pixels[(y+sy)*256+x+sx]=color
    im=Image.new('P',(256,192));im.putdata(pixels)
    levels=(0,43,81,118,153,187,221,255) # openMSX default V9938 RGB levels
    rgb=[levels[v] for c in META['palettes'][style] for v in c]
    im.putpalette(rgb+[0]*(768-len(rgb)))
    return im.convert('RGB')
if __name__=='__main__':
    for i,name in enumerate(['01-pasto-fusca-amarelo','02-terra-vermelha-fusca-azul','03-fazenda-seca-fusca-vermelho']):
        im=render(i)
        im.save(OUT/(name+'.png'))
        im.resize((1024,768),Image.NEAREST).save(OUT/(name+'-4x.png'))
    print('Three 256x192 previews and 4x nearest-neighbor copies saved to previews/')
