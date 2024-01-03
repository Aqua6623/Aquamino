return {
    volume=1,
    pack={},
    buffer={},
    timer=0,
    TTL=1,
    cloneLim=8,
    add=function(arg)
        for k,v in pairs(arg) do
            if love.filesystem.getInfo(v) then sfx.pack[k]=love.audio.newSource(v,'static') end
            sfx.buffer[k]={}
        end
    end,
    play=function(name,volume,pitch)
        if not (sfx.pack[name] and sfx.buffer[name]) then print('sound not exist') return -1 end
        if not volume then volume=1 end if not pitch then pitch=1 end
        if sfx.pack[name]:isPlaying() then
            local newClone=true
            local buffer=sfx.buffer[name]
            for i=1,#buffer do
                if not buffer[i].sfx:isPlaying() then
                    buffer[i].sfx:setVolume(sfx.volume*volume) buffer[i].sfx:setPitch(pitch)
                    buffer[i].sfx:play() buffer[i].TTL=sfx.TTL newClone=false break
                end
            end
            if newClone and #sfx.buffer[name]<sfx.cloneLim then
            buffer[#buffer+1]={sfx=sfx.pack[name]:clone(),TTL=sfx.TTL}
            buffer[#buffer].sfx:setPitch(pitch) buffer[#buffer].sfx:play()
            end
        else
            sfx.pack[name]:setVolume(sfx.volume*volume) sfx.pack[name]:setPitch(pitch)
            sfx.pack[name]:play()
        end
    end,
    update=function(dt)
        for name,buffer in pairs(sfx.buffer) do for i=buffer,1,-1 do
            buffer[i].TTL=buffer[i].TTL-dt
            if buffer[i].TTL<=0 then table.remove(buffer,i) end
        end end
    end
}