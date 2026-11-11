-- Diagnostic only: run from repo root with `lua tools/profile_prediction.lua`.
-- Counts desktop Lua VM instructions via debug hooks, in 1000-instruction buckets.
-- It does NOT measure PICO-8 cycles, fixed-point costs, drawing, or native C math.
local shim=dofile("tests/pico8_shim.lua")
for _,name in ipairs({"arena","physics","players","ai","game","rendering","main"}) do
 dofile("src/"..name..".lua")
end
local report=shim.print
local interval=1000
report("Desktop VM diagnostic: ".._VERSION.."; not official PICO-8 CPU profiling")
report("balls,max_instructions,arena,speed,spin,angle_degrees,max_world_samples")
for count=1,5 do
 local peak=0
 local peak_arena,peak_speed,peak_spin,peak_angle
 for arena=1,4 do
  _init()
  cfg.cpus=3 cfg.diff=4 cfg.arena=arena cfg.sound=false cfg.music=false
  start_match()
  for _,speed in ipairs({2.133,6.6}) do
   for _,spin in ipairs({-1,1}) do
    for angle=0,355,5 do
     balls={}
     for i=1,count do
      add(balls,{x=50,y=50,vx=math.cos(math.rad(angle))*speed,
       vy=math.sin(math.rad(angle))*speed,spin=spin,age=0})
     end
     local instructions=0
     debug.sethook(function() instructions=instructions+interval end,"",interval)
     for ball in all(balls) do predict(ball,2,levels[4]) end
     debug.sethook()
     if instructions>peak then
      peak=instructions peak_arena=arena peak_speed=speed peak_spin=spin peak_angle=angle
     end
    end
   end
  end
 end
 report(string.format("%d,%d,%s,%.3f,%d,%d,%d",count,peak,arena_names[peak_arena],
  peak_speed,peak_spin,peak_angle,count*math.min(24,math.floor(60/count))))
end
report("Peaks cover sampled center-origin balls and top-side Insane predictions only.")
report("Coincident ball headings stress prediction work; this is not a gameplay benchmark.")
report("Use official PICO-8 stat(1) for actual update/draw CPU and crowded gameplay testing.")
