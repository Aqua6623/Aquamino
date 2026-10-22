local BGTest={}
local t=0
local sddl=gc.newImage('pic/assets/sddl.png')--540*540

local cv=gc.newCanvas(400,400)
gc.setCanvas(cv)
gc.setColor(1,1,1)
gc.rectangle('fill',0,0,400,400)
gc.setCanvas()
function BGTest.init()
    scene.BG=require('BG/circles')
    if scene.BG.init then scene.BG.init() end
    --mus.add('music/Hurt Record/Symphonic Laser','whole','ogg',45,200*60/128)
    --BGTest.sd=gc.newShader('shader/merge.glsl')
    --scene.setShader('shader/mosaic.glsl')
    --scene.shader:send('phase',t)
end
function BGTest.keyP(k)
    if k=='space' then
        mus.start()
    end
end
function BGTest.update(dt)
    t=t+dt
    --scene.shader:send('phase',t)

    --scene.BG.time=mus.whole:tell()
end
function BGTest.draw()
    --gc.draw(sddl,0,0,0,1.25,1.25,270,270)
    --[[gc.setLineWidth(4)
    gc.setColor(1,1,1,.5)
    for i=-960,960,120 do
        gc.line(i,-540,i,540)
    end
    for i=-540,540,120 do
        gc.line(-960,i,960,i)
    end]]

    --[[gc.setColor(1,1,1)
    BGTest.sd:send('phase',t/3)
    gc.setShader(BGTest.sd)
    gc.draw(cv,0,0,0,2,2,200,200)
    gc.setShader()]]
end
return BGTest