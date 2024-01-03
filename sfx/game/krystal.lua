local krystal={}
function krystal.addSFX()
    sfx.add({
        die='sfx/game/krystal/die.wav',
        move='sfx/game/krystal/move.wav',
        moveFail='sfx/game/krystal/move fail.wav',
        landedMove='sfx/game/krystal/landed move.wav',
        HD='sfx/game/krystal/hard drop.wav',
        lock='sfx/game/krystal/lock.wav',
        hold='sfx/game/krystal/hold.wav',
        rotate='sfx/game/krystal/rotate.wav',
        spin='sfx/game/krystal/spin.wav',
        rotateFail='sfx/game/krystal/rotate fail.wav',
        touch='sfx/game/krystal/touch.wav',

        ['1']='sfx/game/krystal/1.wav',
        ['2']='sfx/game/krystal/2.wav',
        ['3']='sfx/game/krystal/3.wav',
        ['4']='sfx/game/krystal/4.wav',
        spin0='sfx/game/krystal/spin0.wav',
        spin1='sfx/game/krystal/spin1.wav',
        spin2='sfx/game/krystal/spin2.wav',
        spin3='sfx/game/krystal/spin3.wav',
        PC='sfx/game/krystal/PC.wav',
        B2B='sfx/game/krystal/B2B.wav',
    })
end
function krystal.move(player,success,landed)
    if success then
        if landed and sfx.pack.landedMove then sfx.play('landedMove') else sfx.play('move') end
    else sfx.play('moveFail') end
end
function krystal.rotate(player,success,spin)
    if success then
        if spin then sfx.play('spin')
        else sfx.play('rotate')end
    else sfx.play('rotateFail') end
end
function krystal.hold()
    sfx.play('hold')
end
function krystal.touch(player,touch)
    if touch then sfx.play('touch') end
end
function krystal.lock(player)
    if player.history.dropHeight>0 then sfx.play('HD',.3+.7*player.history.dropHeight/player.h)
    else sfx.play('lock') end
end
function krystal.clear(player)
    local his=player.history
    local clearType=(his.spin and 'spin' or '')..min(his.line,(his.spin and 3 or 4))
    local pitch=his.line==0 and 1 or min(2^((his.combo-1)/12),2.848)
    print('line clear:'..clearType) sfx.play(clearType,1)
    if his.PC then sfx.play('PC') end  if his.B2B>0 and his.line>0 then sfx.play('B2B') end
end
function krystal.die()
    sfx.play('die')
end
return krystal