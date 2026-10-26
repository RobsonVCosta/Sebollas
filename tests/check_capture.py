#!/usr/bin/env python3
"""Check the actual emulated SCREEN 4 VRAM against the packaged ROM assets."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
d=ROOT/'resources/generated'
v=(d/'capture-vram.bin').read_bytes()
p=(d/'patterns.bin').read_bytes(); c=(d/'colors.bin').read_bytes()
for bank in range(3):
    assert v[bank*2048:(bank+1)*2048]==p,f'pattern bank {bank}'
    assert v[0x2000+bank*2048:0x2000+(bank+1)*2048]==c,f'color bank {bank}'
s=(d/'sprites.bin').read_bytes()
expected_sprites=(d/'trio_patterns.bin').read_bytes()+(d/'donkey_patterns.bin').read_bytes()+s[768:]
assert v[0x3800:0x3800+len(s)]==expected_sprites
assert (d/'capture-palette.bin').read_bytes()==(d/'palette0.bin').read_bytes()
assert v[0x1801:0x1806]==b'SCORE'
assert bytes(v[a] for a in (0x181b,0x181c,0x181d,0x181e,0x181f))==bytes([140]*5)
assert all(t==193 or t in range(32,91) or 128<=t<=199 or t in (232,233,234) for t in v[0x1840:0x1b00])
assert v[0x1821:0x1825]==b'FOME'
assert v[0x1840-10:0x1840]==b'          '
print('Captured V9938: 3 pattern/color banks, sprite patterns, palette and fixed HUD match ROM assets')

# Compare every pixel of the cheese over the bridge, including its clear border.
# This catches a solid rectangle even when it blends into the dirt road.
import json
from PIL import Image
meta=json.loads((d/'manifest.json').read_text())
world=(d/'world.bin').read_bytes()
palette=(d/'palette1.bin').read_bytes()
levels=(0,43,81,118,153,187,221,255)
def rgb(index):
    rb,g=palette[index*2:index*2+2]
    return levels[rb>>4],levels[g],levels[rb&15]
bridge=Image.open(ROOT/'previews/ponte-openmsx.png').convert('RGB')
pattern=meta['cheese']
for y in range(16):
    for x in range(16):
        bits=s[pattern*32+(16 if x>=8 else 0)+y]
        if bits&(128>>(x%8)):
            color=(d/'sprite_colors.bin').read_bytes()[pattern*16+y]&15
        else:
            px,py=144+x,96+y
            tile=world[(76+(py-16)//8)*32+px//8]
            bits=p[tile*8+py%8]
            line=c[tile*8+py%8]
            color=line>>4 if bits&(128>>(px%8)) else line&15
        assert bridge.getpixel((144+x,96+y))==rgb(color),(x,y)
print('Captured cheese: transparent border and holes preserve the actual bridge pixels')

# The opening uses SCREEN 5 and its own palette; PLAY may be on or off.
opening=(d/'capture-title-vram.bin').read_bytes()
expected=bytearray((d/'title_bitmap.bin').read_bytes())
assert (d/'capture-title-palette.bin').read_bytes()==(d/'title_palette.bin').read_bytes()
for row in range(212):
    for col in range(128):
        if 100<=row<108 and 76<=col<96: continue
        pos=row*128+col
        assert opening[pos]==expected[pos],('title',row,col)
assert Image.open(ROOT/'previews/abertura-openmsx.png').size==(256,212)
print('Captured title: full 256x212 SCREEN 5 bitmap and dedicated palette match ROM assets')

# Verify every requested letter at its pixel position, including 11px line pitch.
encoding={'ç':240,'é':241,'ó':242,'ê':243,'Ç':244,'í':245}
for name in ('prologue','credits'):
    text_vram=(d/f'capture-{name}-vram.bin').read_bytes()
    rows=json.loads((d/f'{name}_text.json').read_text())['pixel_rows']
    if name=='credits': rows=[[8,12,'CREDITOS']]+rows
    def pattern_byte(x,y):
        tile=text_vram[0x1800+(y//8)*32+x]
        return text_vram[(y//64)*2048+tile*8+y%8]
    for y,x,line in rows:
        for col,ch in enumerate(line,x):
            code=encoding.get(ch,ord(ch))
            actual=bytes(pattern_byte(col,y+i) for i in range(8))
            assert actual==p[code*8:code*8+8],(name,y,col,ch)
        for gap in range(8,11):
            assert all(pattern_byte(col,y+gap)==0 for col in range(32)),(name,'extra gap',y+gap)
    print(f'Captured {name}: font, accents and three extra pixels between lines match')
