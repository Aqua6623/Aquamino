local mymath={}
function mymath.lerp(a,b,t)
    if type(a)~=type(b) then error('a and b nust be the same type') end
    if type(a)=='number' then return b*t+a*(1-t)
    elseif type(a)=='table' then
    local n={}
    for i=1,min(#a,#b) do
        if type(a[i])=='table' then n[i]=mymath.lerp(a[i],b[i],t)
        else n[i]=b[i]*t+a[i]*(1-t) end
    end
    return n
    else error('WTF') end
end
function mymath.clamp(n,low,high)
    return max(min(n,high or 1),low or 0)
end
function mymath.vecplus(a,b)--矢量叠加
    local l=math.min(#a,#b) local c={}
    for i=1,l do c[i]=a[i]+b[i] end
    if #a>#b then for i=l+1,#a do c[i]=a[i] end
    elseif #b>#a then for i=l+1,#a do c[i]=a[i] end
    end
    return c
end
function mymath.dotProduct(a,b)--数量积
    local result=0
    for i=1,#a do result=result+a[i]*b[i] end
    return result
end
function mymath.compmult(a,b)--复数相乘
    local m={}
    m[1]=a[1]*b[1]-a[2]*b[2]
    m[2]=a[2]*b[1]+a[1]*b[2]
    return m
end
function mymath.isSameSign(list)--列表中所有元素是否同号
    if list[1]>0 then
        for i=2,#list do if list[i]<=0 then return false end end
    elseif list[1]<0 then
        for i=2,#list do if list[i]>=0 then return false end end
    else
        for i=2,#list do if list[i]~=0 then return false end end
    end
    return true
end
function mymath.round(x)
    return math.floor(x+.5)
end
function mymath.pointInPolygon(px,py,poly)--检测某点是否位于凸多边形内，凸多边形必须为列表形式
    local check=true local edge=#poly
    for i=1,edge,2 do
        local ax,ay=poly[(i+2)%edge+1]-poly[i+1],poly[i]-poly[(i+1)%edge+1]--(sinx,cosx)->(cosx,-sinx)
        local bx,by=px-poly[i],py-poly[i+1]
        if ax*bx+ay*by>=0 then check=false break end
    end
    return check
end
function mymath.pointInRect(px,py,U,D,L,R)
    return px>=L and px<=R and py>=U and py<=D
end
function mymath.pointInCircle(px,py,X,Y,r)
    return (X-px)^2+(Y-py)^2<=r^2
end

function mymath.rotate3D(x,y,z,oplist,scale)--沿着作为旋转轴的坐标轴的正方向看，旋转均为顺时针
    if x^2+y^2+z^2==0 then return 0,0,0 end
    local x1,y1,z1=x,y,z
    for i=1,#oplist,2 do
        local axis,angle=oplist[i],oplist[i+1]
        local m,n=cos(angle),sin(angle)
        if axis=='x' then y1,z1=y1*m-z1*n,y1*n+z1*m
        elseif axis=='y' then z1,x1=z1*m-x1*n,z1*n+x1*m
        else x1,y1=x1*m-y1*n,x1*n+y1*m end
    end
    x1=x1*scale[1] y1=y1*scale[2] z1=z1*scale[3]
    return x1,y1,z1
end
function mymath.transpos(x,y)--将屏幕上某点转换成与画面显示匹配的坐标
    local w,h=love.graphics.getDimensions() 
    x,y=x-w/2,y-h/2
    if h/w<9/16 then x,y=x*1080/h,y*1080/h
    else x,y=x*1920/w,y*1920/w end
    return x,y
end

return mymath