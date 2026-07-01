#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength;
uniform float money;
uniform float saturation;

#define iChannel0 bitmap
#define texture flixel_texture2D

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
    vec4 texColor = texture(iChannel0, fragCoord / iResolution.xy);

    for(float i = 1.0; i < 10.0; i++)
    {
        uv.x += 0.6 / i * cos(i * 2.5 * uv.y + iTime);
        uv.y += 0.6 / i * cos(i * 1.5 * uv.x + iTime);
    }

    float wave = abs(sin(iTime - uv.y - uv.x));

    vec3 baseEffect = vec3(0.1);

    vec3 hsv = rgb2hsv(baseEffect);

    if (money == 0.0) {
        hsv.x = rgb2hsv(baseEffect).x;
    }
    else if (money == 1.0) {
        hsv.x = 0.0;
    }
    else if (money >= 1.1) {
        hsv.x = mod(iTime * 0.1, 1.0);
    }
    else {
        hsv.x = mod(money, 1.0);
    }

    hsv.y = saturation;
    hsv.z = 0.1;

    vec3 effectColor = hsv2rgb(hsv) / max(wave, 0.05) * strength;

    fragColor = vec4(texColor.rgb + effectColor, texColor.a);
}

void main()
{
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}