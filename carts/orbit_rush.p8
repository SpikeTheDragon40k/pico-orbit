pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- orbit rush: pico-8 edition
-- by spikethedragon40k

-- module: arena
ai_budget=1
players={} balls={} orbs={} bumps={} corner=14
round_no=0 clock=0 serve_timer=0 orb_timer=0 desired=1 extra_count=0
winner=false
-- Orbit Rush: units are 1/10 of the source world; velocities per 30Hz frame.
arena_names={"neon grid","solar core","void nebula","ion reactor"}
diff_names={"easy","normal","hard","insane"}
pilot_names={"volt-9","nyx","axi","prisma"}
colors={12,14,9,11}
function point(s,a,d)
 if s==1 then return a,100-d elseif s==2 then return a,d elseif s==3 then return d,a end
 return 100-d,a
end
function localpos(s,x,y)
 if s==1 then return x,100-y elseif s==2 then return x,y elseif s==3 then return y,x end
 return y,100-x
end
function normal(s)
 if s==1 then return 0,-1 elseif s==2 then return 0,1 elseif s==3 then return 1,0 end
 return -1,0
end
function axis(s) if s<3 then return 1,0 end return 0,1 end
function setup_arena()
 corner=({14,15,12,17.5})[cfg.arena]
 bumps={}
 if cfg.arena==2 then bumps={{x=50,y=50,r=7.2}}
 elseif cfg.arena==3 then
  for x=32,68,36 do for y=32,68,36 do add(bumps,{x=x,y=y,r=3.4}) end end
 elseif cfg.arena==4 then bumps={{x=50,y=33,r=4},{x=50,y=67,r=4}} end
end
function length(x,y) return sqrt(x*x+y*y) end
function clamp(x,a,b) return mid(a,x,b) end
function sound(n) if cfg.sound then sfx(n,2) end end

-- module: physics
function cap(b)
 local v=length(b.vx,b.vy)
 if v>6.6 then b.vx=b.vx*6.6/v b.vy=b.vy*6.6/v end
end
function reflect(b,nx,ny,e,mu)
 local v=b.vx*nx+b.vy*ny
 if v>=0 then return false end
 b.vx=b.vx-(1+e)*v*nx b.vy=b.vy-(1+e)*v*ny
 local tx,ty=-ny,nx
 local j=-mu*(b.vx*tx+b.vy*ty-b.spin*1.6)/3
 b.vx=b.vx+tx*j b.vy=b.vy+ty*j b.spin=clamp(b.spin-2*j/1.6,-1.3,1.3)
 cap(b)
 return true
end
function circle_hit(b,x,y,r)
 local dx,dy=b.x-x,b.y-y
 local d=length(dx,dy)
 if d>=r+1.6 then return false end
 local nx,ny=1,0
 if d>0.001 then nx=dx/d ny=dy/d end
 b.x=x+nx*(r+1.6) b.y=y+ny*(r+1.6)
 return reflect(b,nx,ny,1.08,0.2)
end
function world(b,predict)
 local hits=0
 for s=1,4 do
  local p=players[s]
  local a,d=localpos(s,b.x,b.y)
  if d<1.6 and (not p or not p.alive or p.shield>0) then
   local nx,ny=normal(s)
   b.x,b.y=point(s,a,1.6)
   if reflect(b,nx,ny,1,0.15) then
    hits=hits+1
    if not predict and p and p.alive and p.shield>0 then p.shield=0 sound(6) end
   end
  end
 end
 -- Inward half planes form the four chamfer walls.
 for i=1,4 do
  local sx=1 local sy=1 local ox=0 local oy=0
  if i==2 or i==3 then sx=-1 ox=100 end
  if i==3 or i==4 then sy=-1 oy=100 end
  local depth=((b.x-ox)*sx+(b.y-oy)*sy-corner)*0.707107
  if depth<1.6 then
   local nx,ny=sx*0.707107,sy*0.707107
   b.x=b.x+nx*(1.6-depth) b.y=b.y+ny*(1.6-depth)
   if reflect(b,nx,ny,1,0.15) then hits=hits+1 end
  end
 end
 for o in all(bumps) do if circle_hit(b,o.x,o.y,o.r) then hits=hits+1 end end
 return hits
