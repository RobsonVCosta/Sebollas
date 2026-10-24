#!/usr/bin/env python3
"""Remove openMSX's 32x24 border and export nearest-neighbor copies."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
for name in ('abertura','gameplay','gameover','posto','ponte','chegada'):
    src=ROOT/f'previews/{name}-openmsx-raw.png'
    im=Image.open(src)
    assert im.size==(320,240),im.size
    im=im.crop((32,24,288,216))
    assert im.getbbox(),f"Empty emulator capture: {src}"
    im.save(ROOT/f'previews/{name}-openmsx.png')
    im.resize((1024,768),Image.NEAREST).save(ROOT/f'previews/{name}-openmsx-4x.png')
print('Native emulator captures and 4x copies exported')
