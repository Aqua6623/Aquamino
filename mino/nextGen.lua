local GenShin={}
local Impact=GenShin
local M,T=require'framework/mathextend',require'framework/tableextend'
local rand=math.random
function GenShin.bag(bag,next)
    local new=T.copy(bag)
    for i=1,#new do
        table.insert(next,table.remove(new,rand(#new)))
    end
end
function GenShin.pairs(bag,next,keep)
end
function GenShin.history(bag,h,r)
end
return Impact