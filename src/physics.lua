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
