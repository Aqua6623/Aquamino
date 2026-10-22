//法线贴图格式：
//        |
//      \ |
//       \|
//--------O------->X
//        |\
//        | \
//        v  vZ(指向屏幕外)
//         Y

extern vec3 light; //光照方向
extern float ambientLight; //环境光照
vec4 effect( vec4 color, Image texture, vec2 texCoord, vec2 scrCoord ){
    vec4 px=texture2D(texture,texCoord);
    highp float sLight=max(dot(normalize(px.rgb*2.-1.),normalize(light)),0.)*(1-ambientLight)+ambientLight;
    return vec4(sLight,sLight,sLight,px.a);
}