end
function forces(b,dt,reads)
 local v=length(b.vx,b.vy)
 local target=min(5,2.133*(1+0.05*b.age/30))
 local nv=v
 if v<0.01 then b.vx=0 b.vy=2.133 v=2.133 nv=v end
 if v<target then nv=min(target,v+0.0189*dt) else nv=target+(v-target)*(1-0.0263*dt) end
 local curve=0
 if reads then curve=0.02*b.spin*dt end
 local vx,vy=b.vx-b.vy*curve,b.vy+b.vx*curve
 local n=length(vx,vy)
 b.vx=vx*nv/n b.vy=vy*nv/n
 b.spin=b.spin*(1-0.0198*dt)
 cap(b)
end
function goal_axis(b)
 local xl=(players[3] and players[3].alive) or (players[4] and players[4].alive)
 local yl=players[1].alive or players[2].alive
 local v=length(b.vx,b.vy)
 if yl and not xl and abs(b.vy)<v*0.28 then
  b.vy=(b.vy<0 and -1 or 1)*v*0.28
  b.vx=(b.vx<0 and -1 or 1)*sqrt(max(0,v*v-b.vy*b.vy))
 elseif xl and not yl and abs(b.vx)<v*0.28 then
  b.vx=(b.vx<0 and -1 or 1)*v*0.28
  b.vy=(b.vy<0 and -1 or 1)*sqrt(max(0,v*v-b.vx*b.vx))
 end
end
function ball_pairs()
 for i=1,#balls do for j=i+1,#balls do
  local a,b=balls[i],balls[j]
  if not a.held and not b.held and not a.dead and not b.dead then
   local dx,dy=b.x-a.x,b.y-a.y
   local d=length(dx,dy)
   if d<3.2 then
    local nx,ny=1,0
    if d>0.001 then nx=dx/d ny=dy/d end
    local o=(3.2-d)/2
    a.x=a.x-nx*o a.y=a.y-ny*o b.x=b.x+nx*o b.y=b.y+ny*o
    local rel=(a.vx-b.vx)*nx+(a.vy-b.vy)*ny
    if rel>0 then
     a.vx=a.vx-nx*rel a.vy=a.vy-ny*rel b.vx=b.vx+nx*rel b.vy=b.vy+ny*rel
     local spin=(a.spin-b.spin)*0.25 a.spin=a.spin-spin b.spin=b.spin+spin
     cap(a) cap(b)
    end
   end
  end
 end end
end

-- module: players
function held_ball(p)
 for b in all(balls) do if b.held==p.id then return b end end
end
function paddle_depth(p)
 if p.dash>0 then return 4.6-5.5*sin(p.dash/6.6/2) end
 return 4.6
end
function launch(p,b)
 local nx,ny=normal(p.id) local ax,ay=axis(p.id)
 local angle=clamp(b.offset/p.half*0.7+p.vel/8.33,-1,1)/6
 if p.aim then angle=p.aim p.aim=nil end
 local v=min(6.6,max(2.133,2.133*(1+0.05*b.age/30))*1.6)
 b.vx=(nx*cos(angle)+ax*-sin(angle))*v
 b.vy=(ny*cos(angle)+ay*-sin(angle))*v
 b.spin=clamp(-p.vel*0.4,-0.5,0.5) b.held=nil b.stall=0
 sound(5)
end
function ability(p,kind)
 if not p.alive then return end
 if kind==1 and p.dc<=0 then p.dc=66 p.dash=6.6 sound(3)
 elseif kind==2 then
  local b=held_ball(p)
  if b then launch(p,b)
  elseif p.gc<=0 then p.gc=120 p.grab=27 sound(4) end
 end
end
function update_players()
 ai_budget=1
 for p in all(players) do if p.alive then
  if p.id==1 then
   p.target=p.pos
   if btn(0) then p.target=p.pos-5.3/0.6 end
   if btn(1) then p.target=p.pos+5.3/0.6 end
   if btnp(4) then ability(p,1) end
   if btnp(5) then ability(p,2) end
  else ai_update(p) end
  p.half=7.5*(p.wide>0 and 1.45 or 1)
  local limit=corner+p.half-2
  p.target=clamp(p.target,limit,100-limit)
  local speed=5.3
  if p.id~=1 then speed=speed*levels[cfg.diff].speed end
  local old=p.pos
  p.pos=clamp(p.pos+clamp((p.target-p.pos)*0.6,-speed,speed),limit,100-limit)
  p.vel=p.pos-old
  for k in all({"dc","gc","grab","dash","shield","slow","wide"}) do p[k]=max(0,p[k]-1) end
 end end
