local spinCheck={}
local fLib=require('mino/fieldLib')
local M,T=mymath,mytable
--return spin,mini
function spinCheck.default(player)
    local C=player.cur
    if T.include({'Z','S','O','I'},C.name) then
        if fLib.isImmobile(player) then return true,false end
    elseif T.include({'T','J','L'},C.name) then
        if fLib.isImmobile(player) then return true,fLib.corner(player)<(C.name=='T' and 3 or 2)
        else return false,false end
    else return false,false end
end
return spinCheck