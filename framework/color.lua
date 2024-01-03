local M=mymath

local color={
	red='ff0000',
	orange='ff7f00',
	yellow='ffff00',
	lawn='7fff00',
	green='00ff00',
	jade='00ff7f',
	cyan='00ffff',
	azure='007fff',
	blue='0000ff',
	violet='7f00ff',
	magenta='ff00ff',
	hotpink='ff007f',

	white='ffffff',
	silver='c0c0c0',
	gray='7f7f7f',
	dark='404040',
	black='0f0f0f'
}
function color.hex2num(str)
	local r=(tonumber(string.sub(str,1,2),16) or 0)/255
    local g=(tonumber(string.sub(str,3,4),16) or 0)/255
    local b=(tonumber(string.sub(str,5,6),16) or 0)/255
    local a=(tonumber(string.sub(str,7,8),16) or 255)/255 
    return {r,g,b,a}
end
function color.hsv(h,s,v,a)-- Color type, Color amount, Light
    if s<=0 then return v,v,v,a end
    h=h%6
    local c=v*s
    local x=math.abs((h-1)%2-1)*c
    if     h<1 then return v,x+v-c,v-c,a
    elseif h<2 then return x+v-c,v,v-c,a
    elseif h<3 then return v-c,v,x+v-c,a
    elseif h<4 then return v-c,x+v-c,v,a
    elseif h<5 then return x+v-c,v-c,v,a
    else            return v,v-c,x+v-c,a
    end
end
function color.find(clr)
	if type(clr)=='table' then return clr
	elseif type(clr)=='string' then return color[clr] and color[clr] or color.hex2num(clr) or error("Cannot find color you want")
	else error("color must be a string") end
end
return color