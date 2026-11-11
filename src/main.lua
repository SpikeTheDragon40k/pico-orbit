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
