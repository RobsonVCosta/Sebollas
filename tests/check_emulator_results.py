#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'resources/generated'
for hz in (50,60):
    suite=(ROOT/f'emulator-{hz}.txt').read_text()
    stress=(ROOT/f'stress-{hz}.txt').read_text()
    assert 'FAIL' not in suite,suite
    assert '144 Z80 cases; 0 failures' in suite,suite
    assert 'overflow frames=0' in stress,stress
    assert 'maximum sprites/scanline=8' in stress,stress
    route=(ROOT/f'route-{hz}.txt').read_text()
    assert route.startswith('PASS'),route
    campaign=(ROOT/f'campaign-{hz}.txt').read_text()
    assert campaign.startswith('PASS'),campaign
    print(campaign.strip())
    print(route.strip())
    print(f'{hz} Hz: '+suite.splitlines()[-1]+'; '+stress.strip())