end
function paddles(b)
 for p in all(players) do if p.alive then
  local along,depth=localpos(p.id,b.x,b.y)
  local pd=paddle_depth(p)
  local nx,ny=normal(p.id) local ax,ay=axis(p.id)
  local vn=b.vx*nx+b.vy*ny
  if depth>=pd-0.1 and depth<pd+2.7 and abs(along-p.pos)<p.half+1.6 and vn<0 then
   local offset=clamp((along-p.pos)/p.half,-1,1)
   b.x,b.y=point(p.id,along,pd+2.71)
   b.owner=p.id b.stall=0
   if p.grab>0 and not held_ball(p) then
    p.grab=0 b.held=p.id b.hold=0 b.offset=offset*p.half*0.8 b.spin=0 sound(4)
    return
   end
   local v=max(2.133,length(b.vx,b.vy))*1.04
   if p.dash>0 then v=v*1.45 end
   local rvx,rvy=b.vx-2*vn*nx,b.vy-2*vn*ny
   local rv=length(rvx,rvy)
   local angle=offset/6
   local dx=rvx/rv*0.35+(nx*cos(angle)+ax*-sin(angle))*0.65
   local dy=rvy/rv*0.35+(ny*cos(angle)+ay*-sin(angle))*0.65
   local d=length(dx,dy)
   b.vx=dx*v/d b.vy=dy*v/d
   b.spin=clamp(b.spin*0.5+p.vel*((p.id==2 or p.id==4) and 0.18 or -0.18),-1.3,1.3)
   cap(b) sound(0)
   return
  end
 end end
end

-- module: ai
levels={
 {delay=10,error=7,speed=0.5,bounce=0,horizon=24,lapse=0.1,aim=0.1,dash=0.04,grab=0},
 {delay=7,error=4,speed=0.68,bounce=1,horizon=36,lapse=0.05,aim=0.4,dash=0.12,grab=0.05},
 {delay=4,error=2.2,speed=0.85,bounce=2,horizon=48,lapse=0.02,aim=0.7,dash=0.25,grab=0.12},
 {delay=3,error=1.1,speed=1,bounce=4,horizon=60,lapse=0.005,aim=0.92,dash=0.4,grab=0.25}}
