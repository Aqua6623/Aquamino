local skin={}
local COLOR=require('framework/color')
local M=mymath
skin.pic=gc.newImage('skin/block/wheelchair/wheelchair.png')
function skin.draw(player,x,y,color,alpha)
    local clr=M.lerp({1,1,1},color,.8)
    gc.push()
    gc.translate(36*x,-36*y)
    gc.setColor(clr[1],clr[2],clr[3],alpha or 1)
    gc.draw(skin.pic,0,0,0,.5,.5,36,36)
    gc.pop()
end
function skin.loosenDraw(player,mino)
    local ls=player.loosen
    local delay=mino.rule.loosen.fallTPB
    local t=player.event[2]=='loosenDrop' and player.event[1]
        or player.event[2] and delay or 0
    local N=(delay~=0 and t) and t/delay or 0
    gc.push()
    gc.setColor(1,1,1)
    for i=1,#ls do
        gc.translate(36*ls[i].x,-36*(ls[i].y+N))
        gc.draw(skin.pic,0,0,0,.5,.5,36,36)
        gc.translate(-36*ls[i].x,36*(ls[i].y+N))
    end
    gc.pop()
end
function skin.ghost(player,x,y)
    gc.push()
    gc.translate(36*x,-36*y)
    gc.setColor(1,1,1,.22)
    gc.setLineWidth(2)
    gc.rectangle('fill',-18,-18,36,36)
    gc.pop()
end
function skin.dropEffect(color,alpha)
end
function skin.clearEffect(y,h,alpha,width)
end
return skin