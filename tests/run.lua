local shim=dofile('tests/pico8_shim.lua')
local report=shim.print
local flags={}
for _,flag in ipairs(arg or {}) do flags[flag]=true end
if flags['--cart'] then
 local f=assert(io.open('carts/orbit_rush.p8','r')) local cart=f:read('*a') f:close()
 local code=assert(cart:match('\n__lua__\n(.-)\n__[%a_]+__'), 'cartridge Lua section missing')
 assert(load(code,'@carts/orbit_rush.p8'))()
 report('Testing generated cartridge Lua (desktop shim)')
else
 for _,name in ipairs({'arena','physics','players','ai','game','rendering','main'}) do dofile('src/'..name..'.lua') end
 report('Testing modular source Lua (desktop shim)')
end
local tests,assertions=0,0
local function check(v,message) assertions=assertions+1 assert(v,message or 'assertion failed') end
local function close(a,b,eps) check(math.abs(a-b)<(eps or 0.00001),tostring(a)..' ~= '..tostring(b)) end
local function test(name,f)
 f() tests=tests+1 report('PASS '..name)
end
local function reset(cpus,diff,arena,seed)
 _init() srand(seed or 1) set_buttons()
 cfg.cpus=cpus or 1 cfg.diff=diff or 2 cfg.arena=arena or 1 cfg.points=5 cfg.wins=1 cfg.music=false cfg.sound=false
 start_match()
end
local function ball(x,y,vx,vy)
 return {x=x,y=y,vx=vx,vy=vy,spin=0,age=0,stall=0,trail={},scale=1}
