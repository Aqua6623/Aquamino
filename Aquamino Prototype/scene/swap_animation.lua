local anim={}--animation的缩写

function anim.cover(intime,keeptime,outtime,r,g,b)
    if scene.swaptime>keeptime then 
        gc.setColor(r,g,b,1-((scene.swaptime-keeptime)/intime))
    elseif scene.swaptime>0 then
        gc.setColor(r,g,b)
    else
        gc.setColor(r,g,b,scene.outtime/outtime)
    end
        gc.rectangle('fill',-960,-540,1920,1080)
end
function anim.enter1(intime,keeptime,outtime)
    local rect_w=(1-((scene.swaptime-keeptime)/intime))^2
    gc.setColor(0,0,0)
    if scene.swaptime>0 then
        if scene.swaptime>keeptime then
            gc.rectangle('fill',-960*rect_w,-540,1920*rect_w,1080)
        else gc.rectangle('fill',-960,-540,1920,1080) end
    else
        for i=1,8 do for j=1,9 do
            if scene.outtime/outtime>j/9 then gc.setColor(0,0,0)
                gc.rectangle('fill',-960+120*(2*i-2),-540+120*(j-1),120,120)
                gc.rectangle('fill',-960+120*(2*i-1),-540+120*(9-j),120,120)
            elseif scene.outtime/outtime>(j-1)/9 then gc.setColor(.5,1,.75)
                gc.rectangle('fill',-960+120*(2*i-2),-540+120*(j-1),120,120)
                gc.rectangle('fill',-960+120*(2*i-1),-540+120*(9-j),120,120)
            end
        end end
    end
end
function anim.enter2(intime,keeptime,outtime)
    local rect_w=(1-((scene.swaptime-keeptime)/intime))^2
    gc.setColor(0,0,0)
    if scene.swaptime>0 then
        if scene.swaptime>keeptime then
            gc.rectangle('fill',-960*rect_w,-550,1920*rect_w,1100)
        else 
            gc.rectangle('fill',-960,-540,1920,1080)
            gc.rectangle('line',-960,-540,1920,1080)
        end
    else
        for i=1,8 do for j=1,9 do
            if scene.outtime/outtime>(j+8)/18 then gc.setColor(0,0,0)
                gc.rectangle('fill',-960+120*(2*i-2),-540+120*(j-1),120,120)
                gc.rectangle('fill',-960+120*(2*i-1),-540+120*(9-j),120,120)
            elseif scene.outtime/outtime>(j-1)/18 then gc.setColor(0,0,0,.625)
                gc.rectangle('fill',-960+120*(2*i-2),-540+120*(j-1),120,120)
                gc.rectangle('fill',-960+120*(2*i-1),-540+120*(9-j),120,120)
            end
        end end
    end
end
return anim