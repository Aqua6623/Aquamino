--轨迹对象
local ins,rem=table.insert,table.remove
local gc=love.graphics
local setColor,setLineWidth=gc.setColor,gc.setLineWidth
local circle,line,poly=gc.circle,gc.line,gc.polygon
local trailModule={}
function trailModule.create(time,width,alpha)
    return {
        posList={},--存储位置，格式为：时间 x坐标 y坐标
        time=time,--轨迹持续时长
        width=width,--绘制宽度
        alpha=alpha,--最大不透明度
    }
end
function trailModule.addPos(trail,posx,posy)
    ins(trail.posList,trail.time)
    ins(trail.posList,posx)
    ins(trail.posList,posy)
end
function trailModule.update(trail,dt)
    for i=#trail.posList-2,1,-3 do
        trail.posList[i]=trail.posList[i]-dt
        if trail.posList[i]<=0 then
            for j=i+2,i,-1 do rem(trail.posList,j) end
        end
    end
end
function trailModule.drawCircle(trail,colorR,colorG,colorB)
    for i=1,#trail.posList,3 do
        local a=trail.posList[i]/trail.time
        setColor(colorR,colorG,colorB,trail.alpha*a)
        circle('fill',trail.posList[i+1],trail.posList[i+2],trail.width/2)
    end
end
function trailModule.drawCircle2(trail,colorR,colorG,colorB)
    for i=1,#trail.posList,3 do
        local a=trail.posList[i]/trail.time
        setColor(colorR,colorG,colorB,trail.alpha)
        circle('fill',trail.posList[i+1],trail.posList[i+2],trail.width/2*a)
    end
end
local function calculateDirection(Ax,Ay,Bx,By,Cx,Cy)--计算B点角平分线对应的法向量
    if not Ax then Ax=Bx end  if not Ay then Ay=By end
    if not Cx then Cx=Bx end  if not Cy then Cy=By end
    if Ax==Bx and Bx==Cx and Ay==By and By==Cy then--完全没动
        return 0,0
    end

    local dx,dy
    local ABx,ABy=Bx-Ax,By-Ay
    local BCx,BCy=Cx-Bx,Cy-By
    if ABx==0 and ABy==0 then--AB两点重合，只给BC
        dx=BCx/(BCx^2+BCy^2)^.5
        dy=BCy/(BCx^2+BCy^2)^.5
        return -dy/(dx^2+dy^2)^.5,dx/(dx^2+dy^2)^.5
    elseif BCx==0 and BCy==0 then--BC两点重合，只给AB
        dx=ABx/(ABx^2+ABy^2)^.5
        dy=ABy/(ABx^2+ABy^2)^.5
        return -dy/(dx^2+dy^2)^.5,dx/(dx^2+dy^2)^.5
    else
        dx=ABx/(ABx^2+ABy^2)^.5+BCx/(BCx^2+BCy^2)^.5
        dy=ABy/(ABx^2+ABy^2)^.5+BCy/(BCx^2+BCy^2)^.5
        return -dy/(dx^2+dy^2)^.5*min(2^.5,2/(dx^2+dy^2)^.5),dx/(dx^2+dy^2)^.5*min(2^.5,2/(dx^2+dy^2)^.5)
    end
end
function trailModule.drawLine(trail,colorR,colorG,colorB)
    for i=4,#trail.posList,3 do
        local p=trail.posList
        --计算1号点角平分线对应的法向量
        local dx1,dy1=calculateDirection(p[i-5],p[i-4],p[i-2],p[i-1],p[i+1],p[i+2])
        --计算2号点角平分线对应的法向量
        local dx2,dy2=calculateDirection(p[i-2],p[i-1],p[i+1],p[i+2],p[i+4],p[i+5])
        dx1,dy1,dx2,dy2=dx1*trail.width/2,dy1*trail.width/2,dx2*trail.width/2,dy2*trail.width/2
        local a=trail.posList[i]/trail.time
        setColor(colorR,colorG,colorB,trail.alpha*a)
        poly('fill',p[i-2]+dx1,p[i-1]+dy1,p[i-2]-dx1,p[i-1]-dy1,p[i+1]-dx2,p[i+2]-dy2,p[i+1]+dx2,p[i+2]+dy2)
        --setLineWidth(trail.width)
        --circle('fill',p[i+1],p[i+2],trail.width/10)
    end
end
function trailModule.drawLine2(trail,colorR,colorG,colorB)
    for i=4,#trail.posList,3 do
        local p=trail.posList
        --计算1号点角平分线对应的法向量
        local dx1,dy1=calculateDirection(p[i-5],p[i-4],p[i-2],p[i-1],p[i+1],p[i+2])
        --计算2号点角平分线对应的法向量
        local dx2,dy2=calculateDirection(p[i-2],p[i-1],p[i+1],p[i+2],p[i+4],p[i+5])
        dx1,dy1,dx2,dy2=dx1*trail.width/2,dy1*trail.width/2,dx2*trail.width/2,dy2*trail.width/2
        local a1=trail.posList[i-3]/trail.time
        local a2=trail.posList[i]/trail.time
        setColor(colorR,colorG,colorB,trail.alpha)
        poly('fill',p[i-2]+dx1*a1,p[i-1]+dy1*a1,p[i-2]-dx1*a1,p[i-1]-dy1*a1,p[i+1]-dx2*a2,p[i+2]-dy2*a2,p[i+1]+dx2*a2,p[i+2]+dy2*a2)
        --setLineWidth(trail.width)
        --circle('fill',p[i+1],p[i+2],trail.width/10)
    end
end
return trailModule