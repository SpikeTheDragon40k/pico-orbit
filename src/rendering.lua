-- Pixel portraits reinterpret the original pilots' silhouettes and colours.
function centered(t,y,c)
 print(t,64-#t*2,y,c)
end
function portrait(n,x,y)
 local c=colors[n]
 circfill(x,y+10,9,1)
 rectfill(x-7,y+6,x+7,y+11,13)
 line(x-6,y+6,x+6,y+6,c)
 circfill(x-8,y+9,2,c) circfill(x+8,y+9,2,c)
 if n==1 then
  rectfill(x-6,y-7,x+6,y+4,6)
  rectfill(x-5,y-4,x+5,y+1,1)
  line(x,y-8,x,y-11,6) pset(x,y-12,c)
 elseif n==2 then
  circfill(x,y-2,7,2)
  rectfill(x-6,y-4,x+6,y,14)
  line(x+6,y-4,x+10,y-7,14)
  line(x+6,y-3,x+11,y-2,14)
 elseif n==3 then
  for i=-1,1 do
   line(x-5,y+i*3,x-10,y+i*5,14)
   line(x+5,y+i*3,x+10,y+i*5,14)
  end
  ovalfill(x-7,y-6,x+7,y+5,15)
  rectfill(x-4,y-7,x+4,y-5,13)
  pset(x-3,y-6,9) pset(x+3,y-6,9)
 else
  ovalfill(x-6,y-9,x+6,y+5,11)
  circfill(x,y-5,2,7) pset(x,y-5,0)
 end
 pset(x-3,y-1,7) pset(x+3,y-1,7)
 pset(x-3,y,0) pset(x+3,y,0)
 line(x-1,y+3,x+1,y+3,c)
end
function backdrop(c)
 cls(0)
 for i=0,15 do
  local x=(i*43+9)%128 local y=(i*29+7)%128
  pset(x,y,i%3==0 and c or 1)
 end
end
function edge(s,a,b,d,c)
 local x,y=point(s,a,d) local u,v=point(s,b,d)
 line(x+14,y+14,u+14,v+14,c)
end
function render_game()
 local c=({12,9,13,11})[cfg.arena]
 backdrop(c)
 rectfill(14,14,114,114,1)
 if cfg.arena==1 then
  for i=24,104,10 do line(i,15,i,113,0) line(15,i,113,i,0) end
 elseif cfg.arena==2 then
  for r=16,48,16 do circ(64,64,r,2) end
 elseif cfg.arena==3 then
  for i=1,24 do pset(20+(i*37)%87,20+(i*23)%87,2) end
 else
  for i=30,98,17 do line(i,20,i,108,0) end
 end
 for s=1,4 do
  local p=players[s]
  local alive=p and p.alive
  edge(s,corner,100-corner,0,alive and p.color or c)
  if alive then
   edge(s,corner+1,100-corner-1,0,5)
   if p.shield>0 then edge(s,corner,100-corner,1,p.color) end
   if p.slow>0 then edge(s,corner,100-corner,8,13) end
   local depth=paddle_depth(p)
   edge(s,p.pos-p.half,p.pos+p.half,depth,p.color)
   edge(s,p.pos-p.half,p.pos+p.half,depth+1,p.dash>0 and 7 or p.color)
   if p.grab>0 then edge(s,p.pos-p.half,p.pos+p.half,depth+3,7) end
  end
 end
 line(14,14+corner,14+corner,14,c)
 line(114-corner,14,114,14+corner,c)
 line(114,114-corner,114-corner,114,c)
 line(14+corner,114,14,114-corner,c)
 for o in all(bumps) do
  circfill(o.x+14,o.y+14,o.r,0)
  circ(o.x+14,o.y+14,o.r,c)
  circ(o.x+14,o.y+14,max(1,o.r-2),5)
  pset(o.x+13,o.y+13,7)
 end
 for o in all(orbs) do
  circfill(o.x+14,o.y+14,4,0)
  circ(o.x+14,o.y+14,4,10)
  print(({"s","t","m","w"})[o.k],o.x+13,o.y+12,10)
 end
 for b in all(balls) do
  for t in all(b.trail) do pset(t.x+14,t.y+14,b.spin~=0 and 13 or 6) end
  circfill(b.x+14,b.y+14,1.6,7)
  if b.held then circ(b.x+14,b.y+14,3,10) end
 end
 for p in all(players) do
  local x=(p.id-1)*32
  print((p.id==1 and "p" or "c")..p.id..":"..p.hp,x+1,1,p.alive and p.color or 5)
  print(p.wins.."/"..cfg.wins,x+9,7,6)
 end
 local p=players[1]
 print("o:"..(p.dc<=0 and "dash" or "wait"),2,120,p.dc<=0 and p.color or 5)
 print("x:"..(held_ball(p) and "throw" or (p.gc<=0 and "grab" or "wait")),43,120,p.gc<=0 and p.color or 5)
 print("r"..round_no,109,120,6)
 if serve_timer>0 and #balls==0 and state=="play" then centered("ready",61,7) end
 if flash>0 then rect(0,0,127,127,8) end
 if state~="play" then
  rectfill(9,40,118,88,0) rect(9,40,118,88,c)
  centered(state=="match" and "match complete" or "round complete",46,c)
  centered(winner and pilot_names[winner.pilot].." wins!" or "draw",57,7)
  centered(state=="round" and "o/x: next round" or "o: rematch",70,6)
  if state=="match" then centered("x: setup",79,6) end
 end
end
function render_menu()
 backdrop(12)
 if state=="setup" then
  centered("orbit rush / setup",4,12)
  local values={cfg.cpus,diff_names[cfg.diff],cfg.points,arena_names[cfg.arena],cfg.wins,cfg.power and "on" or "off",cfg.extra and "on" or "off",pilot_names[cfg.pilot],cfg.music and "on" or "off",cfg.sound and "on" or "off","o / x"}
  for i=1,11 do
   local y=13+i*8
   if i==menu then rectfill(1,y-1,126,y+5,1) print(">",2,y,10) end
   print(menu_labels[i],9,y,i==menu and 7 or 6)
   local v=""..values[i]
   print(v,125-#v*4,y,i==menu and 12 or 5)
  end
  centered("up/down select  left/right edit",116,6)
 elseif state=="credits" then
  centered("orbit rush",16,12)
  centered("original game and pilots",35,7)
  centered("spikethedragon40k",45,10)
  centered("pico-8 edition",64,12)
  centered("offline / single player",75,6)
  centered("o/x: back",110,7)
 else
  centered("orbit",16,12) centered("r u s h",28,14)
  line(26,40,102,40,12)
  for i=1,4 do portrait(i,19+(i-1)*30,61) end
  centered("pico-8 edition",84,6)
  centered("o/x: configure & launch",99,7)
  centered("left/right: move  o: dash",110,6)
  centered("x: grab/throw  down: credits",119,6)
 end
end
