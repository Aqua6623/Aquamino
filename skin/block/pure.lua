local skin={}
local COLOR=require('framework/color')
function skin.draw(player,x,y,color,alpha)
    gc.push()
    gc.translate(36*x,-36*y)
    gc.setColor(color[1],color[2],color[3],color[4] or alpha or 1)
    gc.rectangle('fill',-18,-18,36,36)
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
        local clr=COLOR.find(player.color[ls[i].block])
        gc.setColor(clr[1],clr[2],clr[3],clr[4] or alpha or 0.5)
        gc.rectangle('fill',-18,-18,36,36)
        gc.translate(-36*ls[i].x,36*(ls[i].y+N))
    end
    gc.pop()
end
function skin.dropAnim(player)
    local DA=player.dropAnim
    for i=1,#DA do
        local c=DA[i].color
        gc.setColor(c[1],c[2],c[3],0.2*DA[i].TTL/DA[i].TMax*(1+.5*DA[i].h/DA[i].w))
        gc.setLineWidth(36)
        gc.rectangle('fill',36*(DA[i].x)-18,-36*(DA[i].y+.5),36,36*DA[i].len)
    end
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