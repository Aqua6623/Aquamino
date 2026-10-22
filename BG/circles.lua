--对Lumines的关卡Circles的拙劣模仿
local BPM=120
local tau=2*math.pi
local bg={time=0}

local circleShader = love.graphics.newShader[[
vec4 effect(vec4 color,Image tex,vec2 texCoord,vec2 scrCoord){
    vec4 pixel = Texel(tex, texCoord);
    return pixel*color*(1.-.8*(texCoord.x-.5)*(texCoord.x-.5));
}
]]
local lightShader=love.graphics.newShader[[
vec4 effect(vec4 color,Image tex,vec2 texCoord,vec2 scrCoord){
    vec4 pixel = Texel(tex, texCoord);
    return pixel*color*vec4(1,pixel.a,3.*pixel.a-2.,1);
}
]]
local lightShader2=love.graphics.newShader[[
vec4 effect(vec4 color,Image tex,vec2 texCoord,vec2 scrCoord){
    vec4 pixel = Texel(tex, texCoord);
    return pixel*vec4(1,pixel.a*color.a,(3.*pixel.a*color.a-2.),color.a);
}
]]
local sunShader=love.graphics.newShader[[
vec4 effect(vec4 color,Image tex,vec2 texCoord,vec2 scrCoord){
    highp float x=texCoord.x*2.-1.;
    highp float y=texCoord.y*2.-1.;
    highp float r=sqrt(x*x+y*y);
    highp float a=max(1-(r-.72)/.18,0);
    return vec4(1,1,1,a*a);
}
]]
local circle=gc.newCanvas(810,810)
gc.setCanvas(circle)
gc.setBlendMode('alpha','premultiplied')
gc.setLineWidth(8)
gc.setColor(1,1,1,.3)
gc.circle('fill',405,405,400)
gc.setColor(1,1,1)
gc.circle('line',405,405,400)
gc.setLineWidth(16)
gc.line(5,405,65,405)
gc.line(745,405,805,405)
gc.line(405,5,405,65)
gc.line(405,745,405,805)
gc.circle('line',405,405,300)
gc.setBlendMode('alpha','alphamultiply')
gc.setCanvas()

local light=gc.newCanvas(600,100)
gc.setCanvas(light)
gc.setBlendMode('lighten','premultiplied')
for i=0,59 do
gc.setColor(1,1,1,(1-i/60))
gc.ellipse('fill',300,50,300*i/60,50*i/60)
end
gc.setBlendMode('alpha','alphamultiply')
gc.setCanvas()

local wp=gc.newCanvas(1000,1000)
gc.setCanvas(wp)

gc.setColor(1,1,1)
gc.rectangle('fill',0,0,1000,1000)

gc.setCanvas()
local sun=gc.newCanvas(1000,1000)
gc.setCanvas(sun)
gc.setBlendMode('lighten','premultiplied')
gc.setShader(sunShader)
gc.setColor(1,1,1)
gc.draw(wp,0,0)
--[[for i=0,59 do
gc.setColor(1,1,1,(1-i/60)^2)
gc.circle('fill',500,500,366+2*i)
end]]
gc.setBlendMode('alpha','alphamultiply')
gc.setCanvas()

function bg.init()
    bg.time=0
end
function bg.setTime(time)
    bg.time=time
end
function bg.update(dt)
    bg.time=bg.time+dt
end
rng.newGenerator('circlesBG',-987654321)
local lightAmount=128
local lightSize={}
for i=1,lightAmount do
    lightSize[i]=.4+7.6*rng.random('circlesBG')
end
local lightWidth={}
for i=1,lightAmount do
    lightWidth[i]=1+2*rng.random('circlesBG')
end
local lightAngle={}
for i=1,lightAmount do
    lightAngle[i]=rng.random('circlesBG')
end
local lightPhase={}
for i=1,lightAmount do
    lightPhase[i]=rng.random('circlesBG')
