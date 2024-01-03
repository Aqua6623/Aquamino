local skin={}
local color=require('framework/color')
skin.sticker=gc.newImage('skin/block/carbon fibre/sticker.png')
skin.shadow=gc.newImage('skin/block/carbon fibre/ghost.png')
function skin.draw(x,y,clr,alpha)
    gc.push()
    gc.translate(36*x,-36*y)
    gc.setColor(clr[1],clr[2],clr[3],clr[4] or alpha or 1)
    gc.rectangle('fill',-18,-18,36,36)
    gc.draw(skin.sticker,0,0,0,1,1,18,18)
    gc.pop()
end
function skin.loosenDraw(player,mino)
    local ls=player.loosen
    local delay=mino.rule.loosen.fallTPB
    local t=player.event[2]=='loosenDrop' and player.event[1]
        or player.event[2] and delay or 0
    local N=(delay~=0 and t) and t/delay or 0
    gc.push()
    for i=1,#ls do
        gc.translate(36*ls[i].x,-36*(ls[i].y+N))
        local clr=color.find(player.color[ls[i].block])
        gc.setColor(clr[1],clr[2],clr[3],clr[4] or alpha or 0.5)
        gc.rectangle('fill',-18,-18,36,36)
        gc.translate(-36*ls[i].x,36*(ls[i].y+N))
    end
    gc.pop()
end
function skin.ghost(x,y,lockDelay,clr)
    gc.push()
    gc.translate(36*x,-36*y)
    gc.setColor(clr[1],clr[2],clr[3],.22)
    gc.rectangle('fill',-18,-18,36,36)
    gc.pop()
end
function skin.dropEffect(color,alpha)
end
function skin.clearEffect(y,h,alpha,width)
end
return skin