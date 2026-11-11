#!/usr/bin/env python3
"""Original code-drawn 128px PICO-8 label. Requires Pillow; no external art/fonts."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math
ROOT=Path(__file__).resolve().parents[1]
PALETTE=['000000','1d2b53','7e2553','008751','ab5236','5f574f','c2c3c7','fff1e8','ff004d','ffa300','ffec27','00e436','29adff','83769c','ff77a8','ffccaa']
GLYPHS={
 'O':['01110','11011','11011','11011','11011','11011','01110'],
 'R':['11110','11011','11011','11110','11100','11010','11011'],
 'B':['11110','11011','11011','11110','11011','11011','11110'],
 'I':['111','010','010','010','010','010','111'],
 'T':['11111','01110','00100','00100','00100','00100','00100'],
 'U':['11011','11011','11011','11011','11011','11011','01110'],
 'S':['01111','11000','11000','01110','00011','00011','11110'],
 'H':['11011','11011','11011','11111','11011','11011','11011']}
def title(draw,word,y,scale,fg):
    width=sum(len(GLYPHS[c][0])+1 for c in word)*scale-scale
    x=(128-width)//2
    for c in word:
        for row,bits in enumerate(GLYPHS[c]):
            for col,bit in enumerate(bits):
                if bit=='1':
                    xx=x+col*scale; yy=y+row*scale
                    draw.rectangle((xx+1,yy+2,xx+scale,yy+scale+1),fill=2)
                    draw.rectangle((xx,yy,xx+scale-1,yy+scale-1),fill=fg if row<4 else 6)
        x+=(len(GLYPHS[c][0])+1)*scale

def main():
    im=Image.new('P',(128,128),0)
    palette=[int(h[i:i+2],16) for h in PALETTE for i in (0,2,4)]
    im.putpalette(palette+[0]*(768-len(palette)))
    d=ImageDraw.Draw(im)
    for i in range(64):
        x=(i*47+13)%128; y=(i*71+19)%128
        d.point((x,y),fill=1 if i%4 else 13)
    d.ellipse((5,36,122,114),outline=1)
    d.ellipse((14,44,113,106),outline=1)
    arena=[(64,48),(116,78),(64,109),(12,78),(64,48)]
    d.polygon(arena,fill=1)
    for k in (0.25,0.5,0.75):
        d.line((12+52*k,78-30*k,64+52*k,109-31*k),fill=0)
        d.line((64+52*k,48+30*k,12+52*k,78+31*k),fill=0)
    d.line(arena,fill=12,width=1)
    for a,b,c in [((29,67),(45,58),14),((84,60),(101,70),11),((84,97),(100,87),9),((29,89),(45,99),12)]:
        d.line((a,b),fill=c,width=3)
        d.point(a,fill=7)
    # Curved shot trail converging on a bright central ball.
    for i in range(18):
        x=43+i; y=88-int(0.045*i*i)
        d.point((x,y),fill=13 if i<9 else 12)
    d.ellipse((59,70,67,78),outline=12)
    d.ellipse((61,72,65,76),fill=7)
    d.point((62,73),fill=10)
    d.line((64,67,64,69),fill=7); d.line((69,74,71,74),fill=7)
    title(d,'ORBIT',7,3,12)
    title(d,'RUSH',31,3,14)
    d.rectangle((21,114,106,123),fill=0)
    font=ImageFont.load_default(size=8)
    text='PICO-8 EDITION'
    box=d.textbbox((0,0),text,font=font)
    d.text(((128-(box[2]-box[0]))//2,114),text,font=font,fill=6)
    # Pair of neon framing ticks.
    for x in (9,116): d.line((x,9,x,20),fill=12); d.line((x,29,x,40),fill=14)
    (ROOT/'assets').mkdir(exist_ok=True)
    im.save(ROOT/'assets/label.png')
    (ROOT/'assets/label.txt').write_text('\n'.join(''.join(format(im.getpixel((x,y)),'x') for x in range(128)) for y in range(128))+'\n')
    im.resize((512,512),Image.Resampling.NEAREST).save(ROOT/'media/cartridge-label.png')
    print('Created native 16-colour label and nearest-neighbour preview')
if __name__=='__main__': main()
