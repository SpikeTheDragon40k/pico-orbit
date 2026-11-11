#!/usr/bin/env python3
"""Assemble a self-contained, deterministic official-format PICO-8 cartridge."""
from pathlib import Path
import hashlib
ROOT=Path(__file__).resolve().parents[1]
MODULES='arena physics players ai game rendering main'.split()
def note(pitch,wave=0,volume=5,effect=0):
    return f'{pitch:02x}{wave:x}{volume:x}{effect:x}'
def effect(index):
    # Original short synth gestures. One effect channel, no runtime synthesizer.
    lengths=[7,4,14,9,10,10,14,22,24,24]
    starts=[38,25,30,20,45,29,40,34,36,34]
    ns=[]
    for i in range(32):
        active=i<lengths[index]
        pitch=max(0,min(63,starts[index]+(i if index in (3,5,6,8) else -i)))
        ns.append(note(pitch, index%4, max(1,6-i//4) if active else 0,0))
    return '00'+'02'+'00'+'00'+''.join(ns)
def music_voice(bass=False):
    melody=[24,31,36,31,27,34,39,34,29,36,41,36,22,29,34,29]
    notes=[]
    for i in range(32):
        pitch=melody[i//2]-(12 if bass else 0)
        notes.append(note(pitch,2 if bass else 0,2 if bass else 3,0))
    return '00100020'+''.join(notes)
def build():
    code='-- orbit rush: pico-8 edition\n-- by spikethedragon40k\n'
    for name in MODULES:
        code+=f'\n-- module: {name}\n'+(ROOT/'src'/f'{name}.lua').read_text().rstrip()+'\n'
    audio=[effect(i) for i in range(10)]+[music_voice(),music_voice(True)]
    # Pattern flags 3: loop begin+loop end. Channels 0,1; disabled 2,3.
    cart='pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n'+code
    cart+='__sfx__\n'+'\n'.join(audio)+'\n__music__\n03 0a0b4243\n'
    out=ROOT/'carts/orbit_rush.p8'
    out.parent.mkdir(exist_ok=True)
    out.write_text(cart,encoding='ascii')
    print(f'{out.relative_to(ROOT)}: {len(code)} Lua characters; sha256 {hashlib.sha256(out.read_bytes()).hexdigest()}')
    return out
if __name__=='__main__': build()
