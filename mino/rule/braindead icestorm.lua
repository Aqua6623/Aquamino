local gc=love.graphics
local M,T=mymath,mytable
local B=require'mino/blocks'
local rule={}
function rule.init(P,mino)
    P[1].posx=-440 P[2]=T.copy(P[1]) P[2].posx=440 mino.stacker.opList={1,2}
    mino.rule.spinType='default'
    mino.rule.allowSpin={'Z','S','J','L','T','O','I'}
    --print(#rule.allowSpin)
    sfx.add({
        smash='sfx/rule/ice storm/smash.wav',
        lvup='sfx/rule/ice storm/level up.wav'
    })
    rule.allowPush={}
    rule.scoreUp=200
    rule.scoreBase=400
    for i=1,#P do
        P[i].stormLv=1
        P[i].iceScore=0
        P[i].ruleAnim={
            score={preScore=0,t=0,tMax=.15},
            ice={},iceTMax=.3, smashParList={},
            lvupT=3,
            scoreTxt={},--[1]={x,y,v,g,color,size,TTL,Tmax}
        }
        for j=1,P[i].w do
            P[i].ruleAnim.ice[j]={preH=0,t=0}
        end
        P[i].iceColumn={}
        for j=1,P[i].w do
            P[i].iceColumn[j]={H=-1,topTimer=0,speed=0,speedmax=0,dvps=0}
        end
        rule.rise(P[i],rand(P[i].w))
    end
end
function rule.addScore(player,score)
    local A=player.ruleAnim.score
    A.preScore=player.iceScore A.t=A.tMax
    player.iceScore=player.iceScore+score
end
function rule.rise(player,col)
    local ice=player.iceColumn[col]
    if ice.H<0 then ice.H=0
        ice.speed=(1/1024+player.stormLv*1/8192)*(.95+.1*rand())
    end
end
function rule.destroy(player,col,scoring)
    local A=player.ruleAnim
    local ice,AIce=player.iceColumn[col],A.ice[col]
    if ice and ice.H~=-1 then
        if scoring then local score=(ice.H<=.15 and 320 or ice.H<=.25 and 240 or 160)
            rule.addScore(player,score)
            table.insert(player.ruleAnim.scoreTxt,{
                x=36*col+18,y=-36*player.h*min(ice.H,1),v={128*(rand()-.5),-90},g=864,TTL=.8,tMax=.4,
                size=72,color=(ice.H<=.15 and {1,.7,.4,1} or ice.H<=.25 and {1,.9,.1,1} or {.6,.8,1,1}),
                score=score
            })
        end
        sfx.play('smash')

        for i=1,floor((1+.4*rand())*min(ice.H,1)*player.h+.5) do
            table.insert(player.ruleAnim.smashParList,{
                x=36*(col+rand()),y=36*(-rand()*min(ice.H,1)*player.h),v={60*(rand()-.5),60*(rand()-.5)},g=1024,TTL=3
            })
        end
        for i=1,floor(min(ice.H,1)*player.h+.5) do
            table.insert(player.ruleAnim.smashParList,{
                x=36*(col+rand()),y=36*(.5-rand()-i),v={60*(rand()-.5),60*(rand()-.5)},g=1024,TTL=3
            })
        end

        ice.H=-1 ice.topTimer=0
        AIce.preH,AIce.t=0,0
    end
    local clear=true
    for i=1,player.w do if player.iceColumn[i].H>=0 then clear=false break end end
    if clear then rule.rise(player,rand(player.w)) end
end
function rule.decrease(player,col,amount,mtp)
    if not mtp then mtp=1 end
    local A=player.ruleAnim
    local ice=player.iceColumn[col]
    local his=player.history
    if ice and ice.H~=-1 then
        table.insert(player.ruleAnim.scoreTxt,{
            x=36*col+18,y=-36*player.h*min(ice.H,1),v={0,-90},g=90,TTL=.4,tMax=.4,
            size=(his.line==4 and 36 or 28+4*his.combo),color={1,1,1,.8},score=floor(amount*160*mtp)
        })
        A.ice[col]={
            --preH=ice.H,
            preH=M.lerp(min(ice.H,1),A.ice[col].preH, (A.ice[col].t/A.iceTMax)^2 ),
            t=A.iceTMax
        }
        ice.H=max(0,min(ice.H,1)-amount)
        rule.addScore(player,floor(amount*160*mtp))
        ice.topTimer=0
    end
end
function rule.lvup(player,mino)
    local A=player.ruleAnim
    while player.iceScore>=rule.scoreUp*(player.stormLv-1)+rule.scoreBase do
        for i=1,player.w do rule.destroy(player,i) end
        rule.rise(player,rand(player.w))
        A.preScore=rule.scoreUp*(player.stormLv-1)+rule.scoreBase
        player.iceScore=0 A.t=A.tMax
        player.stormLv=player.stormLv+1
        sfx.play('lvup')
        if 17==player.stormLv then mino.win() break end
        A.lvupT=0
    end
    sfx.play('lvup')
end

function rule.update(player,dt,mino)
    local A=player.ruleAnim
    if rand()<((player.stormLv-1)/100+.08)*dt then
        local col=rand(player.w) rule.rise(player,col)
    end
    for i=1,player.w do local ice=player.iceColumn[i]
        if ice.H>=2 then ice.topTimer=ice.topTimer+dt
            if ice.topTimer>=3 then mino.lose()
            player.deadTimer=0 mino.sfxPlay.die() end
        elseif ice.H>=0 then ice.H=min(ice.H+dt*ice.speed,2)
        A.ice[i].t=max(A.ice[i].t-dt,0) end
    end
    A.score.t=max(A.score.t-dt,0)
    local PL=A.smashParList
    for i=#PL,1,-1 do
        PL[i].TTL=PL[i].TTL-dt
        if PL[i].TTL<=0 then table.remove(PL,i) else
            PL[i].x,PL[i].y=PL[i].x+PL[i].v[1]*dt,PL[i].y+PL[i].v[2]*dt
            PL[i].v[2]=PL[i].v[2]+PL[i].g*dt
        end
    end
    local txt=A.scoreTxt
    for i=#txt,1,-1 do
        txt[i].TTL=txt[i].TTL-dt
        if txt[i].TTL<=0 then table.remove(txt,i) else
            txt[i].x,txt[i].y=txt[i].x+txt[i].v[1]*dt,txt[i].y+txt[i].v[2]*dt
            txt[i].v[2]=txt[i].v[2]+txt[i].g*dt
        end
    end

    A.lvupT=A.lvupT+dt
end
function rule.onPieceDrop(player,mino)
    local his=player.history
    if his.spin and his.line==0 then for i=1,#his.piece do
        rule.decrease(player,his.piece[i][1]+his.x,.3,1.5)
    end end
    rule.lvup(player,mino)
end
function rule.onLineClear(player,mino)
    local his=player.history
    local r=B.getX(his.piece)
    local PIC=player.iceColumn
    if his.line>=4 and his.name=='I' then
        local k=his.piece[1][1]+his.x
        for i=k-1,k+1 do rule.destroy(player,i,true) end
        if PIC[k-2] then rule.decrease(player,k-2,min(PIC[k-2].H,1),2) end
        if PIC[k+2] then rule.decrease(player,k+2,min(PIC[k+2].H,1),2) end
    else
        if his.spin then for i=1,#r do rule.destroy(player,r[i]+his.x,true) end
        else
            for i=1,#r do rule.decrease(player,r[i]+his.x,his.line*.2*(.75+.25*his.combo)) end
        end
    end
    for i=1,#r do for j=1,2 do
        if his.combo-j>0 then
            rule.decrease(player,r[i]+j+his.x,(his.combo-1)*.05/j)
            rule.decrease(player,r[i]-j+his.x,(his.combo-1)*.05/j)
        end
    end end
    rule.lvup(player,mino)
end
function rule.underFieldDraw(player)
    local A=player.ruleAnim.score
    local score,tar=player.iceScore,rule.scoreUp*(player.stormLv-1)+rule.scoreBase
    local sz=M.lerp(score,A.preScore,(A.t/A.tMax)^2)/tar
    gc.push()
        gc.translate(-18*player.w-90,0)
        gc.setColor(1,1,1)
        gc.setLineWidth(4)
        gc.rectangle('line',-47,-152,94,304)
        gc.setColor(.4,.8,1,.8)
        gc.rectangle('fill',-45,150-300*sz,90,300*sz)
        gc.setColor(1,1,1,.1)
        gc.rectangle('fill',-45,-150,90,300)
        gc.setColor(1,1,1)
        gc.printf("Lv."..player.stormLv,Consolas_B,-500,-194,3000,'center',0,1/3,1/3)
        gc.printf(("%d/%d"):format(score,tar),Consolas,-1250,160,10000,'center',0,.25,.25)
    gc.pop()
end
function rule.overFieldDraw(player)
    gc.push()
    local FW,FH=36*player.w,36*player.h
    gc.translate(-FW/2-36,FH/2)
    local A=player.ruleAnim
    for i=1,player.w do
        local ice=player.iceColumn[i]
        if ice.H>=0 then
            local clr=ice.H==2 and {.8,.1,.1} or ice.H>=1 and {.6,.9,1} or {.4,.8,1}
            gc.setColor(clr[1],clr[2],clr[3],.2)
            local H=M.lerp(min(ice.H,1),A.ice[i].preH, (A.ice[i].t/A.iceTMax)^2 )

            gc.rectangle('fill',36*i,-FH*H,36,FH*H)
            gc.setColor(clr[1],clr[2],clr[3],.4)
            local topH=M.clamp(ice.H-1,0,1)
            gc.rectangle('fill',36*i,-FH*topH,36,FH*topH)
            gc.setColor(clr[1],clr[2],clr[3],1)
            gc.rectangle('fill',36*i,-FH*H,4,FH*H)
            gc.rectangle('fill',36*i+32,-FH*H,4,FH*H)
        end
    end
    gc.setColor(.6,.9,1,min(player.deadTimer*2,0.8))
    gc.rectangle('fill',36,-FH,FW,FH)

    gc.setColor(.6,.84,1,.8)
    local PL=player.ruleAnim.smashParList
    for i=1,#PL do
        gc.rectangle('fill',PL[i].x-12,PL[i].y-12,24,24)
    end
    local txt=A.scoreTxt
    for i=1,#txt do
        local clr=txt[i].color
        gc.setColor(clr[1],clr[2],clr[3],clr[4]*txt[i].TTL/txt[i].tMax)
        gc.printf(""..txt[i].score,Consolas_B,txt[i].x,txt[i].y,5000,'center',0,txt[i].size/128,txt[i].size/128,2500,56)
    end
    gc.translate(18*player.w+36,-18*player.h)
    local t=A.lvupT
    gc.setColor(1,1,1,1.8-t/.3)
    gc.printf("LEVEL UP",Consolas_B,0,-1200*(t-.16)*t,5000,'center',0,.8,.8,2500,56)
    gc.pop()
end
return rule