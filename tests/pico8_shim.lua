-- Desktop execution shim, not an emulator: Lua floats, not PICO-8 fixed point.
local native_print=print
local held,pressed={},{}
sqrt=math.sqrt abs=math.abs min=math.min max=math.max flr=math.floor
function mid(a,b,c) return math.max(math.min(a,b),math.min(math.max(a,b),c)) end
function sin(t) return -math.sin(t*math.pi*2) end
function cos(t) return math.cos(t*math.pi*2) end
function atan2(x,y) return (-math.atan(y,x)/(2*math.pi))%1 end
function srand(n) math.randomseed(n) end
function rnd(n)
 if type(n)=='table' then return n[math.random(#n)] end
 return math.random()*(n or 1)
end
function add(t,v,i) if i then table.insert(t,i,v) else table.insert(t,v) end return v end
function deli(t,i) return table.remove(t,i or #t) end
function del(t,v) for i,x in ipairs(t) do if x==v then return table.remove(t,i) end end end
function all(t)
 local i=0 local previous=nil
 return function()
  if i>0 and t[i]~=previous then i=i-1 end
  i=i+1 previous=t[i] return previous
 end
end
function btn(n,p) return (not p or p==0) and held[n] or false end
function btnp(n,p) return (not p or p==0) and pressed[n] or false end
function set_buttons(h,p) held=h or {} pressed=p or {} end
for _,n in ipairs({'sfx','music','cls','rect','rectfill','circ','circfill','ovalfill','oval','line','pset','pal','palt','camera','clip','spr','sspr','map','menuitem','color','fillp'}) do _G[n]=function() end end
function print(s,x,y,c) if x==nil then native_print(s) end return (x or 0)+#tostring(s)*4 end
function t() return os.clock() end
function stat() return 0 end
function tostr(x) return tostring(x) end
function split(s,sep)
 local out={} for x in s:gmatch('[^'..(sep or ',')..']+') do table.insert(out,tonumber(x) or x) end return out
end
return {print=native_print}
