--来自Techmino，有些许改动
-- Space with stars
local gc=love.graphics
local back={}
function back.init()
    back.stars={}
    --BG.resize(SCR.w,SCR.h)
    local S=back.stars
    for i=1,1260,5 do
        local sz=rand(26,40)*.15
        --S[i]=sz*SCR.k           -- Size
        S[i]=sz                   -- Size
        S[i+1]=rand(1920)-10      -- X
        S[i+2]=rand(1080)-10      -- Y
        S[i+3]=(rand()-.5)*.01*sz-- Vx
        S[i+4]=(rand()-.5)*.01*sz-- Vy
    end
end
function back.update(dt)
    local S=back.stars
    -- Star moving
    for i=1,1260,5 do
        S[i+1]=(S[i+1]+S[i+3]*dt*60)%1920
        S[i+2]=(S[i+2]+S[i+4]*dt*60)%1080
    end
end
function back.draw()
    gc.push()
    gc.translate(-960,-540)
        gc.clear(.05,.06,.08)
        if not back.stars[1] then return end
        gc.translate(-10,-10)
        gc.setColor(1,1,1,.75)
        for i=1,1260,5 do
            gc.rectangle('fill',back.stars[i+1],back.stars[i+2],back.stars[i],back.stars[i])
        end
        gc.translate(10,10)
    gc.pop()
end
--[[function back.discard()
    stars=nil
end]]
return back
