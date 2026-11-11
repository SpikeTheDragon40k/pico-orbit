#!/usr/bin/env python3
"""Structural checks plus optional shrinko8 console-specific budget validation."""
import argparse, json, re, subprocess, sys
from pathlib import Path
from build import build, ROOT
p=argparse.ArgumentParser()
p.add_argument('--shrinko8',type=Path,help='path to pinned shrinko8.py (see README)')
p.add_argument('--require-budget',action='store_true')
a=p.parse_args()
cart=build(); data=cart.read_text()
assert data.startswith('pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n')
code=data.split('__lua__\n',1)[1].split('__sfx__\n')[0]
assert '#include' not in code and len(code)<=65535
assert data.count('__lua__')==1
sfx=data.split('__sfx__\n')[1].split('__music__\n')[0].splitlines()
assert len(sfx)<=64
assert all(re.fullmatch('[0-9a-f]{168}',line) for line in sfx)
assert all(int(line[8+i*5+2],16)<=7 and int(line[8+i*5+3],16)<=7 for line in sfx for i in range(32))
assert all(re.fullmatch('[0-9a-f]{2} [0-9a-f]{8}',line) for line in data.split('__music__\n')[1].splitlines())
print('PASS: self-contained cartridge sections, ASCII, source-character and audio storage limits')
if a.shrinko8:
    cmd=[sys.executable,str(a.shrinko8),str(cart),'--count','--parsable-count','--lint','--no-lint-unused','--no-lint-duplicate']
    run=subprocess.run(cmd,text=True,capture_output=True)
    print(run.stdout,end=''); print(run.stderr,end='',file=sys.stderr)
    if run.returncode: sys.exit(run.returncode)
    counts={k:int(v) for k,v in re.findall(r'(?m)^count:[^:]*:(tokens|chars|compressed):(\d+):\d+$',run.stdout)}
    assert set(counts)=={'tokens','chars','compressed'}, 'unrecognized shrinko8 count output'
    limits={'tokens':8192,'chars':65535,'compressed':15360}
    for key,value in counts.items(): assert value<=limits[key],f'{key} exceeds console limit'
    (ROOT/'docs/resource-report.txt').write_text(run.stdout)
else:
    print('UNVERIFIED: PICO-8 token count and compressed size (provide --shrinko8)')
    if a.require_budget: sys.exit(2)
