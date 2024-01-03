--[[
变量介绍：
场地(field)——存储当前场地上方块信息。按照field[y][x]寻找对应的砖格。
松动块(loosen)——存储所有松动块。结构同field。
场地初始为空，如果方块有部分放在了场地外就加一行，如果满了就把这行去掉，loosen同理
]]
--[[*未来计划：
block={
    name='Z',loosen=false,
    color={1,0,0},colorName='Red',
}
空气一律为{}
]]
local M=require'framework/mathextend'
local T=require'framework/tableextend'
local B=require'mino/blocks'
local RS=require'mino/RSlist'

local fieldLib={}
--场地
function fieldLib.addLine(player)--加一行
    local line={}
    for i=1,player.w do line[i]=' ' end
    player.field[#player.field+1]=line
end
function fieldLib.blockType(player,x,y)--获取特定位置的砖格信息
    if x<1 or x>player.w then return 'wall'
    elseif y<1 then return 'bottom'
    elseif y>#player.field then return ' '
    else return player.field[y][x] end
end

--方块旋转&spin判定

function fieldLib.kick(player,mode)--b,o,mode,name,px,py,field,RS
    local cur=player.cur
    local originPiece,originO=T.copy(cur.piece),cur.O--先存一个，万一你没踢成功呢
    cur.piece,cur.O=B.rotate(cur.piece,cur.O,mode)
    local ukick=RS[player.RS][cur.name][mode][originO+1]
    if ukick and player.LDR>0 then
        for i=1,#ukick do
            local x,y=ukick[i][1],ukick[i][2]
            if not fieldLib.coincide(player,x,y) then cur.x,cur.y=cur.x+x,cur.y+y
            return i end
        end
    else
        if not fieldLib.coincide(player,x,y) then return 1 end
    end
    cur.piece,cur.O=T.copy(originPiece),originO
end

function fieldLib.isImmobile(player)
    local kokodayo=fieldLib.coincide
    local r=kokodayo(player, 1, 0)
    local l=kokodayo(player,-1, 0)
    local u=kokodayo(player, 0, 1)
    local d=kokodayo(player, 0,-1)
    return u and d and l and r
end
function fieldLib.corner(player)
    local x,y,c=player.cur.x,player.cur.y,0
    local bt=fieldLib.blockType
    if bt(player,x-1,y-1)~=' ' then c=c+1 end
    if bt(player,x-1,y+1)~=' ' then c=c+1 end
    if bt(player,x+1,y-1)~=' ' then c=c+1 end
    if bt(player,x+1,y+1)~=' ' then c=c+1 end
    print(c)
    return c
end

--获取阴影坐标
function fieldLib.getGhostY(player)
    local gy=0
    if #player.cur.piece~=0 then
        while not fieldLib.coincide(player,0,gy-1) do gy=gy-1 end
        return gy+player.cur.y
    end
end

--方块与场地相关
function fieldLib.coincide(player,offX,offY)
    local c,ls=player.cur,player.loosen
    if not c.piece or #c.piece==0 then error("Fuck you!") end
    if not offX then offX=0 end  if not offY then offY=0 end
    for i=1,#c.piece do
        local x,y=c.piece[i][1]+c.x+offX,c.piece[i][2]+c.y+offY
        if fieldLib.blockType(player,x,y)~=' ' then return true end
        for j=1,#ls do
            if ls[j].x==x and ls[j].y==y then return true end
        end
    end
    return false
end
function fieldLib.lock(player)
    local C=player.cur
    local his=player.history
    for i=1,#C.piece do
        local x=C.x+C.piece[i][1]
        local y=C.y+C.piece[i][2]
        while not player.field[y] do fieldLib.addLine(player) end
        player.field[y][x]=C.name
    end
    his.piece,his.name,his.o,his.x,his.y=C.piece,C.name,C.o,C.x,C.y
    C.piece,C.name,C.o={},nil,nil
    player.FTimer=0 player.pushAtt=0
end
function fieldLib.lineClear(player)
    local cunt=0 local field=player.field
    local PC=true
    for y=#field,1,-1 do
        local pass=true
        for x=1,player.w do
            if field[y][x]==' ' then pass=false break end
        end
        if pass then field[y]={} cunt=cunt+1 end
    end
    for y=#field,1,-1 do for x=1,#field[y] do
        if not PC then break end
        if field[y][x]~=' ' then PC=false break end
    end end
    return cunt,PC
end
function fieldLib.eraseEmptyLine(player)
    for y=#player.field,1,-1 do if #player.field[y]==0 then table.remove(player.field,y) end end
    if player.history.PC then player.field={} end
end
function fieldLib.garbage(player,block,atk,hole)
    local field=player.field
    local h=#field
    local gb={}
    for i=1,player.w do gb[i]=block end
    if type(hole)=='number' then gb[hole or math.random(1,10)]=' '
    else for i=1,#hole do gb[hole[i]]=' ' end end
    for i=1,atk do
        for j=h,1,-1 do field[j+1]=field[j] end
        field[1]=T.copy(gb)
        if fieldLib.coincide(player) then player.cur.y=player.cur.y+1 end
    end
    if h+atk>3*player.h then for i=3*player.h,(h+atk) do field[i]=nil end end
end
function fieldLib.freefall(piece,name,px,py,field)
    for i=1,#field do  for j=#piece,1,-1 do
        if piece[j][2]+py==i then
            local x,y=px+piece[j][1],py+piece[j][2]
            if y==1 or field[y-1][x]~=' ' then
                field[y][x]=name table.remove(piece,j)
            end
        end
    end end
    return px,py-1
end

--推土机！
function fieldLib.isLoosen(player,x,y)
    local ls=player.loosen
    for i=1,#ls do if x==ls[i].x and y==ls[i].y then return i end end
    return nil
end
function fieldLib.loosenFall(player)
    local field,ls=player.field,player.loosen
    local fall=true local minh,maxh=ls[1] and ls[1].y,ls[1] and ls[1].y
    for i=2,#ls do
        minh=ls[i].y<minh and ls[i].y or minh  maxh=ls[i].y>maxh and ls[i].y or maxh
    end
    for y=(minh or 0),(maxh or 0) do  for i=#ls,1,-1 do
        if ls[i].y==y then
            if fieldLib.blockType(player,ls[i].x,ls[i].y-1)~=' ' then
            field[ls[i].y][ls[i].x]=ls[i].block table.remove(ls,i)
            end
        end
    end  end
    for i=1,#ls do ls[i].y=ls[i].y-1 end
end
function fieldLib.pushField(player,mode) --loosen[1]={x=1,y=1,block='Z'}
    local P=player local C=P.cur
    local piece,field,ls=C.piece,P.field,P.loosen
    local dir={L={-1,0},R={1,0},D={0,-1}}
    local testP,BTM={},{} --BTM=Block To Move
    local canMove,moreTest=true,true

    --生成检测点并向指定方向移动
    for i=1,#piece do testP[i]={piece[i][1]+dir[mode][1]+C.x,piece[i][2]+dir[mode][2]+C.y} end

    --第一次检测

    for i=#testP,1,-1 do --对于所有检测点
        local testO=fieldLib.isLoosen(player,testP[i][1],testP[i][2]) --=Test Order,检测松动块序号
        local testBlock=fieldLib.blockType(player,testP[i][1],testP[i][2])
        if testBlock=='wall' or testBlock=='bottom' then --如果检测到墙
            canMove=false moreTest=false --不移动松动块，不进行之后的检测
            table.remove(testP,i) --销毁检测点
        elseif testBlock~=' ' then --如果检测到了固定块
            canMove=false moreTest=false --不移动松动块，不进行之后的检测
            if P.pushAtt>=3 then --如果旋转计数>=3
                table.insert(ls,{x=testP[i][1],y=testP[i][2],block=field[testP[i][2]][testP[i][1]]}) --将它加入松动块列表
                field[testP[i][2]][testP[i][1]]=' ' --去掉场地上对应的块
            end
            table.remove(testP,i) --最后销毁检测点
        elseif testO then --如果检测到了松动块
            table.insert(BTM,table.remove(ls,testO)) --将对应松动块暂时加入BTM
            testP[i]={testP[i][1]+dir[mode][1],testP[i][2]+dir[mode][2]} --移动该检测点
        else table.remove(testP,i) end --再然后就是检测到空气了，去死吧你
    end

    --之后的检测：

    if moreTest then  for i=#testP,1,-1 do --如果继续测试，对于所有检测点
        local testO=fieldLib.isLoosen(player,testP[i][1],testP[i][2]) --=Test Order,检测松动块序号
        local testBlock=fieldLib.blockType(player,testP[i][1],testP[i][2])
        if testBlock=='wall' or testBlock=='bottom' then canMove=false --如果检测到墙，不移动松动块
        elseif testBlock~=' ' then
            table.insert(ls,{x=testP[i][1],y=testP[i][2],block=field[testP[i][2]][testP[i][1]]})
            canMove=false field[testP[i][2]][testP[i][1]]=' '
        elseif testO then --如果检测到了松动块
            while testO do --只要检测到了松动块
                table.insert(BTM,table.remove(ls,testO))  --将对应松动块暂时加入BTM
                testP[i]={testP[i][1]+dir[mode][1],testP[i][2]+dir[mode][2]} --移动该检测点
                testO=fieldLib.isLoosen(player,testP[i][1],testP[i][2]) --看看检测点还在不在松动块上
            end
            testBlock=fieldLib.blockType(player,testP[i][1],testP[i][2])--检测点动了，所以要刷新
            if testBlock=='wall' or testBlock=='bottom' then canMove=false --如果检测到墙，不移动松动块
            elseif fieldLib.blockType(player,testP[i][1],testP[i][2])~=' ' then --如果检测到了固定块
                table.insert(ls,{x=testP[i][1],y=testP[i][2],block=field[testP[i][2]][testP[i][1]]}) --将它加入松动块列表
                canMove=false field[testP[i][2]][testP[i][1]]=' ' --不移动松动块并去掉场地上对应的块
            end
        end
        table.remove(testP,i) --检测点：我滴任务，完成啦！
    end  end

    if canMove then --如果松动块可以移动
        for i=1,#BTM do BTM[i].x=BTM[i].x+dir[mode][1] BTM[i].y=BTM[i].y+dir[mode][2] end --把BTM里的所有松动块朝指定方向移一格
    end
    for i=1,#BTM do table.insert(ls,BTM[i]) end --放回松动块列表，结束
end
return fieldLib