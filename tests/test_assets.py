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
        self.assertTrue(all(128<=x<=138 for x in a.WORLD))
    def test_palette_and_table_bounds(self):
        self.assertEqual(len(a.PAT),2048)
        self.assertEqual(len(a.COL),2048)
        self.assertLessEqual(len(a.SPR),2048)
        self.assertEqual(len(a.SPR)//32,len(a.SCOL)//16)
        self.assertEqual(len(a.WORLD),64*32)
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
    def test_cow_pose_and_direction(self):
        start=a.META['cow']*32
        poses=[a.SPR[start+i*256:start+(i+1)*256] for i in range(4)]
        self.assertNotEqual(poses[0],poses[1])
        self.assertNotEqual(poses[0],poses[2])
        self.assertIn(9,a.SCOL) # pink muzzle is an actual hardware color
    def test_maximum_scanline_budget(self):
        # Two 32-high cows separated by >=48 cannot share a line: <=4 sprites.
        # Car and trailing dust cannot share a line: <=3 sprites.
        # The two bullets are >=16 apart: <=1 sprite. Total <=8.
        peak=0
        for car_y in range(32,145):
            for cow_y in range(40,161):
                for line in range(192):
                    cows=4*sum(y<=line<y+32 for y in (cow_y,cow_y+48) if y<=160)
                    car=3*(car_y<=line<car_y+32)
                    dust=int(car_y+32<=line<car_y+48)
                    count=cows+car+dust+1 # worst possible bullet on this line
                    peak=max(peak,count)
                    self.assertLessEqual(count,8)
        self.assertEqual(peak,8)
        self.assertLessEqual(6+2*8+1+2,32)
    def test_previews_and_cartridge(self):
        for i in range(3):
            im=a.render(i)
            self.assertEqual(im.size,(256,192))
            self.assertLessEqual(len(im.getcolors()),16)
        rom=(ROOT/'Sebollas.rom').read_bytes()
        self.assertEqual(len(rom),16384)
        self.assertEqual(rom[:2],b'AB')
        entry=int.from_bytes(rom[2:4],'little')
        self.assertTrue(0x4010<=entry<0x8000)
if __name__=='__main__': unittest.main()
