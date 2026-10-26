#!/usr/bin/env python3
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]/'resources/generated'
for hz in (50,60):
    suite=(ROOT/f'emulator-{hz}.txt').read_text()
    stress=(ROOT/f'stress-{hz}.txt').read_text()
    assert 'FAIL' not in suite,suite
    assert '324 Z80 cases; 0 failures' in suite,suite
    assert 'overflow frames=0' in stress,stress
    assert int(re.search(r'maximum sprites/scanline=(\d+)',stress).group(1))<=8,stress
    route=(ROOT/f'route-{hz}.txt').read_text()
    assert route.startswith('PASS'),route
    campaign=(ROOT/f'campaign-{hz}.txt').read_text()
    assert campaign.startswith('PASS'),campaign
    print(campaign.strip())
    print(route.strip())
    print(f'{hz} Hz: '+suite.splitlines()[-1]+'; '+stress.strip())
