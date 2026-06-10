// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel
// Will destroy your PC, sorry.

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength;
uniform float angle;
#define iChannel0 bitmap
#define texture flixel_texture2D

uniform vec4 iMouse;

#define bmp 170.0

vec2 uvp(vec2 uv) {
    return clamp(uv, 0.001, 0.999); // Fuck you.
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 col = vec3(0.0);

    float amp = (iMouse.z <= 0.0) ? 1.0 : iMouse.x / iResolution.x;
    amp *= strength;

    float bandHeight = 0.2 + rand(vec2(iTime, 3.14)) * 0.1;
    float bandIndex = floor(uv.y / bandHeight);
    float bandShift = (rand(vec2(bandIndex, iTime)) - 0.5) * amp * 0.5;

    vec2 dir = vec2(cos(angle), sin(angle));
    uv += dir * bandShift;

    vec3 texOrig = texture(iChannel0, uvp(uv)).rgb;

    for (int i = 0; i < 3; i++) {
        vec2 jitterUV = uv;

        float jitterX = (rand(vec2(uv.y + float(i), iTime)) * 2.0 - 1.0);
        float jitterY = (rand(vec2(uv.x, iTime + float(i))) * 2.0 - 1.0);

        jitterUV.x += jitterX * amp * 0.5 * (texOrig[i] + 0.2);
        jitterUV.y += jitterY * amp * 0.05 * (texOrig[i] + 0.2);

        vec3 tex = texture(iChannel0, uvp(jitterUV)).rgb;

        float diff = abs(tex[i] - texOrig[i]);
        tex += diff * 0.5;

        tex *= 1.0 + rand(jitterUV) * amp * 0.2;

        col[i] = clamp(tex[i], 0.0, 1.0);
    }

    fragColor = vec4(col, texture(iChannel0, fragCoord / iResolution.xy).a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}
