local slider={list={},acting=nil}
local gc=love.graphics
local M,T=mymath,mytable
function slider.create(name,arg)
    if name and arg then slider.list[name]=arg
    else slider.list={} end
end
--[[e.g.
arg={
    x=0,y=0,type=(hori/vert),sz={128,32},button={18,36}
1.  gear=5(|--|--|--|--|),pos=(0/1/2/3/4),
2.  gear=0(-------------),pos=0.6180339887,
    sliderDraw=function() end
    buttonDraw=function() end
    aboveT=0,
    event=function() end
}
]]
function slider.draw()
    for k,v in pairs(slider.list) do gc.push()
        gc.translate(v.x,v.y)
        v.sliderDraw(v.gear) v.buttonDraw(v.gear==0 and v.pos or v.pos/(v.gear-1))
    gc.pop() end
end
function slider.check(slid,x,y)
    local ax,ay=x-slid.x,y-slid.y
        return ax>-(slid.sz[1]+slid.button[1])/2 and ax<(slid.sz[1]+slid.button[1])/2
           and ay>-(slid.sz[2]+slid.button[2])/2 and ay<(slid.sz[2]+slid.button[2])/2
end
function slider.mouseP(x,y,button,istouch)
    for k,v in pairs(slider.list) do if slider.check(v,x,y) then
        local pos=M.clamp(v.type=='hori' and (x-v.x)/v.sz[1]+.5 or (y-v.y)/v.sz[2]+.5,0,1)
        if v.gear==0 then v.pos=pos else
            v.pos=floor((v.gear-1)*pos+.5)
        end
        slider.acting=k
        if v.click then v.click(pos) end break
    end end
end
function slider.mouseR(x,y,button,istouch)
    if slider.acting and slider.list[slider.acting].release then
        slider.list[slider.acting].release(slider.list[slider.acting].pos)
    end
    slider.acting=nil
end
function slider.always(slid,x,y)
    local pos=M.clamp((slid.type=='hori' and (x-slid.x)/slid.sz[1]+.5 or (y-slid.y)/slid.sz[2]+.5),0,1)
    if slid.gear==0 then slid.pos=pos else
        slid.pos=floor((slid.gear-1)*pos+.5)
    end
    if slid.always then slid.always(slid.pos) end
end
return slider