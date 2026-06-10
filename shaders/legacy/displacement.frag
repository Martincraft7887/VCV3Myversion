//SHADERTOY PORT FIX
#pragma header
vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define fragColor gl_FragColor
#define mainImage main
//so sorry for the names lolol
float str = 1.3;
float ok = 2.;

vec2 warp(vec2 inp)
{
    inp.y -= (inp.y - .5)* str * pow(abs(inp.x - .5), ok);
    return inp;
}

//adds these circles on screen to show how it works
vec4 col(vec2 inp)
{
    vec4 clr = vec4(1,1,1,1);
    clr.r = clr.g = clr.b = 1. - sin(inp.y * iResolution.y * .5) - 1. - sin(inp.x * iResolution.x * .5);
    return clr;
}

void mainImage()
{
    vec2 uv = warp(fragCoord/iResolution.xy) + vec2(iTime/4.,sin(iTime/4.)*0.1);
    fragColor = texture(iChannel0,uv);
}