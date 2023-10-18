local menu={}
local modekey,lvl=1,1
local flashT,enterT=0,0
menu.modelist={'Sprint','Marathon','Invisible','Master','Attack','Blitz','Zen','Multitasking','Ice storm'}
menu.modename={"竞速","马拉松","隐形","大师","100攻击","闪电","无尽","脑裂","冰风暴"}
local modelist=menu.modelist
local modename=menu.modename
local discription={}

function menu.ini()
    scene.bg=require'BG/pond'
    modekey=1
end
function menu.keyP(k)
    local len=#modelist
    if k=='return' then lvl=lvl+1
    elseif k=='escape' then lvl=lvl-1 end
    if lvl==0 then
        scene.dest='intro' scene.swaptime=.7 scene.outtime=.3
        scene.anim=function() anim.cover(.3,.4,.3,0,0,0) end
    elseif lvl==1 then
        if k=='left' or k=='right' or k=='r' then flashT=.3 end
        if k=='left' then modekey=(modekey-2)%len+1 
        elseif k=='right' then modekey=modekey%len+1
        elseif k=='r' then modekey=rand(1,#modelist)
        end
    end
end
function menu.mouseP(x,y,button,istouch)
    local len=#modelist
    l=1920/len
    if button==1 then
        if y>=500 then
        for i=1,len do
            if x>-960+l*(i-1) and x<-960+l*i then
                modekey=i flashT=.3 break
            end
        end
        elseif x<-640 then modekey=(modekey-2)%len+1 flashT=.3
        elseif x>=640 then modekey=modekey%len+1 flashT=.3 end
    end
end
function menu.update(dt)
    if flashT>0 then flashT=flashT-dt end 
end
function menu.draw()
    local l=1920/#modelist
    gc.printf(modename[modekey],Exo_2,-750,-540,1000,'center',0,1.5,1.5)
    gc.setColor(1,1,1,.4-.2*cos(scene.time%8*math.pi/4))
    gc.printf("按Enter键开始游戏\n按R键随机跳转\n*现在还没有写模式。选择任何模式都会跳到同一个界面。",Exo_2,-600,-320*.6,2000,'center',0,.6,.6)
    gc.setLineWidth(3)
    for i=1,#modelist do
        if i==modekey then
        gc.setColor(1,1,1,.4) 
        gc.rectangle('fill',-960+l*(modekey-1),500,l,40)
    else
        gc.setColor(1,1,1,.1+.03*(i%2))
        gc.rectangle('fill',-960+l*(i-1),500,l,40)
    end
    end
    
    gc.setColor(1,1,1,.5)
    gc.setLineWidth(20)
    gc.line(-760,-100,-860,0,-760,100)
    gc.line( 760,-100, 860,0, 760,100)
    do
        local s=scene.time%4/4
        if.08-s>0 then
            gc.setColor(1,1,1,10*(.08-s))
            gc.line(-760-800*s,-100,-860-800*s,0,-760-800*s,100)
            gc.line( 760+800*s,-100, 860+800*s,0, 760+800*s,100)
        end
    end
    if flashT>0 then gc.setColor(1,1,1,flashT/.3*.15)
        gc.rectangle('fill',-1000,-600,2000,1200)
    end
end
return menu