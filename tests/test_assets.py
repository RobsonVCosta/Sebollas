#!/usr/bin/env python3
"""Hardware constraints and native art checks; no external test framework."""
import importlib.util
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('previews',ROOT/'tools/render_previews.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
class Assets(unittest.TestCase):
    def test_font_is_original_and_ascii_mapped(self):
        old=(ROOT/'resources/font-original.bin').read_bytes()
        for i,ch in enumerate(a.META['font_chars']):
            self.assertEqual(a.PAT[ch*8:ch*8+8],old[i*8:i*8+8])
        self.assertTrue(all(x in a.META["font_chars"]+a.META["extra_font_chars"] or 128<=x<=158 for x in a.WORLD))
    def test_route_landmarks_and_safe_center(self):
        rows=[a.WORLD[y*32:(y+1)*32] for y in range(160)]
        self.assertEqual(bytes(rows[147][1:5]),'VAVÁ'.encode('latin-1'))
        self.assertEqual(bytes(rows[1][13:20]),b'DESTINO')
        for y,row in enumerate(rows[7:147],7):
            self.assertIn(row[a.META["road_centers"][y]//8],(130,131,146,157))
        self.assertGreaterEqual(max(a.META["road_centers"])-min(a.META["road_centers"]),56)
        for y in (54,110):
            self.assertEqual(bytes(rows[y-3][24:29]),b'POSTO')
            self.assertEqual(rows[y][22],157)
        for y in (36,86):
            self.assertEqual(rows[y][0],145)
            self.assertEqual(rows[y][a.META["road_centers"][y]//8],146)
            self.assertEqual(sum(t==146 for t in rows[y]),6)
    def test_palette_and_table_bounds(self):
        self.assertEqual(len(a.PAT),2048)
        self.assertEqual(len(a.COL),2048)
        self.assertLessEqual(len(a.SPR),2048)
        self.assertEqual(len(a.SPR)//32,len(a.SCOL)//16)
        self.assertEqual(len(a.WORLD),160*32)
        for pal in a.META['palettes']:
            self.assertEqual(len(pal),16)
            self.assertTrue(all(0<=c<=7 for rgb in pal for c in rgb))
        ranges=[(0x0000,0x1800),(0x1800,0x1b00),(0x1b80,0x1bb0),
                (0x1c00,0x1e00),(0x1e00,0x1e80),(0x2000,0x3800),(0x3800,0x4000)]
        self.assertTrue(all(p[1]<=q[0] for p,q in zip(ranges,ranges[1:])))
    def test_car_layers_are_disjoint(self):
        for half in range(2):
            layers=[a.SPR[(half*3+i)*32:(half*3+i+1)*32] for i in range(3)]
            for masks in zip(*layers):
                self.assertEqual(sum(x.bit_count() for x in masks), (masks[0]|masks[1]|masks[2]).bit_count())
    def test_cow_static_directions(self):
        start=a.META['cow']*32
        poses=[a.SPR[start+i*256:start+(i+1)*256] for i in range(2)]
        self.assertNotEqual(poses[0],poses[1])
        self.assertIn(9,[c&15 for c in a.SCOL]) # pink muzzle is an actual hardware color
    def test_cow_keeps_all_reference_colors(self):
        from PIL import Image
        src=Image.open(ROOT/'resources/cow-reference.png').convert('RGBA')
        src=src.crop(src.getbbox()).resize((32,24),Image.NEAREST)
        for direction in range(2):
            base=a.META['cow']+direction*8
            for y in range(32):
                for x in range(32):
                    quadrant=(y//16)*2+x//16
                    sy,sx=y%16,x%16
                    color=0
                    for layer in range(2):
                        n=base+quadrant*2+layer
                        bits=a.SPR[n*32+(16 if sx>=8 else 0)+sy]
                        if bits&(128>>(sx%8)): color|=a.SCOL[n*16+sy]&15
                    expected=0
                    if 4<=y<28:
                        r,g,b,alpha=src.getpixel((31-x if direction else x,y-4))
                        if alpha: expected=9 if r>200 and g<200 else 15 if r>200 else 6
                    self.assertEqual(color,expected,(direction,x,y))
    def test_maximum_scanline_budget(self):
        # Two 32-high cows separated by >=48 cannot share a line: <=4 sprites.
        # Car and trailing dust cannot share a line: <=3 sprites.
        # The single transparent cheese uses one sprite. Total <=8.
        peak=0
        for car_y in range(32,145):
            for cow_y in range(40,161):
                for line in range(192):
                    cows=4*sum(y<=line<y+32 for y in (cow_y,cow_y+48) if y<=160)
                    car=3*(car_y<=line<car_y+32)
                    dust=int(car_y+32<=line<car_y+48)
                    count=cows+car+dust+1 # worst possible cheese on this line
                    peak=max(peak,count)
                    self.assertLessEqual(count,8)
        self.assertEqual(peak,8)
        self.assertLessEqual(6+2*8+1+1,32)
    def test_cheese_transparency(self):
        for frame in range(2):
            pattern=a.META['cheese']+frame
            def opaque(x,y):
                bits=a.SPR[pattern*32+(16 if x>=8 else 0)+y]
                return bool(bits&(128>>(x%8)))
            self.assertTrue(opaque(7,7))
            for x,y in ((0,0),(15,0),(0,15),(15,15),(0,8),(15,8)):
                self.assertFalse(opaque(x,y))
            for x,y in ((5,4),(10,7),(6,11)):
                if frame: x,y=15-y,x
                self.assertFalse(opaque(x,y))
    def test_title_bitmap_and_compression(self):
        data=(ROOT/'resources/generated/title.rle').read_bytes()
        decoded=bytearray();i=0
        while data[i]:
            token=data[i];i+=1
            if token<128:
                decoded.extend(data[i:i+token]);i+=token
            else:
                decoded.extend([data[i]]*((token&127)+3));i+=1
        bitmap=(ROOT/'resources/generated/title_bitmap.bin').read_bytes()
        self.assertEqual(decoded,bitmap)
        self.assertEqual(len(bitmap),256*212//2)
        palette=(ROOT/'resources/generated/title_palette.bin').read_bytes()
        self.assertEqual(len(palette),32)
        self.assertEqual(palette[:2],bytes(2))
        for rb,g in zip(palette[::2],palette[1::2]):
            self.assertLessEqual(rb>>4,7)
            self.assertLessEqual(rb&15,7)
            self.assertLessEqual(g,7)
    def test_credits_preserve_requested_text(self):
        import json
        credits=json.loads((ROOT/'resources/generated/credits_text.json').read_text())
        self.assertEqual(credits['paragraphs'],[
            'Essa foi a aventura de Argon, Gordinho (Leto) e Robson em sua jornada de Nova Iguaçu até Sebollas.',
            'Obrigado amigos, pelas boas memórias.',
            'By Robson Velloso'])
        self.assertTrue(all(0<=y<24 and x+len(line)<=32 for y,x,line in credits['rows']))
    def test_three_runners_have_distinct_sizes(self):
        bounds={}
        for name in ('runner_small','runner_tall','runner_fat'):
            pixels=[]
            for y in range(32):
                for x in range(16):
                    n=a.META[name]+(y//16)*2
                    byte=(16 if x>=8 else 0)+y%16
                    if (a.SPR[n*32+byte]|a.SPR[(n+1)*32+byte])&(128>>(x%8)):
                        pixels.append((x,y))
            bounds[name]=(max(x for x,y in pixels)-min(x for x,y in pixels)+1,
                          max(y for x,y in pixels)-min(y for x,y in pixels)+1)
        self.assertGreater(bounds['runner_tall'][1],bounds['runner_small'][1])
        self.assertGreater(bounds['runner_fat'][0],bounds['runner_tall'][0])
    def test_road_bounds_match_the_drivable_tiles(self):
        bounds=(ROOT/'resources/generated/road_bounds.bin').read_bytes()
        self.assertEqual(len(bounds),320)
        for row in range(160):
            left,right=bounds[row*2:row*2+2]
            self.assertLessEqual(left,right)
            self.assertTrue(all(a.WORLD[row*32+col] in (130,131,146,157)
                                for col in range(left//8,(right+15)//8+1)))
        for row in range(139):
            for y in range(32,145):
                spans=[bounds[r*2:r*2+2] for r in range(row+y//8-2,row+(y+31)//8-1)]
                self.assertLessEqual(max(s[0] for s in spans),min(s[1] for s in spans))
    def test_three_distinct_routes_and_fixed_cheese_color(self):
        routes={stage:(ROOT/f'resources/generated/world{suffix}.bin').read_bytes()
                for stage,suffix in ((1,'1'),(2,''),(3,'3'))}
        centers=[(ROOT/f'resources/generated/road_centers{suffix}.bin').read_bytes()
                 for suffix in ('1','','3')]
        self.assertEqual(len(set(centers[0])),1)
        self.assertGreater(len(set(centers[1])),5)
        self.assertNotIn(145,routes[1]); self.assertNotIn(146,routes[1])
        self.assertIn(145,routes[2]); self.assertIn(146,routes[2])
        for row in range(20,148):
            widths=[sum(t in (130,131,146) for t in routes[stage][row*32:row*32+32]) for stage in (1,3)]
            self.assertLess(widths[1],widths[0])
        for stage in range(3):
            self.assertEqual(a.META['palettes'][stage][10],a.META['palettes'][0][10])
    def test_ending_art_native_pixels_and_rom_banks(self):
        from PIL import Image
        rom=(ROOT/'Sebollas.rom').read_bytes()
        for number,offset in ((1,0x10000),(2,0x20000)):
            source=Image.open(ROOT/f'resources/ending-{number}-reference.png').convert('RGB')
            self.assertEqual(source.size,(256,212))
            expected=bytes((round(g*7/255)<<5)|(round(r*7/255)<<2)|round(b*3/255)
                           for r,g,b in source.getdata())
            data=(ROOT/f'resources/generated/ending{number}.bin').read_bytes()
            self.assertEqual(len(data),54272)
            self.assertEqual(data,expected)
            self.assertEqual(rom[offset:offset+len(data)],data)
    def test_previews_and_cartridge(self):
        for i in range(3):
            im=a.render(i)
            self.assertEqual(im.size,(256,192))
            self.assertLessEqual(len(im.getcolors()),16)
        rom=(ROOT/'Sebollas.rom').read_bytes()
        self.assertEqual(len(rom),262144)
        self.assertEqual(rom[:2],b'AB')
        entry=int.from_bytes(rom[2:4],'little')
        self.assertTrue(0x4010<=entry<0x8000)
if __name__=='__main__': unittest.main()
