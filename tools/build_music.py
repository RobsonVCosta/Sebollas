#!/usr/bin/env python3
"""Pack the transcribed user-supplied excerpt into AY-3-8910 tone events."""
from pathlib import Path
import hashlib
import json
from fractions import Fraction
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'resources/generated'
score=json.loads((ROOT/'resources/sultans-score.json').read_text())
assert hashlib.sha256((ROOT/'resources'/score['source']).read_bytes()).hexdigest()==score['source_sha256']
# Quantize absolute musical positions rather than accumulating rounded lengths.
# One silent tick releases each note; tied notes are already merged in the score.
length=round(Fraction(score['measures']*4*60*50,score['tempo_bpm']))
tracks={voice:[0]*length for voice in ('lead','bass')}
for voice,notes in score['voices'].items():
    for note in notes:
        start=Fraction(note['beat']);end=start+Fraction(note['duration'])
        a=round(start*60*50/score['tempo_bpm'])
        b=round(end*60*50/score['tempo_bpm'])
        release=1 if b-a>=3 else 0
        assert 0<=a<b<=length
        assert not any(tracks[voice][a:b])
        tracks[voice][a:b-release]=[note['midi']]*(b-a-release)
events=[]
for lead,bass in zip(tracks['lead'],tracks['bass']):
    if events and (events[-1]['lead'],events[-1]['bass'])==(lead,bass) and events[-1]['ticks']<255:
        events[-1]['ticks']+=1
    else:
        events.append({'lead':lead,'bass':bass,'ticks':1})
assert 0<len(events)<256
# MSX PSG clock is half the 3.579545 MHz master clock; tone divider is 16.
def period(note):
    return round(1789772.5/(16*440*2**((note-69)/12))) if note else 0
lines=[f'MUSIC_NOTE_COUNT equ {len(events)}','MusicNotes:']
packed=bytearray()
for event in events:
    lead=period(event['lead']);backing=period(event['bass']);ticks=event['ticks']
    assert 0<=lead<=4095 and 0<=backing<=4095 and 1<=ticks<=255
    lines.extend((f'    dw {lead},{backing}',f'    db {ticks}'))
    packed.extend(lead.to_bytes(2,'little')+backing.to_bytes(2,'little')+bytes([ticks]))
(OUT/'sultans.inc').write_text('\n'.join(lines)+'\n')
(OUT/'sultans.bin').write_bytes(packed)
manifest={'source':score['source'],'source_sha256':score['source_sha256'],'events':len(events),
          'ticks':sum(e['ticks'] for e in events),'tick_rate':50,'seconds':sum(e['ticks'] for e in events)/50,
          'first_lead_period':period(events[0]['lead']),'first_backing_period':period(events[0]['bass']),
          'first_ticks':events[0]['ticks'],'last_ticks':events[-1]['ticks'],'event_bytes':5,'tempo_bpm':score['tempo_bpm'],'measures':score['measures']}
(OUT/'music_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f"Music: {len(events)} two-voice events, {manifest['seconds']:.2f}s loop, {len(packed)} bytes")
