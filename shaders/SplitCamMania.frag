#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
#define iChannel0 bitmap
#define texture flixel_texture2D

// Important float
uniform float iTime;
uniform float center1X;
uniform float center1Y;
uniform float center2X;
uniform float center2Y;
uniform float zoom1;
uniform float zoom2;
uniform float strength;

// Bonus float
uniform float invert1;
uniform float invert2;
uniform float directsplit;
uniform float bordersize;
uniform float animation;

// manual control
uniform float move; // is control a same time the split1 and split2
uniform float split1;
uniform float split2;   

vec2 returnUV(vec2 uv, vec2 center, float zoom, float invert) {
    vec2 result = (uv - center) / zoom + center;
    if(invert == 1.0) result.x = 1.0 - result.x;
    return result;
}

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec2 center1;
    vec2 center2;
    vec4 effect;
    vec4 black = vec4(0.0, 0.0, 0.0, 1.0);

    float autoMove = 0.25 + 0.25 * sin(iTime);

    float currentMove = mix(move, autoMove, animation);

    float currentSplit1 = currentMove + split1;
    float currentSplit2 = currentMove + split2;

    float dynamicBorder = bordersize * (1.0 - (currentSplit1 + currentSplit2));

    if(directsplit == 0.0) {
        center1 = vec2(center1X + currentSplit1, center1Y);
        center2 = vec2(center2X * 1.5 - 0.51 - currentSplit2, center2Y);

        if(abs(uv.x - 0.5) < dynamicBorder * 0.1) {
            effect = black;
        } else if(uv.x < 0.5 - currentSplit1) {
            effect = texture(iChannel0, returnUV(uv, center1, zoom1, invert1));
        } else if(uv.x > 0.5 + currentSplit2) {
            effect = texture(iChannel0, returnUV(uv, center2, zoom2, invert2));
        } else {
            effect = texture(iChannel0, uv);
        }
    } else {
        center1 = vec2(center1X, center1Y + currentSplit1);
        center2 = vec2(center2X, center2Y - 0.51 - currentSplit2);

        if(abs(uv.y - 0.5) < dynamicBorder * 0.1) {
            effect = black;
        } else if(uv.y < 0.5 - currentSplit1) {
            effect = texture(iChannel0, returnUV(uv, center1, zoom1, invert1));
        } else if(uv.y > 0.5 + currentSplit2) {
            effect = texture(iChannel0, returnUV(uv, center2, zoom2, invert2));
        } else {
            effect = texture(iChannel0, uv);
        }
    }

    vec4 base = texture(iChannel0, uv);
    gl_FragColor = mix(base, effect, strength);
}