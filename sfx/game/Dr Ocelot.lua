local DrOcelot={}
function DrOcelot.addSFX()
    sfx.add({
        die='sfx/game/Dr Ocelot/die.wav',
        win='sfx/game/Dr Ocelot/win.wav',
        move='sfx/game/Dr Ocelot/move.wav',

        HD='sfx/game/Dr Ocelot/hard drop.wav',
        lock='sfx/game/Dr Ocelot/lock.wav',
        hold='sfx/game/Dr Ocelot/hold.wav',
        rotate='sfx/game/Dr Ocelot/rotate.wav',
        touch='sfx/game/Dr Ocelot/touch.wav',

        ['1']='sfx/game/Dr Ocelot/1.wav',
        ['2']='sfx/game/Dr Ocelot/2.wav',
        ['3']='sfx/game/Dr Ocelot/3.wav',
        ['4']='sfx/game/Dr Ocelot/4.wav',
        spin0='sfx/game/Dr Ocelot/spin0.wav',
        spin1='sfx/game/Dr Ocelot/spin1.wav',
        spin2='sfx/game/Dr Ocelot/spin2.wav',
        spin3='sfx/game/Dr Ocelot/spin3.wav',
        PC='sfx/game/Dr Ocelot/PC.wav',
    })
end
function DrOcelot.move(player,success,landed)
    if success then sfx.play('move') end
end
function DrOcelot.rotate(player,success,spin)
    if success then sfx.play('rotate') end
end
function DrOcelot.hold()
    sfx.play('hold')
end
function DrOcelot.touch(player,touch)
    if touch then sfx.play('touch') end
end
function DrOcelot.lock(player)
    if player.history.dropHeight>0 then sfx.play('HD',.3+.7*player.history.dropHeight/player.h)
    else sfx.play('lock') end
end
function DrOcelot.clear(player)
    local his=player.history
    local clearType=(his.spin and 'spin' or '')..min(his.line,(his.spin and 3 or 4))
    local pitch=his.line==0 and 1 or min(2^((his.combo-1)/12),2.848)
    print('line clear:'..clearType) sfx.play(clearType,1)
    if his.PC then sfx.play('PC') end
end
function DrOcelot.die()
    sfx.play('die')
end
function DrOcelot.win()
    sfx.play('win')
end
return DrOcelot