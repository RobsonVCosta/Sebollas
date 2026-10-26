#!/usr/bin/env python3
"""Convert the supplied title art into a native MSX2 SCREEN 5 opening."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'resources/generated'
OUT.mkdir(exist_ok=True)
source=Image.open(ROOT/'resources/title-reference.png').convert('RGB')
assert source.size==(256,212)
# Preserve the art; reserve the second action for the runtime Continue menu.
background=(1,39,159)
d=ImageDraw.Draw(source)
d.rectangle((144,90,201,116),fill=background)
d.rectangle((152,112,223,119),fill=background)
font=(ROOT/'resources/font-original.bin').read_bytes()
chars=[32,127,45]+list(range(48,58))+list(range(65,91))
for i,ch in enumerate('PLAY'):
    rows=font[chars.index(ord(ch))*8:chars.index(ord(ch))*8+8]
    for y,bits in enumerate(rows):
        for x in range(8):
            if bits&(128>>x): source.putpixel((160+i*8+x,100+y),(255,255,220))
d.polygon([(152,101),(157,104),(152,107)],fill=(255,255,220))
# Quantize the source and round the palette to the hardware's 3-bit RGB space.
quantized=source.quantize(colors=16,method=Image.MEDIANCUT,dither=Image.NONE)
rawpal=quantized.getpalette()
levels=(0,43,81,118,153,187,221,255)
palette=[]
for i in range(16):
    rgb=rawpal[i*3:i*3+3]
    palette.append(tuple(min(range(8),key=lambda j:abs(levels[j]-v)) for v in rgb))
black=min(range(16),key=lambda i:sum(palette[i]))
palette[0],palette[black]=palette[black],palette[0]
palette[0]=(0,0,0)
# Map source pixels directly to the representable colors; no blurred resampling.
rgbpal=[tuple(levels[c] for c in rgb) for rgb in palette]
cache={}
def nearest(rgb):
    if rgb not in cache:
        cache[rgb]=min(range(16),key=lambda i:sum((a-b)**2 for a,b in zip(rgb,rgbpal[i])))
    return cache[rgb]
pixels=[nearest(rgb) for rgb in source.getdata()]
bitmap=bytes((pixels[i]<<4)|pixels[i+1] for i in range(0,len(pixels),2))
# Command stream: 0=end; 1..127=literal count; 128..255=repeat count minus 3.
def compress(data):
    result=bytearray();literals=bytearray();i=0
    def flush():
        while literals:
            n=min(127,len(literals));result.append(n)
            result.extend(literals[:n]);del literals[:n]
    while i<len(data):
        run=1
        while i+run<len(data) and data[i+run]==data[i] and run<130: run+=1
        if run>=3:
            flush();result.extend((128+run-3,data[i]));i+=run
        else:
            literals.append(data[i]);i+=1
            if len(literals)==127: flush()
    flush();result.append(0)
    return bytes(result)
packed=compress(bitmap)
play=b''.join(bitmap[y*128+76:y*128+96] for y in range(100,108))
# Continue uses the same quantized palette and original font as PLAY.
continued=source.copy()
for i,ch in enumerate('CONTINUE'):
    rows=font[chars.index(ord(ch))*8:chars.index(ord(ch))*8+8]
    for y,bits in enumerate(rows):
        for x in range(8):
            if bits&(128>>x): continued.putpixel((160+i*8+x,112+y),(255,255,220))
ImageDraw.Draw(continued).polygon([(152,113),(157,116),(152,119)],fill=(255,255,220))
cpixels=[nearest(rgb) for rgb in continued.getdata()]
cbitmap=bytes((cpixels[i]<<4)|cpixels[i+1] for i in range(0,len(cpixels),2))
continue_button=b''.join(cbitmap[y*128+76:y*128+112] for y in range(112,120))
(OUT/'title_continue.bin').write_bytes(continue_button)
(OUT/'title.rle').write_bytes(packed)
(OUT/'title_bitmap.bin').write_bytes(bitmap)
(OUT/'title_play.bin').write_bytes(play)
(OUT/'title_palette.bin').write_bytes(bytes(v for r,g,b in palette for v in ((r<<4)|b,g)))
bg=nearest(background)
(OUT/'title.inc').write_text(f'TITLE_PLAY_BACKGROUND equ {bg*17}\n')
(OUT/'title_manifest.json').write_text(json.dumps({'size':[256,212],'packed_bytes':len(packed),'decoded_bytes':len(bitmap),'play_rect':[152,100,40,8],'palette':palette},indent=2)+'\n')
im=Image.new('P',(256,212));im.putdata(pixels)
im.putpalette([v for rgb in rgbpal for v in rgb]+[0]*(768-48))
im.convert('RGB').save(ROOT/'previews/abertura-convertida.png')
im.convert('RGB').resize((1024,848),Image.NEAREST).save(ROOT/'previews/abertura-convertida-4x.png')
print(f'Title: {len(bitmap)} SCREEN 5 bytes -> {len(packed)} RLE bytes, 16-color hardware palette')

preview_pixels=cpixels.copy()
for y in range(112,120):
    preview_pixels[y*256+152:y*256+158]=[nearest(background)]*6
im.putdata(preview_pixels)
im.convert('RGB').resize((1024,848),Image.NEAREST).save(ROOT/'previews/abertura-continue-4x.png')
