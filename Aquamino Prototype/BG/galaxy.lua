--Space with stars
local gc=love.graphics
local circle,setColor,hsv=gc.circle,gc.setColor,color.hsv
local sin,cos=math.sin,math.cos
local back={}
local tau=2*math.pi

local sDist,sRev={},{} -- star data in SoA [distance from center, revolution progress, color]

function back.ini()
    if sDist[1] then return end
    local max
    for i=0,20 do
        max=16*(i+1)
        for j=1,max do
            sDist[#sDist+1]=i+math.random()
            sRev[#sRev+1]=tau*j/max+tau*math.random()/max
        end
    end
end
function back.update(dt)
    for i=1,#sDist do
        sRev[i]=(sRev[i]+dt/(sDist[i]+1))%tau
    end
end
function back.draw()
    gc.push('all')
    gc.rotate(1)
    gc.scale(1.7)
    for i=1,#sDist do
        local d,r=sDist[i],sRev[i]
        if d<5 then
            setColor(hsv(.088,(d-2)/7,1,.2))
        else
            setColor(hsv(.572,d/70+.1,(22-d)/12,.2))
        end
        circle('fill',8*d*cos(r),24*d*sin(r),5)
    end
    gc.pop()
end

return back
