local T={}
function T.attend(list,atd)
    local l=#list
    for i=1,#atd do list[l+i]=atd[i] end
end
function T.copy(list,mode,depth)
    --[[mode:'surface'只复制指针,'all'完全复制
    不写默认'surface'
    ]]
    if not mode then mode='surface' end
    if not depth then depth=1e999 end
    local clone={}
    for k,v in pairs(list) do
    if type(v)=='table' and depth>0 then
        if mode=='surface' then clone[k]=T.copy(v,mode,depth-1) end
    else clone[k]=v end
    end
    return clone
end
function T.include(a,b)--检测a中有无b元素
    if not b or not a then return false,nil end
    for k,v in pairs(a) do
        if b==v then return true,k end
    end
    return false,nil
end
function T.isEqual(a,b,depth)--两列表是否相等
    if not mode then mode='surface' end
    if not depth then depth=1e99 end
    local la,lb=0,0
    for ka,va in pairs(a) do la=la+1 end
    for kb,vb in pairs(b) do lb=lb+1 end
    if la~=lb then return false end
    for k,va in pairs(a) do
        local vb=b[k]
        if not va==vb and type(va)=='table' or type(vb)=='table' and depth>0 then
            if not isEqual(va,vb,mode,depth) then return false end
        elseif c~=d then return false end
    end
    return true
end
function T.shuffle(list)
    local key,mess={},{}
    for k,v in pairs(list) do key[#key+1]=k end
    for i=#key,1,-1 do
        table.insert(key,table.remove(key,math.random(i)))
    end
    for i=1,#key do mess[key[i]]=list[key[i]] end
    return mess
end

return T