---@diagnostic disable: deprecated
--[[
    stacker是你自己，player存储的是玩家相关变量，player[any]就好像一个干员的所有信息（卧槽，舟！）。
    stacker是可以操控多个player的。stacker.opList存储着你所操控的player序号。
]]

local gc=love.graphics
local fs=love.filesystem

local T,M=mytable,mymath

local fLib=require'mino/fieldLib'
local B=require'mino/blocks'
local NG=require'mino/nextGen'
local SC=require'mino/spinCheck'

local pause=require'mino/special/pause'
--math.randomseed(os.time())

local mino={
    sfxPlay=nil,
    rule={
        timer=0,
        allowPush={},allowSpin={T=true},spinType='default',loosen={fallTPB=0}
    },
    paused=false,pauseTimer=0,
    stacker={
        keySet={},ctrl={},opList={1},trail=nil,
        dieAnim=function() end,
        winState=0,
    },
    --bag={},
    bagGen='bag',
    bag={'Z','S','J','L','T','O','I'},orient={Z=0,S=0,J=0,L=0,T=0,O=0,I=0},
    player={}
    --[[example:
        P[1]={
        started=false,gameTimer=0,deadTimer=-1,

        event={1.5,'curIns'},
        posx=0,posy=0,r=0,scale=1,
        field={},w=10,h=20,loosen={},
        moveDir='',pushAtt=0,
        color={
            Z={1,.16,.32},S={.4,.96,.04},J={0,.64,1},L={.98,.62,.32},T={.8,.2,1},O={1,1,0},I={.08,1,.6},

            g1={.5,.5,.5},
            g2={.75,.75,.75},
            g_ls={1,1,.5},

            ls={1,1,.75}
        },
        blockSkin=require('skin/block/pure'),
        fieldSkin=require('skin/field/simple'),
        RS='SRS',
        next={},NO={},NP={},preview=6,
        hold={mode='S'},canHold=true,

        CDelay=0.,EDelay=0,
        MTimer=0,DTimer=0,
        FDelay=1,FTimer=0,
        LDelay=1,LTimer=0,LDR=15,LDRInit=15,

        history={
            name=nil,piece={},x=0,y=0,O=0,
            dropHeight=0,kickOrder=0,
            line=0,spin=false,PC=false,combo=0,B2B=-1,
        },
        cur={
            name=nil,piece={},x=5,y=21,O=0,
            moveSuccess=false,
            kickOrder=0
        },

        animAct=false,
        smoothAnim={piece={},timer=0,delay=0.05},
        dropAnim={}
        --dropAnim[1]={x=0,ys=0,yf=0,TMax=0.5,TTL=0.5}
    }
    }]]
}
local P,S,rule=mino.player,mino.stacker,mino.rule

function mino.start(player) end
function mino.pause(player) end
function mino.win()
    S.winState=1 if mino.sfxPlay.win then mino.sfxPlay.win() end
end
function mino.lose()
    S.winState=-1 if mino.sfxPlay.lose then mino.sfxPlay.lose() end
end
function mino.die(player)
    if fLib.coincide(player) then
        player.deadTimer=0 mino.sfxPlay.die()
        if rule.onDie then rule.onDie(player,mino) end
    end
end
function mino.curIns(player)
    if player.next[player.preview+1] then
        local wtf=player.preview+1
        player.NP[wtf]=T.copy(B[player.next[wtf]])
        player.NO[wtf]=mino.orient[player.next[wtf]]
        for k=1,player.NO[wtf] do
            player.NP[wtf]=B.rotate(player.NP[wtf],0,'R')
        end
    end

    local C=player.cur
    local A=player.smoothAnim
    local his=player.history
    if player.next[1] then
        C.x,C.y=ceil(player.w/2)+B.Soff[player.next[1]][1],player.h+1+B.Soff[player.next[1]][2]
        C.piece=table.remove(player.NP,1)
        A.piece=T.copy(C.piece)
        for i=1,#A.piece do
            A.piece[i][1],A.piece[i][2]=A.piece[i][1]+C.x,A.piece[i][2]+C.y
        end
        C.O=table.remove(player.NO,1)
        C.name=table.remove(player.next,1)
        player.canHold=true C.kickOrder=nil
    elseif player.hold.name then mino.hold(player)
    else C.piece,C.name=nil,nil end
    if #player.next<=21 then NG[mino.bagGen](mino.bag,player.next) end
    player.MTimer,player.DTimer=min(player.MTimer,S.ctrl.DAS),min(player.DTimer,S.ctrl.SD_DAS)
    player.LDR=player.LDRInit player.LTimer=0
    while player.FDelay==0 and not fLib.coincide(player,0,-1) do C.y=C.y-1 end
    player.started=true

    his.line=0 his.mini=false
    if rule.onPieceEnter then rule.onPieceEnter(player) end
