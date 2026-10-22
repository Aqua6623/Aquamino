local LP=love.physics
local setColor,setLineWidth,setShader=gc.setColor,gc.setLineWidth,gc.setShader
local circle,arc,centerRect,poly,line,draw=gc.circle,gc.arc,gc.centerRect,gc.polygon,gc.line,gc.draw
local printf=gc.printf

local gb={}
local contactList={}
local endContactList={}
local contactSolveList={}

local function beginContact(fa,fb,coll)
    if (fa:getUserData() and fa:getUserData().onCollide) or (fb:getUserData() and fb:getUserData().onCollide) then ins(contactList,coll) end
end
local function endContact(fa,fb,coll)
    if (fa:getUserData() and fa:getUserData().afterCollide) or (fb:getUserData() and fb:getUserData().afterCollide) then ins(endContactList,fa) ins(endContactList,fb) end
end
local function preSolve(fa,fb,coll)
    if (fa:getUserData() and fa:getUserData().onCollideSolve) or (fb:getUserData() and fb:getUserData().onCollideSolve) then ins(contactSolveList,coll) end
end
local function postSolve(fa,fb,coll,normalImpulse,tangentImpulse)

end

local function die(this)
    table.insert(gb.dieList,this)
end

local u,ud,v,hp,liveShape
local tud,oud
local ux,uy

local teamList={'L','R'}
local LColorH={10,40}
local RColorH={210,165}

local BPM=128

local cannonType={'normal','bomber','shield','pierce'}
local cannonIcon={}
for k,v in pairs(cannonType) do
    cannonIcon[v]=gc.newImage('minigame/square/pic/icon_'..v..'.png')
end
local entityPic={
    normal={},
    upgrade={},
}
for k,v in pairs(cannonType) do
    entityPic.normal[v]=gc.newImage('minigame/square/pic/entity_'..v..'.png')
    --entityPic.normal[v]:setFilter('nearest')
    entityPic.upgrade[v]=gc.newImage('minigame/square/pic/entity_'..v..'2.png')
    --entityPic.upgrade[v]:setFilter('nearest')
end

local base=gc.newImage('minigame/square/pic/base.png')
local square=gc.newImage('minigame/square/pic/square.png')
local garbage=gc.newImage('minigame/square/pic/garbage.png')

--[[
分类设定：
1 - 指令区、墙壁
2 - 红塔
3 - 蓝塔
4 - 红弹
5 - 蓝弹

红塔屏蔽红弹 蓝塔屏蔽蓝弹 指令区屏蔽红弹蓝弹 全部炮弹互相屏蔽 其余不限
]]
local cannonShape,marbleShape,atkObsShape
local bulletShape,miniBulletShape,bombShape,miniBombShape,arrowShape

local function cmdMarbleSummon(team,x,y,color)
    local mb={
        body=LP.newBody(gb.world,x or (690*(team=='L' and -1 or 1)),y or -430,'dynamic'),
        shape=marbleShape,
    }
    mb.fixture=LP.newFixture(mb.body,mb.shape,1)
    mb.fixture:setRestitution(.8)
    mb.fixture:setFriction(0)
    mb.fixture:setUserData({team=team,color=color or 0,HP=0})
    mb.body:setLinearVelocity(400*(rand()-.5),0)

    mb.fixture:setMask(2,3,4,5)
    ins(gb.cmdMarble[team],mb)
end
local function atkMarbleSummon(team)
    local mb={
        body=LP.newBody(gb.world,((810+rand()*5)*(team=='L' and -1 or 1)),440,'dynamic'),
        shape=marbleShape,
    }
    mb.fixture=LP.newFixture(mb.body,mb.shape,1)
    mb.fixture:setRestitution(.8)
    mb.fixture:setFriction(0)

    mb.fixture:setMask(2,3,4,5)
    ins(gb.atkMarble[team],mb)
end
local function cannonDeploy(team,x,color,type,HP)
    if x<1 or x>8 then return end
    local list=gb.cannonField[team][x]
    if #list<10 and (#list==0 or list[#list].h<10) then
        local s=team=='L' and -1 or 1
        local newCannon={
            body=LP.newBody(gb.world,s*(570-60*x),-380,'static'),
            shape=cannonShape,
        }
        newCannon.fixture=LP.newFixture(newCannon.body,newCannon.shape,1)
        newCannon.fixture:setUserData({cannon=true,HP=(type=='shield' and 50 or 100)*HP,MaxHP=(type=='shield' and 50 or 100)*HP})

        if team=='L' then
            newCannon.fixture:setCategory(2)
            newCannon.fixture:setMask(4)
        else
            newCannon.fixture:setCategory(3)
            newCannon.fixture:setMask(5)
        end
        ins(gb.cannonField[team][x],{h=11,c=color,type=type,entity=newCannon,ammo=0,ammoT=.25*60/BPM,ammoTMax=.25*60/BPM,animT=.25,animTMax=.25})
    end
end
local function garbageDeploy(team,x)
    if x<1 or x>8 then return end
    local list=gb.cannonField[team][x]
    if #list<10 and (#list==0 or list[#list].h<10) then
        local s=team=='L' and -1 or 1
        local newCannon={
            body=LP.newBody(gb.world,s*(570-60*x),-380,'static'),
            shape=cannonShape,
        }
        newCannon.fixture=LP.newFixture(newCannon.body,newCannon.shape,1)
        newCannon.fixture:setUserData({cannon=true,HP=800,MaxHP=800})

        if team=='L' then
            newCannon.fixture:setCategory(3)
            newCannon.fixture:setMask(5)
        else
            newCannon.fixture:setCategory(2)
            newCannon.fixture:setMask(4)
        end

        ins(gb.cannonField[team][x],{h=11,c=-1,type='garbage',entity=newCannon,animT=.25,animTMax=.25})
    end
end

local function isInSquare(team,x,y)
    local s=false
    for o=0,3 do
        local m,n=math.floor(o/2),o%2
        if (gb.squareList[team][x-m] and gb.squareList[team][x-m][y-n] and gb.squareList[team][x-m][y-n].t>0) then s=true break end
    end
    return s
end
local function shuffleColor(team)
    local list=gb.cannonField[team]
    for i=1,8 do  for j=1,#list[i] do
        if not isInSquare(team,i,j) and list[i][j].c~=-1 then
            list[i][j].c=rand(2)
            list[i][j].animT=0
        end
    end  end
end
local function getAngle(h)
    return math.pi/8*cos(gb.time/2%2*math.pi)+(h-5.5)*math.pi/36
end
local function getUpgradeBomberAngle()
    return gb.time*BPM/240%2*math.pi
end

local function bulletSummon(team,x,y,angle,color)
    local vx,vy=cos(angle),sin(angle)
    local bl={
        body=LP.newBody(gb.world,x+30*vx*(team=='L' and 1 or -1),y+30*vy,'dynamic'),
        shape=bulletShape,
        color=color,
    }
    bl.fixture=LP.newFixture(bl.body,bl.shape,1)
    bl.fixture:setUserData({
        onCollide=function (this,other)
            oud=other:getUserData()
            if oud then
                if oud.base then
                    gb.targetHP[oud.base]=gb.targetHP[oud.base]-4
                elseif oud.HP then
                    oud.HP=oud.HP-20
                end
            end
            die(this)
        end
    })

    bl.body:setLinearVelocity(800*vx*(team=='L' and 1 or -1),800*vy)

    bl.fixture:setCategory(team=='L' and 4 or 5)
    bl.fixture:setMask(4,5)
    ins(gb.bullet[team],bl)
end
local function miniBulletSummon(team,x,y,angle,color)
    local vx,vy=cos(angle),sin(angle)
    for i=-1,1,2 do
        local bl={
            body=LP.newBody(gb.world,x+(20*vx-13*i*vy)*(team=='L' and 1 or -1),y+(13*i*vx+20*vy),'dynamic'),
            shape=miniBulletShape,
            color=color,
        }
        bl.fixture=LP.newFixture(bl.body,bl.shape,1)
        bl.fixture:setUserData({
            onCollide=function (this,other)
                oud=other:getUserData()
                if oud then
                    if oud.base then
                        gb.targetHP[oud.base]=gb.targetHP[oud.base]-4
                    elseif oud.HP then
                        oud.HP=oud.HP-20
                    end
                end
                die(this)
            end
        })

        bl.body:setLinearVelocity(800*vx*(team=='L' and 1 or -1),800*vy)

        bl.fixture:setCategory(team=='L' and 4 or 5)
        bl.fixture:setMask(4,5)
        ins(gb.bullet[team],bl)
    end
end
local function bombSummon(team,x,y,angle,color)
    local vx,vy=cos(angle),sin(angle)
    local bl={
        body=LP.newBody(gb.world,x+30*vx*(team=='L' and 1 or -1),y+30*vy,'dynamic'),
        shape=LP.newCircleShape(16),
        color=color,
    }
    bl.fixture=LP.newFixture(bl.body,bl.shape,1)
    bl.fixture:setSensor(true)
    bl.fixture:setUserData({
        initRadius=16,
        scaleSpeed=640,
        triggered=false,
        triggerTime=0,
        liveTime=.25,
        damage=.625,
        collideList={},
        onCollide=function (this,other)
            tud=this:getUserData()
            tud.triggered=true
            local body=this:getBody()
            body:setLinearVelocity(0,0)
            body:setAngularVelocity(0)
            body:setGravityScale(0)

            oud=other:getUserData()
            if oud and oud.cannon then tud.collideList[other]=true end
        end,
        afterCollide=function (this,other)
            tud.collideList[other]=nil
        end
    })

    bl.body:setLinearVelocity(600*vx*(team=='L' and 1 or -1),600*vy)
    bl.body:setAngularVelocity((team=='L' and 8 or -8))


    bl.fixture:setCategory(team=='L' and 4 or 5)
    bl.fixture:setMask(4,5)
    ins(gb.bomb[team],bl)