function predict(ball,side,level)
 local b={x=ball.x,y=ball.y,vx=ball.vx,vy=ball.vy,spin=ball.spin,age=ball.age}
 local bounce=0
 -- Share at most 60 world samples across the current ball set.
 -- Coarse prediction may miss small bumpers; live physics stays at ten substeps.
 local samples=min(24,flr(60/max(1,#balls)))
 local step=level.horizon/samples
 local nx,ny=normal(side)
 for sample=1,samples do
  local scale=1
  for p in all(players) do
   if p.alive and p.slow>0 then
    local a,d=localpos(p.id,b.x,b.y) local px,py=normal(p.id)
    if d<42 and b.vx*px+b.vy*py<0 then scale=0.5 end
   end
  end
  forces(b,step*scale,cfg.diff>=3)
  b.age=min(900,b.age+step*scale)
  b.x=b.x+b.vx*scale*step b.y=b.y+b.vy*scale*step
  bounce=bounce+world(b,true)
  local a,d=localpos(side,b.x,b.y)
  if d<=7.3 and b.vx*nx+b.vy*ny<0 then return a,sample*step end
  for p in all(players) do
   if p.id~=side and p.alive and p.shield<=0 then
    local oa,od=localpos(p.id,b.x,b.y)
    if od< -1.6 then return end
   end
  end
  if bounce>level.bounce then return end
 end
end
function signed_angle(x,y)
 return ((atan2(x,y)+0.5)%1)-0.5
end
function victim(p)
 local best=nil
 for q in all(players) do if q.alive and q.id~=p.id then
  if not best or (rnd(1)<0.65 and q.hp<best.hp) then best=q end
 end end
 return best
end
function ai_update(p)
 local l=levels[cfg.diff]
 if p.dash_wait then
  p.dash_wait=p.dash_wait-1
  if p.dash_wait<=0 then ability(p,1) p.dash_wait=nil end
 end
 local held=held_ball(p)
 if held then
  if held.hold>12+cfg.diff*2 then
   local q=victim(p)
   if q then
    local x,y=point(q.id,q.pos<50 and 100-corner-5 or corner+5,0)
    local nx,ny=normal(p.id) local ax,ay=axis(p.id)
    local dx,dy=x-held.x,y-held.y
    p.aim=clamp(-signed_angle(dx*nx+dy*ny,dx*ax+dy*ay),-0.158,0.158)
   end
   ability(p,2)
  end
  return
 end
 p.think=p.think-1
 if p.think>0 or ai_budget<=0 then return end
 ai_budget=ai_budget-1
 p.think=l.delay*(0.75+rnd(0.5))
 if rnd(1)<l.lapse then return end
 local best=1000 local at=nil
 for b in all(balls) do if not b.held then
  local a,t=predict(b,p.id,l)
  if a and t<best then best=t at=a end
 end end
 if not at then p.target=50 return end
 p.target=at+(rnd(2)-1)*l.error*(0.4+best/30)*1.7
 if best<30 and rnd(1)<l.aim then
  local q=victim(p)
  if q then
   local tx,ty=point(q.id,q.pos<50 and 100-corner-5 or corner+5,0)
   local px,py=point(p.id,at,4.6)
   local ax,ay=axis(p.id) local nx,ny=normal(p.id)
   local dx,dy=tx-px,ty-py
   local angle=clamp(-signed_angle(dx*nx+dy*ny,dx*ax+dy*ay),-0.15,0.15)
   p.target=p.target-angle*6*p.half
  end
 end
 if best<18 then
  if rnd(1)<l.grab then ability(p,2)
  elseif not p.dash_wait and p.dc<=0 and rnd(1)<l.dash then p.dash_wait=max(1,best-3) end
 end
end

-- module: game
function start_match()
 players={}
 for i=1,cfg.cpus+1 do
  add(players,{id=i,wins=0,pilot=(cfg.pilot+i-2)%4+1,color=colors[(cfg.pilot+i-2)%4+1]})
 end
 round_no=0
 start_round()
end
function start_round()
 round_no=min(100,round_no+1) setup_arena()
 balls={} orbs={} clock=0 serve_timer=45 orb_timer=270 winner=nil
 desired=min(3,1+flr((round_no-1)/2)) extra_count=0
 for p in all(players) do
  p.alive=true p.hp=cfg.points p.pos=50 p.target=50 p.vel=0 p.half=7.5
  p.dash=0 p.dc=0 p.gc=0 p.grab=0 p.shield=0 p.slow=0 p.wide=0
  p.think=p.id*2 p.dash_wait=nil p.aim=nil
 end
 state="play"
 if cfg.music then music(0,0,3) end
end
function spawn_ball(owner)
 if #balls>=5 then return end
 local x,y=50,50
 if cfg.arena==2 then x=33 y=33 end
 local choices={}
 for p in all(players) do if p.alive then add(choices,p) end end
 if #choices==0 then return end
 local p=choices[flr(rnd(#choices))+1]
 local gx,gy=point(p.id,corner+rnd(100-2*corner),0)
 local dx,dy=gx-x,gy-y local d=length(dx,dy)
 add(balls,{x=x,y=y,vx=dx/d*2.133,vy=dy/d*2.133,age=0,spin=0,stall=0,owner=owner,trail={}})
end
function goal(p,b)
 p.hp=max(0,p.hp-1) b.dead=true flash=5 sound(2)
 if p.hp==0 then
  p.alive=false p.shield=0 p.grab=0 sound(7)
  for q in all(balls) do if not q.dead then
   local a,d=localpos(p.id,q.x,q.y) local nx,ny=normal(p.id)
   if q.held==p.id then q.held=nil q.vx=nx*2.133 q.vy=ny*2.133 end
   if d<2 then q.x,q.y=point(p.id,a,2) reflect(q,nx,ny,1,0) end
  end end
  local count=0 local last=nil
  for q in all(players) do if q.alive then count=count+1 last=q end end
  if count<=1 then
   winner=last
   if last then last.wins=last.wins+1 end
   state=(last and last.wins>=cfg.wins) and "match" or "round"
   music(-1) sound(last and last.id==1 and 8 or 9)
  end
 end
end
function pickup(p,k)
 if k==1 then p.shield=360 elseif k==2 then p.slow=180
 elseif k==3 then spawn_ball(p.id) else p.wide=300 end
 sound(6)
end
function update_orbs()
 if not cfg.power then return end
 orb_timer=orb_timer-1
 if orb_timer<=0 then
  orb_timer=240+flr(rnd(150))
  if #orbs<2 then
   for attempt=1,12 do
    local x,y=26+rnd(48),26+rnd(48) local valid=true
    for o in all(bumps) do if length(x-o.x,y-o.y)<o.r+7 then valid=false end end
    for o in all(orbs) do if length(x-o.x,y-o.y)<14 then valid=false end end
    if valid then add(orbs,{x=x,y=y,k=flr(rnd(4))+1,life=420}) break end
   end
  end
 end
 for o in all(orbs) do
  o.life=o.life-1
  for b in all(balls) do
   local p=b.owner and players[b.owner]
   if not b.dead and not b.held and p and p.alive and length(b.x-o.x,b.y-o.y)<4.6 then
    pickup(p,o.k) o.life=0 break
   end
  end
  if o.life<=0 then del(orbs,o) end
 end
end
function update_game()
 clock=(clock+1)%1800 flash=max(0,flash-1)
 update_players()
 if serve_timer>0 then serve_timer=serve_timer-1
 elseif #balls<desired then spawn_ball() serve_timer=33 end
 if cfg.extra and clock%1800==0 and extra_count<3 then
  extra_count=extra_count+1 desired=min(5,desired+1)
 end
 for b in all(balls) do
  if #b.trail>=4 then deli(b.trail,1) end
  add(b.trail,{x=b.x,y=b.y})
  if b.held then
   local p=players[b.held] b.hold=b.hold+1
   b.x,b.y=point(p.id,p.pos+b.offset,paddle_depth(p)+4.2)
   if b.hold>=36 then launch(p,b) end
  else
   b.age=min(900,b.age+1) b.stall=min(301,b.stall+1)
   local scale=1
   for p in all(players) do
    local a,d=localpos(p.id,b.x,b.y) local nx,ny=normal(p.id)
    if p.alive and p.slow>0 and d<42 and b.vx*nx+b.vy*ny<0 then scale=0.5 end
   end
   forces(b,scale,true) goal_axis(b)
   if b.stall>300 then
    local best=1000 local gx,gy=50,50
    for p in all(players) do if p.alive then
     local x,y=point(p.id,50,0) local d=length(x-b.x,y-b.y)
     if d<best then best=d gx=x gy=y end
    end end
    if best>0.01 then b.vx=b.vx+(gx-b.x)/best*0.02 b.vy=b.vy+(gy-b.y)/best*0.02 end
    cap(b)
   end
   b.scale=scale
  end
 end
 -- Shared substeps also bound relative ball-ball travel.
 for sub=1,10 do
  for b in all(balls) do
   if state~="play" then break end
   if not b.dead and not b.held then
   b.x=b.x+b.vx*b.scale/10 b.y=b.y+b.vy*b.scale/10
   local hits=world(b,false)
   if hits>0 and sub==1 then sound(1) end
   paddles(b) cap(b)
   for p in all(players) do
    local a,d=localpos(p.id,b.x,b.y)
    if p.alive and d< -1.6 then goal(p,b) break end
   end
  end end
  if state~="play" then break end
  ball_pairs()
 end
 for b in all(balls) do if b.dead then del(balls,b) end end
 if state=="play" then update_orbs() end
end

-- module: rendering
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

-- module: main
function _init()
 cfg={cpus=1,diff=2,points=15,arena=1,wins=3,power=true,extra=true,pilot=1,music=true,sound=true}
 state="title" menu=1 flash=0 ticks=0 profile=false peak_cpu=0
 menuitem(1,"toggle music",function()
  cfg.music=not cfg.music
  if cfg.music and state=="play" then music(0,0,3) else music(-1) end
 end)
 menuitem(2,"toggle effects",function() cfg.sound=not cfg.sound end)
 menuitem(3,"show cpu/memory",function() profile=not profile peak_cpu=0 end)
 menuitem(4,"match setup",function() state="setup" music(-1) end)
 menu_labels={"cpu rivals","difficulty","points","arena","round wins","power-ups","extra balls","pilot","music","sound","launch"}
end
function option(dir)
 if menu==1 then cfg.cpus=(cfg.cpus-1+dir)%3+1
 elseif menu==2 then cfg.diff=(cfg.diff-1+dir)%4+1
 elseif menu==3 then cfg.points=({5,10,15,20,25})[((cfg.points/5-1+dir)%5)+1]
 elseif menu==4 then cfg.arena=(cfg.arena-1+dir)%4+1
 elseif menu==5 then local opts={1,2,3,5} local n=1 for i=1,4 do if opts[i]==cfg.wins then n=i end end cfg.wins=opts[(n-1+dir)%4+1]
 elseif menu==6 then cfg.power=not cfg.power
 elseif menu==7 then cfg.extra=not cfg.extra
 elseif menu==8 then cfg.pilot=(cfg.pilot-1+dir)%4+1
 elseif menu==9 then cfg.music=not cfg.music
 elseif menu==10 then cfg.sound=not cfg.sound
 elseif menu==11 then start_match() end
end
function _update()
 ticks=(ticks+1)%1800
 if state=="play" then update_game()
 elseif state=="title" then
  if btnp(4) or btnp(5) then state="setup" end
  if btnp(3) then state="credits" end
 elseif state=="setup" then
  if btnp(2) then menu=(menu-2)%11+1 end
  if btnp(3) then menu=menu%11+1 end
  if btnp(0) then option(-1) end
  if btnp(1) or btnp(4) or btnp(5) then option(1) end
 elseif state=="round" then
  if btnp(4) or btnp(5) then start_round() end
 elseif state=="match" then
  if btnp(4) then start_match() end
  if btnp(5) then state="setup" end
 elseif state=="credits" then if btnp(4) or btnp(5) then state="title" end end
end
function _draw()
 if state=="play" or state=="round" or state=="match" then render_game() else render_menu() end
 if profile then
  peak_cpu=max(peak_cpu,stat(1))
  rectfill(0,56,127,69,0)
  print("cpu:"..flr(stat(1)*100).."% peak:"..flr(peak_cpu*100).."%",1,57,7)
  print("lua:"..flr(stat(0)).."kb",1,64,7)
 end
end
__sfx__
00020000260602506024060230602205021050200501f0001e0001d0001c0001b0001a000190001800017000160001500014000130001200011000100000f0000e0000d0000c0000b0000a000090000800007000
00020000191601816017160161601510014100131001210011100101000f1000e1000d1000c1000b1000a10009100081000710006100051000410003100021000110000100001000010000100001000010000100
000200001e2601d2601c2601b2601a250192501825017250162401524014240132401223011230102000f2000e2000d2000c2000b2000a2000920008200072000620005200042000320002200012000020000200
000200001436015360163601736018350193501a3501b3501c3401d3001e3001f300203002130022300233002430025300263002730028300293002a3002b3002c3002d3002e3002f30030300313003230033300
000200002d0602c0602b0602a060290502805027050260502504024040230002200021000200001f0001e0001d0001c0001b0001a000190001800017000160001500014000130001200011000100000f0000e000
000200001d1601e1601f160201602115022150231502415025140261402710028100291002a1002b1002c1002d1002e1002f100301003110032100331003410035100361003710038100391003a1003b1003c100
0002000028260292602a2602b2602c2502d2502e2502f250302403124032240332403423035230362003720038200392003a2003b2003c2003d2003e2003f2003f2003f2003f2003f2003f2003f2003f2003f200
000200002236021360203601f3601e3501d3501c3501b3501a340193401834017340163301533014330133301232011320103200f3200e3100d3100c3000b3000a30009300083000730006300053000430003300
000200002406025060260602706028050290502a0502b0502c0402d0402e0402f040300303103032030330303402035020360203702038010390103a0103b0103c0003d0003e0003f0003f0003f0003f0003f000
000200002216021160201601f1601e1501d1501c1501b1501a140191401814017140161301513014130131301212011120101200f1200e1100d1100c1100b1100a10009100081000710006100051000410003100
0010002018030180301f0301f03024030240301f0301f0301b0301b0302203022030270302703022030220301d0301d03024030240302903029030240302403016030160301d0301d03022030220301d0301d030
001000200c2200c2201322013220182201822013220132200f2200f22016220162201b2201b2201622016220112201122018220182201d2201d22018220182200a2200a220112201122016220162201122011220
__music__
03 0a0b4243
