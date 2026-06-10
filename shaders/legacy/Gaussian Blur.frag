// Source: https://www.shadertoy.com/view/XsfSDs
// little rewritted and ported to flixel by TheLeerName

#pragma header

uniform float posX; // from 0.0 to 1.0
uniform float posY; // from 0.0 to 1.0
uniform float focusPower; // 10.0

uniform float iTime;
uniform float strength;

#define focusDetail 7.0
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define mainImage main

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 pos = vec2(posX, posY);
    vec2 focus = uv - pos;
    
    vec4 finalColor = vec4(0.0);
    float totalWeight = 0.0;
    
    float Pi = 6.28318530718;
    float Directions = 12.0;
    float Quality = 3.0;
    float Size = strength * 8.0;
    vec2 Radius = Size / openfl_TextureSize.xy;

    for (int i = 0; i < int(focusDetail); i++) {
        float power = 1.0 - focusPower * (1.0 / openfl_TextureSize.x) * float(i);
        vec2 sampleUV = focus * power + pos;
        
        vec4 blurredSample = vec4(0.0);
        
        float stepAngle = Pi / Directions;
        for (float d = 0.0; d < Pi; d += stepAngle) {
            vec2 dir = vec2(cos(d), sin(d)) * Radius;
            for (float j = 1.0 / Quality; j <= 1.0; j += 1.0 / Quality) {
                blurredSample += texture(iChannel0, sampleUV + dir * j) * 0.5;
            }
        }

        blurredSample /= Quality * Directions - 15.0;
        
        float weight = 1.0 / (1.0 + float(i));
        finalColor += blurredSample * weight;
        totalWeight += weight;
    }

    fragColor = finalColor / totalWeight;
}