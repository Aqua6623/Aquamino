function love.conf(t)
    local w=t.window
    w.title ="Test"
    w.icon='UI/icon.png'
    w.borderless=false
    w.resizable=true
    w.minwidth=200
    w.minheight=150
    w.width=1600
    w.height=900

    w.msaa=24
    w.vsync=0

    t.modules.physics=false
    t.modules.touch=false

    t.gammacorrect=false
end