#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength;
#define iChannel0 bitmap
#define texture flixel_texture2D

#define TAU 6.28318530716

float spiral(vec2 p, float scl, float phase) 
{
    float r = length(p);
    r = log(r);
    float a = atan(p.y, p.x);
    return abs(mod(scl * (r - 1.0 / scl * a) - phase * 2.0, TAU) - 1.0) / 2.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= 0.5;

    float modifier1 = 1.0 / spiral(uv, 1.0, iTime + 2.3);
    float modifier2 = 1.0 / spiral(uv, 2.0, iTime);
    float modifier3 = 1.0 / spiral(uv, 3.0, iTime * 2.0 - 1.0);
    float modifier4 = 1.0 / spiral(uv, 25.0, iTime * 5.0 - 2.0);

    vec4 bitmapColor = texture(iChannel0, fragCoord / iResolution.xy);
    float effect = (modifier1 + modifier2 + modifier3 + modifier4) / 4.0;
    
    fragColor = mix(bitmapColor, bitmapColor * effect, strength);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}