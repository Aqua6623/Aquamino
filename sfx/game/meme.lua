local meme={}
function meme.addSFX()
    sfx.add({
        die='sfx/game/meme/die.wav',
        move='sfx/game/meme/move.wav',
        moveFail='sfx/game/meme/move fail.wav',

        lock='sfx/game/meme/lock.wav',
        hold='sfx/game/meme/hold.wav',
        rotate='sfx/game/meme/rotate.wav',
        spin='sfx/game/meme/spin.wav',
        rotateFail='sfx/game/meme/rotate fail.wav',
        touch='sfx/game/meme/touch.wav',

        ['1']='sfx/game/meme/1.wav',
        ['2']='sfx/game/meme/2.wav',
        ['3']='sfx/game/meme/3.wav',
        ['4']='sfx/game/meme/4.wav',
        spin0='sfx/game/meme/spin0.wav',
        spin1='sfx/game/meme/spin1.wav',
        spin2='sfx/game/meme/spin2.wav',
        spin3='sfx/game/meme/spin3.wav',
        PC='sfx/game/meme/PC.wav',
    })
end
function meme.move(player,success,landed)
    if success then
        if landed and sfx.pack.landedMove then sfx.play('landedMove') else sfx.play('move') end
    else sfx.play('moveFail') end
end
function meme.rotate(player,success,spin)
    if success then
        if spin then sfx.play('spin')
        else sfx.play('rotate')end
    else sfx.play('rotateFail') end
end
function meme.hold(player)
    sfx.play('hold')
end
function meme.touch(player,touch)
    if touch then sfx.play('touch') end
end
function meme.lock(player)
    sfx.play('lock',.3+.7*player.history.dropHeight/player.h)
end
function meme.clear(player)
    local his=player.history
    local clearType=(his.spin and 'spin' or '')..min(his.line,(his.spin and 3 or 4))
    local pitch=his.line==0 and 1 or min(2^((his.combo-1)/12),2.848)
    print('line clear:'..clearType) sfx.play(clearType,1)
    if his.PC then sfx.play('PC') end
end
function meme.die()
    sfx.play('die')
end
return meme