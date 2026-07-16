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

// Independent M/color controls for each half
uniform float temperature1;
uniform float hue1;
uniform float saturation1;
uniform float contrast1;
uniform float temperature2;
uniform float hue2;
uniform float saturation2;
uniform float contrast2;

vec2 returnUV(vec2 uv, vec2 center, float zoom, float invert) {
    vec2 result = (uv - center) / zoom + center;
    if(invert == 1.0) result.x = 1.0 - result.x;
    return result;
}

vec3 getStraightRGB(vec4 color) {
    return color.a > 0.0 ? color.rgb / color.a : color.rgb;
}

vec4 withAlpha(vec3 rgb, float alpha) {
    return vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}

vec3 adjustTemperature(vec3 color, float temp) {
    color.r *= 1.0 + (temp * 0.1);
    color.b *= 1.0 - (temp * 0.1);
    return clamp(color, 0.0, 1.0);
}

vec3 rgb2hsv(vec3 color) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(color.bg, K.wz), vec4(color.gb, K.xy), step(color.b, color.g));
    vec4 q = mix(vec4(p.xyw, color.r), vec4(color.r, p.yzx), step(p.x, color.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 color) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(color.xxx + K.xyz) * 6.0 - K.www);
    return color.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y);
}

vec3 adjustHue(vec3 color, float hue) {
    vec3 hsv = rgb2hsv(color);
    hsv.x = fract(hsv.x + hue);
    return hsv2rgb(hsv);
}

vec3 adjustSaturation(vec3 color, float saturation) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, saturation);
}

vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec4 applyColor(vec4 color, float temperature, float hue, float saturation, float contrast) {
    vec3 result = getStraightRGB(color);
    result = adjustTemperature(result, temperature);
    result = adjustHue(result, hue);
    result = adjustSaturation(result, saturation);
    result = adjustContrast(result, contrast);
    return withAlpha(result, color.a);
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
            effect = applyColor(texture(iChannel0, returnUV(uv, center1, zoom1, invert1)), temperature1, hue1, saturation1, contrast1);
        } else if(uv.x > 0.5 + currentSplit2) {
            effect = applyColor(texture(iChannel0, returnUV(uv, center2, zoom2, invert2)), temperature2, hue2, saturation2, contrast2);
        } else {
            effect = texture(iChannel0, uv);
        }
    } else {
        center1 = vec2(center1X, center1Y + currentSplit1);
        center2 = vec2(center2X, center2Y - 0.51 - currentSplit2);

        if(abs(uv.y - 0.5) < dynamicBorder * 0.1) {
            effect = black;
        } else if(uv.y < 0.5 - currentSplit1) {
            effect = applyColor(texture(iChannel0, returnUV(uv, center1, zoom1, invert1)), temperature1, hue1, saturation1, contrast1);
        } else if(uv.y > 0.5 + currentSplit2) {
            effect = applyColor(texture(iChannel0, returnUV(uv, center2, zoom2, invert2)), temperature2, hue2, saturation2, contrast2);
        } else {
            effect = texture(iChannel0, uv);
        }
    }

    vec4 base = texture(iChannel0, uv);
    gl_FragColor = mix(base, effect, strength);
}
