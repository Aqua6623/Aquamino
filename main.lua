if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE')=='1' then
    require('lldebugger').start()
end

loopTime=0

draw_frame={dtRestrict=0,timer=0,FPS=0,count=0,FPStimer=0}
draw_frame.timer=draw_frame.dtRestrict
function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    if love.timer then love.timer.step() end

    local dt=0

    return function()
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == 'quit' then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        if love.timer then dt = love.timer.step()
            if draw_frame.dtRestrict~=0 then draw_frame.timer=draw_frame.timer+dt end
            draw_frame.FPStimer=draw_frame.FPStimer+dt
        end

        if love.update then love.update(dt) end

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(0,0,0)

            if draw_frame.timer>=draw_frame.dtRestrict then
                if love.draw then love.draw() end
                love.graphics.present() draw_frame.count=draw_frame.count+1
                while draw_frame.timer>draw_frame.dtRestrict do draw_frame.timer=draw_frame.timer-draw_frame.dtRestrict end
                if draw_frame.FPStimer>1 then
                    draw_frame.FPS=draw_frame.count/math.floor(draw_frame.FPStimer) draw_frame.count=0
                    draw_frame.FPStimer=draw_frame.FPStimer-math.floor(draw_frame.FPStimer)
                end
            end
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end

mainLoop=love.run()

gc=love.graphics
fs=love.filesystem
kb=love.keyboard
ms=love.mouse
touch=love.touch

mymath=require'framework/mathextend' mytable=require'framework/tableextend'
anim=require'scene/swap_animation'
adjust=require'scene/window_adjust'
color=require'framework/color'
json=require'json by rxi/json'

rand=math.random
sin=math.sin cos=math.cos
floor=math.floor ceil=math.ceil
max=math.max min=math.min
abs=math.abs

ins,rem=table.insert,table.remove

math.randomseed(os.time()-6623)
for i=1,5 do rand() end

canop=true--=can operate，是决定玩家是否能操作的变量

scene={
    totalTime=0,
    cur=require('scene/intro'),pos='intro',
    dest=nil,destScene=nil,
    BG=require('BG/blank'),
    nextBG=nil,
    time=0,
    swapT=0,
    outT=0,
    anim=nil,--过场动画
    latest=nil,
    path={'intro'},
    switch=function(arg)
        for k,v in pairs(arg) do scene[k]=v end
    end,

    button=require'framework/control/button',
    slider=require'framework/control/slider'
}

love.window.setMode(love.window.getMode()) --看似废话，但是如果去掉的话在我的框架里窗口颜色就会出神秘问题（至少Love 11.4如此）

win={
    showInfo=false,
    --[[showAdjustKey=true,
    isAdjusting=false,]]
    fullscr=false,
    W=gc.getWidth(),
    W_win=gc.getWidth(),
    H=gc.getHeight(),
    H_win=gc.getHeight(),
    x=0,y=0,
    x_win=0,y_win=0
}
win.x,win.y=love.window.getPosition()
win.x_win,win.y_win=love.window.getPosition()

mus=require'framework/music' sfx=require'framework/sound'
voice={
    pack={},
    buffer={},
    timer=0
}
do
    local AnV=require'scene/game conf/AnV'
    AnV.read()
    mus.volume,sfx.volume=AnV.audio.mus,AnV.audio.sfx
end

scene.cur=require'scene/game conf/AnV'
scene.pos='testing...'
scene.cur.init()
if scene.BG.init then scene.BG.init() end

lastkeyP=nil lastkeyR=nil

adaptAllWindow=love.math.newTransform(
    win.W/2,win.H/2,0,
    win.H/win.W<9/16 and win.H/1080 or win.W/1920,win.H/win.W<9/16 and win.H/1080 or win.W/1920
)

function love.load()
    fs.createDirectory('conf')
    fs.createDirectory('player')

    win.H=gc.getHeight()
    win.W=gc.getWidth()
    Exo_2=gc.newFont('font/Exo2-Regular.otf',128)
    Exo_2_SB=gc.newFont('font/Exo2-SemiBold.otf',128)
    Exo_2_B=gc.newFont('font/Exo2-Bold.otf',128)
    SYHT=gc.newFont('font/SourceHanSans-Regular.otf',128)
    Exo_2:setFallbacks(SYHT) Exo_2_SB:setFallbacks(SYHT)
    haisi=gc.newFont('font/haisi.ttf',128)
    haisi:setFallbacks(SYHT)
    Consolas=gc.newFont('font/Consolas.ttf',128)
    Consolas_B=gc.newFont('font/Consolas-Bold.ttf',128)
    Consolas:setFallbacks(SYHT) Consolas_B:setFallbacks(SYHT)

    UI_mini=gc.newImage('UI/mini.png')
    UI_mini_hv=gc.newImage('UI/mini_hover.png')
    UI_FS=gc.newImage('UI/fullscreen.png')
    UI_FS_hv=gc.newImage('UI/fullscreen_hover.png')
    UI_win=gc.newImage('UI/windowed.png')
    UI_win_hv=gc.newImage('UI/windowed_hover.png')
    UI_close=gc.newImage('UI/X.png')
    UI_close_hv=gc.newImage('UI/X_hover.png')
    UI_adjust=gc.newImage('UI/adjust.png')
    UI_adjust_hv=gc.newImage('UI/adjust_hover.png')
