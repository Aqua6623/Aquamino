local T=require'framework/tableextend'

local block={
    Z={{0,0},{ 1, 0},{-1, 1},{ 0, 1}},
    S={{0,0},{-1, 0},{ 1, 1},{ 0, 1}},
    J={{0,0},{-1, 0},{ 1, 0},{-1, 1}},
    L={{0,0},{-1, 0},{ 1, 0},{ 1, 1}},
    T={{0,0},{-1, 0},{ 1, 0},{ 0, 1}},
    O={{.5,.5},{.5,-.5},{-.5,.5},{-.5,-.5}},
    I={{-1.5,.5},{-.5,.5},{.5,.5},{1.5,.5}},
--[[
    Z5={{0,0},{ 0,-1},{ 1,-1},{-1, 1},{ 0, 1}},
    S5={{0,0},{ 0,-1},{-1,-1},{ 1, 1},{ 0, 1}},
    J5={{-1.5,-.5},{-.5,-.5},{.5,-.5},{1.5,-.5},{-1.5,.5}},
    L5={{-1.5,-.5},{-.5,-.5},{.5,-.5},{1.5,-.5},{1.5,.5}},
    T5={{0,0},{-1,-1},{ 0,-1},{ 1,-1},{ 0, 1}},
    I5={{0,0},{-2, 0},{-1, 0},{ 1, 0},{ 2, 0}},
    N ={{-1.5,.5},{-.5,.5},{-.5,-.5},{.5,-.5},{1.5,-.75}},
    H ={{1.5,.5},{.5,.5},{.5,-.5},{-.5,-.5},{-1.5,-.75}},
    E ={{0,0},{-1, 0},{ 1, 0},{ 0,-1},{-1, 1}},
    F ={{0,0},{-1, 0},{ 1, 0},{ 0,-1},{ 1, 1}},
    R ={{-1.5,-.5},{-.5,-.5},{.5,-.5},{1.5,-.5},{-.5,.5}},
    Y ={{-1.5,-.5},{-.5,-.5},{.5,-.5},{1.5,-.5},{.5,.5}},
    X ={{0,0},{ 0, 1},{ 1, 0},{ 0,-1},{-1, 0}},
    W ={{0,0},{ 0,-1},{ 1,-1},{-1, 0},{-1, 1}},
    V ={{0,0},{ 0, 1},{ 0, 2},{ 1, 1},{ 0, 1}},
    U ={{0,0},{ 0,-1},{ 0, 1},{-1, 1},{ 1, 1}},
]]
}
block.Soff={--生成方块的旋转中心相对“基准点”的偏移
    Z={0,0},S={0,0},J={0,0},L={0,0},T={0,0},O={.5,.5},I={.5,-.5}
}

--Z 酱 锐 评：压得过于离谱，你一个月不看都不敢动的那种
function block.rotate(b,o,mode)--mode='R'是顺时针 'L'是逆时针 'F'是180
    local spin={R=1,L=-1,F=2} local newb=T.copy(b)
    for i=1,#newb do
        if mode=='F' then newb[i][1],newb[i][2]=newb[i][1]*(-1),newb[i][2]*(-1)
        else newb[i][1],newb[i][2]=newb[i][2],newb[i][1]
            if mode=='R' then newb[i][2]=newb[i][2]*(-1)
            else newb[i][1]=newb[i][1]*(-1) end
        end
    end
    o=(o+spin[mode])%4 return newb,o
end

function block.size(b)--计算方块最小外包框大小以及旋转中心相对这个框的偏移
    local xMiao,xmax,yMiao,ymax=b[1][1],b[1][1],b[1][2],b[1][2]
    for i=1,#b do
        if b[i][1]<xMiao then xMiao=b[i][1] end
        if b[i][1]>xmax  then xmax =b[i][1] end
        if b[i][2]<yMiao then yMiao=b[i][2] end
        if b[i][2]>ymax  then ymax =b[i][2] end
    end
    return xmax-xMiao+1,ymax-yMiao+1,-(xmax+xMiao)/2,-(ymax+yMiao)/2
end
function block.edge(b)--获取最边缘的方块信息
    local xMiao,xmax,yMiao,ymax=b[1][1],b[1][1],b[1][2],b[1][2]
    for i=1,#b do
        if b[i][1]<xMiao then xMiao=b[i][1] end
        if b[i][1]>xmax  then xmax =b[i][1] end
        if b[i][2]<yMiao then yMiao=b[i][2] end
        if b[i][2]>ymax  then ymax =b[i][2] end
    end
    return xMiao,xmax,yMiao,ymax
end
function block.getX(b)
    local n={}
    for i=1,#b do
        if not T.include(n,b[i][1]) then table.insert(n,b[i][1]) end
    end
    return n
end

return block