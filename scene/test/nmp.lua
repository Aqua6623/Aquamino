--暂时搁置的法线贴图测试
local nmp={}
function nmp.init()
    nmp.img=gc.newImage('pic/assets/nmp1.png')
    local sha=fs.newFile('shader/normal map.glsl'):read()
    nmp.shader=gc.newShader(sha)
    win.watermark=false
    nmp.angle=0
    nmp.light={1,0,1}
end
function nmp.update(dt)
    if love.keyboard.isDown('left') then nmp.angle=nmp.angle+dt*.5 end
    if love.keyboard.isDown('right') then nmp.angle=nmp.angle-dt*.5 end
    nmp.light[1],nmp.light[2]=cos(nmp.angle*math.pi),sin(nmp.angle*math.pi)
end
function nmp.draw()
    nmp.shader:send('light',nmp.light)
    nmp.shader:send('ambientLight',.15)
    gc.setShader(nmp.shader)
    gc.draw(nmp.img,0,0,0,2,2,128,128)
    gc.setShader()
    gc.circle('fill',480*cos(nmp.angle*math.pi),480*sin(nmp.angle*math.pi),10)
end
return nmp