end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<100000 end
local function invariant()
 check(#players==cfg.cpus+1,'incorrect seating') check(#balls<=5,'too many balls')
 for i,p in ipairs(players) do
  check(p.id==i and p.hp>=0 and p.hp<=cfg.points,'invalid player')
  check(p.alive==(p.hp>0),'elimination mismatch')
  check(finite(p.pos) and p.pos>=corner+p.half-2-0.001 and p.pos<=100-corner-p.half+2+0.001,'paddle bounds')
  for _,k in ipairs({'dc','gc','grab','dash','shield','slow','wide'}) do check(finite(p[k]) and p[k]>=0,'bad timer '..k) end
 end
 for _,b in ipairs(balls) do
  check(finite(b.x) and finite(b.y) and finite(b.vx) and finite(b.vy) and finite(b.spin),'invalid ball')
  check(b.x>=-3 and b.x<=103 and b.y>=-3 and b.y<=103,'ball escaped arena')
  check(length(b.vx,b.vy)<=6.6001,'ball speed cap')
  if b.held then check(players[b.held].alive,'held by eliminated player') end
 end
end

test('coordinate transformations and direction',function()
 for s=1,4 do
  local x,y=point(s,32,7) local a,d=localpos(s,x,y) close(a,32) close(d,7)
  local nx,ny=normal(s) x,y=point(s,50,0) local x1,y1=point(s,50,1) close(x1-x,nx) close(y1-y,ny)
 end
 close(sin(0.25),-1) close(cos(0.5),-1) close(atan2(0,-1),0.25)
end)
test('menu control, pilot selection, start and restart',function()
 _init() set_buttons({}, {[4]=true}) _update() check(state=='setup')
 set_buttons() menu=8 option(1) check(cfg.pilot==2)
 menu=1 option(1) check(cfg.cpus==2)
 menu=11 option(1) check(state=='play' and #players==3)
 check(players[1].pilot==2 and players[2].pilot==3 and players[3].pilot==4)
 start_match() check(round_no==1 and players[1].wins==0)
end)
test('cooldowns, dash lunge, grab and offset throw',function()
 reset() local p=players[1]
 ability(p,1) close(p.dc,66) close(p.dash,6.6)
 p.dash=3.3 check(paddle_depth(p)>10,'dash failed to lunge inward')
 p.dash=0 ability(p,1) check(p.dash==0 and p.dc==66,'dash bypassed cooldown')
 ability(p,2) check(p.gc==120 and p.grab==27)
 local b=ball(53,92.8,0,2.133) balls={b} paddles(b)
 check(b.held==1 and held_ball(p)==b,'grab failed') check(b.offset>0)
 ability(p,2) check(not b.held and b.vy<0 and b.vx>0,'throw direction')
 local gc=p.gc ability(p,2) check(p.gc==gc and p.grab==0,'grab bypassed cooldown')
 for i=1,120 do update_players() end
 check(p.dc==0 and p.gc==0) ability(p,2) check(p.grab==27)
end)
test('grab automatically releases after timeout',function()
 reset() local p=players[1] local b=ball(50,91,0,0)
 b.held=1 b.hold=35 b.offset=0 balls={b}
 update_game() check(not b.held and b.vy<0,'automatic throw failed')
end)
test('paddle deflection, dash kick and moving spin',function()
 reset() local p=players[1]
 local b=ball(50,92.8,0,2.133) paddles(b) check(b.vy<0 and abs(b.vx)<0.001)
 local basic=length(b.vx,b.vy)
 b=ball(55,92.8,0,2.133) paddles(b) check(b.vx>0 and b.vy<0,'tip failed to aim')
 p.dash=3.3 local d=paddle_depth(p)
 b=ball(50,100-d-2.5,0,2.133) paddles(b) check(length(b.vx,b.vy)>basic*1.4,'dash kick missing')
 p.dash=0 p.vel=3 b=ball(50,92.8,0,2.133) paddles(b) check(abs(b.spin)>0.1,'moving paddle spin missing')
end)
test('Magnus force bends without adding significant speed',function()
 reset() local a=ball(50,50,2.133,0) local b=ball(50,50,2.133,0)
 a.spin=1 b.spin=1 forces(a,1,true) forces(b,1,false)
 check(abs(a.vy)>0.01 and b.vy==0) close(length(a.vx,a.vy),length(b.vx,b.vy)) check(a.spin<1)
end)
test('all surviving-player combinations retain solid inactive sides',function()
 for arena=1,4 do for mask=1,15 do
  reset(3,2,arena)
  for s=1,4 do players[s].alive=(mask & (1 << (s-1)))~=0 players[s].hp=players[s].alive and 5 or 0 end
  for s=1,4 do
   local x,y=point(s,50,0.8) local nx,ny=normal(s) local b=ball(x,y,-nx*3,-ny*3)
   world(b,false) local a,d=localpos(s,b.x,b.y)
   if players[s].alive then close(d,0.8) else check(d>=1.59 and b.vx*nx+b.vy*ny>0,'inactive goal remained open') end
  end
 end end
 for cpus=1,2 do reset(cpus) for s=cpus+2,4 do
  local x,y=point(s,50,0.8) local nx,ny=normal(s) local b=ball(x,y,-nx*3,-ny*3) world(b,false)
  check(b.vx*nx+b.vy*ny>0,'unoccupied goal remained open')
 end end
end)
test('shield consumption and all power-ups',function()
 reset() local p=players[1]
 pickup(p,1) check(p.shield==360)
 local b=ball(50,99.2,0,3) world(b,false) check(b.vy<0 and p.shield==0)
 pickup(p,2) check(p.slow==180)
 pickup(p,4) update_players() close(p.half,7.5*1.45)
 for i=1,8 do pickup(p,3) end check(#balls==5,'multiball cap')
 for _,b0 in ipairs(balls) do check(b0.owner==1) end
end)
test('equal-mass ball exchange and coincident-ball separation',function()
 reset() local a,b=ball(49,50,2,0),ball(51,50,-2,0) balls={a,b} ball_pairs()
 close(a.vx,-2) close(b.vx,2) check(length(a.x-b.x,a.y-b.y)>=3.199)
 a.x=50 b.x=50 a.y=50 b.y=50 ball_pairs() check(length(a.x-b.x,a.y-b.y)>=3.199)
end)
test('elimination, last survivor, rounds, match result, rematch',function()
 for cpus=1,3 do for win=1,cpus+1 do
  reset(cpus) cfg.wins=2
  for round=1,2 do
   for s=1,cpus+1 do if s~=win then
    local p=players[s] p.hp=1 local b=ball(50,50,0,2) add(balls,b) goal(p,b)
   end end
   check(winner==players[win] and winner.wins==round)
   check(state==(round==1 and 'round' or 'match'))
   if round==1 then start_round() check(players[win].hp==cfg.points) end
  end
  start_match() check(round_no==1 and state=='play' and players[win].wins==0)
 end end
end)
test('eliminating holder releases ball and closes goal safely',function()
 reset(3) local p=players[3] local b=ball(0.2,50,-2,0) b.held=3 b.hold=1 b.offset=0 balls={b}
 p.hp=1 goal(p,ball(0,50,-2,0))
 check(not b.held and b.vx>0 and b.x>=2 and not p.alive)
end)
test('fast shots cannot tunnel through stationary paddles',function()
 for s=1,4 do
  reset(3) local p=players[s] local nx,ny=normal(s)
  local x,y=point(s,50,12) local b=ball(x,y,-nx*6.6,-ny*6.6) balls={b}
  for i=1,10 do
   b.x=b.x+b.vx/10 b.y=b.y+b.vy/10 paddles(b)
  end
  check(b.vx*nx+b.vy*ny>0,'tunnelled at side '..s)
 end
end)
local function snapshot()
 local out={state,tostring(clock)}
 for _,p in ipairs(players) do table.insert(out,string.format('%d:%.6f:%d',p.id,p.pos,p.hp)) end
 for _,b in ipairs(balls) do table.insert(out,string.format('%.6f:%.6f:%.6f:%.6f',b.x,b.y,b.vx,b.vy)) end
 return table.concat(out,'|')
end
test('seed determinism on desktop shim',function()
 local logs={}
 for trial=1,2 do
  reset(3,4,3,100)
  for n=1,300 do update_game() end
  logs[trial]=snapshot()
 end
 check(logs[1]==logs[2],'same seed diverged')
end)
test('predictive defense leads the ball and preserves world state',function()
 reset(1,2)
 local b=ball(20,50,2,-2) local a,arrival=predict(b,2,levels[2])
 check(a and a>50 and arrival>10,'AI did not predict future intercept')
 close(b.x,20) close(b.y,50) close(b.vx,2) close(b.vy,-2)
 players[1].shield=100
 local incoming=ball(50,96,0,2)
 predict(incoming,2,levels[4]) check(players[1].shield==100,'prediction consumed real shield')
end)
test('bumper reflection, chamfers, and goal axis guard',function()
 reset(3,2,2)
 local b=ball(41.5,50,3,0) check(circle_hit(b,50,50,7.2) and b.vx<0)
 b=ball(2,2,-2,-2) world(b,false) check(b.x+b.y>=corner+2.2,'chamfer failed')
 reset(1) b=ball(50,50,3,0) goal_axis(b)
 check(abs(b.vy)>=length(b.vx,b.vy)*0.2799,'vertical stall guard')
 players[1].alive=false players[2].alive=false
 add(players,{alive=true}) b=ball(50,50,0,3) goal_axis(b)
 check(abs(b.vx)>=length(b.vx,b.vy)*0.2799,'horizontal stall guard')
end)
test('extra-ball cap and later-round progression',function()
 reset(1) cfg.extra=true
 for i=1,4 do clock=1799 update_game() end
 check(extra_count==3 and desired==4,'extra-ball progression')
 round_no=2 start_round() check(desired==2)
 round_no=4 start_round() check(desired==3)
 cfg.extra=false clock=1799 update_game() check(extra_count==0)
end)
test('all presentation paths execute with drawing stubs',function()
 _init() _draw()
 state='setup'
 for pilot=1,4 do cfg.pilot=pilot for row=1,11 do menu=row _draw() end end
 state='credits' _draw()
 for arena=1,4 do
  reset(3,2,arena) for i=1,5 do spawn_ball(i%4+1) end
  for p in all(players) do p.grab=3 p.shield=3 p.slow=3 p.dash=3 end
  orbs={{x=30,y=30,k=1},{x=70,y=70,k=4}}
  _draw() winner=players[1] state='round' _draw() state='match' _draw()
 end
end)
test('signed AI aiming stays symmetric across turn wrap',function()
 close(signed_angle(1,1),-0.125)
 close(signed_angle(1,-1),0.125)
 close(signed_angle(1,1),-signed_angle(1,-1))
 reset()
 local p=players[1]
 local a=ball(50,91,0,0) a.offset=0 a.held=1 p.aim=-signed_angle(1,1) launch(p,a)
 local b=ball(50,91,0,0) b.offset=0 b.held=1 p.aim=-signed_angle(1,-1) launch(p,b)
 close(a.vx,-b.vx) close(a.vy,b.vy) check(a.vx>0 and b.vx<0,'AI throw direction bias')
end)
test('scored balls cannot collide with live balls',function()
 reset()
 local a,b=ball(49,50,2,0),ball(51,50,-2,0) a.dead=true balls={a,b}
 ball_pairs() close(a.x,49) close(b.x,51) close(a.vx,2) close(b.vx,-2)
end)
test('long-running counters remain bounded',function()
 reset() cfg.extra=false clock=1799 round_no=99
 local b=ball(50,50,2,0) b.age=900 b.stall=301 balls={b}
 update_game() close(clock,0) close(b.age,900) close(b.stall,301)
 round_no=100 start_round() check(round_no==100,'round counter grew past cap')
end)
if not flags['--quick'] then
local stats={}
test('48 configurations: seeded full matches and invariants',function()
 for cpus=1,3 do for diff=1,4 do for arena=1,4 do
  local wins,total_frames=0,0
  for seed=1,2 do
   reset(cpus,diff,arena,seed) local frames=0
   while state=='play' and frames<18000 do
    -- Deterministic, intentionally basic keyboard agent for the human seat.
    local nearest=nil local bd=1000
    for _,b in ipairs(balls) do if not b.held then
     local d=100-b.y if d<bd then nearest=b bd=d end
    end end
    local h={}
    if nearest then
     if nearest.x<players[1].pos-2 then h[0]=true elseif nearest.x>players[1].pos+2 then h[1]=true end
    end
    set_buttons(h,{}) update_game() frames=frames+1
    if frames%30==0 then invariant() end
   end
   check(state=='match','match stalled: '..cpus..'/'..diff..'/'..arena..' seed '..seed)
   check(winner and winner.alive,'missing winner')
   wins=wins+(winner.id==1 and 1 or 0) total_frames=total_frames+frames
  end
  stats[#stats+1]={cpus=cpus,diff=diff,arena=arena,wins=wins,games=2,seconds=total_frames/60}
 end end end
end)
local f=assert(io.open('tests/tournament-results.csv','w'))
f:write('cpus,difficulty,arena,seeds,human_agent_wins,mean_match_seconds\n')
for _,s in ipairs(stats) do f:write(string.format('%d,%s,%s,%d,%d,%.2f\n',s.cpus,diff_names[s.diff],arena_names[s.arena],s.games,s.wins,s.seconds)) end
f:close()
end
report(string.format('PASS %d test groups; %d assertions. Desktop Lua floats only; official PICO-8 runtime not exercised.',tests,assertions))
