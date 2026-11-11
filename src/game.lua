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