end
function love.resize(w,h)
    win.H=h
    win.W=w
    adaptAllWindow=love.math.newTransform(
        win.W/2,win.H/2,0,
        win.H/win.W<9/16 and win.H/1080 or win.W/1920,win.H/win.W<9/16 and win.H/1080 or win.W/1920
    )
end

function love.keypressed(k)
    lastkeyP=k
    if k=='f10' then win.showInfo=not win.showInfo
    --[[elseif k=='f12' then win.showAdjustKey=not win.showAdjustKey end
    if win.isAdjusting then adjust.keyP(k)]]
    elseif k=='f11' --[[and not win.isAdjusting]] then
        win.fullscr=not win.fullscr
        if win.fullscr then
            win.W_win,win.H_win=gc.getDimensions()
            win.x_win,win.y_win=love.window.getPosition()
        else
            win.W,win.H=win.W_win,win.H_win
            win.x,win.y=win.x_win,win.y_win  
        end
        adaptAllWindow=love.math.newTransform(
            win.W/2,win.H/2,0,
            win.H/win.W<9/16 and win.H/1080 or win.W/1920,win.H/win.W<9/16 and win.H/1080 or win.W/1920
        )
        love.window.setFullscreen(win.fullscr)
        win.W,win.H=gc.getDimensions()
    elseif canop and scene.cur.keyP then
        scene.cur.keyP(k)
    end
end
function love.keyreleased(k)
    if not win.isAdjusting and canop and scene.cur.keyR then
        scene.cur.keyR(k)
    end
end
function love.mousepressed(x,y,button,istouch)
    local rx,ry=adaptAllWindow:inverseTransformPoint(x+.5,y+.5)
    --[[if win.showAdjustKey then
        if button==1 then
            if mymath.pointInRect(x,y,0,36,win.W-36,win.W) then love.event.quit()
            elseif mymath.pointInRect(x,y,0,36,win.W-72,win.W-36) then
                win.fullscr=not win.fullscr
                if win.fullscr then
                    win.W_win,win.H_win=gc.getDimensions()
                    win.x_win,win.y_win=love.window.getPosition()
                else
                    win.W,win.H=win.W_win,win.H_win
                    win.x,win.y=win.x_win,win.y_win  
                end
                adaptAllWindow=love.math.newTransform(
                    win.W/2,win.H/2,0,
                    win.H/win.W<9/16 and win.H/1080 or win.W/1920,win.H/win.W<9/16 and win.H/1080 or win.W/1920
                )
                love.window.setFullscreen(win.fullscr)
                win.W,win.H=gc.getDimensions()
                if win.fullscr then win.isAdjusting=false
                    if win.isAdjusting then adjust.quit() end
                else love.window.setPosition(win.x_win,win.y_win) end
            elseif mymath.pointInRect(x,y,0,36,win.W-108,win.W-72) then love.window.minimize()
            elseif not win.fullscr and mymath.pointInRect(x,y,0,36,0,36) then
                win.isAdjusting=not win.isAdjusting
                if win.isAdjusting then adjust.init() else adjust.quit() end
                if scene.BG.init then scene.BG.init() end
            elseif scene.cur.mouseP and not win.isAdjusting and canop then
                scene.cur.mouseP(rx,ry,button,istouch)
            end
        end
    else]]if scene.cur.mouseP and not win.isAdjusting and canop then
        scene.cur.mouseP(rx,ry,button,istouch)
    end
end


function love.mousereleased(x,y,button,istouch)
    local rx,ry=gc.inverseTransformPoint(x+.5,y+.5)
    if scene.cur.mouseR and not win.isAdjusting and canop then 
    scene.cur.mouseR(rx,ry,button,istouch) end
end

function mainUpdate(dt)
    if scene.dest or scene.destScene then canop=false
        if scene.swapT>0 then scene.swapT=scene.swapT-dt
        else scene.outT=scene.outT+scene.swapT scene.swapT=0 mus.stop()
            local temp={}
            if scene.cur.tempSend then scene.cur.tempSend(temp) end
            local tosend=scene.cur.send
            if scene.cur.exit then scene.cur.exit() end
            scene.button.create() scene.slider.create()
            scene.pos=scene.dest
            if scene.destScene then scene.cur=scene.destScene scene.destScene=nil
            else scene.cur=require('scene/'..scene.dest) end
            if scene.nextBG then scene.BG=require('BG/'..scene.nextBG) end
            if scene.cur.init then scene.cur.init() end
            if scene.BG.init then scene.BG.init() end
            if tosend then tosend(scene.cur) end
            canop=true scene.dest=nil
            if scene.BG.init then scene.BG.init() end
            if tosend then tosend(temp) end
            scene.time=0
        end
    else canop=true
        if scene.outT>0 then scene.outT=scene.outT-dt
        else scene.outT=0 scene.anim=nil end
    end


    scene.time,scene.totalTime,sfx.timer=scene.time+dt,scene.totalTime+dt,sfx.timer+dt

    if scene.cur.update then scene.cur.update(dt) end
    if scene.BG.update then scene.BG.update(dt) end

    if sfx.timer>5 then
        for i=#sfx.buffer,1,-1 do
            if not sfx.buffer[i]:isPlaying() then table.remove(sfx.buffer,i) end
        end
        sfx.timer=sfx.timer-5
    end
    if win.isAdjusting then adjust.update(dt) end
