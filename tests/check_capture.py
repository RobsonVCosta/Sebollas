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
assert v[0x3800:0x3800+len(s)]==s
assert (d/'capture-palette.bin').read_bytes()==(d/'palette0.bin').read_bytes()
assert v[0x1801:0x1806]==b'SCORE'
assert bytes(v[a] for a in (0x1819,0x181b,0x181d))==bytes([140]*3)
assert all(t in range(32,91) or 128<=t<=158 for t in v[0x1840:0x1b00])
assert v[0x1821:0x1824]==b'GAS'
print('Captured V9938: 3 pattern/color banks, sprite patterns, palette and fixed HUD match ROM assets')
