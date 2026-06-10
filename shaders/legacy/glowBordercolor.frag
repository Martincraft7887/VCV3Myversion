#pragma header

uniform float iTime;
uniform float transparency;  
uniform float transparency2;
uniform float uTime;
uniform float money;
uniform float colorraro;

const float offset = 1.0 / 128.0;

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 12.1414))) * 83758.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n);
    vec2 f = mix(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

vec3 ramp(float t) {
    return t <= 0.5 ? vec3(1.0 - t * 1.4, 0.2, 1.05) / max(t, 0.01) : vec3(0.3 * (1.0 - t) * 2.0, 0.2, 1.05) / max(t, 0.01);
}

float fire(vec2 n) {
    return noise(n) + noise(n * 2.1) * 0.6 + noise(n * 5.4) * 0.42;
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 originalColor = flixel_texture2D(bitmap, uv);
    
    // Glow border effect
    uv *= 5.0;
    float q = fire(uv - iTime * 0.013) / 3.0;
    vec2 r = vec2(fire(uv + q / 2.0 + iTime - uv.x - uv.y), fire(uv + q - iTime));
    float gradX = pow((r.y + r.y) * max(0.0, uv.x), 2.0);
    float gradY = pow((r.y + r.y) * max(0.0, uv.y), 2.0);
    float borderGlow = gradX + gradY;
    borderGlow = clamp(borderGlow - transparency, 0.0, 1.0);

    // Color effect
    vec3 hsvColor = rgb2hsv(originalColor.rgb);
    if (money >= 1.1) {
        hsvColor.r += mod(uTime * 0.1, 1.0);
    } else {
        float hueIncrement = money;
        hsvColor.r = mod(hsvColor.r + mod(money, 1.0) * hueIncrement, 1.0);
    }

    if (colorraro == 0.0) {
        hsvColor.r = hsvColor.r;
    } else if (colorraro >= 1.1) {
        hsvColor.r = mod(uTime * 0.1, 1.0);
    } else {
        hsvColor.r = mod(colorraro, 1.0);
    }

    vec3 colorEffect = hsv2rgb(hsvColor);
    vec3 finalColor = mix(originalColor.rgb, colorEffect, borderGlow);

    gl_FragColor = vec4(finalColor, originalColor.a);
}