function love.conf(t)
    local w=t.window
    w.title ="Test"
    w.icon='UI/icon.png'
    w.borderless=true
    w.resizable=true
    w.minwidth=200
    w.minheight=150
    w.width=1024
    w.height=576

    w.msaa=24
    w.vsync=0

    t.modules.physics=false
    t.modules.touch=false

    t.gammacorrect=true
end