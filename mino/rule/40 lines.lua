local gc=love.graphics

local rule={}
function rule.init(P)
    mus.add('music/Hurt Record/Exciter','whole','mp3',30.709,192*60/127)
    mus.start()
    for i=1,#P do P[i].line=0 end
end
function rule.onLineClear(player,mino)
    player.line=player.line+player.history.line
    if player.line>=40 then mino.win() end
end
function rule.underFieldDraw(player)
    gc.setColor(1,1,1)
    gc.printf(""..max(40-player.line,0),Consolas,-18*player.w-90,-48,6000,'center',0,.75,.75,3000,0)
end
function rule.overFieldDraw(player)
    gc.push()
    local remain=max(40-player.line,0)
    if remain<=player.h and remain>0 then
        local lx,rx,y=-18*player.w,18*player.w,18*(player.h-2*remain)
        local clr=(remain<=10 and player.gameTimer%.2<.1) and {.6,1,.2,1} or {1,1,1,1}
        gc.setColor(clr)
        gc.setLineWidth(2)
        gc.line(lx,y,rx,y)
        gc.circle('fill',lx,y,9,4)
        gc.circle('fill',rx,y,9,4)
    end
    gc.pop()
end
function rule.onDie(player,mino)
    mino.stacker.winState=-1
end
return rule