local marathon={}
function marathon.init(P,mino)
    sfx.add({
        lvup='sfx/rule/marathon/level up.wav'
    })
    mino.stacker.ctrl={
       DAS=.15,ARR=.03,SDType='D',SD_DAS=0,SD_ARR=1/20
    }
    P[1].posx=-440 P[2]=mytable.copy(P[1]) P[2].posx=440 mino.stacker.opList={1,2}
    print(#mino.stacker.opList)
    for k,v in pairs(P) do
        v.CDelay=.2

        v.speedLv=1
        v.FDelay=2^(-(v.speedLv-1)/14*8)
        v.totalLine=0
    end
end
function marathon.onLineClear(player,mino)
    local his=player.history
    player.totalLine=player.totalLine+his.line
    while player.totalLine>=player.speedLv*5 do
        local win=true
        for k,v in pairs(mino.player) do
            if player.totalLine<75 then win=false break end
        end
        if win then mino.win() break end
        player.speedLv=player.speedLv+1
        player.FDelay=2^(-(player.speedLv-1)/14*8)
        mino.stacker.ctrl.SD_ARR=2^(-(player.speedLv-1)/14*8)/20
        sfx.play('lvup')
    end
end
function marathon.underFieldDraw(player)
    gc.setColor(1,1,1)
    gc.printf(""..player.totalLine,Consolas_B,-player.w*18-90,-32,2048,'center',0,.5,.5,1024,56)
    gc.printf(""..player.speedLv*5,Consolas_B,-player.w*18-90,32,2048,'center',0,.5,.5,1024,56)
    gc.printf("Speed Lv.\n"..player.speedLv,Consolas_B,-player.w*18-8,256,2048,'right',0,0.25,0.25,2048,56)
    gc.setLineWidth(7)
    gc.line(-player.w*18-150,0,-player.w*18-30,0)
end
function marathon.onDie(player,mino)
    mino.stacker.winState=-1
end
return marathon