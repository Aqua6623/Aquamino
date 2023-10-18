local clock={}
function clock.ini()
    abstime=(os.time()+28800)%86400
end
function clock.update(dt)
    abstime=(os.time()+28800)%86400--我们是东八区
end
function clock.draw()
    local timetxt=''..(floor(abstime/36000))..floor(abstime/3600%10)..":"..(floor(abstime/600)%6)..(floor(abstime/60)%10)..":"..(floor(abstime/10)%6)..(abstime%10)
    gc.setLineWidth(4)
    gc.line(0,0,sin(tau*abstime/60)*400,-cos(tau*abstime/60)*400)
    gc.setLineWidth(8)
    gc.line(0,0,sin(tau*abstime/3600)*360,-cos(tau*abstime/3600)*360)
    gc.setLineWidth(12)
    gc.line(0,0,sin(tau*abstime/43200)*256,-cos(tau*abstime/43200)*256)
    gc.circle('line',0,0,500)
    gc.setColor(.5,1,.75)
    gc.printf(timetxt,Exo_2,0,-300,1000,'center',0,1,1,500,64)
end
function clock.keyP(k)
end
return clock