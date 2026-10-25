#!/usr/bin/env python3
"""Convert the supplied ending illustrations to MSX2 SCREEN 8 (GRB 3:3:2)."""
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
for kind, number in [("ending",1),("ending",2),("intro",0),("intro",1),("intro",2),("intro",3)]:
    source = Image.open(ROOT / f'resources/{kind}-{number}-reference.png').convert('RGB')
    assert source.size == (256, 212), source.size
    # Nearest fixed hardware color, without scaling, cropping or dithering.
    pixels = bytes((round(g * 7 / 255) << 5) | (round(r * 7 / 255) << 2)
                   | round(b * 3 / 255) for r, g, b in source.getdata())
    (ROOT / f'resources/generated/{kind}{number}.bin').write_bytes(pixels)
    preview = Image.new('RGB', source.size)
    preview.putdata([(round(((v >> 2) & 7) * 255 / 7), round((v >> 5) * 255 / 7),
                      round((v & 3) * 255 / 3)) for v in pixels])
    preview.save(ROOT / f'previews/{kind}-{number}-converted.png')
    print(f'{kind.title()} {number}: {len(pixels)} bytes, SCREEN 8, 256x212')
