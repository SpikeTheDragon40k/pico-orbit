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
