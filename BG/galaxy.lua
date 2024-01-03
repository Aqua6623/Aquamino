--来自Techmino，有些许改动
--Space with stars
local gc=love.graphics
local setColor,hsv=gc.setColor,color.hsv
local galaxy={}
local tau=2*math.pi


function galaxy.init()
    if galaxy.sDist and galaxy.sDist[1] then return end
    galaxy.sDist,galaxy.sRev={},{} -- star data in SoA [distance from center, revolution progress, color]
    for i=0,20 do
        local max=16*(i+1)
        for j=1,max do
            galaxy.sDist[#galaxy.sDist+1]=i+math.random()
            galaxy.sRev[#galaxy.sRev+1]=tau*j/max+tau*math.random()/max
        end
    end
end
function galaxy.update(dt)
    for i=1,#galaxy.sDist do
        galaxy.sRev[i]=(galaxy.sRev[i]+dt/(galaxy.sDist[i]+1))%tau
    end
end
function galaxy.draw()
    gc.push('all')
    gc.rotate(1)
    gc.scale(1.5)
    for i=1,#galaxy.sDist do
        local d,r=galaxy.sDist[i],galaxy.sRev[i]
        if d<5 then
            setColor(hsv(.088*6,(d-2)/7,1,.4))
        else
            setColor(hsv(.572*6,d/70+.1,(22-d)/12,.4))
        end
        gc.circle('fill',8*d*cos(r),24*d*sin(r),5)
    end
    gc.pop()
end

return galaxy
