#!/usr/bin/env python3
"""Capture actual official-PICO-8 rendering using scripted input, never mocked art.

Requires the licensed runtime. Uses SDL's off-screen software renderer, native
EXTCMD screenshots/GIF recording, and a temporary capture-only cartridge.
The distributed cartridge and its game Lua are not modified.
"""
import argparse, os, subprocess, tempfile
from pathlib import Path
from build import ROOT, build
SCRIPT=r'''
local game_init=_init
local capture_frame=0
local capture_buttons={}
function btn(n,p) return (not p or p==0) and capture_buttons[n] or false end
function btnp(n,p) return false end
function capture_shot(name)
 extcmd("set_filename",name.."-native") extcmd("screen",1)
 extcmd("set_filename",name) extcmd("screen",4)
end
function capture_controls()
 capture_buttons={}
 local target=50 local best=1000
 for b in all(balls) do if not b.held then
  local distance=100-b.y
  if distance<best then target=b.x best=distance end
 end end
 if target<players[1].pos-1 then capture_buttons[0]=true end
 if target>players[1].pos+1 then capture_buttons[1]=true end
 if best<25 and capture_frame%45==0 then ability(players[1],1) end
 if best<18 and capture_frame%61==0 then ability(players[1],2) end
end
function _init()
 game_init()
 _draw() capture_shot("01-title") flip()
 for arena=1,4 do
  srand(42+arena)
  cfg.cpus=3 cfg.diff=2 cfg.arena=arena cfg.points=15 cfg.wins=1
  start_match()
  for frame=1,150 do
   capture_frame=frame capture_controls()
   _update() _draw()
   if frame==120 then capture_shot("0"..(arena+1).."-"..({"neon-grid","solar-core","void-nebula","ion-reactor"})[arena]) end
   flip()
  end
  printh("captured arena "..arena)
 end
 srand(81) cfg.arena=1 start_match()
 -- Settle into a real rally before beginning the clip.
 for frame=1,90 do capture_frame=frame capture_controls() _update() _draw() flip() end
 extcmd("set_filename","orbit-rush-gameplay") extcmd("rec_frames")
 for frame=1,240 do
  capture_frame=frame capture_controls() _update() _draw() flip()
 end
 extcmd("video",3)
 printh("capture complete: 240 actual gameplay frames, native gif recorder")
 _update=nil _draw=nil
end
'''
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--pico8',required=True,type=Path)
    a=p.parse_args()
    data=build().read_text()
    data=data.replace('__sfx__\n',SCRIPT+'\n__sfx__\n',1)
    media=ROOT/'media'; media.mkdir(exist_ok=True)
    env=dict(os.environ,SDL_VIDEODRIVER='dummy',SDL_AUDIODRIVER='dummy')
    with tempfile.TemporaryDirectory(prefix='orbit-capture-') as tmp:
        cart=Path(tmp)/'capture.p8'; cart.write_text(data)
        subprocess.run([str(a.pico8.resolve()),'-home',str(Path(tmp)/'home'),'-desktop',str(media),'-software_blit','1','-x',str(cart)],env=env,check=True,timeout=180)
        subprocess.run([str(a.pico8.resolve()),'-home',str(Path(tmp)/'home'),'-root_path',str(ROOT),'-x','carts/orbit_rush.p8','-export','release/orbit_rush.p8.png'],env=env,check=True,timeout=60)
    expected=['01-title.png','02-neon-grid.png','03-solar-core.png','04-void-nebula.png','05-ion-reactor.png','orbit-rush-gameplay.gif']
    for name in expected:
        path=media/name
        assert path.is_file(),f'Runtime did not produce {path}'
        print(f'{path.relative_to(ROOT)}: {path.stat().st_size} bytes')
if __name__=='__main__': main()
