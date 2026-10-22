local test={}
function test.init()
    test.trail=trail.create(.25,40,.5)
    test.t=0
end
function test.update(dt)
    msx,msy=adaptWindow:inverseTransformPoint(ms.getX()+.5,ms.getY()+.5)
    if love.mouse.isDown(1) then trail.addPos(test.trail,msx,msy) end
    test.t=test.t+dt
    --if test.t>1/64 then trail.addPos(test.trail,msx,msy) test.t=test.t-1/64 end
    --trail.addPos(test.trail,300*cos(test.t*math.pi),300*sin(test.t*math.pi))
    trail.update(test.trail,dt)
end
function test.draw()
    trail.drawLine2(test.trail,1,1,1)
    gc.setColor(1,1,1)
    --gc.circle('fill',300*cos(test.t*math.pi),300*sin(test.t*math.pi),20)
end
return test