end
local function miniBombSummon(team,x,y,angle,color)
    for i=0,7 do
        local vx,vy=cos(angle+i*math.pi/4),sin(angle+i*math.pi/4)
        local bl={
            body=LP.newBody(gb.world,x+50*vx*(team=='L' and 1 or -1),y+50*vy,'dynamic'),
            shape=LP.newCircleShape(12),
            color=color,
        }
        bl.fixture=LP.newFixture(bl.body,bl.shape,1)
        bl.fixture:setSensor(true)
        bl.fixture:setUserData({
            initRadius=12,
            scaleSpeed=480,
            triggered=false,
            triggerTime=0,
            liveTime=.25,
            damage=.625,
            collideList={},
            onCollide=function (this,other)
                tud=this:getUserData()
                tud.triggered=true
                local body=this:getBody()
                body:setLinearVelocity(0,0)
                body:setAngularVelocity(0)
                body:setGravityScale(0)

                oud=other:getUserData()
                if oud and oud.cannon then tud.collideList[other]=true end
            end,
            afterCollide=function (this,other)
                tud=this:getUserData()
                tud.collideList[other]=nil
            end
        })

        bl.body:setLinearVelocity(600*vx*(team=='L' and 1 or -1),600*vy)
        bl.body:setAngularVelocity((team=='L' and 8 or -8))


        bl.fixture:setCategory(team=='L' and 4 or 5)
        bl.fixture:setMask(4,5)
        ins(gb.bomb[team],bl)
    end
end
local function arrowSummon(team,x,y,angle,color,ug)
    local vx,vy=cos(angle),sin(angle)
    local bl={
        body=LP.newBody(gb.world,x+45*vx*(team=='L' and 1 or -1),y+45*vy,'dynamic'),
        shape=LP.newCircleShape(5),
        color=color,
    }
    bl.fixture=LP.newFixture(bl.body,bl.shape,1)
    bl.fixture:setSensor(true)
    bl.fixture:setUserData({
        upgraded=ug,
        damage=ug and 6 or 3,
        collideList={},
        onCollide=function (this,other)
            tud=this:getUserData()

            oud=other:getUserData()
            if oud and oud.cannon then tud.collideList[other]=true end
        end,
        afterCollide=function (this,other)
            tud=this:getUserData()
            tud.collideList[other]=nil
        end
    })

    bl.body:setGravityScale(0)
    bl.body:setLinearVelocity(960*vx*(team=='L' and 1 or -1),960*vy)
    bl.body:setAngle((team=='L' and angle or math.pi-angle))

    bl.fixture:setCategory(team=='L' and 4 or 5)
    bl.fixture:setMask(4,5)
    ins(gb.arrow[team],bl)
end
local function getCannonCount(team)
    local count=0
    for i=1,8 do
        for j=1,#gb.cannonField[team][i] do
            if gb.cannonField[team][i][j].type~='garbage' then count=count+1 end
        end
    end
    return count
end
local function getWeightedCannonCount(team)
    local count=0
    for i=1,8 do
        for j=1,#gb.cannonField[team][i] do
            if gb.cannonField[team][i][j].type~='garbage' then
                ud=gb.cannonField[team][i][j].entity.fixture:getUserData()
                count=count+1
                if isInSquare(team,i,j) then count=count+1.5 end
            else
                count=count-.5
            end
        end
    end
    return count
