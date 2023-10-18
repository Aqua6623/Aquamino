
local mode={
    sprint={
        gravity=1,

        lineTarget=40,lineselect={10,40,100,500,1000},

        allowOspin=true,allowT2O=false,

        rule={
            --onPieceSpawn=nil,
            --onPieceDrop=nil,
            onLineClear=function(player)
                if player.lineClr>=target then player.state='success' end
            end
            --onAtkRecv=nil,
            --待补充
        }
    },
    marathon={},invisible={},master={},attack={},blitz={},zen={},multitasking={}
}
return mode