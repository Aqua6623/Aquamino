local pause={}
function pause.init()
    pause.time=0
    local bt=fs.read('framework/control/button.lua')
    pause.button=assert(loadstring(bt))()
    pause.button.create('pause_resume',{
        x=0,y=-150,type='rect',w=600,h=100,
        draw=function(t)
            gc.setColor(.5,.5,.5,.5+t)
            gc.rectangle('fill',-300,-50,600,100)
            gc.setColor(1,1,1)
            gc.printf("继续",SYHT,0,0,1280,'center',0,.5,.5,640,96)
        end,
        event=function()
            scene.cur.paused=false
        end
    })
    pause.button.create('pause_retry',{
        x=0,y=0,type='rect',w=600,h=100,
        draw=function(t)
            gc.setColor(.5,.5,.5,.5+t)
            gc.rectangle('fill',-300,-50,600,100)
            gc.setColor(1,1,1)
            gc.printf("重开",SYHT,0,0,1280,'center',0,.5,.5,640,96)
        end,
        event=function()
            scene.dest='solo' scene.destScene=require'mino/game'
            scene.swapT=.7 scene.outT=.3
            scene.anim=function() anim.cover(.3,.4,.3,0,0,0) end
            mus.stop()
        end
    })
    pause.button.create('pause_quit',{
        x=0,y=150,type='rect',w=600,h=100,
        draw=function(t)
            gc.setColor(.5,.5,.5,.5+t)
            gc.rectangle('fill',-300,-50,600,100)
            gc.setColor(1,1,1)
            gc.printf("退出",SYHT,0,0,1280,'center',0,.5,.5,640,96)
        end,
        event=function()
            scene.dest='menu'
            scene.swapT=.7 scene.outT=.3
            scene.anim=function() anim.cover(.3,.4,.3,0,0,0) end
        end
    })
end
function pause.mouseP(x,y,button,istouch)
    pause.button.click(x,y,button,istouch)
end
function pause.update(dt)
    pause.time=pause.time+dt
    pause.button.update(dt,gc.inverseTransformPoint(ms.getX()+.5,ms.getY()+.5))
end
function pause.draw(paused)
    if paused then pause.button.draw() end
end
function pause.exit() end
return pause