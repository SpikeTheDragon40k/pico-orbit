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
