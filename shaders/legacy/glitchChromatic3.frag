#pragma header
uniform float iTime;
uniform float GLITCH;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define mainImage main
const int NUM_SAMPLES = 20;
    
float rand(vec2 p)
{
    float t = floor(iTime * 40.) / 40.;
    return fract(sin(dot(p, vec2(t * 12.9898, t * 78.233))) * 43758.5453);
}

float noise(vec2 uv, float blockiness)
{   
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    float n1 = rand(id);
    float n2 = rand(id+vec2(1,0));
    float n3 = rand(id+vec2(0,1));
    float n4 = rand(id+vec2(1,1));
    
    vec2 u = smoothstep(0.0, 1.0 + blockiness, lv);

    return mix(mix(n1, n2, u.x), mix(n3, n4, u.x), u.y);
}

float fbm(vec2 uv, int count, float blockiness, float complexity)
{
    float val = GLITCH;
    float amp = GLITCH;
    
    while(count != 0)
    {
    	val += amp * noise(uv, blockiness);
        amp *= GLITCH;
        uv *= complexity;    
        count--;
    }
    
    return val;
}

const float glitchAmplitude = 0.3; // increase this
const float glitchNarrowness = 5.0;
const float glitchBlockiness = 5.0;
const float glitchMinimizer = 6.0; // decrease this

void mainImage()
{
    
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
    vec2 uv = fragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    vec2 a = vec2(uv.x * aspect , uv.y);
    vec2 uv2 = vec2(a.x / iResolution.x, exp(a.y));

    
    float shift = glitchAmplitude * pow(fbm(uv2, 4, glitchBlockiness, glitchNarrowness), glitchMinimizer);
    
    float colR = texture(iChannel0, vec2(uv.x + shift, uv.y)).r * (1. - shift);
    float colG = texture(iChannel0, vec2(uv.x - shift, uv.y)).g * (1. - shift);
    float colB = texture(iChannel0, vec2(uv.x - shift, uv.y)).b * (1. - shift);
    
    // Mix with the scanline effect
    vec3 f = vec3(colR, colG, colB);

    
    fragColor = vec4(f, 1.);
}