local gc=love.graphics
local fs=love.filesystem

local T,M=mytable,mymath

local BF=require'mino/minofunc'
local RS=require'mino/RSlist'
--math.randomseed(os.time())

local mino={
    stacker={
        keyset={},ctrl={},oplist={1},
        Lban=false,Rban=false
    },
    --bag={},
    bag={'Z','S','J','L','T','O','I'},
    player={}
    --[[player[1]={
        posx=0,posy=0,
        field={},loosen={},Ocnt(O-spin Count)=0,
        RS='SRS',
        c(clear)Delay=0,e(enter)Delay=0,l(lock)Delay=.5,
        N(Next)={},NP(Next Piece)={},preview=6,
        H(Hold)={}(多hold),HP(Hold Piece)={},canH=true,
        Ltimer=0,Rtimer=0,Dtimer=0,
        FT(Fall Time)=1,Ftimer=0,
        cur={
            name=(方块名),piece={},x=5,y=21,o=0,
            LDR(Lock Delay Reset)=15
        }
    }]]
}
local P,S,R=mino.player,mino.stacker,mino.rule
local key=S.keyset

P[1]={
    posx=0,posy=0,r=0,scale=1,
    field={},loosen={},w=10,h=10,
    Ocnt=0,
    RS='SRS',
    cDelay=0,eDelay=0,lDelay=.5,
    N={},NP={},preview=6,
    H={},HP={},canH=true,
    Ltimer=0,Rtimer=0,Dtimer=0,
    FT=1,Ftimer=0,
    cur={
        name='',piece={},x=5,y=21,o=0,
        LDR=15
    }
}

--[[S.keyset={
    ML={'left','l'},MR={'right','\''},
    RL={'y','up','p'},RR={'t','x'},RF={},
    SD={'down',';'},HD={'space','c'},HD={'z','lshift','rshift','0'}
}
S.ctrl={
    DAS=.09,ARR(Auto Repeat Period)=0,
    SDType='I(Instant)' / 'M(Multiply)' / 'D(Distinguish touch and hold)',
    SDX=2,SD_DAS=.2,SD_ARR=.2
}
]]
function mino.ini()
do
    --BF.NG('bag')
end
end
function love.keypressed(k)
    --if k=='escape' then end
    
    if T.include(k,key.R) then
        scene.dest='intro' scene.swaptime=1.5 scene.outtime=.5
        scene.anim=function() anim.cover(.5,1,.5,0,0,0) end
    end
    for i=1,#oplist do
        local landed=BF.coincide(P[i].field,P[i].loosen,C.x,C.y-1,C.piece)
        local success=false
        if T.include(k,keyset.ML) and not S.Lban then
                if not BF.coincide(P[i].field,P[i].loosen,C.x-1,C.y,C.piece) then 
                if landed and re_chance>0 then landtime=0 re_chance=re_chance-1 end
                C.x=C.x-1
                end
        elseif T.include(k,keyset.MR) and not s.R.ban and not BF.coincide(P[i].field,P[i].loosen,C.x+1,C.y,C.piece) then 
            if landed and re_chance>0 then landtime=0 re_chance=re_chance-1 end
            C.x=C.x+1
        elseif T.include(k,keyset.RL) then C.piece,ori,C.x,C.y, success=kick(C.piece,ori,'R',C.name,C.x,C.y,P[i].field,P[i].loosen,SRS)
            if landed and re_chance>0 and success then landtime=0 re_chance=re_chance-1 end
        elseif T.include(k,keyset.RR) then C.piece,ori,C.x,C.y, success=kick(C.piece,ori,'L',C.name,C.x,C.y,P[i].field,P[i].loosen,SRS)
            if landed and re_chance>0 and success then landtime=0 re_chance=re_chance-1 end
        elseif T.include(k,keyset.HD) then
            while not BF.coincide(P[i].field,loosen,C.x,C.y-1,C.piece) do C.y=C.y-1 end
            lock_ini()
        elseif T.include(k,keyset.SD) then
            if SDtime==0 then
                while not BF.coincide(P[i].field,loosen,C.x,C.y-1,C.piece)
                do C.y=C.y-1 end
            elseif not landed then C.y=C.y-1 end
        elseif T.include(k,keyset.hold) and canhold then 
            hold,C.name=C.name,hold
            canhold=false ori=0 falltime=0
            if C.name=='' then
                C.name=table.remove(next,1)
            end
            C.piece=T.copy(blocks[C.name]) C.x,C.y=spawnpos[C.name][1],spawnpos[C.name][2]
            if landed and re_chance>0 then landtime=0 end
        end
        
        --O 旋 盾 构 机
        if C.name=='O' then 
            local reset=true
            if not s.Rban and love.keyboard.isDown(keyset.right) and BF.coincide(_ENV["P[i].field"],loosen,C.x+1,C.y,C.piece) then
                if T.include(k,keyset.CW) or T.include(k,keyset.CCW) then reset=false
                spincount=spincount+1
                check_loose_move(C.piece,C.x,C.y,'R',_ENV["P[i].field"],loosen,spincount)
                end
            end
            if not S.Lban and love.keyboard.isDown(keyset.left) and BF.coincide(_ENV["P[i].field"],loosen,C.x-1,C.y,C.piece) then
                if T.include(k,keyset.CW) or T.include(k,keyset.CCW) then reset=false
                spincount=spincount+1
                check_loose_move(C.piece,C.x,C.y,'L',_ENV["P[i].field"],loosen,spincount)
                end
            end
            if love.keyboard.isDown(keyset.SD) and BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) then
                if T.include(k,keyset.CW) or T.include(k,keyset.CCW) then reset=false
                spincount=spincount+1
                check_loose_move(C.piece,C.x,C.y,'D',_ENV["P[i].field"],loosen,spincount)
                end
            end
            if reset then spincount=0 end
        end
    end
