local ZNHJ={}
function ZNHJ.init(P,mino)
    mino.rule.allowPush={O=true}
    mino.rule.allowSpin={Z=true,S=true,J=true,L=true,T=true,O=true,I=true,}
end
return ZNHJ