end
function mino.hold(player)
    local H,C,A=player.hold,player.cur,player.smoothAnim
    H.name,C.name=C.name,H.name  H.piece,C.piece=C.piece,H.piece  H.O,C.O=C.O,H.O
    if player.hold.mode=='A' then
        H.x,H.y,C.x,C.y=C.x,C.y,H.x,H.y
        while C.piece and fLib.coincide(player) and C.y<player.h+B.Soff[C.name][2] do C.y=C.y+1 end
    elseif player.hold.mode=='S' then
    if C.name then
        C.x,C.y=ceil(player.w/2)+B.Soff[C.name][1],player.h+1+B.Soff[C.name][2]
        C.O=mino.orient[C.name]
        A.piece=T.copy(C.piece)
        for i=1,#A.piece do
            A.piece[i][1],A.piece[i][2]=A.piece[i][1]+C.x,A.piece[i][2]+C.y
        end
    end
    while H.O~=0 do
        H.piece,H.O=B.rotate(H.piece,H.O,'L')
    end
    else error("player.hold.mode must be 'S' or 'A'") end
    player.LTimer,player.FTimer=0,0
end

function mino.loosenDrop(player)
    local his,delay=player.history,rule.loosen.fallTPB
    fLib.loosenFall(player)
    if player.loosen[1] then mino.addEvent(player,delay,'loosenDrop')
    else his.line,his.PC=fLib.lineClear(player)
    mino.clearCalc(player,true) mino.sfxPlay.clear(player)
    if his.line>0 and rule.onLineClear then rule.onLineClear(player,mino) end
    end
end

function mino.clearCalc(player,comboBreak,delayBreak)
    local his=player.history
    if his.line>0 then
        if delayBreak or player.CDelay==0 then fLib.eraseEmptyLine(player)
        else mino.addEvent(player,player.CDelay,'eraseEmptyLine') end
        his.combo=his.combo+1
        his.B2B=(his.spin or his.line>=4) and his.B2B+1 or -1
    elseif comboBreak then his.combo=0 end
end