end
local circleMode=1
function bg.draw()
    local beat=bg.time*BPM/60
    local t=beat/64%1
    local t1=beat/16%3

    gc.scale(5/6)

    gc.setBlendMode('add')
    gc.setShader(lightShader2)
    gc.setColor(1,1,1)
    gc.draw(sun,0,0,0,2,2,500,500)
    --gc.setColor(1,1,1,.5+.5*max(1-beat%4*2,0))
    --gc.draw(sun,0,0,0,2,2,500,500)
    gc.setShader(lightShader)
    gc.setColor(1,1,1,.4)
    for i=1,lightAmount do
        local j=lightAngle[i]
        gc.draw(light,480*cos(tau*j),480*sin(tau*j),tau*j,sin(tau*(beat/16%1+lightPhase[i]))^2*lightSize[i],lightWidth[i],300,50)
    end
    --gc.setShader(lightShader2)
    gc.setShader()
    gc.setBlendMode('alpha')

    gc.setColor(0,0,0)
    gc.circle('fill',0,0,720)
    gc.setColor(1,1,1)
    gc.setLineWidth(4)
    gc.circle('line',0,0,720)

    gc.setShader(circleShader)
    if circleMode==1 then
        gc.setColor(.8,0,0)
        gc.draw(circle,480*cos(tau*(t    )),480*sin(tau*(t    )),tau*t*(1-3),.6,.6,405,405)
        gc.draw(circle,480*cos(tau*(t+1/4)),480*sin(tau*(t+1/4)),tau*t*(1-3),.6,.6,405,405)
        gc.draw(circle,480*cos(tau*(t+2/4)),480*sin(tau*(t+2/4)),tau*t*(1-3),.6,.6,405,405)
        gc.draw(circle,480*cos(tau*(t+3/4)),480*sin(tau*(t+3/4)),tau*t*(1-3),.6,.6,405,405)

        gc.setColor(.8,.4,0)
        gc.draw(circle,0,0,tau*t*(3+1),.6,.6,405,405)

        gc.setColor(.8,.8,0)
        gc.draw(circle,160*cos(tau*(t    )),160*sin(tau*(t    )),tau*t*(1-3+12),.2,.2,405,405)
        gc.draw(circle,160*cos(tau*(t+1/4)),160*sin(tau*(t+1/4)),tau*t*(1-3+12),.2,.2,405,405)
        gc.draw(circle,160*cos(tau*(t+2/4)),160*sin(tau*(t+2/4)),tau*t*(1-3+12),.2,.2,405,405)
        gc.draw(circle,160*cos(tau*(t+3/4)),160*sin(tau*(t+3/4)),tau*t*(1-3+12),.2,.2,405,405)
        gc.draw(circle,0,0,tau*t*(3+1-12),.2,.2,405,405)

        gc.setColor(.8,.6,0)
        for i=0,3 do
            local x,y=480*cos(tau*(t+i/4)),480*sin(tau*(t+i/4))
            gc.draw(circle,x+160*cos(tau*(t    )),y+160*sin(tau*(t    )),tau*t*(1-3-6),.2,.2,405,405)
            gc.draw(circle,x+160*cos(tau*(t+1/4)),y+160*sin(tau*(t+1/4)),tau*t*(1-3-6),.2,.2,405,405)
            gc.draw(circle,x+160*cos(tau*(t+2/4)),y+160*sin(tau*(t+2/4)),tau*t*(1-3-6),.2,.2,405,405)
            gc.draw(circle,x+160*cos(tau*(t+3/4)),y+160*sin(tau*(t+3/4)),tau*t*(1-3-6),.2,.2,405,405)
            gc.draw(circle,x,y,tau*t*(3+1+6),.2,.2,405,405)
        end
    elseif circleMode==2 then
        local ax,bx,cx=180*cos(tau*(t1)),180*cos(tau*(2*t1)),180*cos(tau*(2*t1))
        local ay,by,cy=180*sin(tau*(t1)),180*sin(tau*(2*t1)),180*sin(tau*(2*t1))
        gc.setColor(.8,0,0)
        gc.draw(circle,ax,ay,tau*t1*(1-4/3),1.35,1.35,405,405)
        gc.setColor(.8,.4,0)
        gc.draw(circle,ax+bx,ay+by,tau*t1*-1.5,.9,.9,405,405)
        gc.setColor(.8,.8,0)
        gc.draw(circle,ax+bx+cx,ay+by+cy,tau*t1*-5,.45,.45,405,405)
    end
    gc.setShader()

    gc.scale(6/5)
    gc.setColor(0,1,1)
    --gc.printf(floor(beat),font.JB,0,480,8000,'center',0,.6,.6,4000,font.height.JB/2)
end
return bg