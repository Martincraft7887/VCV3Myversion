#pragma header

uniform float iTime;
uniform float strength;
#define iChannel0 bitmap
#define texture texture2D
#define fragColor gl_FragColor
#define mainImage main 

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float de(vec3 p) {
    p.y += cos(iTime * 2.0) * 0.2;
    p.xy *= r2d(iTime + p.z);
    
    vec3 r;
    float d = 0.0, s = 1.0;
    for (int i = 0; i < 3; i++) {
        r = max(r = abs(mod(p * s + 1.0, 2.0) - 1.0), r.yzx);
        d = max(d, (0.9 - min(r.x, min(r.y, r.z))) / s);
        s *= 3.0;
    }
    return d;
}

void main() {
    vec2 iResolution = openfl_TextureSize;
    vec2 uv = (openfl_TextureCoordv * iResolution - 0.5 * iResolution) / iResolution.y;

    vec3 ro = vec3(0.1 * cos(iTime), 0.0, -iTime);
    vec3 rd = normalize(vec3(uv, -1.0));
    vec3 p = ro;

    float it = 0.0, d;
    for (float i = 0.0; i < 1.0; i += 0.01) {
        d = de(p);
        it = i;
        if (d < 0.0001) break;
        p += rd * d * 0.4;
    }
    
    float factor = (it > 0.0) ? 1.0 / (0.4 * sqrt(abs(tan(iTime) + dot(p.xy, p.xy)))) : 1.0;
    it *= factor;

    vec3 c = mix(vec3(0.1, 0.1, 0.3), vec3(0.7, 0.1, 0.3), it * sin(p.z));
    vec4 bgColor = texture(iChannel0, openfl_TextureCoordv);

    if (strength <= 0.0) {
        fragColor = bgColor;
        return;
    }

    fragColor = mix(bgColor, vec4(c, 1.0), strength);
    fragColor.a = bgColor.a;
}