--[[目标：
逻辑上实现多玩家（机器人加入）
T-spin连续4下判定成功T当场变成O并硬降锁定
旋转判定开关
]]

local BF=require'mino/minofunc'
local M=mymath
local T=mytable

local mino={}
local oplist={1}

mino.keyset={} --储存玩家键位
mino.rule={}
--[[example:
keyset={L={'left'},R={'right'},SD={'down'},HD={'space'},hold={'lshift','rshift'},CW={'z'},CCW={'x'},flip={'c'}}
]]

mino.player={}--储存所有由操作者操控的变量
local player=mino.player
player[1]={
    --场地绘制
    x=0,y=0,r=0,scale=1,
    --控制数据
    Lban=false,Rban=false,
    MDAS=0.09,MARR=0,SDDAS=0,SDARR=0,MT_L=0,MT_R=0,SDT=0,
    holdamount=1,lockT=.5,lockD=.5,
    RS='SRS',
    LDtime=15,LDtimeinit=15,
    --场地相关
    field={},loosen={},w=10,h=20,
    garbage={},
    --手上拿的和暂时存的
    curname='',holdname='',canhold=true,
    curpiece={},holdpiece={},
    --坐标和鬼
    posx=5,posy=21,gposx=nil,gposy=nil,
    ori=0,
    --特殊spin
    Ospincnt=0,Tspincnt=0
}

function mino.init()
    win.showadjustkey=false
end
function mino.update(dt)
end
function mino.keyP(k)
    local n=#oplist
    if T.include(k,hand.left) then
        for i=1,n do
            local p=player[i]
        end
    end
end
function mino.keyR(k)
end
function mino.mouseP(x,y,button,istouch)
end
function mino.mouseR(x,y,button,istouch)
end
function mino.draw()
    for i=1,#player do
        local p=player[i]
        gc.translate(p.x,p.y)

        gc.push('all')
            gc.translate(p.x,p.y)
            gc.scale(p.scale)
            gc.setLineWidth(4)
            gc.line(-182,-360,-182,362,182,362,182,-360)
            for x=1,p.w do for y=1,#p.field do
                if p.field[i][i] and p.field[i][i]~=' ' then end
            end end
        gc.pop()

        gc.translate(-p.x,-p.y)
    end
end
return mino