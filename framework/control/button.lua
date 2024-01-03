local BUTTON={list={},active=nil}
local gc=love.graphics
local M,T=mymath,mytable
function BUTTON.create(name,arg)
    if name and arg then BUTTON.list[name]=arg BUTTON.list[name].aboveT=0
    else BUTTON.list={} end
    BUTTON.active=nil
end
--[[e.g.
arg={
    x=0,y=0,
1.  type='circle',r=36,
2.  type='rect',w=72,h=48,
3.  type='poly',edge={ 80,0 , 0,80 , -80,0 , 0,-80 },
    draw=function()
        gc.setColor(1,1,1)
        gc.rectangle('fill',-16,-16,32,32)
        gc.setColor(1,1,1,.6)
        gc.rectangle('fill',-16,-16,32,32)
    end
    aboveT=0
    event=function() end
}
]]
function BUTTON.remove(name)
    if type(name)=='table' then for k,v in pairs(name) do BUTTON.list[v]=nil end
    else BUTTON.list[name]=nil end
end
function BUTTON.update(dt,x,y)
    for k,v in pairs(BUTTON.list) do
        if BUTTON.check(v,x,y) then v.aboveT=v.aboveT+dt
        else v.aboveT=max(v.aboveT-dt,0) end
    end
end
function BUTTON.check(butt,x,y)
    local ax,ay=x-butt.x,y-butt.y
    if butt.type=='circle' then return (x-butt.x)^2+(y-butt.y)^2<butt.r^2
    elseif butt.type=='rect' then
        return ax>-butt.w/2 and ax<butt.w/2 and ay>-butt.h/2 and ay<butt.h/2
    elseif butt.type=='poly' then return M.pointInPolygon(ax,ay,butt.edge) end
end
function BUTTON.draw()
    for k,v in pairs(BUTTON.list) do gc.push()
        gc.translate(v.x,v.y)
        v.draw(v.aboveT)
    gc.pop() end
end
function BUTTON.press(x,y)
    for k,v in pairs(BUTTON.list) do
        if BUTTON.check(v,x,y) then BUTTON.active=k return k end
    end
end
function BUTTON.release(x,y)
    for k,v in pairs(BUTTON.list) do
        if BUTTON.check(v,x,y) and BUTTON.active==k then v.event() end
    end
end
function BUTTON.click(x,y,button,istouch)
    for k,v in pairs(BUTTON.list) do
        if BUTTON.check(v,x,y) then v.event() return k end
    end
end
return BUTTON