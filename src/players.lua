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