end
function love.update(dt)
    mus.update(dt)
    local dtRemain=dt
    while dtRemain>=1/256 do mainUpdate(1/256) dtRemain=dtRemain-1/256 end
    mainUpdate(dtRemain)

end
function love.draw()
    local dpiS=love.window.getDPIScale()
    local rw,rh=dpiS*win.W,dpiS*win.H

    --[[画面显示：找到最大的16:9的矩形，居中，以该矩形的中心为原点，向右为x轴正方向，向下为y轴正方向，
    矩形长边为1920单位，短边为1080单位，以此为基准进行绘制]]
    gc.applyTransform(adaptAllWindow)
    local aw,ah=win.H/win.W<9/16 and win.H*16/9 or win.W,win.H/win.W<9/16 and win.H or win.W*9/16
    gc.setScissor((win.W-aw)/2,(win.H-ah)/2,
    aw,ah)
    local rx,ry=gc.inverseTransformPoint(ms.getX()+.5,ms.getY()+.5)
    gc.setColor(1,1,1)--若未说明，图像绘制统一为白色，下同
    if scene.BG.draw then scene.BG.draw() end
    gc.setColor(1,1,1)
    if scene.cur.draw then scene.cur.draw() end
    gc.setColor(.5,1,.75,.25+.05*sin(scene.totalTime*5*math.pi))
    gc.printf("作者：Aqua6623",Consolas_B,480*sin(scene.totalTime/2*math.pi),-440,5000,'center',0,.5,.5,2500,56)
    gc.printf("未经授权禁止转载",Consolas_B,-480*sin(scene.totalTime/2*math.pi),440,5000,'center',0,.5,.5,2500,56)
    gc.setColor(1,1,1)
    if scene.anim then scene.anim() end
    gc.setColor(1,1,1,.5)
    --gc.print("绘制帧率/实际帧率:"..draw_frame.FPS.."/"..love.timer.getFPS(),Exo_2_SB,-955,510,0,.2,.2)
    gc.print("FPS:"..love.timer.getFPS(),Exo_2_SB,-955,510,0,.2,.2)

    --[[if win.isAdjusting then adjust.draw() end]]
    gc.setScissor()
    gc.origin()
    gc.setColor(1,1,1)
    local infoL="Current scene: "..scene.pos.."\nYou\'ve stayed here for "..string.format("%.2f",scene.time).."s".."\nCursor pos:"..("%.2f,%.2f"):format(rx,ry)
    if canop then infoL=infoL.."\nYou can operate now"
    else infoL=infoL.."\nYou can\'t operate now" end
    infoR=""..gcinfo().."KB\nRes:"..win.W.."*"..win.H.."\nReal res:"..rw.."*"..rh.."\nWindow mode position:"..win.x_win..","..win.y_win.."\n"..draw_frame.timer.."/"..draw_frame.dtRestrict.."\n"..(lastkeyP and lastkeyP or "")

    --[[if win.showAdjustKey then
        gc.setColor(1,1,1)
        if mymath.pointInRect(ms.getX(),ms.getY(),0,36,win.W-36,win.W) then gc.draw(UI_close_hv,win.W-36,0)
        else gc.draw(UI_close,win.W-36,0) end
        if win.fullscr then
            if mymath.pointInRect(ms.getX(),ms.getY(),0,36,win.W-72,win.W-36) then gc.draw(UI_win_hv,win.W-72,0)
            else gc.draw(UI_win,win.W-72,0) end
        else
            if mymath.pointInRect(ms.getX(),ms.getY(),0,36,0,36) then gc.draw(UI_adjust_hv,0,0)
            else gc.draw(UI_adjust,0,0) end
            if mymath.pointInRect(ms.getX(),ms.getY(),0,36,win.W-72,win.W-36) then gc.draw(UI_FS_hv,win.W-72,0)
            else gc.draw(UI_FS,win.W-72,0) end
        end
        if mymath.pointInRect(ms.getX(),ms.getY(),0,36,win.W-108,win.W-72) then gc.draw(UI_mini_hv,win.W-108,0)
        else gc.draw(UI_mini,win.W-108,0) end
    end]]
    if win.showInfo then
        gc.print(infoL,Exo_2,10,25,0,.15,.15)
        gc.printf(infoR,Exo_2,win.W-10-114514*.15,25,114514,'right',0,.15,.15)
    end

    --gc.setLineWidth(2)
    --gc.setColor(0,1,.75)
    --gc.rectangle('line',0,0,win.W,win.H)
end