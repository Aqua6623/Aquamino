local intro={}
local bannedkey={'f1','f2','f3','f4','f5','f6','f7','f8','f9','f10','f11','f12','tab'}
function intro.ini()
    scene.bg=require'BG/blank'
end
function intro.keyP(k)
    if k=='escape' then love.event.quit()
    else
    scene.dest='menu' scene.swaptime=1.4 scene.outtime=.6
    scene.anim=function() anim.enter2(.4,1,.6) end
    end
end
function intro.mouseP(x,y,button,istouch)
    scene.dest='menu' scene.swaptime=1.4 scene.outtime=.6
    scene.anim=function() anim.enter2(.4,1,.6) end
end
function intro.draw()
    --gc.printf("Aquamino",Exo_2,-114514,-256,114514,'center',0,2,2)

    gc.printf("Press any key to start",Exo_2,-57257,150,114514,'center',0,1,1)

    gc.setColor(1,1,1,.25)
    gc.printf("Version : Contructing...",Exo_2,-240,480,1600,'center',0,.3,.3)
end
--function intro.send() scene.cur.modename[1]="40行" end
return intro