end
function love.update(dt)
    falltime=falltime+dt
    if not BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) then 
        while falltime>=fallARR and not BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) do
            C.y=C.y-1 falltime=falltime-fallARR
        end
    else
        falltime=0 landtime=landtime+dt
        if landtime>=lockdelay then lock_ini() end
    end
    if #next<21 then
        local s=shuffle(bag)
        for h=1,#s do
            table.insert(next,s[h])
        end
    end
    
    --和DAS ARR相关的操作
    if not S.Lban then
        if love.keyboard.isDown(keyset.left) then
            s.Rban=true
            if Ldas>=DAS_move then Larr=Larr+dt+Ldas-DAS_move Ldas=DAS_move
                while Larr>=ARR and not BF.coincide(_ENV["P[i].field"],loosen,C.x-1,C.y,C.piece) do
                    if BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) and re_chance>0
                    then landtime=0 re_chance=re_chance-1 end
                    C.x=C.x-1 Larr=Larr-ARR
                    while falltime>=fallARR and not BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) do
                        C.y=C.y-1 falltime=falltime-fallARR
                    end
                end
            else Ldas=Ldas+dt end
        else s.Rban=false Ldas,Larr=0,ARR end
    end
    if not s.Rban then
        if love.keyboard.isDown(keyset.right) then
            S.Lban=true
            if Rdas>=DAS_move then Rarr=Rarr+dt+Rdas-DAS_move Rdas=DAS_move
                while Rarr>=ARR and not BF.coincide(_ENV["P[i].field"],loosen,C.x+1,C.y,C.piece) do
                    if BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) and re_chance>0
                    then landtime=0 re_chance=re_chance-1 end
                    C.x=C.x+1 Rarr=Rarr-ARR
                    while falltime>=fallARR and not BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) do
                        C.y=C.y-1 falltime=falltime-fallARR
                    end
                end
            else Rdas=Rdas+dt end
        else S.Lban=false Rdas,Rarr=0,ARR end
    end
    if love.keyboard.isDown(keyset.SD) then SDarr=SDarr+dt
        while SDarr>=SDtime and not BF.coincide(_ENV["P[i].field"],loosen,C.x,C.y-1,C.piece) do C.y=C.y-1 SDarr=SDarr-SDtime end
    else SDarr=0 end
end
function mino.update(dt)
    --P[1].posx,P[1].posy=600*math.cos(scene.time%4*math.pi),600*math.sin(scene.time%4*math.pi)
    --P[1].scale=2*math.sin(scene.time%4*math.pi)
end
function mino.draw()
    for i=1,#P do
        local p=P[i]

        gc.push('all')
            gc.translate(p.posx,p.posy)
            gc.scale(p.scale)
            gc.setLineWidth(4)
            gc.line(-182,-360,-182,362,182,362,182,-360)
            gc.rectangle('line',-400,-400,800,800)
            if T.include(S.oplist,i) then
                gc.printf("HOLD",Exo_2_SB,-390,-400,800,'center',0,.25)
                gc.printf("NEXT",Exo_2_SB, 190,-400,800,'center',0,.25)
            end
            --skin.draw()
            for x=1,p.w do for y=1,#p.field do
                if p.field[y][x] and p.field[y][x]~=' ' then 
                --gc.draw(blockskin,...)
                end
            end end
        gc.pop()

    end
end
return mino