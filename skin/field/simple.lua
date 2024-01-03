local simple={}
local T,M=mytable,mymath
function simple.draw(mino,order)
    local player=mino.player[order]
    local W,H=36*player.w,36*player.h
    gc.setColor(.1,.1,.1,.626)
    gc.rectangle('fill',-W/2,-H/2,W,H)
    gc.setColor(1,1,1)

    gc.setLineWidth(4)
    gc.rectangle('line',-400,-400,800,800)
    gc.line(-W/2-2,-H/2,-W/2-2,H/2+2,W/2+2,H/2+2,W/2+2,-H/2)
    gc.printf("HOLD",Exo_2_SB,-W/2-90,-400,800,'center',0,.25,.25,400,0)
    gc.printf("NEXT",Exo_2_SB, W/2+90,-400,800,'center',0,.25,.25,400,0)
    gc.setLineWidth(2)
    gc.setColor(1,1,1,.125)
    for y=-.5*player.h+1,.5*player.h-1 do
        gc.line(-W/2,36*y,W/2,36*y)
    end
    for x=-.5*player.w+1,.5*player.w-1 do
        gc.line(36*x,-H/2,36*x,H/2)
    end
    gc.setColor(1,1,1)
    gc.setColor(.5,1,.75)
    gc.rectangle('fill',-W/2,H/2+4,(W-36)*(1-player.LTimer/player.LDelay),20)
    gc.printf(""..player.LDR,Consolas_B,W/2-36,H/2+4,36/.2,'right',0,.2)
end
function simple.readyDraw(t)
    if t>1 then
    elseif t>.5 then gc.setColor(1,1,1,min((t-.5)/.25,1))
        gc.printf("READY",Exo_2_SB,0,0,1000,'center',0,.9,.9,500,256/3)
    elseif t>0 then gc.setColor(1,1,1,min(t/.25,1))
        gc.printf("SET",Exo_2_SB,0,0,1000,'center',0,.9,.9,500,256/3)
    elseif t>-.5 then gc.setColor(1,1,1,min((t+.5)/.25,1))
        gc.printf("GO!",Exo_2_SB,0,0,1000,'center',0,1.2,1.2,500,256/3)
    end
end
return simple