end
local function changeCmdColor()
    --local cList={1,1,2,2}
    for i=1,4 do
        --gb.cmdColorType[i]=rem(cList,rand(#cList))
        gb.cmdColorType[i]=rand(2)
    end
end

function gb.init()
    --拟真运行状态
    gb.sim=false
    gb.readyTime=3
    gb.time=0
    gb.beat=0
    gb.updateTimer=0

    gb.dieList={}
    --初始化世界
    gb.world=LP.newWorld(0,480) gb.world:setSleepingAllowed(false)
    gb.world:setCallbacks(beginContact,endContact,preSolve,postSolve)
    LP.setMeter(20)

    cannonShape=LP.newRectangleShape(60,60)
    marbleShape=LP.newCircleShape(9.5)
    atkObsShape=LP.newRectangleShape(10,10)

    bulletShape=LP.newCircleShape(8)
    miniBulletShape=LP.newCircleShape(4)
    --边界
    gb.edge={
    }
    for i=1,#gb.edge do
        gb.edge[i].fixture=LP.newFixture(gb.edge[i].body,gb.edge[i].shape,1)
        gb.edge[i].fixture:setFriction(0)
        gb.edge[i].fixture:setRestitution(.5)
    end
    --分割区域的障碍
    gb.obs={
        [1]={
            body=LP.newBody(gb.world,0,255,'static'),
            shape=LP.newRectangleShape(1600,10),
        },
        [2]={
            body=LP.newBody(gb.world,0,350,'static'),
            shape=LP.newRectangleShape(20,200),
        },
        [3]={
            body=LP.newBody(gb.world,-585,275,'static'),
            shape=LP.newRectangleShape(10,30),
        },
        [4]={
            body=LP.newBody(gb.world, 585,275,'static'),
            shape=LP.newRectangleShape(10,30),
        },
        [5]={
            body=LP.newBody(gb.world,0,445,'static'),
            shape=LP.newRectangleShape(2000,10),
        },
        [6]={
            body=LP.newBody(gb.world, 795,-15,'static'),
            shape=LP.newRectangleShape(10,870),
        },
        [7]={
            body=LP.newBody(gb.world,-795,-15,'static'),
            shape=LP.newRectangleShape(10,870),
        },
        [8]={
            body=LP.newBody(gb.world,-730,300,'static'),
            shape=LP.newRectangleShape(140,20),
        },
        [9]={
            body=LP.newBody(gb.world, 730,300,'static'),
            shape=LP.newRectangleShape(140,20),
        },
        [10]={
            body=LP.newBody(gb.world,-565,-1250,'static'),
            shape=LP.newRectangleShape(50,3000),
        },
        [11]={
            body=LP.newBody(gb.world, 565,-1250,'static'),
            shape=LP.newRectangleShape(50,3000),
        },
        [12]={
            body=LP.newBody(gb.world,-690,-445,'static'),
            shape=LP.newRectangleShape(200,10),
        },
        [13]={
            body=LP.newBody(gb.world, 690,-445,'static'),
            shape=LP.newRectangleShape(200,10),
        },
        [14]={
            body=LP.newBody(gb.world,-740,415,'static'),
            shape=LP.newRectangleShape(160,10),
        },
        [15]={
            body=LP.newBody(gb.world, 740,415,'static'),
            shape=LP.newRectangleShape(160,10),
        },
        [16]={
            body=LP.newBody(gb.world,-665,385,'static'),
            shape=LP.newRectangleShape(10,50),
        },
        [17]={
            body=LP.newBody(gb.world, 665,385,'static'),
            shape=LP.newRectangleShape(10,50),
        },
    }
    for i=1,#gb.obs do
        gb.obs[i].fixture=LP.newFixture(gb.obs[i].body,gb.obs[i].shape,1)
        gb.obs[i].fixture:setFriction(0)
        gb.obs[i].fixture:setRestitution(.5)
    end
    --基地
    gb.base={
        L={
            body=LP.newBody(gb.world,-565,-50,'static'),
            shape=LP.newRectangleShape(50,600),
        },
        R={
            body=LP.newBody(gb.world, 565,-50,'static'),
            shape=LP.newRectangleShape(50,600),
        },
    }
    gb.base.L.fixture=LP.newFixture(gb.base.L.body,gb.base.L.shape,1)
    gb.base.R.fixture=LP.newFixture(gb.base.R.body,gb.base.R.shape,1)
    gb.base.L.fixture:setUserData({base='L',cannon=true})
    gb.base.R.fixture:setUserData({base='R',cannon=true})
    gb.base.L.fixture:setCategory(2)
    gb.base.L.fixture:setMask(1,4)
    gb.base.R.fixture:setCategory(3)
    gb.base.R.fixture:setMask(1,5)
    --看不见的攻击小球加速板
    gb.conveyor={}
    gb.conveyor[1]={
        body=LP.newBody(gb.world,-740,445,'static'),
        shape=LP.newRectangleShape(160,10),
    }
    gb.conveyor[1].fixture=LP.newFixture(gb.conveyor[1].body,gb.conveyor[1].shape,1)
    gb.conveyor[1].fixture:setUserData({
        onCollideSolve=function (this,other)
            other:getBody():setLinearVelocity(240,0)
        end
    })
    gb.conveyor[1].fixture:setMask(4,5)
    gb.conveyor[2]={
        body=LP.newBody(gb.world, 740,445,'static'),
        shape=LP.newRectangleShape(160,10),
    }
    gb.conveyor[2].fixture=LP.newFixture(gb.conveyor[2].body,gb.conveyor[2].shape,1)
    gb.conveyor[2].fixture:setUserData({
        onCollideSolve=function (this,other)
            other:getBody():setLinearVelocity(-240,0)
        end
    })
    gb.conveyor[2].fixture:setMask(4,5)
    --抬升小球的障碍物
    gb.atkObs={}
    for i=0,1 do
        for j=0,(i%2==0 and 16 or 15) do
            for k=-1,1,2 do
                local obs={
                    body=LP.newBody(gb.world,(655-40*j-20*(i%2))*k,445+80*i,'kinematic'),
                    shape=atkObsShape,
                }
                obs.fixture=LP.newFixture(obs.body,obs.shape,1)
                obs.body:setLinearVelocity(0,-50)
                gb.atkObs[#gb.atkObs+1]=obs
            end
        end
    end
    --逐渐往中间缩的攻击球挡板
    gb.marginObs={}
    for k=-1,1,2 do
        local obs={
            body=LP.newBody(gb.world,500*k,375,'kinematic'),
            shape=LP.newRectangleShape(20,130),
        }
        obs.fixture=LP.newFixture(obs.body,obs.shape,1)
        obs.body:setLinearVelocity(-2.5*k,0)
        gb.marginObs[k]=obs
    end
    --攻击倍率
    gb.atkMult={
        L={},
        R={}
    }
    for i=0,3 do
        gb.atkMult.L[i+1]={
            body=LP.newBody(gb.world,-585+150*i,300,'static'),
            shape=LP.newRectangleShape(150,20),
        }
        gb.atkMult.L[i+1].fixture=LP.newFixture(gb.atkMult.L[i+1].body,gb.atkMult.L[i+1].shape,1)
        gb.atkMult.L[i+1].fixture:setUserData({
            onCollide=function (this,other)
                ins(gb.atkCmdPar.L,{col=gb.cmdPos,mult=i+1,t=0})
                die(other)
                for j=1,#gb.cannonField.L[gb.cmdPos] do
                    u=gb.cannonField.L[gb.cmdPos][j]
                    if u.ammo then u.ammo=u.ammo+i+1 end
                end
            end
        })
        gb.atkMult.L[i+1].fixture:setMask(4,5)
        gb.atkMult.R[i+1]={
            body=LP.newBody(gb.world, 585-150*i,300,'static'),
            shape=LP.newRectangleShape(150,20),
        }
        gb.atkMult.R[i+1].fixture=LP.newFixture(gb.atkMult.R[i+1].body,gb.atkMult.R[i+1].shape,1)
        gb.atkMult.R[i+1].fixture:setUserData({
            onCollide=function (this,other)
                ins(gb.atkCmdPar.R,{col=gb.cmdPos,mult=i+1,t=0})
                die(other)
                for j=1,#gb.cannonField.R[gb.cmdPos] do
                    u=gb.cannonField.R[gb.cmdPos][j]
                    if u.ammo then u.ammo=u.ammo+i+1 end
                end
            end
        })
        gb.atkMult.R[i+1].fixture:setMask(4,5)
    end
    --打乱
    gb.shuffle={
        L={
            body=LP.newBody(gb.world,-35,300,'static'),
            shape=LP.newRectangleShape(50,20),
        },
        R={
            body=LP.newBody(gb.world, 35,300,'static'),
            shape=LP.newRectangleShape(50,20),
        },
    }
    gb.shuffle.L.fixture=LP.newFixture(gb.shuffle.L.body,gb.shuffle.L.shape,1)
    gb.shuffle.R.fixture=LP.newFixture(gb.shuffle.R.body,gb.shuffle.R.shape,1)
    gb.shuffle.L.fixture:setMask(4,5)
    gb.shuffle.R.fixture:setMask(4,5)
    gb.shuffle.L.fixture:setUserData({
        onCollide=function (this,other)
            shuffleColor('L')
            die(other)
        end
    })
    gb.shuffle.L.fixture:setMask(4,5)
    gb.shuffle.R.fixture:setUserData({
        onCollide=function (this,other)
            shuffleColor('R')
            die(other)
        end
    })
    --垃圾干扰
    gb.garbage={
        L={},R={}
    }
    for i=0,1 do
        gb.garbage.L[i+1]={
            body=LP.newBody(gb.world,-700-60*i,400,'static'),
            shape=LP.newRectangleShape(60,20),
        }
        gb.garbage.R[i+1]={
            body=LP.newBody(gb.world, 700+60*i,400,'static'),
            shape=LP.newRectangleShape(60,20),
        }
        gb.garbage.L[i+1].fixture=LP.newFixture(gb.garbage.L[i+1].body,gb.garbage.L[i+1].shape,1)
        gb.garbage.R[i+1].fixture=LP.newFixture(gb.garbage.R[i+1].body,gb.garbage.R[i+1].shape,1)
        gb.garbage.L[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local col={1,2,3,4,5,6,7,8}
                for j=1,1+i*2 do
                    local n=rem(col,rand(#col))
                    garbageDeploy('R',n)
                    ins(gb.garbageSummonPar,{sx=-700-60*i,sy=400,fx= 570-60*n,fy=-380,c=LColorH[1],t=0})
                end
                die(other)
            end
        })
        gb.garbage.R[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local col={1,2,3,4,5,6,7,8}
                for j=1,1+i*2 do
                    local n=rem(col,rand(#col))
                    garbageDeploy('L',n)
                    ins(gb.garbageSummonPar,{sx= 700+60*i,sy=400,fx=-570+60*n,fy=-380,c=RColorH[1],t=0})
                end
                die(other)
            end
        })
        gb.garbage.L[i+1].fixture:setMask(4,5)
        gb.garbage.R[i+1].fixture:setMask(4,5)
    end

    --小球数量
    gb.cmdAmount={
        L={},R={}
    }
    for i=0,3 do
        gb.cmdAmount.L[i+1]={
            body=LP.newBody(gb.world,-765+50*i,-175,'static'),
            shape=LP.newRectangleShape(50,50),
        }
        gb.cmdAmount.R[i+1]={
            body=LP.newBody(gb.world, 765-50*i,-175,'static'),
            shape=LP.newRectangleShape(50,50),
        }
        gb.cmdAmount.L[i+1].fixture=LP.newFixture(gb.cmdAmount.L[i+1].body,gb.cmdAmount.L[i+1].shape,1)
        gb.cmdAmount.R[i+1].fixture=LP.newFixture(gb.cmdAmount.R[i+1].body,gb.cmdAmount.R[i+1].shape,1)
        gb.cmdAmount.L[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                    ud=other:getUserData()
                    for j=1,i+1 do cmdMarbleSummon('L',-690,-130,ud.color) end
                    die(other)
                end
            end
        })
        gb.cmdAmount.R[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                    ud=other:getUserData()
                    for j=1,i+1 do cmdMarbleSummon('R', 690,-130,ud.color) end
                    die(other)
                end
            end
        })
        gb.cmdAmount.L[i+1].fixture:setMask(4,5)
        gb.cmdAmount.R[i+1].fixture:setMask(4,5)
    end

    --生命倍率
    gb.cmdHP={
        L={},R={}
    }
    for i=0,3 do
        gb.cmdHP.L[i+1]={
            body=LP.newBody(gb.world,-765+50*i,25,'static'),
            shape=LP.newRectangleShape(50,50),
        }
        gb.cmdHP.R[i+1]={
            body=LP.newBody(gb.world, 765-50*i,25,'static'),
            shape=LP.newRectangleShape(50,50),
        }
        gb.cmdHP.L[i+1].fixture=LP.newFixture(gb.cmdHP.L[i+1].body,gb.cmdHP.L[i+1].shape,1)
        gb.cmdHP.R[i+1].fixture=LP.newFixture(gb.cmdHP.R[i+1].body,gb.cmdHP.R[i+1].shape,1)
        gb.cmdHP.L[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                ud=other:getUserData()
                ud.HP=i+1
                other:getBody():setLinearVelocity(400*(rand()-.5),0)
                other:getBody():setPosition(-690,70)
                end
            end
        })
        gb.cmdHP.R[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                ud=other:getUserData()
                ud.HP=i+1
                other:getBody():setLinearVelocity(400*(rand()-.5),0)
                other:getBody():setPosition(690,70)
                end
            end
        })
        gb.cmdHP.L[i+1].fixture:setMask(4,5)
        gb.cmdHP.R[i+1].fixture:setMask(4,5)
    end

    --炮塔部署
    gb.cmdDeploy={
        L={},R={}
    }
    for i=0,3 do
        gb.cmdDeploy.L[i+1]={
            body=LP.newBody(gb.world,-765+50*i,225,'static'),
            shape=LP.newRectangleShape(50,50),
        }
        gb.cmdDeploy.R[i+1]={
            body=LP.newBody(gb.world, 765-50*i,225,'static'),
            shape=LP.newRectangleShape(50,50),
        }
        gb.cmdDeploy.L[i+1].fixture=LP.newFixture(gb.cmdDeploy.L[i+1].body,gb.cmdDeploy.L[i+1].shape,1)
        gb.cmdDeploy.R[i+1].fixture=LP.newFixture(gb.cmdDeploy.R[i+1].body,gb.cmdDeploy.R[i+1].shape,1)
        gb.cmdDeploy.L[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                    ud=other:getUserData()
                    cannonDeploy('L',gb.cmdPos,ud.color,cannonType[i+1],ud.HP)
                    ins(gb.cannonSummonPar,{sx=-765+50*i,sy=225,fx=-570+60*gb.cmdPos,fy=-380,c=LColorH[ud.color],t=0})
                    die(other)
                end
            end
        })
        gb.cmdDeploy.R[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                    ud=other:getUserData()
                    cannonDeploy('R',gb.cmdPos,ud.color,cannonType[i+1],ud.HP)
                    ins(gb.cannonSummonPar,{sx= 765-50*i,sy=225,fx= 570-60*gb.cmdPos,fy=-380,c=RColorH[ud.color],t=0})
                    die(other)
                end
            end
        })
        gb.cmdDeploy.L[i+1].fixture:setMask(4,5)
        gb.cmdDeploy.R[i+1].fixture:setMask(4,5)
    end

    --颜色选择
    gb.cmdColor={
        L={},R={}
    }
    for i=0,3 do
        gb.cmdColor.L[i+1]={
            body=LP.newBody(gb.world,-765+50*i,-360,'static'),
            shape=LP.newRectangleShape(50,20),
        }
        gb.cmdColor.R[i+1]={
            body=LP.newBody(gb.world, 765-50*i,-360,'static'),
            shape=LP.newRectangleShape(50,20),
        }
        gb.cmdColor.L[i+1].fixture=LP.newFixture(gb.cmdColor.L[i+1].body,gb.cmdColor.L[i+1].shape,1)
        gb.cmdColor.R[i+1].fixture=LP.newFixture(gb.cmdColor.R[i+1].body,gb.cmdColor.R[i+1].shape,1)
        gb.cmdColor.L[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                ud=other:getUserData()
                ud.color=gb.cmdColorType[i+1]
                other:getBody():setLinearVelocity(400*(rand()-.5),0)
                other:getBody():setPosition(-690,-330)
                end
            end
        })
        gb.cmdColor.R[i+1].fixture:setUserData({
            onCollide=function (this,other)
                local tx,ty=this:getBody():getPosition()
                local ox,oy=other:getBody():getPosition()
                if oy<ty then
                ud=other:getUserData()
                ud.color=gb.cmdColorType[i+1]
                other:getBody():setLinearVelocity(400*(rand()-.5),0)
                other:getBody():setPosition(690,-330)
                end
            end
        })
        gb.cmdColor.L[i+1].fixture:setMask(4,5)
        gb.cmdColor.R[i+1].fixture:setMask(4,5)
    end
    --随时间解锁选项的障碍
    gb.timedObs={
        [1]={},[2]={},[3]={},[4]={}
    }
    gb.obsRemoveTime={60,120,200,150}
    for i=0,2 do
        local obj={
            body=LP.newBody(gb.world,-715,200-200*i,'static'),
            shape=LP.newPolygonShape(-25,0,-25,-60,25,-80,25,0),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[1],obj)
        local obj={
            body=LP.newBody(gb.world, 715,200-200*i,'static'),
            shape=LP.newPolygonShape(25,0,25,-60,-25,-80,-25,0),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[1],obj)
        local obj={
            body=LP.newBody(gb.world,-665,200-200*i,'static'),
            shape=LP.newPolygonShape(-25,0,-25,-80,25,-100,25,0),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[2],obj)
        local obj={
            body=LP.newBody(gb.world, 665,200-200*i,'static'),
            shape=LP.newPolygonShape(25,0,25,-80,-25,-100,-25,0),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[2],obj)
        local obj={
            body=LP.newBody(gb.world,-615,200-200*i,'static'),
            shape=LP.newPolygonShape(-25,0,-25,-100,25,-120,25,0),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[3],obj)
        local obj={
            body=LP.newBody(gb.world, 615,200-200*i,'static'),
            shape=LP.newPolygonShape(25,0,25,-100,-25,-120,-25,0),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[3],obj)
    end
    for i=-1,1,2 do
        local obj={
            body=LP.newBody(gb.world,725*i,335,'static'),
            shape=LP.newRectangleShape(130,50),
        }
        obj.fixture=LP.newFixture(obj.body,obj.shape,1)
        ins(gb.timedObs[4],obj)
    end
    --小刺
    local needle={
        U=LP.newPolygonShape(10,0,0,-10,-10,0),
        D=LP.newPolygonShape(10,0,0, 10,-10,0)
    }
    local fixNeedle={}
    for i=0,3 do
        fixNeedle[#fixNeedle+1]={'D',-510+150*i,310}
    end
    for i=0,2 do  for j=0,2 do
        fixNeedle[#fixNeedle+1]={'U',-740+50*i,200-200*j}
    end  end
    for i=0,2 do
        fixNeedle[#fixNeedle+1]={'U',-740+50*i,-370}
    end
        fixNeedle[#fixNeedle+1]={'U',-730,390}
    gb.fixNeedle={}
    for i=1,#fixNeedle do
        gb.fixNeedle[2*i-1]={
            body=LP.newBody(gb.world,fixNeedle[i][2],fixNeedle[i][3],'static'),
            shape=needle[fixNeedle[i][1]],
        }
        gb.fixNeedle[2*i]={
            body=LP.newBody(gb.world,-fixNeedle[i][2],fixNeedle[i][3],'static'),
            shape=needle[fixNeedle[i][1]],
        }
        gb.fixNeedle[2*i-1].fixture=LP.newFixture(gb.fixNeedle[2*i-1].body,gb.fixNeedle[2*i-1].shape,1)
        gb.fixNeedle[2*i].fixture=LP.newFixture(gb.fixNeedle[2*i].body,gb.fixNeedle[2*i].shape,1)
    end

    local circleObsShape=LP.newCircleShape(5)
    gb.circleObs={}
    for i=-1,1,2 do
        for j=0,3 do  for k=0,2 do
            local obs={
                body=LP.newBody(gb.world,i*(765-50*j),-260+200*k,'static'),
                shape=circleObsShape,
            }
            obs.fixture=LP.newFixture(obs.body,obs.shape,1)
            gb.circleObs[#gb.circleObs+1]=obs
        end  end
    end

    gb.cannonField={
        L={},R={}
    }
    gb.squareList={
        L={},R={}
    }

    for i=1,8 do
        gb.cannonField.L[i]={}
        gb.cannonField.R[i]={}
    end
    for i=1,7 do
        gb.squareList.L[i]={}
        gb.squareList.R[i]={}
        for j=1,9 do
            gb.squareList.L[i][j]={t=0,c=-1,animT=1,animTMax=1}
            gb.squareList.R[i][j]={t=0,c=-1,animT=1,animTMax=1}
        end
    end

    gb.bullet={--普通炮弹实体
        L={},R={}
    }
    gb.bomb={--炸弹实体（Sensor）
        L={},R={}
    }
    gb.arrow={--穿透箭实体（Sensor）
        L={},R={}
    }

    gb.cmdMarble={
        L={},R={}
    }
    gb.atkMarble={
        L={},R={}
    }

    --模拟参数
    gb.targetHP={L=5000,R=5000,max=5000}
    gb.targetAnimTime={L=0,R=0}
    gb.loseTimer={L=0,R=0}
    gb.cmdColorType={}
    changeCmdColor()
    gb.changeColorTimer=0
    gb.changeColorPeriod=8*60/BPM

    gb.cmdMarbleSummon={
        L={timer=4,period=4},
        R={timer=4,period=4},
    }
    gb.atkMarbleSummon={
        L={timer=0,period=4},
        R={timer=0,period=4},
    }
    gb.cmdPos=1

    gb.cannonCount={L=0,R=0}
    gb.weightedCannonCount={L=0,R=0}
    gb.crisisMeter={L=0,R=0,max=100}
    gb.crisisTime={L=0,R=0,max=15}
    gb.crisisDecreaseTime={L=0,R=0}
    --绘制
    gb.sd=gc.newShader('shader/grayscale stain.glsl')

    gb.cannonSummonPar={}
    --[1]={sx,sy,fx,fy,c,t}
    gb.garbageSummonPar={}
    --[1]={sx,sy,fx,fy,c,t}
    gb.atkCmdPar={
        L={},R={}
    }
    --[1]={col,mult,t}
    gb.cannonDiePar={}
    --[1]={x,y,team,c,t}
    gb.arrowAttackPar={}
    --[1]={x,y,ug,c,t}
    gb.healEffectPar={}
    --[1]={x,y,t}
    gb.healNumPar={}
    --[1]={x,y,heal,dmg,t}
    gb.explodePar={}
    --[1]={x,y,c,vx,vy,g,av,t}
end

function gb.keyP(k)
    if k=='space' or k=='return' then gb.sim=not gb.sim
    elseif k=='escape' then
        scene.switch({
            dest='intro',destScene=require('scene/secret/AquaMarbler'),swapT=.6,outT=.2,
            anim=function() anim.cover(.2,.4,.2,0,0,0) end
        })
    end

    --[[local n=tonumber(k)
    if n then
        garbageDeploy(love.keyboard.isDown('lshift','rshift') and 'R' or 'L',n)
    end]]
    --[[if k=='s' then
        shuffleColor(love.keyboard.isDown('lshift','rshift') and 'R' or 'L')
    end]]
end
function gb.touchP(id,x,y)
    gb.sim=not gb.sim
end
function gb.update(dt)
    if gb.sim then gb.updateTimer=gb.updateTimer+dt
        while gb.updateTimer>=1/128 do gb.gameUpdate(1/128) gb.updateTimer=gb.updateTimer-1/128 end
    end
end
local c,sq
local fa,fb
local diedCannon={L=0,R=0}
local preHP={L=0,R=0}
function gb.gameUpdate(dt)
    gb.readyTime=gb.readyTime-dt
    if gb.readyTime>0 then return end

    gb.world:update(dt,8,3) gb.time=gb.time+dt
    gb.beat=gb.time*BPM/60
    gb.cmdMarbleSummon.L.period=max(1,4-max(gb.time-30,0)/50)
    gb.cmdMarbleSummon.R.period=max(1,4-max(gb.time-30,0)/50)
    gb.atkMarbleSummon.L.period=max(1,4-max(gb.time-30,0)/50)
    gb.atkMarbleSummon.R.period=max(1,4-max(gb.time-30,0)/50)

    for k,v in pairs(preHP) do
        preHP[k]=gb.targetHP[k]
    end

    for i=#contactList,1,-1 do
        if not contactList[i]:isDestroyed() and contactList[i]:isTouching() then fa,fb=contactList[i]:getFixtures()
        if fa:getUserData() and fa:getUserData().onCollide then fa:getUserData().onCollide(fa,fb) end
        if fb:getUserData() and fb:getUserData().onCollide then fb:getUserData().onCollide(fb,fa) end
        end
        rem(contactList,i)
    end
    for i=#endContactList,1,-2 do
        fa,fb=endContactList[i],endContactList[i-1]
        if not fa:isDestroyed() and fa:getUserData() and fa:getUserData().afterCollide then fa:getUserData().afterCollide(fa,fb) end
        if not fb:isDestroyed() and fb:getUserData() and fb:getUserData().afterCollide then fb:getUserData().afterCollide(fb,fa) end
        rem(endContactList,i)
        rem(endContactList,i-1)
    end
    for i=#contactSolveList,1,-1 do
        if not contactSolveList[i]:isDestroyed() and contactSolveList[i]:isTouching() then fa,fb=contactSolveList[i]:getFixtures()
        if fa:getUserData() and fa:getUserData().onCollideSolve then fa:getUserData().onCollideSolve(fa,fb) end
        if fb:getUserData() and fb:getUserData().onCollideSolve then fb:getUserData().onCollideSolve(fb,fa) end
        end
        rem(contactSolveList,i)
    end
    for i=#gb.dieList,1,-1 do
        if not gb.dieList[i]:isDestroyed() then gb.dieList[i]:getBody():destroy() end
        gb.dieList[i]=nil
    end

    --清除已失效物件
    for k,v in pairs(gb.cmdMarble) do
        for i=#v,1,-1 do
            if v[i].body:isDestroyed() then rem(v,i) end
        end
    end
    for k,v in pairs(gb.atkMarble) do
        for i=#v,1,-1 do
            if v[i].body:isDestroyed() then rem(v,i) end
        end
    end
    for k,v in pairs(gb.bullet) do
        for i=#v,1,-1 do
            if v[i].body:isDestroyed() then rem(v,i) end
        end
    end
    --特殊：炸弹和箭矢
    for k,v in pairs(gb.bomb) do
        for i=#v,1,-1 do
            ud=v[i].fixture:getUserData()
            if ud.triggered then
                ud.triggerTime=ud.triggerTime+dt

                liveShape=v[i].fixture:getShape()
                liveShape:setRadius(ud.initRadius+ud.scaleSpeed*ud.triggerTime)
                v[i].shape=liveShape

                for k1,v1 in pairs(ud.collideList) do
                    if k1:isDestroyed() then
                        ud.collideList[k1]=nil
                    else
                        oud=k1:getUserData()
                        if oud.base then
                            gb.targetHP[oud.base]=gb.targetHP[oud.base]-ud.damage
                        else
                            oud.HP=oud.HP-ud.damage
                        end
                    end
                end
            end
            if ud.triggerTime>=ud.liveTime then v[i].body:destroy() rem(v,i) end
        end
    end
    for k,v in pairs(gb.arrow) do
        for i=#v,1,-1 do
            local atk=false
            ud=v[i].fixture:getUserData()
            for k1,v1 in pairs(ud.collideList) do
                if k1:isDestroyed() then
                    ud.collideList[k1]=nil
                else
                    oud=k1:getUserData()
                    if oud.base then
                        gb.targetHP[oud.base]=gb.targetHP[oud.base]-ud.damage/4
                    else
                        oud.HP=oud.HP-ud.damage
                    end
                    atk=true
                end
            end
            if atk then
                ins(gb.arrowAttackPar,{x=v[i].body:getX(),y=v[i].body:getY(),ug=ud.upgraded,c=(k=='L' and LColorH or RColorH)[v[i].color],t=0})
            end
            if abs(v[i].body:getX())>1200 then v[i].body:destroy() rem(v,i) end
        end
    end

    --攻击区障碍物
    for i=1,#gb.atkObs do
        u=gb.atkObs[i]
        local x,y=u.body:getPosition()
        if y<295 then u.body:setPosition(x,y+160) end
    end
    --解锁新选项
    for i=1,#gb.obsRemoveTime do
        if gb.time>=gb.obsRemoveTime[i] then
            for j=1,#gb.timedObs[i] do
                gb.timedObs[i][j].body:setPosition(0,2000)
            end
        end
    end
    --生成小球
    for k,v in pairs(gb.cmdMarbleSummon) do
        if gb.targetHP[k]>0 then
        v.timer=v.timer+dt
            if v.timer>=v.period then
                cmdMarbleSummon(k)
                v.timer=v.timer-v.period*(gb.crisisTime[k]>0 and 1/3 or 1)
            end
        end
    end
    for k,v in pairs(gb.atkMarbleSummon) do
        if gb.targetHP[k]>0 then
            v.timer=v.timer+dt
            if v.timer>=v.period then
                atkMarbleSummon(k)
                v.timer=v.timer-v.period*(gb.crisisTime[k]>0 and .75 or 1)
            end
        end
    end
    --炮塔更新
    for k,v in pairs(gb.cannonField) do
        local s=k=='L' and -1 or 1
        for i=1,8 do  for j=#v[i],1,-1 do
            local b=v[i][j]
            local targetH=max(j,v[i][j-1] and v[i][j-1].h+1 or 0)
            if b.h>targetH then b.h=max(b.h-dt*(b.c==-1 and 2.5 or 10),targetH) b.entity.body:setPosition(s*(570-60*i),280-60*b.h) end
            b.animT=min(b.animT+dt,b.animTMax)

            if b.c~=-1 then
                b.ammoT=b.ammoT+dt
                if b.ammoT>b.ammoTMax then
                    if b.ammo>0 then
                        if b.type=='shield' then
                            local ug=isInSquare(k,i,j)
                            local heal=(ug and 40 or 20)*b.ammo
                            for m=-1,1 do
                                if v[i+m] then
                                    for n=1,#v[i+m] do
                                        if v[i+m][n] and abs(b.h-v[i+m][n].h)<=1.5 then
                                            ud=v[i+m][n].entity.fixture:getUserData()
                                            if v[i+m][n].type=='garbage' then
                                                ud.HP=ud.HP-heal
                                                ins(gb.healNumPar,{x=s*(570-60*(i+m)),y=260-60*v[i+m][n].h,heal=heal,dmg=true,t=0})
                                            else
                                                ud.HP=min(ud.HP+heal,ud.MaxHP)
                                                ins(gb.healNumPar,{x=s*(570-60*(i+m)),y=260-60*v[i+m][n].h,heal=heal,dmg=false,t=0})
                                            end
                                        end
                                    end
                                end
                            end
                            ins(gb.healEffectPar,{x=s*(570-60*i),y=280-60*b.h,t=0})
                            b.ammo=0
                        elseif b.type=='normal' then
                            b.ammo=b.ammo-1
                            bulletSummon(k,s*(570-60*i),280-60*b.h,getAngle(b.h),b.c)
                            if isInSquare(k,i,j) then miniBulletSummon(k,s*(570-60*i),280-60*b.h,getAngle(b.h),b.c) end
                        elseif b.type=='bomber' then
                            b.ammo=b.ammo-1
                            if isInSquare(k,i,j) then
                                miniBombSummon(k,s*(570-60*i),280-60*b.h,getUpgradeBomberAngle(b.h),b.c)
                            else
                                bombSummon(k,s*(570-60*i),280-60*b.h,getAngle(b.h),b.c)
                            end
                        elseif b.type=='pierce' then
                            b.ammo=b.ammo-1
                            arrowSummon(k,s*(570-60*i),280-60*b.h,getAngle(b.h),b.c,isInSquare(k,i,j))
                        end
                        b.ammoT=b.ammoT-b.ammoTMax
                    else
                        b.ammoT=b.ammoTMax
                    end
                end
            end
        end  end

        for i=1,7 do  for j=1,9 do
            c=-1
            for o=0,3 do
                local x,y=math.floor(o/2),o%2
                if v[i+x][j+y] then c=max(c,v[i+x][j+y].c) end
            end
            sq=c~=-1
            for o=0,3 do
                local x,y=math.floor(o/2),o%2
                if not (v[i+x][j+y] and (v[i+x][j+y].c==c or v[i+x][j+y].c==0) and v[i+x][j+y].h==j+y) then sq=false break end
            end
            if sq then
                gb.squareList[k][i][j].t=min(gb.squareList[k][i][j].t+dt/.25,1)
                gb.squareList[k][i][j].c=c
            else
                gb.squareList[k][i][j].t=0
            end
        end  end
    end
    for k,v in pairs(gb.cannonField) do
        diedCannon[k]=0
        local s=k=='L' and -1 or 1
        for i=1,8 do  for j=#v[i],1,-1 do
            local b=v[i][j]
            ud=b.entity.fixture:getUserData()
            if ud.HP<=0 then
                ins(gb.cannonDiePar,{x=s*(570-60*i),y=280-60*b.h,team=k,c=b.c,t=0})
                if b.type~='garbage' then diedCannon[k]=diedCannon[k]+1 end
                b.entity.body:destroy()
                rem(v[i],j)
            end
        end  end
    end
    --障碍更新
    for k,u in pairs(gb.marginObs) do
        if u.body:getX()*-k>0 then
            u.body:setPosition(0,2000)
            u.body:setLinearVelocity(0,0)
        end
    end
    --参数更新
    gb.cmdPos=floor(gb.time*BPM/60%8)+1

    gb.changeColorTimer=gb.changeColorTimer+dt
    if gb.changeColorTimer>=gb.changeColorPeriod then
        gb.changeColorTimer=gb.changeColorTimer-gb.changeColorPeriod
        changeCmdColor()
    end

    gb.cannonCount.L=getCannonCount('L')
    gb.cannonCount.R=getCannonCount('R')
    gb.weightedCannonCount.L=getWeightedCannonCount('L')
    gb.weightedCannonCount.R=getWeightedCannonCount('R')
    if gb.weightedCannonCount.L<gb.weightedCannonCount.R then--左侧炮塔少，偏袒左侧
        gb.crisisMeter.L=gb.crisisMeter.L+.075*(diedCannon.L)*(.75+.25*(gb.weightedCannonCount.R-gb.weightedCannonCount.L))
        if diedCannon.L>0 then gb.crisisDecreaseTime.L=0 end
    elseif gb.weightedCannonCount.R<gb.weightedCannonCount.L then--右侧炮塔少，偏袒右侧
        gb.crisisMeter.R=gb.crisisMeter.R+.075*diedCannon.R*(.75+.25*(gb.weightedCannonCount.L-gb.weightedCannonCount.R))
        if diedCannon.R>0 then gb.crisisDecreaseTime.R=0 end
    end
    for k,v in pairs(preHP) do
        local diff=preHP[k]-gb.targetHP[k]
        if diff>0 and (gb.weightedCannonCount[k=='L' and 'R' or 'L']-gb.weightedCannonCount[k])>0 then
            gb.crisisMeter[k]=gb.crisisMeter[k]+diff*.075*max(1,.75+.25*(gb.weightedCannonCount[k=='L' and 'R' or 'L']-gb.weightedCannonCount[k]))
            gb.crisisDecreaseTime[k]=0
        end
    end

    for k,v in pairs(gb.crisisDecreaseTime) do
        gb.crisisDecreaseTime[k]=gb.crisisDecreaseTime[k]+dt
        if gb.crisisDecreaseTime[k]>=1.5 then
            gb.crisisMeter[k]=max(gb.crisisMeter[k]-10*dt,0)
        end
    end

    for k,v in pairs(teamList) do
        if gb.crisisMeter[v]>=gb.crisisMeter.max and gb.crisisTime[v]<=0 then
            gb.crisisTime[v]=gb.crisisTime.max

        end
        if gb.crisisTime[v]>0 then
            gb.crisisDecreaseTime[v]=999
            gb.crisisTime[v]=max(gb.crisisTime[v]-dt,0)
            if gb.crisisTime[v]==0 then
                gb.crisisMeter[v]=0
            end
        end
    end

    if gb.targetHP.L<=0 then
        for i=#gb.cmdMarble.L,1,-1 do
            gb.cmdMarble.L[i].body:destroy()
            rem(gb.cmdMarble.L,i)
        end
        for i=#gb.atkMarble.L,1,-1 do
            gb.atkMarble.L[i].body:destroy()
            rem(gb.atkMarble.L,i)
        end
        if gb.loseTimer.L==0 then
            for i=-577.5,-552.5,25 do
                for j=-337.5,237.5,35 do
                    for k=1,2 do
                    local angle=rand()*2*math.pi
                    ins(gb.explodePar,{x=i,y=j,vx=(150+50*rand())*cos(angle),vy=(150+50*rand())*sin(angle),g=600,c=LColorH[1],av=10*(rand()-.5),t=0})
                    end
                end
            end
            for i=1,8 do  for j=#gb.cannonField.L[i],1,-1 do
            local b=gb.cannonField.L[i][j]
                ins(gb.cannonDiePar,{x=-570+60*i,y=280-60*b.h,team='L',c=b.c,t=0})
                b.entity.body:destroy()
                rem(gb.cannonField.L[i],j)
            end  end
            gb.base.L.body:setPosition(0,2000)
        end
        gb.loseTimer.L=gb.loseTimer.L+dt
    end
    if gb.targetHP.R<=0 then
        for i=#gb.cmdMarble.R,1,-1 do
            gb.cmdMarble.R[i].body:destroy()
            rem(gb.cmdMarble.R,i)
        end
        for i=#gb.atkMarble.R,1,-1 do
            gb.atkMarble.R[i].body:destroy()
            rem(gb.atkMarble.R,i)
        end
        if gb.loseTimer.R==0 then
            for i=577.5,552.5,-25 do
                for j=-337.5,237.5,35 do
                    for k=1,2 do
                    local angle=rand()*2*math.pi
                    ins(gb.explodePar,{x=i,y=j,vx=(150+50*rand())*cos(angle),vy=(150+50*rand())*sin(angle),g=600,c=RColorH[1],av=10*(rand()-.5),t=0})
                    end
                end
            end
            for i=1,8 do  for j=#gb.cannonField.R[i],1,-1 do
            local b=gb.cannonField.R[i][j]
                ins(gb.cannonDiePar,{x= 570-60*i,y=280-60*b.h,team='R',c=b.c,t=0})
                b.entity.body:destroy()
                rem(gb.cannonField.R[i],j)
            end  end
            gb.base.R.body:setPosition(0,2000)
        end
        gb.loseTimer.R=gb.loseTimer.R+dt
    end
    --绘制更新
    for i=#gb.cannonSummonPar,1,-1 do
        u=gb.cannonSummonPar[i]
        u.t=u.t+dt*4
        if u.t>=1 then rem(gb.cannonSummonPar,i) end
    end
    for i=#gb.garbageSummonPar,1,-1 do
        u=gb.garbageSummonPar[i]
        u.t=u.t+dt*4
        if u.t>=1 then rem(gb.garbageSummonPar,i) end
    end
    for i=#gb.cannonDiePar,1,-1 do
        u=gb.cannonDiePar[i]
        u.t=u.t+dt*2.5
        if u.t>=1 then rem(gb.cannonDiePar,i) end
    end
    for i=#gb.arrowAttackPar,1,-1 do
        u=gb.arrowAttackPar[i]
        u.t=u.t+dt*5
        if u.t>=1 then rem(gb.arrowAttackPar,i) end
    end
    for i=#gb.healNumPar,1,-1 do
        u=gb.healNumPar[i]
        u.t=u.t+dt*1.25
        if u.t>=1 then rem(gb.healNumPar,i) end
    end
    for i=#gb.healEffectPar,1,-1 do
        u=gb.healEffectPar[i]
        u.t=u.t+dt*1.25
        if u.t>=1 then rem(gb.healEffectPar,i) end
    end
    for i=#gb.atkCmdPar.L,1,-1 do
        u=gb.atkCmdPar.L[i]
        u.t=u.t+dt*5
        if u.t>=1 then rem(gb.atkCmdPar.L,i) end
    end
    for i=#gb.atkCmdPar.R,1,-1 do
        u=gb.atkCmdPar.R[i]
        u.t=u.t+dt*5
        if u.t>=1 then rem(gb.atkCmdPar.R,i) end
    end
    if preHP.L-gb.targetHP.L>0 then gb.targetAnimTime.L=1 end
    if preHP.R-gb.targetHP.R>0 then gb.targetAnimTime.R=1 end
    gb.targetAnimTime.L=max(gb.targetAnimTime.L-dt*2.5,0)
    gb.targetAnimTime.R=max(gb.targetAnimTime.R-dt*2.5,0)

    for i=#gb.explodePar,1,-1 do
        u=gb.explodePar[i]
        u.t=u.t+dt
        u.vy=u.vy+u.g*dt
        u.x=u.x+u.vx*dt
        u.y=u.y+u.vy*dt
        --if u.t>=1 then rem(gb.explodePar,i) end
    end
end

local s
local bgpic=gc.newImage('pic/AquaMarbler/AquaMarbler.png') --1950x450
local arrowPic={
    normal=gc.newImage('minigame/square/pic/arrow.png'),
    upgrade=gc.newImage('minigame/square/pic/arrow2.png'),
}

local cannonDraw={
    normal=function(team,x,y,h,color,upgrade)
        s=team=='L' and 1 or -1
        c=team=='L' and LColorH or RColorH
        setColor(COLOR.hsl(c[color]/60,1,.5625))
        draw(entityPic[upgrade and 'upgrade' or 'normal'].normal,x,y,getAngle(h)*s,.5*s,.5,60,60)
    end,
    shield=function(team,x,y,h,color,upgrade)
        s=team=='L' and 1 or -1
        setColor(1,1,1)
        draw(entityPic[upgrade and 'upgrade' or 'normal'].shield,x,y,0,.5*s,.5,60,60)
    end,
    bomber=function(team,x,y,h,color,upgrade)
        s=team=='L' and 1 or -1
        c=team=='L' and LColorH or RColorH
        local a=getAngle(h)
        if upgrade then
            setColor(COLOR.hsl(c[color]/60,1,.6))
            draw(entityPic.upgrade.bomber,x,y,getUpgradeBomberAngle()*s,.5*s,.5,100,100)
            setColor(1,1,1)
            circle('fill',x,y,15,4)
            centerRect('fill',x,y,15*2^.5)
        else
            setColor(COLOR.hsl(c[color]/60,1,.6))
            draw(entityPic.normal.bomber,x,y,a*s,.5*s,.5,60,60)
            setColor(1,1,1)
            circle('fill',x,y,12,4)
            centerRect('fill',x,y,12*2^.5)
        end
    end,
    pierce=function(team,x,y,h,color,upgrade)
        s=team=='L' and 1 or -1
        c=team=='L' and LColorH or RColorH
        setColor(COLOR.hsl(c[color]/60,1,.75))
        circle('fill',x,y,20,4)
        if upgrade then
            poly('fill',x+18,y+10,x+10,y+18,x+25,y+25)
            poly('fill',x-18,y+10,x-10,y+18,x-25,y+25)
            poly('fill',x-18,y-10,x-10,y-18,x-25,y-25)
            poly('fill',x+18,y-10,x+10,y-18,x+25,y-25)
        end
        setColor(COLOR.hsl(c[color]/60,1,.9))
        draw(arrowPic[upgrade and 'upgrade' or 'normal'],x,y,getAngle(h)*s,.5*s,.5,120,20)
        setColor(COLOR.hsl(c[color]/60,1,.4))
        circle('fill',x,y,10,4)
    end,
}
function gb.draw()
    gc.clear(0,0,0)
    setColor(1,1,1,.4)
    draw(bgpic,0,0,0,1,1,975,225)

    gc.push()
    gc.scale(1.2)

    setColor(1,1,1)
    setLineWidth(2)
    --rect('line',-800,-450,1600,900)

    setColor(1,1,1,.25)
    setLineWidth(2)
    for i=1,8 do
        line(-540+60*i,251,-540+60*i,-351)
        line( 540-60*i,251, 540-60*i,-351)
    end
    for i=1,10 do
        line(-541,250-60*i,-58,250-60*i)
        line( 541,250-60*i, 58,250-60*i)
    end

    setColor(.5,.5,.5)
    for i=1,#gb.edge do
        u=gb.edge[i]
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
    end
    for i=1,#gb.obs do
        u=gb.obs[i]
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
    end

    setColor(1,1,1)
    printf("Attack>>>",font.OX_SB,-690,275,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
    printf("<<<Attack",font.OX_SB, 690,275,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)

    if gb.targetHP.L>0 then
        setColor(COLOR.hsl(LColorH[1]/60,1,.2))
        poly('fill',gb.base.L.body:getWorldPoints(gb.base.L.shape:getPoints()))
        setLineWidth(10)
        for i=1,5 do
            setColor(COLOR.hsl(LColorH[1]/60,1,.3+min(i,4)*.1))
            line(-595+10*i,250,-595+10*i,250-600*max(0,gb.targetHP.L)/gb.targetHP.max)
        end
        setLineWidth(50)
        setColor(1,1,1,gb.targetAnimTime.L*.6)
        line(-565,250,-565,250-600*max(0,gb.targetHP.L)/gb.targetHP.max)
        setColor(COLOR.hsl(LColorH[1]/60,1,.2,.5))
        printf(""..floor(max(0,gb.targetHP.L)).." HP",font.OX_SB,-565+1,240-1,2000,'left',-math.pi/2,.4,.4,0,font.height.OX_SB/3)
        setColor(1,1,1)
        printf(""..floor(max(0,gb.targetHP.L)).." HP",font.OX_SB,-565-1,240+1,2000,'left',-math.pi/2,.4,.4,0,font.height.OX_SB/3)
    end
    if gb.targetHP.R>0 then
        setColor(COLOR.hsl(RColorH[1]/60,1,.2))
        poly('fill',gb.base.R.body:getWorldPoints(gb.base.R.shape:getPoints()))
        setLineWidth(10)
        for i=1,5 do
            setColor(COLOR.hsl(RColorH[1]/60,1,.3+min(i,4)*.1))
            line( 595-10*i,250, 595-10*i,250-600*max(0,gb.targetHP.R)/gb.targetHP.max)
        end
        setLineWidth(50)
        setColor(1,1,1,gb.targetAnimTime.R*.6)
        line( 565,250, 565,250-600*max(0,gb.targetHP.R)/gb.targetHP.max)
        setColor(COLOR.hsl(RColorH[1]/60,1,.2,.5))
        printf(""..floor(max(0,gb.targetHP.R)).." HP",font.OX_SB, 565+1,240-1,2000,'left',-math.pi/2,.4,.4,0,font.height.OX_SB/3)
        setColor(1,1,1)
        printf(""..floor(max(0,gb.targetHP.R)).." HP",font.OX_SB, 565-1,240+1,2000,'left',-math.pi/2,.4,.4,0,font.height.OX_SB/3)
    end

    for i=0,3 do
        u=gb.atkMult.L[i+1]
        setColor(COLOR.hsl(LColorH[1]/60,1,.4+.1*i,.25))
        centerRect('fill',-585+150*i,375,150,130)
        setColor(1,1,1,.5)
        printf("x"..(i+1),font.OX_SB,-585+150*i,375,2000,'center',0,.5,.5,1000,font.height.OX_SB/3)
        u=gb.atkMult.R[i+1]
        setColor(COLOR.hsl(RColorH[1]/60,1,.4+.1*i,.25))
        centerRect('fill', 585-150*i,375,150,130)
        setColor(1,1,1,.5)
        printf("x"..(i+1),font.OX_SB, 585-150*i,375,2000,'center',0,.5,.5,1000,font.height.OX_SB/3)
    end
    setColor(COLOR.hsl(LColorH[1]/60,1,.8,.25))
    centerRect('fill',-35,375,50,130)
    setColor(COLOR.hsl(RColorH[1]/60,1,.8,.25))
    centerRect('fill', 35,375,50,130)

    setColor(.5,.5,.5)
    for i=1,#gb.atkObs do
        u=gb.atkObs[i]
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
    end

    for i=0,3 do
        u=gb.atkMult.L[i+1]
        setColor(COLOR.hsl(LColorH[1]/60,1,.4+.1*i))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        u=gb.atkMult.R[i+1]
        setColor(COLOR.hsl(RColorH[1]/60,1,.4+.1*i))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
    end
    setColor(COLOR.hsl(LColorH[1]/60,1,.8))
    poly('fill',gb.shuffle.L.body:getWorldPoints(gb.shuffle.L.shape:getPoints()))
    setColor(COLOR.hsl(RColorH[1]/60,1,.8))
    poly('fill',gb.shuffle.R.body:getWorldPoints(gb.shuffle.R.shape:getPoints()))
    setColor(1,1,1,.5)
    printf("Shuffle\n打乱颜色",font.OX_SB, 0,375,2000,'center',0,.25,.25,1000,font.height.OX_SB/3+font.height.OX_SB/2)

    for k,v in pairs(gb.garbage) do
        for i=1,#v do
            u=v[i]
            c=k=='L' and LColorH or RColorH
            setColor(COLOR.hsl(c[1]/60,1,.25))
            poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        end
    end

    setColor(1,1,1)
    setLineWidth(1)
    circle('line',-690,-430,10)
    circle('line', 690,-430,10)
    circle('line',-690,-330,10)
    circle('line', 690,-330,10)
    circle('line',-690,-130,10)
    circle('line', 690,-130,10)
    circle('line',-690,  70,10)
    circle('line', 690,  70,10)

    setColor(.5,.5,.5)
    for i=1,#gb.fixNeedle do
        u=gb.fixNeedle[i]
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
    end
    setColor(.5,.5,.5)
    for k,u in pairs(gb.marginObs) do
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
    end

    setColor(.5,.5,.5)
    for i=1,#gb.circleObs do
        u=gb.circleObs[i]
        circle('fill',u.body:getX(),u.body:getY(),u.shape:getRadius())
    end

    setLineWidth(2)
    for i=0,3 do
        u=gb.cmdAmount.L[i+1]
        setColor(COLOR.hsl(LColorH[1]/60,1,.25))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        printf((i+1),font.OX_SB,-765+50*i,-175,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
        u=gb.cmdAmount.R[i+1]
        setColor(COLOR.hsl(RColorH[1]/60,1,.25))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        printf((i+1),font.OX_SB, 765-50*i,-175,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)

        u=gb.cmdHP.L[i+1]
        setColor(COLOR.hsl(LColorH[1]/60,1,.25))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        printf("x"..(i+1),font.OX_SB,-765+50*i,25,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
        u=gb.cmdHP.R[i+1]
        setColor(COLOR.hsl(RColorH[1]/60,1,.25))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        printf("x"..(i+1),font.OX_SB, 765-50*i,25,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)

        u=gb.cmdDeploy.L[i+1]
        setColor(COLOR.hsl(LColorH[1]/60,1,.25))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        draw(cannonIcon[cannonType[i+1]],-765+50*i,225,0,.5,.5,50,50)
        u=gb.cmdDeploy.R[i+1]
        setColor(COLOR.hsl(RColorH[1]/60,1,.25))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        draw(cannonIcon[cannonType[i+1]], 765-50*i,225,0,-.5,.5,50,50)

        u=gb.cmdColor.L[i+1]
        setColor(COLOR.hsl(LColorH[gb.cmdColorType[i+1]]/60,1,.5))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
        u=gb.cmdColor.R[i+1]
        setColor(COLOR.hsl(RColorH[gb.cmdColorType[i+1]]/60,1,.5))
        poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
        setColor(1,1,1)
        poly('line',u.body:getWorldPoints(u.shape:getPoints()))
    end

    setColor(1,1,1)
    setLineWidth(5)
    line(-790,-347.5,-790+200*gb.changeColorTimer/gb.changeColorPeriod,-347.5)
    line( 790,-347.5, 790-200*gb.changeColorTimer/gb.changeColorPeriod,-347.5)

    setColor(1,1,1,.75)
    printf("Deploy/部署",font.OX_SB,-690,165,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
    printf("HP/生命",font.OX_SB,-690,-35,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
    printf("Amount/数量",font.OX_SB,-690,-235,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
    printf("部署/Deploy",font.OX_SB,690,165,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
    printf("生命/HP",font.OX_SB,690,-35,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
    printf("数量/Amount",font.OX_SB,690,-235,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)

    for i=1,#gb.timedObs do
        for j=1,#gb.timedObs[i] do
            u=gb.timedObs[i][j]
            setColor(1,1,1,.5)
            poly('fill',u.body:getWorldPoints(u.shape:getPoints()))
            setColor(1,1,1)
            if i==4 then
                --printf(ceil(gb.obsRemoveTime[i]-gb.time),font.OX_SB,u.body:getX(),u.body:getY(),2000,'center',0,1/3,1/3,1000,font.height.OX_SB/3)
            else
                printf(ceil(gb.obsRemoveTime[i]-gb.time),font.OX_SB,u.body:getX(),u.body:getY()-10,2000,'center',0,1/6,1/6,1000,font.height.OX_SB/3)
            end
        end
    end

    for i=1,#gb.explodePar do
        u=gb.explodePar[i]
        setColor(COLOR.hsl(u.c/60,1,.2))
        arc('fill','closed',u.x,u.y,12.5*2^.5,math.pi/4+u.av*u.t,7*math.pi/4+u.av*u.t,3)
    end

    for k,v in pairs(gb.cmdMarble) do
        for i=1,#v do
            u=v[i]
            ud=u.fixture:getUserData()
            if ud.color==0 then setColor(1,1,1)
            else
                c=k=='L' and LColorH or RColorH
                setColor(COLOR.hsl(c[ud.color]/60,1,.5))
            end
            circle('fill',u.body:getX(),u.body:getY(),u.shape:getRadius())
            if ud.HP~=0 then
                if ud.color==0 then --滚木
                else
                    c=k=='L' and LColorH or RColorH
                    setColor(COLOR.hsl(c[ud.color]/60,1,.5,.6))
                end
                printf("x"..ud.HP,font.OX_SB,u.body:getX(),u.body:getY()-25,2000,'center',0,.25,.25,1000,font.height.OX_SB/3)
            end
        end
    end
    setColor(1,1,1)
    for k,v in pairs(gb.atkMarble) do
        for i=1,#v do
            u=v[i]
            ud=u.fixture:getUserData()
            circle('fill',u.body:getX(),u.body:getY(),u.shape:getRadius())
        end
    end

    setLineWidth(40)
    setColor(COLOR.hsl(LColorH[1]/60,1,.15))
    line(-540,-430,-60,-430)
    if gb.crisisTime.L>0 then
        setColor(COLOR.hsl(LColorH[1]/60,1,(gb.crisisTime.L%.125<=1/16 and .75 or .875)))
        line(-540,-430,-540+480*(gb.crisisTime.L/gb.crisisTime.max),-430)
    else
        setColor(COLOR.hsl(LColorH[1]/60,1,.5))
        line(-540,-430,-540+480*(gb.crisisMeter.L/gb.crisisMeter.max),-430)
    end
    setColor(COLOR.hsl(RColorH[1]/60,1,.15))
    line(540,-430,60,-430)
    if gb.crisisTime.R>0 then
        setColor(COLOR.hsl(RColorH[1]/60,1,(gb.crisisTime.R%.125<=1/16 and .75 or .875)))
        line(540,-430,540-480*(gb.crisisTime.R/gb.crisisTime.max),-430)
    else
        setColor(COLOR.hsl(RColorH[1]/60,1,.5))
        line(540,-430,540-480*(gb.crisisMeter.R/gb.crisisMeter.max),-430)
    end

    setColor(1,1,1,.75)
    poly('fill',-540+60*(gb.cmdPos-1),-410,-510+60*(gb.cmdPos-1),-380,-480+60*(gb.cmdPos-1),-410)
    poly('fill', 540-60*(gb.cmdPos-1),-410, 510-60*(gb.cmdPos-1),-380, 480-60*(gb.cmdPos-1),-410)

    setColor(COLOR.hsl(LColorH[1]/60,1,.5))
    poly('fill',-540+60*(gb.cmdPos-1), 290,-510+60*(gb.cmdPos-1), 260,-480+60*(gb.cmdPos-1), 290)
    setColor(COLOR.hsl(RColorH[1]/60,1,.5))
    poly('fill', 540-60*(gb.cmdPos-1), 290, 510-60*(gb.cmdPos-1), 260, 480-60*(gb.cmdPos-1), 290)

    setColor(1,1,1,.5)
    printf("Cannons/炮塔数 - "..gb.cannonCount.L,font.OX_SB,-535,-365,2000,'left',0,1/5,1/5,0,font.height.OX_SB/3)
    printf(gb.cannonCount.R.." - 炮塔数/Cannons",font.OX_SB, 535,-365,2000,'right',0,1/5,1/5,2000,font.height.OX_SB/3)

    setShader(gb.sd)
    for k,v in pairs(gb.cannonField) do
        c=k=='L' and LColorH or RColorH
        s=(k=='L' and -1 or 1)
        for i=1,8 do  for j=1,#v[i] do
            local b=v[i][j]
            u=b.entity
            ud=u.fixture:getUserData()
            hp=ud.HP/ud.MaxHP
            if b.c==-1 then setColor(.375,.375,.375,.1+.9*hp^.5)
            else setColor(COLOR.hsl(c[b.c]/60,1,.5,.1+.9*hp^.5)) end
            ux,uy=u.body:getPosition()
            draw(b.c==-1 and garbage or base,ux,uy,0,.5,.5,60,60)
            setColor(1,1,1,(1-(b.animT/b.animTMax)^3)*.8)
            centerRect('fill',ux,uy,60,60)
        end  end

        for i=1,7 do  for j=1,9 do
            local b=gb.squareList[k][i][j]
            if b.t>0 then
            setColor(COLOR.hsl(c[b.c]/60,1,.5,b.t^2))
            draw(square,(540-60*i)*s,250-60*j,0,.5*-s,.5,120,120)
            setColor(1,1,1,b.t^2)
            setLineWidth(22.5-15*b.t)
            centerRect('line',(540-60*i)*s,250-60*j,360-240*b.t,360-240*b.t)
            end
        end  end
    end
    setShader()
    for k,v in pairs(gb.cannonField) do
        c=k=='L' and LColorH or RColorH
        s=(k=='L' and -1 or 1)
        for i=1,8 do  for j=1,#v[i] do
            local b=v[i][j]
            u=b.entity
            ud=u.fixture:getUserData()
            hp=ud.HP/ud.MaxHP
            ux,uy=u.body:getPosition()
            if b.c~=-1 then
                cannonDraw[b.type](k,ux,uy,b.h,b.c,isInSquare(k,i,j))
                --draw(entityPic[ug][b.type],ux,uy,b.type=='shield' and 0 or getAngle(b.h)*-s,.5*-s,.5,b.type=='pierce' and 120 or 60,60)

            end
            setLineWidth(5)
            if b.c==-1 then setColor(.5,.5,.5,.25)
            else setColor(COLOR.hsl(c[b.c]/60,1,.75,.25)) end
            line(ux-20,uy-20,ux+20,uy-20)
            if b.c==-1 then setColor(.5,.5,.5)
            else setColor(COLOR.hsl(c[b.c]/60,1,.75)) end
            line(ux-20,uy-20,ux-20+40*hp,uy-20)

            setColor(1,1,1)
            if b.c~=-1 and b.ammo>0 then
                printf(b.ammo,font.OX_SB,ux+17.5*s,uy+15,2000,'center',0,1/6,1/6,1000,font.height.OX_SB/3)
            end
        end  end
    end
    for i=1,#gb.healNumPar do
        u=gb.healNumPar[i]
        setColor(1,1,1,1-u.t)
        printf((u.dmg and "-" or "+")..u.heal,font.OX_SB,u.x,u.y+(u.dmg and 10 or -10)*u.t,2000,'center',0,1/6,1/6,1000,font.height.OX_SB/3)
    end
    setLineWidth(10)
    for i=1,#gb.healEffectPar do
        u=gb.healEffectPar[i]
        setColor(1,1,1,1-u.t)
        centerRect('line',u.x,u.y,60+u.t*30)
    end
    for i=1,#gb.cannonDiePar do
        u=gb.cannonDiePar[i]
        if u.c==-1 then setColor(.25,.25,.25,1-u.t^3)
        else setColor(COLOR.hsl((u.team=='L' and LColorH or RColorH)[u.c]/60,1,.25,1-u.t)) end
        centerRect('fill',u.x,u.y,60+u.t*60)
    end
    for i=1,#gb.arrowAttackPar do
        u=gb.arrowAttackPar[i]
        setColor(COLOR.hsl(u.c/60,1,(u.ug and .875 or .7),(1-u.t)))
        circle('fill',u.x,u.y,5+u.t*25)
    end

    for k,v in pairs(gb.bullet) do
        for i=1,#v do
            u=v[i]
            ud=u.fixture:getUserData()
            setColor(COLOR.hsl((k=='L' and LColorH[u.color] or RColorH[u.color])/60,1,.5625))
            circle('fill',u.body:getX(),u.body:getY(),u.shape:getRadius())
        end
    end
    --setLineWidth(2.5)
    for k,v in pairs(gb.bomb) do
        for i=1,#v do
            u=v[i]
            ud=u.fixture:getUserData()
            ux,uy=u.body:getPosition()
            if ud.triggered then
                setColor(COLOR.hsl((k=='L' and LColorH[u.color] or RColorH[u.color])/60,1,.7,1-ud.triggerTime/ud.liveTime))
                circle('fill',ux,uy,u.shape:getRadius())
            else
                local angle=u.body:getAngle()
                setColor(COLOR.hsl((k=='L' and LColorH[u.color] or RColorH[u.color])/60,1,.7))
                arc('fill','closed',ux,uy,u.shape:getRadius(),0+angle,3*math.pi/2+angle,3)
                arc('fill','closed',ux,uy,u.shape:getRadius(),math.pi/4+angle,7*math.pi/4+angle,3)
            end
            --setColor(0,0,0)
            --printf("triggered:"..(ud.triggered and "TRUE" or "FALSE"),font.OX_SB,ux,uy,2000,'center',0,1/6,1/6,1000,font.height.OX_SB/3)
        end
    end
    for k,v in pairs(gb.arrow) do
        for i=1,#v do
            u=v[i]
            ud=u.fixture:getUserData()
            ux,uy=u.body:getPosition()
            setColor(COLOR.hsl((k=='L' and LColorH[u.color] or RColorH[u.color])/60,1,.9))
            draw(arrowPic[ud.upgraded and 'upgrade' or 'normal'],ux,uy,u.body:getAngle(),.5,.5,210,20)

            --setColor(COLOR.hsl((k=='L' and LColorH[u.color] or RColorH[u.color])/60,1,.5))
            --circle('fill',ux,uy,u.shape:getRadius())
        end
    end

    setLineWidth(20)
    for i=1,#gb.cannonSummonPar do
        u=gb.cannonSummonPar[i]
        setColor(COLOR.hsl(u.c/60,1,.5,1-u.t^3))
        line(u.sx,u.sy,u.fx,u.fy)
    end
    for i=1,#gb.garbageSummonPar do
        u=gb.garbageSummonPar[i]
        setColor(COLOR.hsl(u.c/60,1,.25,1-u.t^3))
        line(u.sx,u.sy,u.fx,u.fy)
    end

    for k,v in pairs(gb.atkCmdPar) do
        c=k=='L' and LColorH[1] or RColorH[1]
        s=(k=='L' and -1 or 1)
        for i=1,#v do
            u=v[i]
            setColor(COLOR.hsl(c/60,1,.3+.1*u.mult))
            setLineWidth(30*(1-u.t))
            line((570-60*u.col)*s,250,(570-60*u.col)*s,-410)
        end
    end

    setColor(1,1,1)
    printf("CRISIS MODE/危机模式",font.OX_SB, -534,-430,2000,'left',0,.25,.25,0,font.height.OX_SB/3)
    printf("危机模式/CRISIS MODE",font.OX_SB,  534,-430,2000,'right',0,.25,.25,2000,font.height.OX_SB/3)

    --setColor(1,1,1,.75)
    for i=-1,1,2 do
        if gb.time>gb.obsRemoveTime[4] then
            printf("Garbage\n干扰方块",font.OX_SB,730*i,335,2000,'center',0,1/6,1/6,1000,font.height.OX_SB/3+font.height.OX_SB/2)
        else
            printf(ceil(gb.obsRemoveTime[4]-gb.time),font.OX_SB,730*i,335,2000,'center',0,1/3,1/3,1000,font.height.OX_SB/3)
        end
        printf("x1",font.OX_SB,700*i,375,2000,'center',0,1/4,1/4,1000,font.height.OX_SB/3)
        printf("x3",font.OX_SB,760*i,375,2000,'center',0,1/4,1/4,1000,font.height.OX_SB/3)
    end

    setColor(1,1,1,.75)
    printf(string.format("%02d:%02d",gb.time/60,gb.time%60),font.OX_SB,0,-430,1000,'center',0,1/3,1/3,500,font.height.OX_SB/3)
    setColor(1,1,1,gb.sim and 1 or .5)
    if gb.readyTime>0 then printf(string.format("%d",ceil(gb.readyTime)),font.OX_SB,0,0,1000,'center',0,1.5,1.5,500,font.height.OX_SB/3) end

    gc.pop()
end
return gb