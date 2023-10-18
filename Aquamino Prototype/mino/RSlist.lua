local RS={}
RS.SRS={
    Z={
        L={
            {{0,0},{-1, 0},{-1, 1},{ 0,-2},{-1,-2}}, --0->R
            {{0,0},{ 1, 0},{ 1,-1},{ 0, 2},{ 1, 2}}, --R->2
            {{0,0},{ 1, 0},{ 1, 1},{ 0,-2},{ 1,-2}}, --2->L
            {{0,0},{-1, 0},{-1,-1},{ 0, 2},{-1, 2}}, --L->0

        },
        R={
            {{0,0},{ 1, 0},{ 1, 1},{ 0,-2},{ 1,-2}}, --0->L
            {{0,0},{ 1, 0},{ 1,-1},{ 0, 2},{ 1, 2}}, --R->0
            {{0,0},{-1, 0},{-1, 1},{ 0,-2},{-1,-2}}, --2->R
            {{0,0},{-1, 0},{-1,-1},{ 0, 2},{-1, 2}}  --L->2
        },
    },
    --[[F={
        {{0,0}}, --0->2
        {{0,0}}, --L->R
        {{0,0}}, --2->0
        {{0,0}}  --R->L
    }]]
    --没有的一律视作{0,0}
    I={
        L={
            {{0,0},{-2, 0},{ 1, 0},{-2,-1},{ 1, 2}},
            {{0,0},{-1, 0},{ 2, 0},{-1, 2},{ 2,-1}},
            {{0,0},{ 2, 0},{-1, 0},{ 2, 1},{-1,-2}},
            {{0,0},{ 1, 0},{-2, 0},{ 1,-2},{-2, 1}},
        },
        R={
            {{0,0},{-1, 0},{ 2, 0},{-1, 2},{ 2,-1}},
            {{0,0},{ 2, 0},{-1, 0},{ 2, 1},{-1,-2}},
            {{0,0},{ 1, 0},{-2, 0},{ 1,-2},{-2, 1}},
            {{0,0},{-2, 0},{ 1, 0},{-2,-1},{ 1, 2}}
        },
    }
}
RS.SRS.S=RS.SRS.Z RS.SRS.J=RS.SRS.Z RS.SRS.L=RS.SRS.Z RS.SRS.T=RS.SRS.Z

--[[
SRS Extend 180踢的设计：
1.{0,0} 2.踢离墙面/地面 3&4.翻离一格高的洞/穿梭一格远的隧道
5.传送sqrt(2)的距离且前后两块相连（如果可以） 6.翻离两格高的洞/穿梭两格远的隧道 7.量子隧穿
]]
RS.SRS_Extend={
    Z={
        L=RS.SRS.Z.L,R=RS.SRS.Z.R,
        F={
            {{0,0},{ 0, 1},{ 1, 0},{-1, 0},{ 1,-1},{ 2, 0},{ 0,-2}}, --0->2
            {{0,0},{-1, 0},{ 0,-1},{ 0, 1},{-1,-1},{ 0,-2},{-2, 0}}, --R->L
            {{0,0},{ 0,-1},{-1, 0},{ 1, 0},{-1, 1},{-2, 0},{ 0, 2}}, --2->0
            {{0,0},{ 1, 0},{ 0, 1},{ 0,-1},{ 1, 1},{ 0, 2},{ 2, 0}}  --L->R
        }
    },
    S={L=RS.SRS.Z.L,R=RS.SRS.Z.R,
        F={
            {{0,0},{ 0, 1},{-1, 0},{ 1, 0},{-1,-1},{-2, 0},{ 0,-2}},
            {{0,0},{-1, 0},{ 0, 1},{ 0,-1},{-1, 1},{ 0, 2},{-2, 0}},
            {{0,0},{ 0,-1},{ 1, 0},{-1, 0},{ 1, 1},{ 2, 0},{ 0, 2}},
            {{0,0},{ 1, 0},{ 0,-1},{ 0, 1},{ 1,-1},{ 0,-2},{ 2, 0}}
        }
    },
    T={
        L=RS.SRS.T.L,R=RS.SRS.T.R,
        F={
            {{0,0},{ 0, 1},{ 1, 0},{-1, 0},{-2, 0},{ 2, 0},{ 0,-2}},
            {{0,0},{-1, 0},{ 0,-1},{ 0, 1},{ 2, 0},{ 0,-2},{-2, 0}},
            {{0,0},{ 0,-1},{-1, 0},{ 1, 0},{-2, 0},{ 2, 0},{ 0, 2}},
            {{0,0},{ 1, 0},{ 0,-1},{ 0, 1},{-2, 0},{ 0, 2},{ 2, 0}}
        }
    },
    I={
        L=RS.SRS.I.L,R=RS.SRS.I.R,
        F={
            {{0,0},{ 0, 1},{ 1, 0},{-1, 0},{ 1,-1},{ 2, 0},{ 0, 2}},
            {{0,0},{-1, 0},{ 0,-1},{ 0, 1},{-1,-1},{ 0,-2},{-2, 0}},
            {{0,0},{ 0,-1},{-1, 0},{ 1, 0},{-1, 1},{-2, 0},{ 0,-2}},
            {{0,0},{ 1, 0},{ 0, 1},{ 0,-1},{ 1, 1},{ 0, 2},{ 2, 0}}
        }
    }
}
RS.SRS.J=RS.SRS.Z RS.SRS.L=RS.SRS.S
