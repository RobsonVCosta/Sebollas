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
def scene_sprites():
    s=[]
    for half in range(2):
        for layer in range(3): s.append((104,128+half*16,META['car']+half*3+layer))
    s.append((104,160,META['dust']+2))
    for x,y,direction,pose in [(84,48,0,0),(154,112,1,1)]:
        start=META['cow']+(direction*2+pose)*8
        for q in range(4):
            for layer in range(2): s.append((x+(q%2)*16,y+(q//2)*16,start+q*2+layer))
    for y in (24,88): s.append((104,y,META['bullet']))
    return s

def render(style=0):
    pixels=[0]*(256*192)
    tilemap=[32]*64
    for row in range(22):
        start=((57+row)%64)*32
        tilemap.extend(WORLD[start:start+32])
    def text(row,col,s):
        for i,c in enumerate(s): tilemap[row*32+col+i]=ord(c)
    text(0,1,'SCORE 00001200');text(0,22,'VIDAS 3')
    for ty in range(24):
        for tx in range(32):
            ch=tilemap[ty*32+tx]
            for y in range(8):
                bits=PAT[ch*8+y]; color=COL[ch*8+y]
                for x in range(8): pixels[(ty*8+y)*256+tx*8+x]=(color>>4) if bits&(128>>x) else color&15
    sprites=scene_sprites()
    counts=[0]*192
    for x,y,n in sprites:
        for sy in range(max(0,y),min(192,y+16)): counts[sy]+=1
    assert max(counts)<=8,max(counts)
    # Lower SAT entry has priority. Draw reversed, skip transparent pixels.
    for x,y,n in reversed(sprites):
        for sy in range(16):
            color=SCOL[n*16+sy]&15
            for sx in range(16):
                bits=SPR[n*32+(16 if sx>=8 else 0)+sy]
                if color and bits&(128>>(sx%8)) and 0<=x+sx<256 and 0<=y+sy<192:
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
