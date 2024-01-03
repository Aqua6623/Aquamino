local mus={
    volume=0.8,
    type='part',
    intro=nil,ITrans=nil,loop=nil,
    introEnd=false,swapDelay=0,
    whole=nil,
    paused=false,stopped=false,
    add=function(path,mode,form,loopStart,loopTime)
        assert(mode=='parts' or mode=='whole',"music type must be 'parts' or 'whole'")
        mus.type=mode
        print(path..'/whole.'..form)
        if mode=='parts' then
            if fs.getInfo(path..'/intro.'..form) then mus.intro=love.audio.newSource(path..'/intro.'..form,'stream') end
            if fs.getInfo(path..'/loop.'..form) then mus.intro=love.loop.newSource(path..'/loop.'..form,'stream') end
            if fs.getInfo(path..'/ITrans.'..form) then mus.ITrans=love.audio.newSource(path..'/ITrans.'..form,'stream') end
        elseif fs.getInfo(path..'/whole.'..form) then mus.whole=love.audio.newSource(path..'/whole.'..form,'stream')
            mus.loopStart=loopStart mus.loopTime=loopTime print('success')
        end
    end,
    start=function()
        print(mus.whole)
        if mus.type=='parts' then
            if mus.intro then mus.intro:setVolume(mus.volume) end
            if mus.ITrans then mus.ITrans:setVolume(mus.volume) end
            if mus.loop then mus.loop:setVolume(mus.volume) mus.loop:setLooping(true) end
            mus.introEnd=false
            if mus.intro then mus.intro:play() print("Music started")
            elseif mus.loop then mus.loop:play() print("Music started") else print("Music not exist") end
        elseif mus.type=='whole' then 
            if mus.whole then mus.whole:setVolume(mus.volume) mus.whole:play() print("Music started")
            else print("Music not exist") end
        end
        mus.paused,mus.stopped=false,false
    end,
    stop=function()
        mus.stopped=true
        if mus.intro then mus.intro:stop() end
        if mus.ITrans then mus.ITrans:stop() end
        if mus.loop then mus.loop:stop() end
        if mus.whole then mus.whole:stop() end
    end,
    setPitch=function(bitch)
        if mus.intro then mus.intro:setPitch(bitch) end
        if mus.ITrans then mus.ITrans:setPitch(bitch) end
        if mus.loop then mus.loop:setPitch(bitch) end
        if mus.whole then mus.whole:setPitch(bitch) end
    end,
    update=function(dt)
        if mus.type=='parts' then 
            if not mus.intro or not mus.loop then return -1 end
            if not mus.paused and not mus.stopped then
                if mus.swapDelay==0 then
                    if not mus.intro:isPlaying() and not mus.introEnd then
                        if mus.ITrans then mus.ITrans:play() print("Playing ITrans") end
                        mus.loop:play() print("Music looping")
                        mus.introEnd=true
                    elseif mus.intro:getDuration()-mus.intro:tell()<=max(.008,mus.swapDelay) and not mus.introEnd then
                        if mus.ITrans then mus.ITrans:play() print("Playing ITrans") end
                        mus.loop:play() print("Music looping")
                        mus.introEnd=true
                    end
                end
            end
        elseif mus.whole then
            if mus.whole:tell()>=mus.loopStart+mus.loopTime then mus.whole:seek(mus.whole:tell()-mus.loopTime) end
        end
    end,
    setVolume=function(volume)
        mus.volume=volume
        if mus.intro then mus.intro:setVolume(mus.volume) end
        if mus.ITrans then mus.ITrans:setVolume(mus.volume) end
        if mus.loop then mus.loop:setVolume(mus.volume) end
        if mus.whole then mus.whole:setVolume(mus.volume) end
    end
}
return mus