function mino.addEvent(player,time,thing)
    player.event[#player.event+1]=time player.event[#player.event+1]=thing
end
function mino.setAnimBLock(player)
    local C,A=player.cur,player.smoothAnim
    local curPiece=T.copy(C.piece)
    for i=1,#curPiece do
        curPiece[i][1],curPiece[i][2]=curPiece[i][1]+C.x,curPiece[i][2]+C.y-(player.FDelay==0 and 0 or player.FTimer/player.FDelay)
    end
    A.piece=M.lerp(curPiece,A.piece,A.timer/A.delay)
end
function mino.addDropAnim(player,x,ys,yf,TTL)
    player.dropAnim[#player.dropAnim+1]={x=x,ys=ys,yf=yf,TTL=TTL,TMax=TTL}
end

function mino.setMusic(theme,type)
    if fs.getInfo('music/'..theme..'/intro.'..type) then
        mus.intro=love.audio.newSource('music/'..theme..'/intro.'..type,'stream')
    else mus.intro=nil end
    if fs.getInfo('music/'..theme..'/ITrans.'..type) then
        mus.ITrans=love.audio.newSource('music/'..theme..'/ITrans.'..type,'stream')
    else mus.ITrans=nil end
    if fs.getInfo('music/'..theme..'/loop.'..type) then
        mus.loop=love.audio.newSource('music/'..theme..'/loop.'..type,'stream')
    else mus.loop=nil end
end

function mino.init()
    mino.waitTime=2
    scene.BG=require('BG/blank')
    S.winState=0
    --测试
    --mus.volume=0
    mino.paused=false mino.pauseTimer=0 mino.pauseAnimTimer=0

    mino.sfxPlay=require('sfx/game/Dr Ocelot')
    mino.sfxPlay.addSFX()

    function S.dieAnim(player)
        gc.setColor(1,1,1,player.deadTimer*4)
        gc.printf("失败",Exo_2,-200,-256/3,400,'center',0,1)
    end

    P[1]={
        started=false,gameTimer=0,deadTimer=-1,

        event={0,'curIns'},
        posx=0,posy=0,r=0,scale=1,
        field={},w=10,h=20,loosen={},
        moveDir='',pushAtt=0,
        color={
            Z={1,.16,.32},S={.5,.96,.04},J={0,.64,1},L={.98,.62,.32},T={.8,.2,1},O={1,1,0},I={.15,1,.75},

            g1={.5,.5,.5},
            g2={.75,.75,.75},
            g_ls={1,1,.5},

            ls={1,1,.75}
        },
        blockSkin=require('skin/block/pure'),
        fieldSkin=require('skin/field/simple'),
        RS='SRS',
        next={},NO={},NP={},preview=6,
        hold={mode='S'},canHold=true,

        CDelay=0.,EDelay=0,
        MTimer=0,DTimer=0,
        FDelay=1,FTimer=0,
        LDelay=1,LTimer=0,LDR=15,LDRInit=15,

        history={
            name=nil,piece={},x=0,y=0,O=0,
            dropHeight=0,kickOrder=0,
            line=0,spin=false,mini=false,PC=false,combo=0,B2B=-1,
        },
        cur={
            name=nil,piece={},x=5,y=21,O=0,
            moveSuccess=false,
            kickOrder=0
        },

        ruleAnim={},
        animAct=false,
        smoothAnim={piece={},timer=0,delay=0.05},
        dropAnim={}
        --dropAnim[1]={x=0,ys=0,yf=0,TMax=0.5,TTL=0.5}
    }

    S.keySet=fs.getInfo('conf/keySet') and json.decode(fs.newFile('conf/keySet'):read()) or
    {
        ML={'left'},MR={'right'},
        CW={'x'},CCW={'c'},flip={'d'},
        SD={'down'},HD={'up'},hold={'z'},
        R={'r'},pause={'escape','p'}
    }

    S.ctrl=fs.getInfo('conf/ctrl') and json.decode(fs.newFile('conf/ctrl'):read()) or
    {DAS=.15,ARR=.03,SD_DAS=0,SD_ARR=.05}

    --[[S.keySet={
        ML={'kp1'},MR={'kp3'},
        CW={'kp5'},CCW={'x'},flip={'kp6'},
        SD={'kp2'},HD={'c','d','f','j','k'},hold={'z'},
        R={'r'},quit={'escape'}
    }]]
    --[[local ctrlstr=love.system.getClipboardText()
    print(_VERSION)
    print(ctrlstr)
    assert(loadstring(ctrlstr))()]]

    T.combine(rule,require('mino/rule/40 lines'))
    if rule.init then rule.init(P,mino) end

    for i=1,#P do
        while #P[i].next<3*#mino.bag do NG[mino.bagGen](mino.bag,P[i].next) end
        for j=1,P[i].preview do --给所有玩家放上预览块
            P[i].NP[j]=T.copy(B[P[i].next[j]])
            P[i].NO[j]=mino.orient[P[i].next[j]]
            for k=1,P[i].NO[j] do
            P[i].NP[j]=B.rotate(P[i].NP[j],0,'R')
            end
        end
        if P[i].blockSkin.init then P[i].blockSkin.init() end
    end
end

function mino.keyP(k)
    local key=S.keySet
    if T.include(key.pause,k) then mino.paused=not mino.paused
        if mino.paused then pause.init() end
    elseif T.include(key.R,k) then
        scene.dest='solo' scene.destScene=require('mino/game') scene.swapT=1.5 scene.outT=.5
        scene.anim=function() anim.cover(.5,1,.5,0,0,0) end
        mus.stop()
    end
    if mino.paused then --nothing
    elseif mino.waitTime>0 then
        for i=1,#S.opList do
            local OP=P[S.opList[i]]--Player Operated by you
            if T.include(key.ML,k) then OP.moveDir='L'
            elseif T.include(key.MR,k) then OP.moveDir='R'
            end
        end
    else
    for i=1,#S.opList do
        local OP=P[S.opList[i]]
        local C,A=OP.cur,OP.smoothAnim
        local his=OP.history
        local landed
        if OP.event[1] and OP.deadTimer<0 and S.winState==0 then
            if T.include(key.ML,k) then
                OP.moveDir='L'
                if love.keyboard.isDown(key.MR) then OP.MTimer=0 end
            elseif T.include(key.MR,k) then 
                OP.moveDir='R'
                if love.keyboard.isDown(key.ML) then OP.MTimer=0 end
            end
        elseif OP.deadTimer<0 and S.winState==0 then
            landed=fLib.coincide(OP,0,-1)
            if T.include(key.ML,k) then
                local success=not fLib.coincide(OP,-1,0)
                if success then mino.setAnimBLock(OP) A.timer=A.delay
                    C.x=C.x-1 C.moveSuccess=true his.spin=false
                    if landed and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1 end
                else  end
                OP.moveDir='L'
                if love.keyboard.isDown(key.MR) then OP.MTimer=0 end

                mino.sfxPlay.move(OP,success,landed)

            elseif T.include(key.MR,k) then
                local success=not fLib.coincide(OP,1,0)
                if success then mino.setAnimBLock(OP) A.timer=A.delay
                    C.x=C.x+1 C.moveSuccess=true his.spin=false
                    if landed and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1 end
                else  end
                OP.moveDir='R'
                if love.keyboard.isDown(key.ML) then OP.MTimer=0 end

                mino.sfxPlay.move(OP,success,landed)

            elseif T.include(key.CW,k) then mino.setAnimBLock(OP)
                C.kickOrder=fLib.kick(OP,'R')
                if C.kickOrder then A.timer=A.delay
                    C.moveSuccess=true
                    if landed and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1
                    else if C.kickOrder~=1 then OP.LDR=OP.LDR-1 end
                    end
                    if rule.allowSpin[C.name] then his.spin,his.mini=SC[rule.spinType](OP)
                    else his.spin,his.mini=false,false end
                end

                mino.sfxPlay.rotate(OP,C.kickOrder,fLib.isImmobile(OP))

            elseif T.include(key.CCW,k) then mino.setAnimBLock(OP)
                C.kickOrder=fLib.kick(OP,'L')
                if C.kickOrder then A.timer=A.delay
                    C.moveSuccess=true
                    if landed and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1
                    else if C.kickOrder~=1 then OP.LDR=OP.LDR-1 end
                    end
                    if rule.allowSpin[C.name] then his.spin,his.mini=SC[rule.spinType](OP)
                    else his.spin,his.mini=false,false end
                end

                mino.sfxPlay.rotate(OP,C.kickOrder,fLib.isImmobile(OP))

            elseif T.include(key.flip,k) then mino.setAnimBLock(OP)
                C.kickOrder=fLib.kick(OP,'F')
                if C.kickOrder then A.timer=A.delay
                    C.moveSuccess=true
                    if landed and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1
                    else if C.kickOrder~=1 then OP.LDR=OP.LDR-1 end
                    end
                    if rule.allowSpin[C.name] then his.spin,his.mini=SC[rule.spinType](OP)
                    else his.spin,his.mini=false,false end
                end

                mino.sfxPlay.rotate(OP,C.kickOrder,fLib.isImmobile(OP))

            elseif T.include(key.HD,k) then --硬降
                local xmin,xmax,ymin,ymax=B.edge(C.piece)
                local xlist=B.getX(C.piece)
                local smoothFall=(OP.animAct and OP.FTimer/OP.FDelay or 0)
                for j=1,#xlist do
                    local lmax=ymax
                    while not T.include(C.piece,{xlist[j],lmax}) do
                        lmax=lmax-1
                    end
                    OP.dropAnim[#OP.dropAnim+1]={
                        x=C.x+xlist[j],y=C.y-smoothFall+lmax,len=-smoothFall,
                        TMax=.5,TTL=.5, w=xmax-xmin+1,h=ymax-ymin+1,
                        color=OP.color[C.name]
                    }
                end
                his.dropHeight=0
                if C.piece and #C.piece~=0 then
                    for h=1,C.y do
                        if not fLib.coincide(OP,0,-1) then his.spin=false
                            C.y=C.y-1  his.dropHeight=his.dropHeight+1
                            for j=#OP.dropAnim,#OP.dropAnim-#xlist+1,-1 do
                                OP.dropAnim[j].len=OP.dropAnim[j].len+1
                            end
                        end
                    end

                    mino.die(OP)

                    fLib.lock(OP) fLib.loosenFall(OP) mino.sfxPlay.lock(OP)
                    if OP.loosen[1] then
                        print(rule.loosen.fallTPB)
                        if rule.loosen.fallTPB==0 and OP.CDelay==0 then
                            while OP.loosen[1] do fLib.loosenFall(OP) end
                            mino.loosenDrop(OP)
                        else mino.addEvent(OP,rule.loosen.fallTPB,'loosenDrop') end
                    else
                        his.line,his.PC=fLib.lineClear(OP)
                        mino.clearCalc(OP,true) mino.sfxPlay.clear(OP)
                        if his.line>0 and rule.onLineClear then rule.onLineClear(OP,mino) end
                    end
                    if rule.onPieceDrop then rule.onPieceDrop(OP,mino) end
                end

                if S.winState==0 then
                    if OP.EDelay==0 then mino.curIns(OP)
                    else mino.addEvent(OP,OP.EDelay,'curIns') end
                end

            elseif T.include(key.SD,k) then
                if S.ctrl.SD_DAS==0 and S.ctrl.SD_ARR==0 then
                    while not fLib.coincide(OP,0,-1) do
                        mino.setAnimBLock(OP) A.timer=A.delay
                        C.y=C.y-1 his.spin=false
                    end
                elseif not landed then
                    mino.setAnimBLock(OP) A.timer=A.delay
                    C.y=C.y-1 his.spin=false
                end

                mino.sfxPlay.touch(OP,fLib.coincide(OP,0,-1))

            elseif T.include(key.hold,k) and OP.canHold then
                mino.hold(OP) mino.sfxPlay.hold(OP)
                if not C.name then mino.curIns(OP) end
                OP.canHold=false

            else end

            --推土机！
            if rule.allowPush[C.name] and C.kickOrder then
                local reset=true
                if OP.moveDir=='R' and love.keyboard.isDown(key.MR) and fLib.coincide(OP,1,0) then
                    if T.include(key.CW,k) or T.include(key.CCW,k) or T.include(key.flip,k) then reset=false
                    OP.pushAtt=OP.pushAtt+1 fLib.pushField(OP,'R')
                    end
                end
                if OP.moveDir=='L' and love.keyboard.isDown(key.ML) and fLib.coincide(OP,-1,0) then
                    if T.include(key.CW,k) or T.include(key.CCW,k) or T.include(key.flip,k) then reset=false
                    OP.pushAtt=OP.pushAtt+1 fLib.pushField(OP,'L')
                    end
                end
                if love.keyboard.isDown(key.SD) and fLib.coincide(OP,0,-1) then
                    if T.include(key.CW,k) or T.include(key.CCW,k) or T.include(key.flip,k) then reset=false
                    OP.pushAtt=OP.pushAtt+1 fLib.pushField(OP,'D')
                    end
                end
                if reset then OP.pushAtt=0 end
            end

            --最高下落速度
            if not T.include(key.HD,k) and OP.FDelay==0 then
                while not fLib.coincide(OP,0,-1) do C.y=C.y-1 end
            end
        end

    end--for
    end--if-else
end

function mino.keyR(k)
    local key=S.keySet
    for i=1,#S.opList do
        local OP=P[S.opList[i]]
        if T.include(key.ML,k) then
            if love.keyboard.isDown(key.MR) then OP.MTimer=S.ctrl.DAS OP.moveDir='R' end
        elseif T.include(key.MR,k) then
            if love.keyboard.isDown(key.ML) then OP.MTimer=S.ctrl.DAS OP.moveDir='L' end
        end
    end
end

function mino.mouseP(x,y,button,istouch)
    if mino.paused then pause.mouseP(x,y,button,istouch) end
end
function mino.gameUpdate(dt)
    local remainTime=0
    local cxk=S.ctrl
    for i=1,#S.opList do
        local OP=P[S.opList[i]]
        local C,A=OP.cur,OP.smoothAnim
        local his=OP.history

        if OP.event[1] then OP.MTimer=min(OP.MTimer+dt,cxk.DAS)
        elseif S.winState==0 and canop then
        --长按移动键
        local L,R=love.keyboard.isDown(S.keySet.ML),love.keyboard.isDown(S.keySet.MR)
        if L or R then OP.MTimer=OP.MTimer+dt end
        if L then local m=0
            if fLib.coincide(OP,-1,0) then OP.MTimer=min(OP.MTimer+dt,cxk.DAS) end

            while OP.MTimer>=cxk.DAS and OP.moveDir=='L' and not fLib.coincide(OP,-1,0) do
                mino.setAnimBLock(OP) A.timer=A.delay
                C.x=C.x-1 his.spin=false m=m+1
                C.moveSuccess=true OP.MTimer=OP.MTimer-cxk.ARR
                if fLib.coincide(OP,0,-1) and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1 end

                if S.ctrl.ARR~=0 or m==1 then mino.sfxPlay.move(OP,true,landed) end

                if OP.FDelay==0 then
                    while not fLib.coincide(OP,0,-1) do C.y=C.y-1 end
                end
                mino.setAnimBLock(OP)
            end
        end

        if R then local m=0
            if fLib.coincide(OP,1,0) then OP.MTimer=min(OP.MTimer+dt,cxk.DAS) end

            while OP.MTimer>=cxk.DAS and OP.moveDir=='R' and not fLib.coincide(OP,1,0) do
                mino.setAnimBLock(OP) A.timer=A.delay
                C.x=C.x+1 his.spin=false m=m+1
                C.moveSuccess=true OP.MTimer=OP.MTimer-cxk.ARR
                if fLib.coincide(OP,0,-1) and OP.LDR>0 then OP.LTimer=0 OP.LDR=OP.LDR-1 end

                if S.ctrl.ARR~=0 or m==1 then mino.sfxPlay.move(OP,true,landed) end

                if OP.FDelay==0 then
                    while not fLib.coincide(OP,0,-1) do C.y=C.y-1 end
                end
                mino.setAnimBLock(OP)
            end
        end
        if not(L or R) then OP.MTimer=0 end

        if love.keyboard.isDown(S.keySet.SD) then 
            if OP.event[1] or fLib.coincide(OP,0,-1) then OP.DTimer=min(OP.DTimer+dt,cxk.SD_DAS)
            else OP.DTimer=OP.DTimer+dt
                while OP.DTimer>=cxk.SD_DAS and not fLib.coincide(OP,0,-1) do
                    mino.setAnimBLock(OP) A.timer=A.delay
                    C.y=C.y-1 his.spin=false OP.DTimer=OP.DTimer-cxk.SD_ARR
                end
                mino.setAnimBLock(OP)
            end
        else OP.DTimer=0 end

        end
    end

    for i=1,#P do
        local C,A=P[i].cur,P[i].smoothAnim
        local his=P[i].history
        A.timer=max(A.timer-dt,0)
        if P[i].started and P[i].deadTimer<0 and S.winState==0 then P[i].gameTimer=P[i].gameTimer+dt end
        if P[i].event[1] then
            P[i].event[1]=P[i].event[1]-dt
            if not P[i].event[3] and P[i].event[1]<=0 then remainTime=P[i].event[1] end
            while P[i].event[1] and P[i].event[1]<=0 do
            if P[i].event[3] then P[i].event[3]=P[i].event[3]+P[i].event[1] end
            if mino[P[i].event[2]] then mino[P[i].event[2]](P[i])
            elseif fLib[P[i].event[2]] then fLib[P[i].event[2]](P[i])
            else error("Cannot find function mino."..P[i].event[2].." or fLib."..P[i].event[2]) end
            rem(P[i].event,1) rem(P[i].event,1)
            end
        elseif S.winState==0 and P[i].deadTimer<0 then
            if fLib.coincide(P[i],0,-1) then P[i].LTimer=P[i].LTimer+dt P[i].FTimer=0 else
                P[i].FTimer=P[i].FTimer+dt+remainTime remainTime=0
                while P[i].FTimer>=P[i].FDelay and not fLib.coincide(P[i],0,-1) do
                    C.y=C.y-1 his.spin=false P[i].FTimer=P[i].FTimer-P[i].FDelay
                    mino.sfxPlay.touch(P[i],fLib.coincide(P[i],0,-1))
                end
            end
            if P[i].LTimer>P[i].LDelay then
                P[i].LTimer=P[i].LTimer-P[i].LDelay
                if C.piece and #C.piece~=0 then
                    mino.die(P[i])
                    fLib.lock(P[i]) fLib.loosenFall(P[i])
                    if P[i].loosen[1] then
                        print(rule.loosen.fallTPB)
                        if rule.loosen.fallTPB==0 and P[i].CDelay==0 then
                            while P[i].loosen[1] do fLib.loosenFall(P[i]) end
                            mino.loosenDrop(P[i])
                        else mino.addEvent(P[i],rule.loosen.fallTPB,'loosenDrop') end
                    else
                        his.line,his.PC=fLib.lineClear(P[i])
                        mino.clearCalc(P[i],true,false) mino.sfxPlay.clear(P[i])
                        if his.line>0 and rule.onLineClear then rule.onLineClear(P[i],mino) end
                    end
                    his.dropHeight=0 mino.sfxPlay.lock(P[i])
                end

                if rule.onPieceDrop then rule.onPieceDrop(P[i],mino) end

                if S.winState==0 then
                    if P[i].EDelay==0 then mino.curIns(P[i])
                    else mino.addEvent(P[i],P[i].EDelay,'curIns') end
                end
                P[i].LTimer=0
            end
        elseif P[i].deadTimer>=0 then P[i].deadTimer=P[i].deadTimer+dt end

        if rule.update and P[i].started and P[i].deadTimer<0 and S.winState==0 then rule.update(P[i],dt,mino) end

        for j=#P[i].dropAnim,1,-1 do
            P[i].dropAnim[j].TTL=P[i].dropAnim[j].TTL-dt
            if P[i].dropAnim[j].TTL<=0 then rem(P[i].dropAnim,j) end
        end
    end
end

function mino.update(dt)
    if mino.paused then pause.update(dt) mino.pauseTimer=mino.pauseTimer+dt mino.pauseAnimTimer=min(mino.pauseAnimTimer+dt,.25)
    else mino.pauseAnimTimer=max(mino.pauseAnimTimer-dt,0)
        mino.waitTime=mino.waitTime-dt
        if mino.waitTime<=0 then mino.gameUpdate(dt) 
        else
            local L,R=love.keyboard.isDown(S.keySet.ML),love.keyboard.isDown(S.keySet.MR)
            for i=1,#S.opList do local OP=P[S.opList[i]]
                if L or R then OP.MTimer=min(OP.MTimer+dt,S.ctrl.DAS)
                else OP.MTimer=0 end
            end
        end
    end
end

function mino.draw()
    for i=#P,1,-1 do
        local C,H,A=P[i].cur,P[i].hold,P[i].smoothAnim
        local holdColor
        if H.name then holdColor=P[i].color[H.name] end

        gc.push()
            gc.translate(P[i].posx,P[i].posy)
            gc.scale(P[i].scale)
            --场地
            gc.push() P[i].fieldSkin.draw(mino,i) gc.pop()
            local t=P[i].gameTimer
            gc.printf(string.format("%d:%d%.3f",t/60,t/10%6,t%10),
            Consolas_B,-18*P[i].w-208,18*P[i].h-32,800,'right',0,.25)

            if rule.underFieldDraw then rule.underFieldDraw(P[i],mino) end
            gc.setColor(1,1,1,.4)
            gc.printf("combo:"..P[i].history.combo,Exo_2_SB,0,-360,1000,'center',0,1,1,500,0)
            gc.push()
            gc.translate(-18*P[i].w-18,18*P[i].h+18)
            --硬降特效
            if P[i].blockSkin.dropAnim then P[i].blockSkin.dropAnim(P[i],mino) end
            --[[local DA=P[i].dropAnim
            for j=1,#DA do
                local c=DA[j].color
                gc.setColor(c[1],c[2],c[3],0.2*DA[j].TTL/DA[j].TMax*(1+.5*DA[j].h/DA[j].w))
                gc.setLineWidth(36)
                gc.rectangle('fill',36*(DA[j].x)-18,-36*(DA[j].y+.5),36,36*DA[j].len)
            end]]

            --场地上的块&方块拖尾&消行特效
            local h=0 local n=P[i].event[1] and P[i].event[1]/P[i].CDelay

            for y=1,#P[i].field do
                if P[i].field[y][1] then h=h+1
                for x=1,P[i].w do
                    local F=P[i].field
                    if F[y][x] and F[y][x]~=' ' then 
                        P[i].blockSkin.draw(P[i],x,h,P[i].color[F[y][x]])
                    end
                end
                else h=h+n gc.push()
                    gc.translate(18,-36*h-18)
                    gc.setColor(1,1,1)
                    gc.rectangle('fill',0,0,36*P[i].w,n*36)
                gc.pop() end
            end
            --松动块
            P[i].blockSkin.loosenDraw(P[i],mino)

            if C.piece then local gy=fLib.getGhostY(P[i])
                local curPiece=T.copy(C.piece) local drawPiece={}
                local actualHeight=C.y-(P[i].animAct and P[i].FDelay~=0 and P[i].FTimer/P[i].FDelay or 0)
                --投影
                for j=1,#C.piece do
                if not P[i].event[1] then
                    P[i].blockSkin.ghost(P[i],C.x+C.piece[j][1],gy+C.piece[j][2],1-(P[i].LTimer/P[i].LDelay),P[i].color[C.name])
                end
                end

                --手上拿的
                for j=1,#C.piece do
                if P[i].animAct then
                    curPiece[j][1],curPiece[j][2]=curPiece[j][1]+C.x,curPiece[j][2]+actualHeight
                    drawPiece[j]=M.lerp(curPiece[j],A.piece[j],A.timer/A.delay)
                    P[i].blockSkin.draw(drawPiece[j][1],drawPiece[j][2],P[i].color[C.name])

                    --[[gc.translate(-36*(drawPiece[j][1]),36*(drawPiece[j][2]))
                    gc.translate(36*(A.piece[j][1]),-36*(A.piece[j][2]))
                    gc.setColor(1,1,1,.5)
                    gc.rectangle('fill',0,0,32,32)]]
                else P[i].blockSkin.draw(P[i],C.piece[j][1]+C.x,C.piece[j][2]+C.y,P[i].color[C.name]) end

                end
            end

            --暂存块（浮空）
            if H.name and H.mode=='A' then gc.push()
                gc.setColor(holdColor[1],holdColor[2],holdColor[3],.5)
                gc.translate(36*H.x,-36*H.y)
                for k=1,#H.piece do P[i].blockSkin.draw(H.piece[k][1],H.piece[k][2],P[i].color[H.name]) end
            gc.pop() end

            gc.pop()

            --预览
            for j=1,#P[i].NP do
                local w,h,x,y=B.size(P[i].NP[j])
                local s=min((w/h>2 and 4/w or 2.5/h),1)
                gc.push()
                    gc.translate(18*P[i].w+90,-410+100*j)
                    for k=1,#P[i].NP[j] do gc.push()
                        gc.scale(s)
                        P[i].blockSkin.draw(P[i],x+P[i].NP[j][k][1],y+P[i].NP[j][k][2],P[i].color[P[i].next[j]])
                    gc.pop() end
                gc.pop()
            end
            --暂存块（标准）
            if P[i].hold.name then
                gc.push()

                if H.mode=='S' then gc.push()
                    local w,h,x,y=B.size(H.piece)
                    local s=min((w/h>2 and 4/w or 2.5/h),1)
                    gc.translate(-18*P[i].w-90,-310)
                    gc.scale(s)

                    for k=1,#P[i].hold.piece do
                        P[i].blockSkin.draw(P[i],x+H.piece[k][1],y+H.piece[k][2],
                        P[i].color[H.name],P[i].canHold and 1 or .4)
                    end
                gc.pop() end

                gc.pop()
            end

            if rule.overFieldDraw then rule.overFieldDraw(P[i],mino) end
            --Ready Set Go
            if P[i].fieldSkin.readyDraw then P[i].fieldSkin.readyDraw(mino.waitTime) end
            --诶你怎么似了
            if P[i].deadTimer>=0 then S.dieAnim(P[i]) end
        gc.pop()
    end
    --暂停
    gc.setColor(.08,.08,.08,mino.pauseAnimTimer*4)
    gc.rectangle('fill',-1000,-1000,2000,2000)
    if mino.paused then
        pause.draw(mino.paused)
    end
end
return mino