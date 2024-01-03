local pSysLib={}
local gc=love.graphics
function pSysLib.create(parType)
    return {parList={},type=parType}
end
function pSysLib.emit(parSys)
end
return pSysLib