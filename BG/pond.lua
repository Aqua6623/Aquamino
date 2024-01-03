local pond={}

local parlist={}
local ringtime=1
local summontime=0
function pond.update(dt)
    for i=#parlist,1,-1 do
        local ring=parlist[i]
        ring.TTL=ring.TTL-dt
        if ring.TTL<=0 then table.remove(parlist,i) end
    end
    
    if summontime<=0 then
        table.insert(parlist,{px=rand()*1920,py=rand()*1080,TTL=1})
        summontime=0.4+0.2*math.random()
    else summontime=summontime-dt end
    if rand()<dt*2 and #parlist<10 then 
        table.insert(parlist,{px=rand()*1920,py=rand()*1080,TTL=1})
    end
end
function pond.draw()
    gc.setColor(.1,.2,.15)
    gc.rectangle('fill',-960,-540,1920,1080)
    for i=1,#parlist do
        local ring=parlist[i]
        gc.setLineWidth(5/( (1-ring.TTL/ringtime)^2+1) )
        gc.setColor(1,1,1,ring.TTL^2*.6)
        gc.circle('line',ring.px-960,ring.py-540,100*(1-ring.TTL))
    end
    gc.setColor(1,1,1)
end
return pond
