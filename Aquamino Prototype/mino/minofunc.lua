--[[
变量介绍：
场地(field)——存储当前场地上方块信息。按照field[y][x]寻找对应的砖格。
松动块(loosen)——存储所有松动块。结构同field。
场地初始为空，如果方块有部分放在了场地外就加一行，如果满了就把这行去掉，loosen同理
b,o,px,py,name——（方块）本体，朝向，旋转中心x坐标，旋转中心y坐标，方块名
]]
local M=require'framework/mathextend'
local T=require'framework/tableextend'

local MinoF={}
--场地
function MinoF.addline(field)--加一行
    local line={}
    for i=1,#field[1] do line[i]=' ' end
    table.insert(field,T.copy(line))
end
function MinoF.blocktype(field,x,y)--获取特定位置的砖格信息
    if x<1 or x>#field[1] or y<1 then return 'wall'
    elseif y>#field then return ' '
    else return field[y][x] end
end

--方块旋转&踢墙&spin判定
function MinoF.rotate(b,o,mode)--mode='R'是顺时针 'L'是逆时针 'F'是180
    local spin={R=1,L=-1,F=2} local newb=T.copy(b)
    for i=1,#newb do
        if mode=='F' then newb[i][2]=newb[i][2]*(-1) newb[i][1]=newb[i][1]*(-1) else
        newb[i][1],newb[i][2]=newb[i][2],newb[i][1]
        if mode=='R' then newb[i][2]=newb[i][2]*(-1)
        else newb[i][1]=newb[i][1]*(-1) end
        end
    end
    o=(o+spin[mode])%4 return newb,o
end
    --Z 酱 锐 评：压得过于离谱，你一个月不看都不敢动的那种
function MinoF.kick(b,o,mode,name,px,py,field,RS)
    local newb,newo=MinoF.rotate(b,o,mode)
    local ukick=RS[name][mode][o+1]
    for i=1,#ukick do
        local x,y=px+ukick[i][1],py+ukick[i][2]
        if not MinoF.coincide(field,x,y,newb) then return newb,newo,x,y, true,i end
    end
    return b,o,px,py, false,0
end

MinoF.corner={{-1,1},{1,1},{1,-1},{-1,-1}}
function MinoF.cornerCount(px,py,field)
    local cnt=0
    local c=MinoF.corner
    for i=1,4 do
        if MinoF.blocktype(field,px+c[i][1],py+c[i][2])~=' ' then cnt=cnt+1 end
    end
    return cnt
end
function MinoF.immovable(field,px,py,piece)
    local u,d,l,r=false,false,false,false
    if MinoF.coincide(field,px-1,py,piece) then l=true
    elseif not MinoF.coincide(field,px+1,py,piece) then r=true
    elseif not MinoF.coincide(field,px,py-1,piece) then d=true
    elseif not MinoF.coincide(field,px,py+1,piece) then u=true
    end
    return u,d,l,r
end
MinoF.isSpin={--spin判定的函数集合
    T=function(o,px,py,field,loosen)
        local c=MinoF.corner
    return MinoF.cornerCount(px,py,field)+MinoF.cornerCount(px,py,loosen)>=3,
    MinoF.blocktype(field,px+c[o+1][1],py+c[o+1][2])~=' ' and MinoF.blocktype(field,px+c[(o+1)%4+1][1],py+c[(o+1)%4+1][2])~=' '
    end
}

--获取阴影坐标
function MinoF.getghostpos(field,px,py,piece)
    if #piece==0 then return px,py end
    local gpy=py
    while not MinoF.coincide(field,px,gpy-1,piece) do gpy=gpy-1 end
    return px,gpy
end

--方块与场地相关
function MinoF.coincide(field,px,py,piece)--是否重叠
    for i=1,#piece do
        local x=piece[i][1]+px
        local y=piece[i][2]+py
        if MinoF.blocktype(field,x,y)~=' ' then return true end
    end
    return false
end
function MinoF.lock(piece,name,px,py,field)
    for i=1,#piece do
        local x=px+piece[i][1]
        local y=py+piece[i][2]
        field[y][x]=name
    end
end
function MinoF.lineClear(field)
    local cunt=0
    for y=#field,1,-1 do
        local pass=true
        for x=1,#field[1] do
            if field[y][x]==' ' then pass=false break end
        end
        if pass then table.remove(field,y) cunt=cunt+1 end
    end
    return cunt
end
function MinoF.garbage(field,block,atk)
    local l=#field[1]
    local h=#field
    local gb={}
    for i=1,l do gb[i]=block end
    gb[math.random(1,10)]=' '
    for i=1,atk do
        for j=h,1,-1 do field[j+1]=field[j] end
        field[1]=T.copy(gb)
    end
    if h+atk>50 then for i=50,(h+atk) do field[i]=nil end end
end
function MinoF.freefall(piece,name,px,py,field)
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

--O-spin专属

function MinoF.Lfall(loosen,field,amount)
    if not amount then amount=1e999 end
    for i=1,amount do end
end
function MinoF.check_loose_move(piece,px,py,mode,field,Scnt)

    --[[第一次检测，若检测到固定块则开启旋转计数且松动块不可移动，且不启动之后的检测
    若旋转计数>=3，将对应固定块转化为松动块
    若检测到松动块则将其移出列表，加入blocktomove列表，检查点向指定方向移一格
    若检查点上啥都没有，销毁该检查点]]

    --[[第二次检测，若检测到固定块则将其转化为松动块，松动块不可移动
    若检测到松动块，同上，但是循环
    其它同上]]

    --[[最后，若可以移动，处于blocktomove的块全部向指定方向移一格
    然后把blocktomove里的东西重新放回]]
end
return MinoF